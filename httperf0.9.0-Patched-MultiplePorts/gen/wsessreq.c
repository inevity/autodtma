/*
    httperf -- a tool for measuring web server performance
    Copyright (C) 2000  Hewlett-Packard Company
    Contributed by Richard Carter <diwa@sce.carleton.ca>

    This file is part of httperf, a web server performance measurment
    tool.

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
    02111-1307 USA
*/

/* Creates a session workload at a fixed request rate given by PARAM.RATE.  
   The session descriptions are read in from a configuration file.

   This tool is heavily inspired by the wsesslog uri generator by Richard Carter 
   <carter@hpl.hp.com>.
   The main differences between wsessreq and wsesslog are
   1) wsesslog interprets PARAM.RATE as the rate at which new sessions are generated 
      whereas wssessreq interprets it as the rate at which new requests are generated. 
   2) In wsesslog, a session consists of several bursts separated by think times. A burst 
      may consist of more than one request.  wsessreq does not have notions of bursts and 
      think times.  In wsessreq, a session merely consists of a sequence of requests.

   There is currently no tool that translates from standard log formats to the format 
   accepted by this module.

   An example input file follows:

   #
   # This file specifies uri sequences for a number of user
   # sessions.  The format rules of this file are as follows:
   #
   # Comment lines start with a '#' as the first character.  # anywhere else
   # is considered part of the uri.
   #
   # Lines with only whitespace delimit session definitions (multiple blank
   # lines do not generate "null" sessions).
   #
   # Lines otherwise specify a uri-sequence (1 uri per line).

   # session 1 definition (this is a comment)

   /foo.html
   /foo2.html

   # session 2 definition

   /foo3.html
   /foo4.html
   /foo5.html

   Any comment on this module contact diwa@sce.carleton.ca  */

#include <ctype.h>
#include <errno.h>

#include <httperf.h>
#include <conn.h>
#include <core.h>
#include <event.h>
#include <rate.h>
#include <session.h>
#include <timer.h>

#include <parser.h>



/* Maximum number of sessions that can be defined in the configuration
   file.  */
#define MAX_SESSION_TEMPLATES	10030

#define TRUE  (1)
#define FALSE (0)

#define SESS_PRIVATE_DATA(c)						\
  ((Sess_Private_Data *) ((char *)(c) + sess_private_data_offset))

typedef struct req REQ;
struct req
  {
    REQ *next;                 
    int method;
    char *uri;
    int uri_len;
    char *contents;
    int contents_len;
    char extra_hdrs[50];	/* plenty for "Content-length: 1234567890" */
    int extra_hdrs_len;
    
  };


typedef struct Sess_Private_Data Sess_Private_Data;
struct Sess_Private_Data
  {

    int total_num_reqs;		/* total number of requests in this session */
    u_int num_calls_destroyed;
    REQ *current_req;		/* the current request we're working on */
 
    int texthtml;

  };

/* A Queue that holds inactive sessions (sessions not currently submitting requests) */
typedef struct OQueue OffQueue;
struct OQueue
{
	OffQueue *next;
        OffQueue *prev;
	Sess *session;
};
	

/* Methods allowed for a request: */
enum
  {
    HM_DELETE, HM_GET, HM_HEAD, HM_OPTIONS, HM_POST, HM_PUT, HM_TRACE,
    HM_LEN
  };
static const char *call_method_name[] =
  {
    "DELETE", "GET", "HEAD", "OPTIONS", "POST", "PUT", "TRACE"
  };


static size_t sess_private_data_offset;
static Time end;
static int num_sessions_generated;
static int num_sessions_destroyed;
static Rate_Generator rg_sess;
/* This is an array rather than a list because we may want different
   httperf clients to start at different places in the sequence of
   sessions. */
static int num_templates;
static int next_session_template;
static Sess_Private_Data session_templates[MAX_SESSION_TEMPLATES] =
  {
    { 0, }
  };

/* Pointers to the top and bottom of the OffQueue */
static OffQueue *toq,*boq;

static void
sess_destroyed (Event_Type et, Object *obj, Any_Type regarg, Any_Type callarg)
{
  Sess_Private_Data *priv;
  Sess *sess;
  Time now;
  
  assert (et == EV_SESS_DESTROYED && object_is_sess (obj));
  sess = (Sess *) obj;

  priv = SESS_PRIVATE_DATA (sess);
 
  now=timer_now();
  if(now>=end)core_exit();
  if (++num_sessions_destroyed >= param.wsessreq.num_sessions) core_exit ();
}

static void
issue_calls (Sess *sess, Sess_Private_Data *priv)
{
  int  retval;
  const char *method_str;
  Call *call;
  REQ *req;
  
  call = call_new ();
  if (!call)
  {
	sess_failure (sess);
	return;
  }

  req = priv->current_req;
  if (req == NULL)
	panic ("%s: internal error, requests ran past end of session\n",
	       prog_name);
  method_str = call_method_name[req->method];
  call_set_method (call, method_str, strlen (method_str));
  call_set_uri (call, req->uri, req->uri_len);
  if (req->contents_len > 0)
  {
	 /* add "Content-length:" header and contents, if necessary: */
	  call_append_request_header (call, req->extra_hdrs,
				      req->extra_hdrs_len);
	  call_set_contents (call, req->contents, req->contents_len);
  }

  if (DBG > 0)
	fprintf (stderr, "%s: accessing URI `%s'\n", prog_name, req->uri);
        retval = session_issue_call (sess, call);
	
	call_dec_ref (call);

      if (retval < 0)
	return;

}



/* Create a new request by issuing a request in an inactive session or by creating a new
   session */
static int
req_create (Any_Type arg)
{
  Sess_Private_Data *priv, *template;
  Sess *sess;
  OffQueue *element;
  
  if(toq=='\0')
  {
        /* No inactive sessions and no more sessions to generate. Do nothing
           and return */
        if (num_sessions_generated++ >= param.wsessreq.num_sessions)
            		return 1;
  	/* No inactive sessions. A new session must be created from a session template
           and the first request in that session must be issued. */
        sess = sess_new ();

  	template = &session_templates[next_session_template];
  	if (++next_session_template >= num_templates)
    		next_session_template = 0;

  	priv = SESS_PRIVATE_DATA (sess);
  	priv->current_req = template->current_req;
  	priv->total_num_reqs = template->total_num_reqs;

  	if (DBG > 0)
    		fprintf (stderr, "Starting session, number of requests = %d\n",
	     priv->total_num_reqs);
  	issue_calls (sess, SESS_PRIVATE_DATA (sess));
  }
  else
  {
        /* Pick an inactive session from the top of the queue and issue its current request */ 
        element=toq;
	if(toq==boq)
	{
                toq='\0';
		boq='\0';
	}
        else
	{
          	toq=toq->next;
		toq->prev='\0';
	}
	sess=element->session;
	free(element);
        
	if(DBG > 0)
		fprintf(stderr, "Resuming existing session\n");
        issue_calls(sess,SESS_PRIVATE_DATA(sess));	
  }
  return 0;
}

static void
prepare_for_next_request (Sess *sess, Sess_Private_Data *priv)
{
 
  OffQueue *element;
 
  /* advance to next req: */
  priv->current_req = priv->current_req->next;
  if(priv->current_req!=NULL)
  {
        /* If there are more request to be submitted in this session, queue it in
           the inactive sessions queue. */

  	element=(OffQueue *)malloc(sizeof(*element));
        if(!element)
	{
		fprintf(stderr,"yikes....no memory\n");
		exit(-1);
	}
  	element->session=sess;
  	element->next='\0';
        element->prev='\0';
  	if(toq=='\0')
	{
		toq=element;
		boq=element;
	}
  	else
  	{
  		boq->next=element;
        	element->prev=boq;
                boq=element;
  	}
  }
	     
}
/*diwa*/

static void
recv_hdr(Event_Type et,Object *obj, Any_Type regarg, Any_Type callarg)
{
 	char *hdr,*ctindex,*thindex,*oldthindex;
 	int i;
 	struct iovec *line;
 	Sess_Private_Data *priv;
 	Sess *sess;
 	Call *call;
 
 	assert (et == EV_CALL_RECV_HDR && object_is_call (obj));
 	call = (Call *) obj;
 	sess = session_get_sess_from_call (call);
 	priv = SESS_PRIVATE_DATA (sess);

 	line=callarg.vp;
	hdr=(char *)malloc(strlen(line->iov_base)+1);
	if(!hdr)
	{
		fprintf(stderr,"yikes...no memory \n");
		exit(-1);
	}
	hdr=strcpy(hdr,line->iov_base);
 	for(i=0;i<strlen(hdr);i++)
 	{
   		hdr[i]=tolower(hdr[i]);
 	}
 	ctindex=strstr(hdr,"content-type");
 	if(ctindex)
 	{
   		thindex=strstr(ctindex,":");
   		if(thindex)
   		{
     			thindex++;
     			for(i=0;i<strlen(thindex);i++)
     			{			
       				if(!(thindex[i]==' '))break;
       				thindex++;
     			}
     			oldthindex=thindex;
     			for(i=0;i<strlen(thindex);i++)
     			{
       				if(thindex[i]==' ')
       				{
         				thindex[i]='\0';
         				break;
        			}
        			thindex++;
     			}
     			thindex=oldthindex;
     			if(strcasecmp("text/html",thindex)==0)
        		priv->texthtml=1;
   		}
 	}
	free(hdr);

}
static void
recv_done(Event_Type et, Object *obj, Any_Type regarg, Any_Type callarg)
{
	char *dollorparse,*nuri,*newpage,*newuri;
	Sess_Private_Data *priv;
 	Sess *sess;
 	Call *call;
 	REQ *req;
	struct Link inputlink;
	struct Link readlink;
	char *oldnuri;
	int old_len;
	NV *current,*readcurrent;

	assert(et==EV_CALL_RECV_STOP && object_is_call (obj));
        
 	call = (Call *) obj;
 	sess = session_get_sess_from_call (call);
 	priv = SESS_PRIVATE_DATA (sess);
 
 	req=priv->current_req->next;
	
	inputlink.namevaluelist=NULL;
	readlink.namevaluelist=NULL;
	if(req && (priv->texthtml==1))
 	{
		
   		nuri=req->uri;
                old_len=strlen(nuri)+1;
		oldnuri=malloc(old_len);
		if(!oldnuri)exit(1);
		strcpy(oldnuri,nuri);
  		dollorparse=stristr(nuri,"$parse");
		if(dollorparse)
		{
			formlink(nuri,&inputlink);
			current=inputlink.namevaluelist;
			if(current!=NULL)
			{
				newpage=call->page;
				readcurrent=NULL;
				newuri=NULL;
				while((newpage=parse_html(newpage,&readlink))!=NULL)
				{
					readcurrent=readlink.namevaluelist;
					if(readcurrent!=NULL)
					{
						newuri=comparelink(&inputlink,&readlink);
						if(newuri!=NULL)break;
						/*fprintf(stderr,"Freeing readcurrent\n");*/
						freelink(readcurrent);
						readcurrent=NULL;
					}
				}
				if(newuri!=NULL)
				{
						/*fprintf(stderr,"Freeing %s \n",priv->current_burst->next->req_list->uri);*/
						free(priv->current_req->next->uri);
						priv->current_req->next->uri=newuri;
						priv->current_req->next->uri_len=strlen(newuri);
						/*fprintf(stderr,"Freeing readcurrent in newuri not null\n");*/
                        			/*req->oldnuri=oldnuri;
						req->old_len=old_len-1;*/
						freelink(readcurrent);
				}
				else
				{
					/*fprintf(stderr,"Freeing %s \n",priv->current_burst->next->req_list->uri);*/
					free(priv->current_req->next->uri);
					priv->current_req->next->uri=oldnuri;
					priv->current_req->next->uri_len=strlen(oldnuri)/*old_len-1*/;
				}
						
				/*fprintf(stderr,"Freeing current\n");*/
				freelink(current);			
			}
				
		}

		priv->texthtml=0;
	}
free(call->page);
	
}

static void
call_destroyed (Event_Type et, Object *obj, Any_Type regarg, Any_Type callarg)
{
  Sess_Private_Data *priv;
  Sess *sess;
  Call *call;

  assert (et == EV_CALL_DESTROYED && object_is_call (obj));
  call = (Call *) obj;
  sess = session_get_sess_from_call (call);
  priv = SESS_PRIVATE_DATA (sess);

  ++priv->num_calls_destroyed;

  if (priv->num_calls_destroyed >= priv->total_num_reqs)
    /* we're done with this session */
    sess_dec_ref (sess);
  else 
    prepare_for_next_request (sess,priv);

}

/* Allocates memory for a REQ and assigns values to data members.
   This is used during configuration file parsing only.  */
static REQ*
new_request (char *uristr)
{
  REQ *retptr;

  retptr = (REQ *) malloc (sizeof (*retptr));
  if (retptr == NULL || uristr == NULL)
    panic ("%s: ran out of memory while parsing %s\n",
	   prog_name, param.wsessreq.file);  

  memset (retptr, 0, sizeof (*retptr));
  retptr->uri = uristr;
  retptr->uri_len = strlen (uristr);
  retptr->method = HM_GET;
  return retptr;
}


/* Read in session-defining configuration file and create in-memory
   data structures from which to assign uri_s to calls. */
static void
parse_config (void)
{
  FILE *fp;
  int lineno, i;
  Sess_Private_Data *sptr;
  char line[10000];	/* some uri's get pretty long */
  char uri[10000];	/* some uri's get pretty long */
  char method_str[1000];
  char this_arg[10000];
  char contents[10000];
  int bytes_read;
  REQ *reqptr,*current_req=0;
  char *from, *to, *parsed_so_far;
  int ch;
  int single_quoted, double_quoted, escaped, done;
  
  fp = fopen (param.wsessreq.file, "r");
  if (fp == NULL)
    panic ("%s: can't open %s\n", prog_name, param.wsessreq.file);  

  num_templates = 0;
  sptr = &session_templates[0];

  for (lineno = 1; fgets (line, sizeof (line), fp); lineno++)
    {
      if (line[0] == '#')
	continue;		/* skip over comment lines */

      if (sscanf (line,"%s%n", uri, &bytes_read) != 1)
	{
	  /* must be a session-delimiting blank line */
	   if(sptr->current_req!=NULL)
	   {
           	sptr->texthtml=0;
	   	sptr++;		/* advance to next session */
	  	continue;
	   }
	}
      /* looks like a request-specifying line */
      reqptr=new_request (strdup (uri) );

      if (sptr->current_req == NULL)
	{
	  num_templates++;
	  if (num_templates > MAX_SESSION_TEMPLATES)
	    panic ("%s: too many sessions (%d) specified in %s\n",
		   prog_name, num_templates, param.wsessreq.file);  
	  current_req = sptr->current_req = reqptr;
	}
      else
	{
            current_req->next=reqptr;
	    current_req = reqptr;
            
	}
      /* do some common steps for all new requests */
      sptr->total_num_reqs++;
      /* parse rest of line to specify additional parameters of this
	 request and burst */
      parsed_so_far = line + bytes_read;
      while (sscanf (parsed_so_far, " %s%n", this_arg, &bytes_read) == 1)
	{
	  if (sscanf (this_arg, "method=%s", method_str) == 1)
	    {
	      for (i = 0; i < HM_LEN; i++)
		{
		  if (!strncmp (method_str,call_method_name[i],
				strlen (call_method_name[i])))
		    {
		      current_req->method = i;
		      break;
		    }
		}
	      if (i == HM_LEN)
		panic ("%s: did not recognize method '%s' in %s\n",
		       prog_name, method_str, param.wsessreq.file);  
	    }
	  
	  else if (sscanf (this_arg, "contents=%s", contents) == 1)
	    {
	      /* this is tricky since contents might be a quoted
		 string with embedded spaces or escaped quotes.  We
		 should parse this carefully from parsed_so_far */
	      from = strchr (parsed_so_far, '=') + 1;
	      to = contents;
	      single_quoted = FALSE;
	      double_quoted = FALSE;
	      escaped = FALSE;
	      done = FALSE;
	      while ((ch = *from++) != '\0' && !done)
		{
		  if (escaped == TRUE)
		    {
		      switch (ch)
			{
			case 'n':
			  *to++ = '\n';
			  break;
			case 'r':
			  *to++ = '\r';
			  break;
			case 't':
			  *to++ = '\t';
			  break;
			case '\n':
			  *to++ = '\n';
			  /* this allows an escaped newline to
			     continue the parsing to the next line. */
			  if (fgets(line,sizeof(line),fp) == NULL)
			    {
			      lineno++;
			      panic ("%s: premature EOF seen in '%s'\n",
				     prog_name, param.wsessreq.file);  
			    }
			  parsed_so_far = from = line;
			  break;
			default:
			  *to++ = ch;
			  break;
			}
		      escaped = FALSE;
		    }
		  else if (ch == '"' && double_quoted)
		    {
		      double_quoted = FALSE;
		    }
		  else if (ch == '\'' && single_quoted)
		    {
		      single_quoted = FALSE;
		    }
		  else
		    {
		      switch (ch)
			{
			case '\t':
			case '\n':
			case ' ':
			  if (single_quoted == FALSE &&
			      double_quoted == FALSE)
			    done = TRUE;	/* we are done */
			  else
			    *to++ = ch;
			  break;
			case '\\':		/* backslash */
			  escaped = TRUE;
			  break;
			case '"':		/* double quote */
			  if (single_quoted)
			    *to++ = ch;
			  else
			    double_quoted = TRUE;
			  break;
			case '\'':		/* single quote */
			  if (double_quoted)
			    *to++ = ch;
			  else
			    single_quoted = TRUE;
			  break;
			default:
			  *to++ = ch;
			  break;
			}
		    }
		}
	      *to = '\0';
	      from--;		/* back up 'from' to '\0' or white-space */
	      bytes_read = from - parsed_so_far;
	      if ((current_req->contents_len = strlen (contents)) != 0)
		{
		  current_req->contents = strdup (contents);
		  sprintf (current_req->extra_hdrs,
			    "Content-length: %d\r\n",
			   current_req->contents_len);
		  current_req->extra_hdrs_len =
		    strlen (current_req->extra_hdrs);
		}
	    }
	  else
	    {
	      /* do not recognize this arg */
	      panic ("%s: did not recognize arg '%s' in %s\n",
		     prog_name, this_arg, param.wsessreq.file);  
	    }
	  parsed_so_far += bytes_read;
	}
    }
  fclose (fp);

  if (DBG > 3)
    {
      fprintf (stderr,"%s: session list follows:\n\n", prog_name);

      for (i = 0; i < num_templates; i++)
	{
	  sptr = &session_templates[i];
	  fprintf (stderr, "#session %d (total_reqs=%d):\n",
		   i, sptr->total_num_reqs);
	    

	      for (reqptr = sptr->current_req;
		   reqptr;
		   reqptr = reqptr->next)
		{  
		  
		  fprintf (stderr, "%s", reqptr->uri);
		  if (reqptr->method != HM_GET)
		    fprintf (stderr," method=%s",
			     call_method_name[reqptr->method]);
		  if (reqptr->contents != NULL)
		    fprintf (stderr, " contents='%s'", reqptr->contents);
		  fprintf (stderr, "\n");
		}
	    }
	  fprintf (stderr, "\n");
	
    }
}

static void print_buf1(Call *call, const char *buf, int len)
{
	char *prevline;
  	prevline=call->page;
  	call->page=(char*)malloc(sizeof(char)*(strlen(prevline)+strlen(buf)+1));
	if(!call->page)
  	{
    		fprintf(stderr,"Yikes...no memory\n");
    		exit(-1);
  	}
   	strcpy(call->page,prevline);
   	strcat(call->page,buf);
	free(prevline);
}

static void
recv_data(Event_Type et,Object *obj, Any_Type regarg, Any_Type callarg)
{
 
	struct iovec *iov;
 	Sess_Private_Data *priv;
 	Sess *sess;
 	Call *call;
 	assert(et==EV_CALL_RECV_DATA && object_is_call (obj));

 	call = (Call *) obj;
 	sess = session_get_sess_from_call (call);
 	priv = SESS_PRIVATE_DATA (sess);
 
 	iov = callarg.vp;
 	if(priv->texthtml)
 	{
   		print_buf1(call, iov->iov_base, iov->iov_len);

 	}
}


static void
init (void)
{
  Any_Type arg;
 
  parse_config ();
  end=timer_now()+60*60;
  toq=boq='\0';
  sess_private_data_offset = object_expand (OBJ_SESS,
					    sizeof (Sess_Private_Data));
  rg_sess.rate = &param.rate;
  rg_sess.tick = req_create;
  rg_sess.arg.l = 0;

  arg.l = 0;
  event_register_handler (EV_SESS_DESTROYED, sess_destroyed, arg);
  event_register_handler (EV_CALL_DESTROYED, call_destroyed, arg);
  event_register_handler (EV_CALL_RECV_HDR,recv_hdr,arg);
  event_register_handler (EV_CALL_RECV_DATA,recv_data,arg);
  event_register_handler (EV_CALL_RECV_STOP,recv_done,arg);
  /* This must come last so the session event handlers are executed
     before this module's handlers.  */
  session_init ();

}

static void
start (void)
{
  rate_generator_start (&rg_sess, EV_CALL_DESTROYED);
}

Load_Generator wsessreq =
  {
    "creates session workload with specified request rate",
    init,
    start,
    no_op
  };
