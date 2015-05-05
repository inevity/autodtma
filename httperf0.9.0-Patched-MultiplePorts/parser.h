#include <stdio.h> 
#include <malloc.h> 
#include <stdlib.h> 
#include <string.h>
#include <assert.h>

 
typedef struct NameValue NV; 
struct NameValue  
{ 
	NV *next; 
	char *name; 
	char *value; 
}; 
 
struct Link  
{ 
	char *url; 
	NV *namevaluelist; 
}; 


extern  char * stristr(char * pszSource, const char * pcszSearchconst);
extern  void formlink(char *url,struct Link *inputlink);
extern char * parse_html(char *page,struct Link *readlink);
extern char * comparelink(struct Link *inputlink,struct Link *readlink);
extern void freelink(NV *current);
