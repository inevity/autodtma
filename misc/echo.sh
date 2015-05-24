#!/bin/bash
$GraphType=svg
$tmpFile=./tmpfile
$z=8
$datfilename=datfilename
$testname=testname
echo Generating servers CPU util per reqs/s graph of type $GraphType 
echo "set terminal "$GraphType > $tmpFile;
u=$(echo "./tmp/CoreUtilpreq$z$datfilename.$GraphType")
echo set output '"'$u'"' >> $tmpFile;
echo 'set title "'Core $z Utilization per reqs/s'"' >> $tmpFile;
echo 'set xlabel "reqs/s"' >> $tmpFile;
echo 'set ylabel "core util in %"' >> $tmpFile;
echo "set yrange [0:100]" >> $tmpFile;
echo plot '"'./tmp/$testname-5all.csv'"' using '"'2:19+$z*6'"' title '"'core 0'"' with lines >> $tmpFile;
