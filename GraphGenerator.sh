#!/bin/bash
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
#set -x
testname=$1
TotalCores=$2
ActiveCoreLocation=$3
GraphType=$4
Sessionbased=$5 
Connections=$6
Home=$7
### Home folder

cd $Home$testname
ls
tempfile="./tmp/temp.txt"
[ -d Plots ] && rm -rf Plots
[ -d tmp ] && rm -rf tmp
[ -f UtilSummary$testname.csv ] && rm -r UtilSummary$testname.csv
mkdir tmp
#rm -rf UtilSummarytestname.csv
############################# CPU Utilization Graph Generator ##########################
declare -i y=3
z=0
ls | grep cpu > $tempfile
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
	rate=$(echo "$utilfilename" | cut -d- --fields=3)
#	rate=$(echo "0.$rate")

	echo "***"
	echo Now working on $rate
	echo "***"
        echo "utilfilename is $utilfilename"
        echo "datfilename is $datfilename"
#        gunzip $utilfilename
#        cp $(datfilename).cpu $(datfilename).csv  must pre varname intermeidtly! 
         csvfile=$(echo "$datfilename.csv") 
#         echo "csvfile $csvfile"
#        sleep 100000  
         cp $utilfilename $csvfile 
	#########################################################################
	##### Running the C++ program to calculate the averages utilization #####
	#########################################################################
	ls -lah ./
	echo "***"
	echo Now calculating the average using the following parameters
	echo $datfilename $rate 36 $TotalCores $Home$testname/ $Sessionbased $Connections
	echo "*** 36lines got ignod"
	#../../AverageCalculator $datfilename $rate 36 $TotalCores $Home$testname/ $Sessionbased $Connections >> UtilSummary$testname.csv
	../../average $datfilename $rate 36 $TotalCores ./ $Sessionbased $Connections >> UtilSummary$testname.csv

	########################################
	##### Generating Utilization Plots #####
	########################################
	 tmpFile=$1"gnuplot_input"
	 rm -f $tmpFile

  
	  ## Graphs for Total Utilization per time ##

  	echo Generating servers CPU time graph of type $GraphType
  	echo "set terminal "$GraphType > $tmpFile;
  	u=$(echo "./tmp/Total$datfilename.$GraphType")
  	echo set output '"'$u'"' >> $tmpFile;
	  echo 'set title "'Total Utilization'"' >> $tmpFile;
	  echo 'set xlabel "Time in seconds"' >> $tmpFile;
	  echo 'set ylabel "Processor time in %"' >> $tmpFile;
	  echo "set yrange [0:$TotalCores00]" >> $tmpFile;
	  echo plot '"'./tmp/Total_Idle$datfilename.dat'"' title '"'Idle'"' with lines, '"'./tmp/Total_User$datfilename.dat'"' title '"'User'"' with lines, '"'./tmp/Total_Sys$datfilename.dat'"' title '"'System'"' with lines >> $tmpFile;
	  `which gnuplot` $tmpFile
          sleep 1

	z=0
	y=3

 	## Graphs for Utilization of each core per time usr/sys/idle##

        awk 'NR > 34' $utilfilename > ./tmp/36$utilfilename
        #37 and after is what we want.so NR>36.but because the sed below ,we set NR>34
	for ((  i = 0 ;  i < TotalCores;  i++  ))
	do
#		cut -d, -f$y $utilfilename > ./tmp/CPU"$z"_User$datfilename.dat
		cut -d, -f$y ./tmp/36$utilfilename  > ./tmp/CPU"$z"_User$datfilename.dat
# maybe the first line is not complete test for the squid ,so delethe the first line.
		sed '1d' ./tmp/CPU"$z"_User$datfilename.dat > ./tmp/tempdat.dat
		sed '1d' ./tmp/tempdat.dat > ./tmp/NCPU"$z"_User$datfilename.dat

		let y+=2
#               cut -d, -f$y $utilfilename > ./tmp/CPU"$z"_Sys$datfilename.dat
		cut -d, -f$y ./tmp/36$utilfilename > ./tmp/CPU"$z"_Sys$datfilename.dat
		sed '1d' ./tmp/CPU"$z"_Sys$datfilename.dat > ./tmp/tempdat.dat
		sed '1d' ./tmp/tempdat.dat > ./tmp/NCPU"$z"_Sys$datfilename.dat
		
		let y+=5
		cut -d, -f$y ./tmp/36$utilfilename > ./tmp/CPU"$z"_Idle$datfilename.dat
		sed '1d' ./tmp/CPU"$z"_Idle$datfilename.dat > ./tmp/tempdat.dat
		sed '1d' ./tmp/tempdat.dat > ./tmp/NCPU"$z"_Idle$datfilename.dat

		let y+=5

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
  		`which gnuplot` $tmpFile
# we use all cpu,so $ActiveCoreLocation"=2
		if [ "$ActiveCoreLocation" -eq 2 ]; then
			let z+=1
		else
			let z+=2
			let y+=3
		fi
	done

done

#from client review
                all=$(echo "./$testname-5alldata.csv")
 
		sed '1d' ./$testname-5.csv > $testname-5d1.csv
                paste -d"," ./$testname-5d1.csv ./UtilSummary$testname.csv > $testname-5alldata.csv
 
		tmpFile=$1"gnuplot_input"
  		rm -f $tmpFile
  		
                echo Generating response time per resq/s graph of type $GraphType
                
                echo "set terminal "$GraphType > $tmpFile;
  		u=$(echo "./tmp/meanresponsetimeperrate$testname.svg")
  		echo set output '"'$u'"' >> $tmpFile;
 		echo 'set title "mean response time per rate"' >> $tmpFile;
 		echo 'set xlabel "reqs/s"' >> $tmpFile;
                echo 'set datafile separator ","' >> $tmpFile;
                echo 'set ylabel "mean response time in ms"' >> $tmpFile;
        	echo "set yrange [0.001:6.000]" >> $tmpFile;
  		echo plot '"'./$testname-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints >> $tmpFile;
  		#`which gnuplot` ../../responseperrate
  		`which gnuplot` $tmpFile
                 echo 'done'


  		echo Generating IO per resq/s graph of type $GraphType

		tmpFile=$1"gnuplot_input"
  		rm -f $tmpFile
                
                echo "set terminal "$GraphType > $tmpFile;
  		u=$(echo "./tmp/netioperrate$testname.svg")
  		echo set output '"'$u'"' >> $tmpFile;
 		echo 'set title "net io per rate"' >> $tmpFile;
 		echo 'set xlabel "reqs/s"' >> $tmpFile;
                echo 'set datafile separator ","' >> $tmpFile;
                echo 'set ylabel "net io in KB"' >> $tmpFile;
#  		echo "set yrange [0.001:6.000]" >> $tmpFile;
  		echo plot '"'./$testname-5alldata.csv'"' using '2:10' title '"'net io'"' with linespoints >> $tmpFile;
  		#`which gnuplot` ../../responseperrate
  		`which gnuplot` $tmpFile
  #		`which gnuplot` ../../ioperrate
                echo 'done'     

        
  		echo Generating CPU core Utilization per resq/s graph of type $GraphType
#                z=0
#                declare -i index=0
#	    for ((  i = 0 ;  i < TotalCores;  i++  ))
#         do
#		tmpFile=$1"gnuplot_input"
#  		rm -f $tmpFile
#                #why need two bracket?
#                index=$((19+6*z)) 
#  		echo "set terminal "$GraphType > $tmpFile;
#  		u=$(echo "./tmp/CoreUtilprate$z$testname.$GraphType")
#  		echo set output '"'$u'"' >> $tmpFile;
#  		echo 'set title "'Core $z Utilization per reqs/s'"' >> $tmpFile;
#  		echo 'set xlabel "reqs/s"' >> $tmpFile;
#                echo 'set datafile separator ","' >> $tmpFile;
#  		echo 'set ylabel "core util in %"' >> $tmpFile;
#  		echo "set yrange [0:100]" >> $tmpFile;
#  		echo plot '"'./$testname-5alldata.csv'"' using '2:($index)' title '"'core $z'"' with lines >> $tmpFile;
#  		`which gnuplot` $tmpFile
#                sleep 1
## we use all cpu,so $ActiveCoreLocation"=2
#		if [ "$ActiveCoreLocation" -eq 2 ]; then
#			let z+=1
#		else
#			let z+=2
#		fi
#	done
             tmpFile=$1"gnuplot_input"
             rm -f $tmpFile 
             echo "set terminal "$GraphType > $tmpFile;
             u=$(echo "./tmp/CoreUtilprate$testname.$GraphType")
             echo set output '"'$u'"' >> $tmpFile;
            # echo 'set title "'Core Utilization per reqs/s'"' >> $tmpFile;
               echo 'set xlabel "reqs/s"' >> $tmpFile;
              echo 'set datafile separator ","' >> $tmpFile;
              echo 'set ylabel "core util in %"' >> $tmpFile;
             echo "set yrange [0:100]" >> $tmpFile;
             echo plot '"'./$testname-5alldata.csv'"' using '2:49' title '"'core 5'"' with linespoints  >> $tmpFile;
#             echo plot '"'./$testname-5alldata.csv'"' using '2:19' title '"'core 0'"' with linespoints,'""' using '2:25' title '"'core 1'"' with linespoints, '""' using '2:31' title '"'core 2'"' with linespoints,'""' using '2:37' title '"'core 3'"' with linespoints,'""' using '2:43' title '"'core 4'"' with linespoints,'""' using '2:49' title '"'core 5'"' with linespoints,'""' using '2:55' title '"'core 6'"' with linespoints,'""' using '2:61' title  '"'core 7'"' with linespoints,'""' using '2:67' title '"'core 8'"' with linespoints,'""' using '2:73' title '"'core 9'"' with linespoints,'""' using '2:79' title '"'core 10'"' with linespoints,'""' using '2:83' title '"'core 11'"' with linespoints >> $tmpFile;
             `which gnuplot` $tmpFile
           echo 'done'


  		echo Generating response time  per core util graph of type $GraphType

#               z=0
#                
#	    for ((  i = 0 ;  i < TotalCores;  i++  ))
#         do
#		tmpFile=$1"gnuplot_input"
#  		rm -f $tmpFile
#
#  		echo "set terminal "$GraphType > $tmpFile;
#  		u=$(echo "./tmp/resppcoreutil$z$testname.$GraphType")
#  		echo set output '"'$u'"' >> $tmpFile;
#  		echo 'set title "'response time per Core $z Utilization'"' >> $tmpFile;
#  		echo 'set xlabel "Core $z Utilization"' >> $tmpFile;
#  		echo 'set ylabel "mean response time in s"' >> $tmpFile;
#  		echo "set xrange [0:100]" >> $tmpFile;
#  		echo plot '"'./$testname-5alldata.csv'"' using '"'19+$z*6:8'"' title '"'core $z'"' with lines >> $tmpFile;
#  		`which gnuplot` $tmpFile
#                sleep 1
## we use all cpu,so $ActiveCoreLocation"=2
#		if [ "$ActiveCoreLocation" -eq 2 ]; then
#			let z+=1
#		else
#			let z+=2
#		fi
#	done
          
		tmpFile=$1"gnuplot_input"
  		rm -f $tmpFile

  		echo "set terminal "$GraphType > $tmpFile;
  		u=$(echo "./tmp/resppcoreutil$testname.$GraphType")
  		echo set output '"'$u'"' >> $tmpFile;
  		echo 'set title "'response time per Core Utilization'"' >> $tmpFile;
  		echo 'set xlabel "Core  Utilization in %"' >> $tmpFile;
  		echo 'set ylabel "mean response time in s"' >> $tmpFile;
  		echo "set yrange [0.001:6.000]" >> $tmpFile;
                echo 'set datafile separator ","' >> $tmpFile;
                echo plot '"'./$testname-5alldata.csv'"' using '49:8' title '"'core 5'"' with linespoints  >> $tmpFile;
#                echo plot '"'./$testname-5alldata.csv'"' using '19:8' title '"'core 0'"' with linespoints,'""' using '25:8' title '"'core 1'"' with linespoints, '""' using '31:8' title '"'core 2'"' with linespoints,'""' using '37:8' title '"'core 3'"' with linespoints,'""' using '43:8' title '"'core 4'"' with linespoints,'""' using '49:8' title '"'core 5'"' with linespoints,'""' using '55:8' title '"'core 6'"' with linespoints,'""' using '61:8' title  '"'core 7'"' with linespoints,'""' using '67:8' title '"'core 8'"' with linespoints,'""' using '73:8' title '"'core 9'"' with linespoints,'""' using '79:8' title '"'core 10'"' with linespoints,'""' using '83:8' title '"'core 11'"' with linespoints >> $tmpFile;
  		`which gnuplot` $tmpFile
          echo 'done'

mkdir Plots
mv ./tmp/*.$GraphType ./Plots
rm -r ./tmp
