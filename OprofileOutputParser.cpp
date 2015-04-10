
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#define eventnum 4
int main(int argc, char *argv[])
{
	
	if (argc<2){
		printf("The experiment name is missing as the input. Program exited without doing anything!");
		exit(0);
	}

	char testname[1000];
	char path[1000];
	char filename[1000];

	FILE * rate_file;
	FILE* out;
	FILE* current;

	strcpy(testname,argv[1]);
	

	// The path for all files related to this experiment
	strcpy(path,"./RUNs/");
	strcat(path,testname);
	strcat(path,"/");



	char line2[1001];
	char line3[1001];
	char rate[100];

	// Opening rates file
	rate_file=fopen("rates.txt","r"); 
	if(!rate_file ){
		printf("Error opening rate file. Program exited without doing anything! ");
		exit(0);
	}
	strcpy(filename,path);
	strcat(filename,"oprofile_output.csv");
	// Opening output file
	out=fopen(filename,"w");
	if(!out){
		printf("\nError opening output file %s\n",filename);
		exit(0);
	}

	
	int *lin=new int[eventnum];
	float *linper=new float[eventnum];
	int *lighty=new int[eventnum];
	float *lightyper=new float[eventnum];

	while(fgets(rate,15,rate_file)){
		int len= strlen(rate);
		rate[len-1]='\0';


		sprintf(filename,"%sprofiler-%s-%s.csv",path,testname,rate);
		printf("\nNow openning ... %s\n",filename);

		// Opening profiler output file for current rate
		current=fopen(filename,"r");
		if (!current){
			printf("\nError opening file: %s -->skipping this file\n",filename);
			continue;
		}

		fgets(line2,1000,current);
		fgets(line3,1000,current);

		sscanf(line2,"%d %f %d %f %d %f %d %f",&lin[0],&linper[0],&lin[1],&linper[1],&lin[2],&linper[2],&lin[3],&linper[3]);
		sscanf(line3,"%d %f %d %f %d %f %d %f",&lighty[0],&lightyper[0],&lighty[1],&lightyper[1],&lighty[2],&lightyper[2],&lighty[3],&lightyper[3]);

		// Changing format of data in the output file
		for(int j=0;j<eventnum;j++){
		fprintf(out,"%d,%d,%d,%f,%f,%f,",lin[j],lighty[j],lighty[j]+lin[j],linper[j],lightyper[j],lightyper[j]+linper[j]);
		}

		fprintf(out,"\n");

		fclose(current);
	}

	fclose(rate_file);
	fclose(out);
	return 0;
}

