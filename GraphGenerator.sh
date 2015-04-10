### !/bin/bash
				##############################################
				##						  ##
				## Developed by Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
###########################################################################################################
### The purpose of this script is to manage the output data collected from a performance testing process ###
### The data includes: 												###
###	1) CPU utilization for each core										###
###	2) Performance Metrics (e.g., Response time, Throughput)						###
###	3) Hardware Monitoring Events 										###
###															###
### Input Parameters: 												###
### 	1) Test name													###
###    2) Number of cores in the server										###
###	3) Output graph type (e.g., JPEG, PNG, ...)								###
###	4) Active Cores Location (2:Different, 4:Same)								###
###	5) Number of Sessions (0 if the workload is not session based						###
###	6) Number of connections in non-sessionbased workloads							###
###	7) File "Home" Folder											###
############################################################################################################

testname=$1
TotalCores=$2
ActiveCoreLocation=$3
GraphType=$4
Sessionbased=$5 
Connections=$6
Home=$7
### Home folder

cd $Home$testname
tempfile="./tmp/temp.txt"
rm -r Plots
rm -r tmp
mkdir tmp

############################# CPU Utilization Graph Generator ##########################
declare -i y=3
z=0
ls | grep util > $tempfile
###############################################
##### Opening utilization file name lists #####
###############################################
FILE=""
# Make sure we get file name as command line argument
# Else read it from standard input device
if [ "$tempfile" == "" ]; then
   FILE="/dev/stdin"
   echo "You should Enter the name of rates file as the second argument"
else
   FILE="$tempfile"
   # make sure file exist and readable
   if [ ! -f $FILE ]; then
  	echo "$FILE : does not exists"
  	exit 1
   elif [ ! -r $FILE ]; then
  	echo "$FILE: can not read"
  	exit 2
   fi
fi
# read $FILE using the file descriptors
# Set loop separator to end of line
BAKIFS=$IFS
IFS=$(echo -en "\n")
exec 3<&0
exec 0<"$FILE"
echo $tempfile file is now open

sleep 1

##### For each test plot the utilization graphes #####

while read -r utilfilename
do

	datfilename=$(echo "$utilfilename" | cut -d. --fields=1,2)
	rate=$(echo "$utilfilename" | cut -d. --fields=2)
	rate=$(echo "0.$rate")

	echo "***"
	echo Now working on $rate
	echo "***"

	#########################################################################
	##### Running the C++ program to calculate the averages utilization #####
	#########################################################################
	
	echo "***"
	echo Now calculating the average using the following parameters
	echo $datfilename $rate 10 $TotalCores $Home$testname/ $Sessionbased $Connections
	echo "***"
	../AverageCalculator $datfilename $rate 10 $TotalCores $Home$testname/ $Sessionbased $Connections >> UtilSummary$testname.csv

	########################################
	##### Generating Utilization Plots #####
	########################################
	 tmpFile=$1"gnuplot_input"
	 rm -f $tmpFile

  
	  ## Graphs for Average Idle Time ##

  	echo Generating servers CPU time graph of type $GraphType
  	echo "set terminal "$GraphType > $tmpFile;
  	u=$(echo "./tmp/Total$datfilename.$GraphType")
  	echo set output '"'$u'"' >> $tmpFile;
	  echo 'set title "'Total Utilization'"' >> $tmpFile;
	  echo 'set xlabel "Time in seconds"' >> $tmpFile;
	  echo 'set ylabel "Processor time in %"' >> $tmpFile;
	  echo "set yrange [0:$TotalCores00]" >> $tmpFile;
	  echo plot '"'./tmp/Total_Idle$datfilename.dat'"' title '"'Idle'"' with lines, '"'./tmp/Total_User$datfilename.dat'"' title '"'User'"' with lines, '"'./tmp/Total_Sys$datfilename.dat'"' title '"'System'"' with lines >> $tmpFile;
	  /usr/bin/gnuplot $tmpFile

	z=0
	y=3

 	## Graphs for Utilization of each core ##

	for ((  i = 0 ;  i < TotalCores;  i++  ))
	do

		cut -d, -f$y $utilfilename > ./tmp/CPU"$z"_User$datfilename.dat
		sed '1d' ./tmp/CPU"$z"_User$datfilename.dat > ./tmp/tempdat.dat
		sed '1d' ./tmp/tempdat.dat > ./tmp/NCPU"$z"_User$datfilename.dat

		let y+=1
		cut -d, -f$y $utilfilename > ./tmp/CPU"$z"_Sys$datfilename.dat
		sed '1d' ./tmp/CPU"$z"_Sys$datfilename.dat > ./tmp/tempdat.dat
		sed '1d' ./tmp/tempdat.dat > ./tmp/NCPU"$z"_Sys$datfilename.dat
		
		let y+=1
		cut -d, -f$y $utilfilename > ./tmp/CPU"$z"_Idle$datfilename.dat
		sed '1d' ./tmp/CPU"$z"_Idle$datfilename.dat > ./tmp/tempdat.dat
		sed '1d' ./tmp/tempdat.dat > ./tmp/NCPU"$z"_Idle$datfilename.dat

		let y+=1

		tmpFile=$1"gnuplot_input"
  		rm -f $tmpFile

  		echo Generating servers CPU time graph of type $GraphType
  		echo "set terminal "$GraphType > $tmpFile;
  		u=$(echo "./tmp/Core$z$datfilename.$GraphType")
  		echo set output '"'$u'"' >> $tmpFile;
  		echo 'set title "'Core $z Utilization'"' >> $tmpFile;
  		echo 'set xlabel "Time in seconds"' >> $tmpFile;
  		echo 'set ylabel "Processor time in %"' >> $tmpFile;
  		echo "set yrange [0:100]" >> $tmpFile;
  		echo plot '"'./tmp/NCPU"$z"_Idle$datfilename.dat'"' title '"'Idle'"' with lines, '"'./tmp/NCPU"$z"_User$datfilename.dat'"' title '"'User'"' with lines, '"'./tmp/NCPU"$z"_Sys$datfilename.dat'"' title '"'System'"' with lines >> $tmpFile;
  		/usr/bin/gnuplot $tmpFile

		if [ "$ActiveCoreLocation" -eq 2 ]; then
			let z+=1
		else
			let z+=2
			let y+=3
		fi
	done

done

mkdir Plots
mv ./tmp/*.$GraphType ./Plots
rm -r ./tmp
