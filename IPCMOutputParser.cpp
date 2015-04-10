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
	char testname[1000];
	char path[1000];
	char filename[1000];

	strcpy(testname,argv[1]);
	// The path for all files related to this experiment
	strcpy(path,"./RUNs/");
	strcat(path,testname);
	strcat(path,"/");


	char * pch;
	FILE * current;
	FILE * out;
	FILE * rate_file;
	char * samples;
	
	char line[1000];
	char lineout[4][1000];
	char eventnametmp[1000];
	int eventcode[4];
	char * rate;
	char * count;
	double Rate=0.0;
	int max_samples=0;
	long double  sum[20];
	long double t=0;
	int Sample_num=0;
	int i=0;
	int j=0;
	int tmp=0;

	strcpy(filename,path);
	strcat(filename,"IPCM_output.csv");

	// Opening output file
	out=fopen(filename,"w");
	if(!out){
		printf("\nError opening file %s\n",filename);
		exit(0);
	}

	rate_file=fopen("ProfilerRates.txt","r");
	
	if (!rate_file){
				printf("Error opening rate file. Program exited without doing anything! ");
		exit(0);
	}	
	
	
	//Writeing Events In the output

	fprintf(out,"Rate, EXEC , IPC  , FREQ  , AFREQ , L3MISS , L2MISS , L3HIT , L2HIT , L3CLK , L2CLK  , READ (SK0), READ (SK1) , WRITE (SK0),WRITE (SK1), SKt0-IC, SKt0-IO, SKt1-IC, SKt1-IO,Total QPI incoming data traffic, QPI data traffic by Memory controller traffic \n");

	while(fgets(line,20,rate_file)){
		rate=strtok(line,",");
		Rate=atof(rate);
		samples=strtok(NULL,"\n");
		max_samples=atoi(samples);
		
		sprintf(filename,"%sprofiler-%s-%s.csv",path,testname,rate);
		printf("\nOpening ... %s\n",filename);

		// Opening profiler output file for current rate
		current=fopen(filename,"r");
		if (!current){
			printf("\nError opening file: %s -->skipping this file\n",filename);
			continue;
		}
		
		Sample_num=0;
		for(i=0;i<20;i++)
			sum[i]=0;
		while (fgets(line,1000,current)){
			if(!strstr(line,"TOTAL")){
				//printf("...%s ...\n",line);
				continue;
			}
			else{	
				Sample_num++;
				if(Sample_num>max_samples){
					//printf("\nhere %d\n",max_samples);
					break;
				}
				//count=strtok(line,",");
				count=strtok(line,",");
				i=0;
				while(count=strtok(NULL,",")){
					
					//printf(">>>%s<<<   >>>%d<<<\n",count,i);
					t=(atof(count));
					//printf("\n%Lf\n",t);
					if(strstr(count,"K")){
						t*=1024;
						//printf("%s\n",count);
					}
					if(strstr(count,"M"))
						t*=1048576;
					if(strstr(count,"G"))
						t*=1074790400;
					sum[i]+=t;
					i++;
				}
				if (i!=20)
					printf(" wrong input !!!!! %d",i);
			}
		}
			fprintf(out,"%f",Rate);
			for(i=0;i<20;i++){
				fprintf(out,",%Lf",sum[i]/double(Sample_num));
				//printf("%Lf,%d,",sum[i],Sample_num);
			}
			fprintf(out,"\n");
			//printf("\n");
			fclose(current);
		
	}
		fclose(rate_file);
		fclose(out);
		return 0;
	}


