// To calculate average of values in the files
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#define cpu_num 12
int main(int argc, char *argv[])
{
	int test_duration = 0;
	float idlecpuavg[cpu_num];
	float idlecpumin[cpu_num];
	float usercpuavg[cpu_num];
	float usercpumin[cpu_num];
	float syscpuavg[cpu_num];
	float syscpumin[cpu_num];
	char filename[1000];
	char line[10001];
	char temp[500];
	char out[5000];
	out[0]=' ';
	out[1]='\0';
	float **cpus_idle=new float*[cpu_num];
	float **cpus_user=new float*[cpu_num];
	float **cpus_sys=new float*[cpu_num];
	char * pch;
	FILE * current;
	FILE * idledat;
	FILE * userdat;
	FILE * sysdat;
	if (argc<8){
		printf("AverageCalculator: Not Enough Arguments\nProgram exited without doing anything!");
		exit(0);
	}
//AverageCalculator $datfilename(arg1) $rate 10 $TotalCores $Home$testname/ $Sessionbased $Connections >> UtilSummary$test    name.csv
	float rate=atof(argv[2]);	// Current request rate,erate or peroid?
	int spare=atoi(argv[3]);    // Number of Spare samples collected before test
    int cpunum=atoi(argv[4]);
	int sessbased=atoi(argv[6]); // Is the workload session based
	int connections=atoi(argv[7]); // Total number of connections in the test (sessions)
	strcpy(filename,argv[5]);
	strcat(filename,"tmp/Total_Idle");//home.testname.tmp.totalidle.utiltestname00015.dat
	strcat(filename,argv[1]); // Name of output data file
	strcat(filename,".dat"); 
	idledat=fopen(filename,"w");
	strcpy(filename,argv[5]); // Name of output data file,home.testname.tmp.totaluser.utiltestname00015.dat
	strcat(filename,"tmp/Total_User");
	strcat(filename,argv[1]); // Data file path
	strcat(filename,".dat"); 
	userdat=fopen(filename,"w");
	strcpy(filename,argv[5]); // Name of output data file,sys.dat
	strcat(filename,"tmp/Total_Sys");
	strcat(filename,argv[1]); // Data file path ,utiltestname00015
	strcat(filename,".dat"); 
//        printf("dat per cpu filename %s\n",filename);
	sysdat=fopen(filename,"w");
	if (!sysdat || !userdat || !idledat){
		
		printf("AverageCalculator: Cannot open %s\nProgram exited without doing anything! ",filename);
		exit(0);

	}
	strcpy(filename,argv[5]);
	strcat(filename,argv[1]);//home.testname.utiltestname000015
	strcat(filename,".csv"); //home.testname.utiltestname.csv,collectl outputfile
	current=fopen(filename,"r");
	if (!current){
		printf("AverageCalculator: Cannot open %s\nProgram exited without doing anything! ",filename);
		exit(0);
	}
	// Discarding the spare samples ,fgets but do nothing,the time=req time,only focus req time?
	for (int j=0;j<spare;j++){
		fgets(line,10000,current);
	}
	//Caclulating test duration
	if (sessbased)
		test_duration = sessbased;
	else
		//test_duration = rate* connections +2;//correct?
		test_duration = rate* connections -3;//correct?

	for( int j=0;j<cpu_num;j++){// 12 cores
		cpus_idle[j]=new float[test_duration];//array object
		cpus_user[j]=new float[test_duration];
		cpus_sys[j]= new float[test_duration];
	}
	for(int j=0;j<test_duration;j++){//collect data
			fgets(line,10000,current);
			pch = strtok (line,",");
			pch = strtok (NULL,",");
			int k=0;
			int l=0;
			while (pch != NULL && l!=cpu_num)
			{
	//			printf ("cpu .......%d\n",l);
			
				pch = strtok (NULL, ",");
				cpus_user[l][j] = atoi(pch);//l is cpuindex
				
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				cpus_sys[l][j] = atoi(pch);
             		
//				printf ("pch should sys per cpu %d  %s\n",l,pch);
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
//				printf ("pch should idle per cpu %d  %s\n",l,pch);
				cpus_idle[l][j] = atoi(pch);
				
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				pch = strtok (NULL, ",");
				l++;
			}
		}
	float totalavg[3]={0,0,0};
	float totalmin[3]={100*cpunum,0,0};
	float tmp[3]={0,0,0};
			int b=0;
			for(b=0;b<test_duration;b++){//test_duration !=collectl sample couts.. each second each total.
				for (int j=0;j<cpu_num;j++){
					tmp[0]+=cpus_idle[j][b];
					tmp[1]+=cpus_user[j][b];
					tmp[2]+=cpus_sys[j][b];
				}
				totalavg[0]+=tmp[0];
				totalavg[1]+=tmp[1];
				totalavg[2]+=tmp[2];
				fprintf(idledat,"%f\n",tmp[0]);
				fprintf(userdat,"%f\n",tmp[1]);
				fprintf(sysdat,"%f\n",tmp[2]);
				if (tmp[0]<totalmin[0])
					totalmin[0]=tmp[0];
				if (tmp[1]>totalmin[1])
					totalmin[1]=tmp[1];
				if (tmp[2]>totalmin[2])
					totalmin[2]=tmp[2];
				tmp[0]=0;
				tmp[1]=0;
				tmp[2]=0;
			}
			fclose(idledat);
			fclose(sysdat);
			fclose(userdat);
			totalavg[0]/=test_duration;
			totalavg[1]/=test_duration;
			totalavg[2]/=test_duration;
			sprintf(temp,"%.8f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,",rate,100*cpunum-totalavg[0],100*cpunum-totalmin[0],totalavg[1],totalmin[1],totalavg[2],totalmin[2]);
			strcat(out,temp);
//next per cpu statistic
			for (int j=0;j<cpu_num;j++){
				idlecpuavg[j]=0;
				idlecpumin[j]=cpus_idle[j][0];
				usercpuavg[j]=0;
				usercpumin[j]=cpus_user[j][0];
				syscpuavg[j]=0;
				syscpumin[j]=cpus_sys[j][0];
			}
			for (int j=0;j<cpu_num;j++){
				for(int m=0;m<test_duration;m++){
					idlecpuavg[j]+=cpus_idle[j][m];
					usercpuavg[j]+=cpus_user[j][m];
					syscpuavg[j]+=cpus_sys[j][m];
					if (idlecpumin[j] > cpus_idle[j][m])
						idlecpumin[j]=cpus_idle[j][m];
					if (usercpumin[j] > cpus_user[j][m])
						usercpumin[j]=cpus_user[j][m];
					if (syscpumin[j] > cpus_sys[j][m])
						syscpumin[j]=cpus_sys[j][m];
				}
				idlecpuavg[j]/=test_duration;
				usercpuavg[j]/=test_duration;
				syscpuavg[j]/=test_duration;
				sprintf(temp,"%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,",100-idlecpuavg[j],100-idlecpumin[j],usercpuavg[j],usercpumin[j],syscpuavg[j],syscpumin[j]);
				strcat(out,temp);
			}
		strcat(out,"\n");
		printf("%s",out);
		fclose(current);
		return 0;
	}

