#!/bin/bash
testname=$1
t2=$2
t3=$3
t4=$4
t5=$5
t6=$6
wholetestname=$7
GraphType=$8
 

#                tmpFile=$wholetestname"gnuplot_input"
#                rm -f $tmpFile
#                    mkdir Plots
#                mkdir tmp
#
#                echo Generating response time per resq/s graph of type $GraphType
#
#                echo "set terminal "$GraphType > $tmpFile;
#                u=$(echo "./tmp/meanresponsetimeperrate$wholetestname.svg")
#                echo set output '"'$u'"' >> $tmpFile;
#                echo 'set title "mean response time per rate"' >> $tmpFile;
#                echo 'set xlabel "reqs/s"' >> $tmpFile;
#                echo 'set datafile separator ","' >> $tmpFile;
#                echo 'set ylabel "mean response time in ms"' >> $tmpFile;
#                echo "set yrange [0.001:6.000]" >> $tmpFile;
#                echo plot '"'./$testname/$testname-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints, '"'./$t2/$t2-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints, '"'./$t3/$t3-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints,'"'./$4/$t4-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints,'"'./$5/$t5-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints,'"'./$6/$t6-5alldata.csv'"' using '2:8' title '"'mean response time'"' with linespoints >> $tmpFile;
#                #`which gnuplot` ../../responseperrate
#                `which gnuplot` $tmpFile
#                 echo 'done'
                tmpFile=$wholetestname"gnuplot_input"
                rm -f $tmpFile
                    mkdir Plots
                mkdir tmp

                echo Generating response time per resq/s graph of type $GraphType

                echo "set terminal "$GraphType > $tmpFile;
                u=$(echo "./tmp/meanresponsetimeperrate$wholetestname.svg")
                echo set output '"'$u'"' >> $tmpFile;
                echo 'set title "mean response time per rate"' >> $tmpFile;
                echo 'set xlabel "reqs/s"' >> $tmpFile;
                echo 'set datafile separator ","' >> $tmpFile;
                echo 'set ylabel "mean response time in ms"' >> $tmpFile;
                echo "set yrange [0.001:6.000]" >> $tmpFile;
              #  echo plot '"'./RUNs/$testname/$testname-5alldata.csv'"' using '2:8' title '"' $testname mean response time'"' with linespoints, '"'./RUNs/$t2/$t2-5alldata.csv'"' using '2:8' title '"' $t2 mean response time'"' with linespoints, '"'./RUNs/$t3/$t3-5alldata.csv'"' using '2:8' title '"' $t3 mean response time'"' with linespoints  >> $tmpFile;
                echo plot '"'./RUNs/$testname/$testname-5alldata.csv'"' using '2:8' title '"' $testname mean response time'"' with linespoints, '"'./RUNs/$t2/$t2-5alldata.csv'"' using '2:8' title '"' $t2 mean response time'"' with linespoints, '"'./RUNs/$t3/$t3-5alldata.csv'"' using '2:8' title '"' $t3 mean response time'"' with linespoints, '"'./RUNs/$t4/$t4-5alldata.csv'"' using '2:8' title '"' $t4 mean response time'"' with linespoints  >> $tmpFile;
                `which gnuplot` $tmpFile
                 echo 'done'

  		echo Generating IO per resq/s graph of type $GraphType

		tmpFile=$1"gnuplot_input"
  		rm -f $tmpFile

                echo "set terminal "$GraphType > $tmpFile;
  		u=$(echo "./tmp/netioperrate$wholetestname.svg")
  		echo set output '"'$u'"' >> $tmpFile;
 		echo 'set title "net io per rate"' >> $tmpFile;
 		echo 'set xlabel "reqs/s"' >> $tmpFile;
                echo 'set datafile separator ","' >> $tmpFile;
                echo 'set ylabel "net io in KB"' >> $tmpFile;
  		#echo plot '"'./$testname-5alldata.csv'"' using '2:10' title '"'net io'"' with linespoints >> $tmpFile;
                echo plot '"'./RUNs/$testname/$testname-5alldata.csv'"' using '2:10' title '"' $testname '"' with linespoints, '"'./RUNs/$t2/$t2-5alldata.csv'"' using '2:10' title '"' $t2 '"' with linespoints, '"'./RUNs/$t3/$t3-5alldata.csv'"' using '2:10' title '"' $t3 '"' with linespoints, '"'./RUNs/$t4/$t4-5alldata.csv'"' using '2:10' title '"' $t4 '"' with linespoints  >> $tmpFile;
  		`which gnuplot` $tmpFile
                echo 'done'


  		echo Generating CPU core Utilization per resq/s graph of type $GraphType
             tmpFile=$1"gnuplot_input"
             rm -f $tmpFile
             echo "set terminal "$GraphType > $tmpFile;
             u=$(echo "./tmp/CoreUtilprate$wholetestname.$GraphType")
             echo set output '"'$u'"' >> $tmpFile;
            # echo 'set title "'Core Utilization per reqs/s'"' >> $tmpFile;
               echo 'set xlabel "reqs/s"' >> $tmpFile;
              echo 'set datafile separator ","' >> $tmpFile;
              echo 'set ylabel "core util in %"' >> $tmpFile;
             echo "set yrange [0:100]" >> $tmpFile;
             #echo plot '"'./$testname-5alldata.csv'"' using '2:49' title '"'core 5'"' with linespoints  >> $tmpFile;
                echo plot '"'./RUNs/$testname/$testname-5alldata.csv'"' using '2:49' title '"' $testname '"' with linespoints, '"'./RUNs/$t2/$t2-5alldata.csv'"' using '2:49' title '"' $t2 '"' with linespoints, '"'./RUNs/$t3/$t3-5alldata.csv'"' using '2:49' title '"' $t3 '"' with linespoints, '"'./RUNs/$t4/$t4-5alldata.csv'"' using '2:49' title '"' $t4 '"' with linespoints  >> $tmpFile;
#             echo plot '"'./$testname-5alldata.csv'"' using '2:19' title '"'core 0'"' with linespoints,'""' using '2:25' title '"'core 1'"' with linespoints, '""' using '2:31' title '"'core 2'"' with linespoints,'""' using '2:37' title '"'core 3'"' with linespoints,'""' using '2:43' title '"'core 4'"' with linespoints,'""' using '2:49' title '"'core 5'"' with linespoints,'""' using '2:55' title '"'core 6'"' with linespoints,'""' using '2:61' title  '"'core 7'"' with linespoints,'""' using '2:67' title '"'core 8'"' with linespoints,'""' using '2:73' title '"'core 9'"' with linespoints,'""' using '2:79' title '"'core 10'"' with linespoints,'""' using '2:83' title '"'core 11'"' with linespoints >> $tmpFile;
             `which gnuplot` $tmpFile
           echo 'done'


  		echo Generating response time  per core util graph of type $GraphType


		tmpFile=$1"gnuplot_input"
  		rm -f $tmpFile

  		echo "set terminal "$GraphType > $tmpFile;
  		u=$(echo "./tmp/resppcoreutil$wholetestname.$GraphType")
  		echo set output '"'$u'"' >> $tmpFile;
  		echo 'set title "'response time per Core Utilization'"' >> $tmpFile;
  		echo 'set xlabel "Core  Utilization in %"' >> $tmpFile;
  		echo 'set ylabel "mean response time in s"' >> $tmpFile;
  		echo "set yrange [0.001:6.000]" >> $tmpFile;
                echo 'set datafile separator ","' >> $tmpFile;
                #echo plot '"'./$testname-5alldata.csv'"' using '49:8' title '"'core 5'"' with linespoints  >> $tmpFile;
                echo plot '"'./RUNs/$testname/$testname-5alldata.csv'"' using '49:8' title '"' $testname core 5'"' with linespoints, '"'./RUNs/$t2/$t2-5alldata.csv'"' using '49:8' title '"' $t2 '"' with linespoints, '"'./RUNs/$t3/$t3-5alldata.csv'"' using '49:8' title '"' $t3 '"' with linespoints, '"'./RUNs/$t4/$t4-5alldata.csv'"' using '49:8' title '"' $t4 '"' with linespoints  >> $tmpFile;
#                echo plot '"'./$testname-5alldata.csv'"' using '19:8' title '"'core 0'"' with linespoints,'""' using '25:8' title '"'core 1'"' with linespoints, '""' using '31:8' title '"'core 2'"' with linespoints,'""' using '37:8' title '"'core 3'"' with linespoints,'""' using '43:8' title '"'core 4'"' with linespoints,'""' using '49:8' title '"'core 5'"' with linespoints,'""' using '55:8' title '"'core 6'"' with linespoints,'""' using '61:8' title  '"'core 7'"' with linespoints,'""' using '67:8' title '"'core 8'"' with linespoints,'""' using '73:8' title '"'core 9'"' with linespoints,'""' using '79:8' title '"'core 10'"' with linespoints,'""' using '83:8' title '"'core 11'"' with linespoints >> $tmpFile;
  		`which gnuplot` $tmpFile
          echo 'done'
