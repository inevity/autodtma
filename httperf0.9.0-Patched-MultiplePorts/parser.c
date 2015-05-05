#include <parser.h>


char * stristr( char * pszSource, const char * pcszSearch )
//
//      Return a pointer to the start of the search string
//      If pszSource does not contain pcszSearch then returns NULL.
{
        const int nLength = strlen( pcszSearch );
        while( *pszSource )
        {
                if( !strncasecmp( pszSource, pcszSearch, nLength ) )
                        break;
                pszSource++;
        }

        if( !( *pszSource ) )
        {
                pszSource = NULL;
        }
        return pszSource;
}

void freelink(NV *current)
{
	NV *prev=NULL;
	while(current!=NULL)
	{
		prev=current;
		current=current->next;
		free(prev);
	}
}

char * comparelink(struct Link *inputlink,struct Link *readlink)
{
	int substrurl=-1;
	int substrname=-1;
	int dollorvalue=-1;
	int flag=0;

	char *substr=NULL;
	char temp[10000];
	char *retvalue=NULL;

	NV *currentinput=NULL;
	NV *currentread=NULL;
	temp[0]='\0';
	substrurl=strcasecmp((readlink)->url,(const char *)(inputlink)->url);
	if(substrurl==0)
	{
		substr=stristr(readlink->url,inputlink->url);
		if(substr==NULL)
		{
			return NULL;
		}
	}
	
	currentinput=(inputlink)->namevaluelist;
        while(currentinput!=NULL)
	{
		currentread=(readlink)->namevaluelist;
		while(currentread!=NULL)
		{
			substrname=strcasecmp((const char *)currentinput->name,(const char *)currentread->name);
			if(substrname==0)
			{
				substrname=-1;
				dollorvalue=strcasecmp(currentinput->value,"$parse");
				if(dollorvalue==0)
				{
					if(!flag)flag=1;
					dollorvalue=-1;
					currentinput->value=currentread->value;
					currentinput=inputlink->namevaluelist;
					continue;
				}
			}
			currentread=currentread->next;
		}
		currentinput=currentinput->next;
	}

	if(!flag)return NULL;
	else
	{
		strcat(temp,inputlink->url);
		strcat(temp,"?");
		currentinput=inputlink->namevaluelist;
		while(currentinput!=NULL)
		{
			strcat(temp,currentinput->name);
			strcat(temp,"=");
			strcat(temp,currentinput->value);
			if(currentinput->next!=NULL)strcat(temp,"&");
			currentinput=currentinput->next;
		}
		retvalue=(char *)malloc((strlen(temp)+1)*sizeof(char));
		if(!retvalue)
		{
			fprintf(stderr,"yikes...no memory \n");
			exit(-1);
		}
		strcpy(retvalue,temp);
		return retvalue;
	}

		
}
			

void formlink(char *url,struct Link *link)
{
	char *startofnamevalues=NULL;
	char *vstart=NULL;
	char *oldvstart=NULL;
		
	NV *current=NULL;
	NV *prev=NULL;
	
	startofnamevalues=(char *)strchr(url,'?');

	if(!startofnamevalues)
	{
		/*fprintf(stderr,"This URL does not contain ?\n");*/
		return;
	}
	/*now that we found out '?' we can do away with it to seperate url and nv*/
	*startofnamevalues='\0';
	/*Increment to point to start of name-value list*/
	startofnamevalues++;
	link->url=url;
	current=link->namevaluelist;
	while(1)
	{
                assert(startofnamevalues);
		vstart=strchr((const char *)startofnamevalues,'=');
		if(vstart==NULL)
		{
			/*fprintf(stderr,"This URL does not contain a
name-value list\n");*/ 			return;
		}
		
		*vstart='\0';
		vstart++;
		
		oldvstart=vstart;
		
		current=(NV *)malloc(sizeof(NV));
		if(current==NULL)
		{
			fprintf(stderr,"Yikes...no memory\n");
			exit(-1);
		}
		if(link->namevaluelist==NULL)
			link->namevaluelist=current;
		else
			prev->next=current;
		current->next=NULL;
		
		current->name=startofnamevalues;
		assert(oldvstart);
			
		vstart=strchr((const char *)oldvstart,'&');
		if(vstart==NULL)
		{
			current->value=oldvstart;
			break;
		}
		
		*vstart='\0';
		vstart++;
		current->value=oldvstart;
		prev=current;
		current=current->next;
		startofnamevalues=vstart;
	}	 	
                
}

char * parse_html(char *page,struct Link *readlink) 
{
	char *line=NULL; 
	char *linkbegin=NULL; 
	char *closebegin=NULL; 
	char *hrefposition=NULL; 
	char *urlend=NULL; 
	char *quotes=NULL; 
	char *nextline=NULL;
	char *oldlinkbegin=NULL;
	int hrefe=1,linke=0,closee=0,first=1; 
	
	
	while(page) 
	{ 
		nextline=strchr((const char *)page,'\n');
		if(nextline)*nextline='\0';
		else break;
		line=page;
		page=nextline+1;

		if(hrefe==1) 
		{ 
			hrefposition=stristr(line,"HREF"); 
			if(hrefposition==NULL)continue; 
			hrefe=0; 
			linke=1; 
		} 
		if(linke==1) 
		{ 
			linkbegin=strchr(line,'='); 
			if(linkbegin==NULL)continue; 
			linkbegin++; 
			assert(linkbegin); 
			linke=0; 
			closee=1; 
		} 
		if(closee==1) 
		{ 
			closebegin=stristr(line,"a>"); 
			if(closebegin==NULL)continue; 
			closee=0; 
			hrefe=1;
			urlend=strchr((const char *)linkbegin,'>'); 
			if(urlend) 
			{ 
				*urlend='\0'; 
				while((quotes=strchr((const char *)linkbegin,'\"'))) 
				{ 
					if(first) 
					{ 
						first=0; 
						linkbegin=quotes+1;
						oldlinkbegin=linkbegin;
						continue; 
					} 
					*quotes='\0'; 
				} 
				formlink(oldlinkbegin,readlink);
			}
			if(!(closebegin+2))return NULL;
			else
			{
				*nextline='\n';
				return (closebegin+2);
			}
		}
	}
	
	return NULL; 
	 
} 


	
