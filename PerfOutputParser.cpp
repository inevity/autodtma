// PerfDataManager.cpp : This Program recives the name of input file which contains a "Perf" report then 
//normalize and summerize it in the report in the output file
//Copyright (C) MAY 2011 : RSH

//#################################################################

#include "stdio.h"
#include "stdlib.h"
#include "string.h"

int main(int argc, char *argv[])
{
	if (argc<2){
		printf("The experiment name is missing as the input. Program exited without doing anything!");
		exit(0);
	}

	char * pch;
	FILE * current;
	FILE * out;
	FILE * eventf;
	FILE * rate_file;
	char testname[200];
	const char * eventfilename="perfevent.txt";
	char filename[200];
	char line[1000];
	char lineout[4][1000];
	char eventnametmp[1000];
	int eventcode[4];
	char * rate;
	char * count;
	char * eventname;
	long scale[4]={0,0,0,0};
	long long  value[4]={0,0,0,0};
	long t=0;
	int eventnumber=0;
	int i=0;
	int j=0;
	int tmp=0;
	double Rate=0.0;
	

	char path[1000];

	strcpy(path,"./RUNs/");
	strcat(path,testname);
	strcat(path,"/");

	strcpy(testname,argv[1]);

	strcpy(filename,path);
	strcat(filename,"perf_output.csv");

	// Opening output file
	out=fopen(filename,"w");
	if(!out){
		printf("\nError opening output file %s\n",filename);
		exit(0);
	}
	
	rate_file=fopen("ProfilerRates.txt","r");
	
	if (!rate_file){
				printf("Error opening rate file. Program exited without doing anything! ");
		exit(0);
	}

	eventf=fopen(eventfilename,"r");

	if (!eventf){
		printf("Can not open the perf events file");
		exit(0);
	}

	i=0;
	// Reading Event List
	while(fgets(line,20,eventf)){
		eventname=strstr(line,",");
		strcpy(lineout[i],eventname+1);
		lineout[i][strlen(lineout[i])-1]=0;
		eventname=strtok(line,",");
		eventcode[i]=strtoul(eventname,NULL,16);
		i++;
	}
	
	// Sorting Events
	for(i=0;i<4;i++)
		for(j=i;j<4;j++)
			if(eventcode[i]>eventcode[j]){
				tmp=eventcode[i];
				eventcode[i]=eventcode[j];
				eventcode[j]=tmp;

				strcpy(eventnametmp,lineout[i]);
				strcpy(lineout[i],lineout[j]);
				strcpy(lineout[j],eventnametmp);
			}

	fprintf(out,"rate");
	for(i=0;i<4;i++)
		fprintf(out,",%s",lineout[i]);
	fprintf(out,"\n");

	//Writeing Events In the output
	while(fgets(line,20,rate_file)){
		rate=strtok(line,",");
		Rate=atof(rate);

		sprintf(filename,"%sprofiler-%s-%s.csv",path,testname,rate);
		printf("\nOpening ... %s\n",filename);

		// Opening profiler output file for current rate
		current=fopen(filename,"r");
		if (!current){
			printf("\nError opening file: %s -->skipping this file\n",filename);
			continue;
		}

		eventnumber=0;
		for(i=0;i<4;i++)
			value[i]=0;
		while (fgets(line,1000,current)){
			if(!strstr(line,"# Events: "))
				continue;
			else{
				scale[eventnumber]=atoi(line+10);
				if (*(line+11) == 'M')
					scale[eventnumber]*=1000;
				printf("%ld %s\n",scale[eventnumber],line+10);
				fgets(line,1000,current);
				fgets(line,1000,current);
				while (fgets(line,1000,current)){
					if(line[0]==10)
						break;
					count=strtok(line,",");
					count=strtok(NULL,",");
					t=(atol(count)/scale[eventnumber]);
					value[eventnumber]+=t;
					if (value[eventnumber]<0)
						printf(" %ld ",value[eventnumber]);
				//	printf("%d,%s,%d ",value[eventnumber],count,eventnumber);
				}
				if(!scale[eventnumber])
					printf("Error measuring Scales!!!!");
				eventnumber++;
			}
		}
		fprintf(out,"%f",Rate);
		for(i=0;i<eventnumber;i++)
			fprintf(out,",%lld",value[i]);
		fprintf(out,"\n");
	
		fclose(current);

	}
fclose(rate_file);
fclose(out);
fclose(eventf);

return 0;
}


//#################################################################

