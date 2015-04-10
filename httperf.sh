#!/bin/sh
				##############################################
				##						  ##
				## Developed by Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
H='~/RUNs/'
rate=$1
testnamecsv=$2
testnametxt=$3
clientid=$4
url=$5
connections=$6
sess=$7
port=$8
serverip=$9
if [ $sess -eq 1 ] ; then
taskset 0x00000001 httperf --server=$serverip   --client=$clientid/8 --des-ports=$port  --period=e$rate --wsesslog=$sess,0,/home/rhashem/sessfile.txt --hog  --rfile-name=$H$rate-$testnamecsv  >> $H$rate-$testnametxt
else
taskset 0x00000001 httperf --server=$serverip   --client=$clientid/8 --des-ports=$port  --period=e$rate --uri=/$url --hog --num-calls=3 --num-conns=$connections --rfile-name=test5.csv >> $H$rate-$testnametxt
fi
##################################################
##### Saving the Summary on the Summary file #####
##################################################
./saveoutput $H$testnamecsv $H$rate-$testnametxt
