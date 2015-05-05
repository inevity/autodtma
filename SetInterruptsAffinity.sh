#!/bin/bash
				##############################################
				##						  ##
				## Developed by Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
NumberofNICs=$1
NIClist=$2
ActiveCoreLocation=$3


##### First NIC ####

OLDIFS=$IFS
IFS=","
read -a array <<< "$(printf "%s" "$NIClist")"
IFS=$OLDIFS

for (( c=1; c<=$NumberofNICs; c++ ))
	do

	cat /proc/interrupts | grep ${array[$c]}-TxRx | awk '{print ""$1""}'  > /root/int.txt
	##### Getting Interrupt Queue List #####
	# Store file name
	FILE=""
	FILE="/root/int.txt"

	if [ ! -f $FILE ]; then
  		echo "$FILE : does not exists"
  		exit 1
   	elif [ ! -r $FILE ]; then
  		echo "$FILE: can not read"
  	exit 2
   	fi
	BAKIFS=$IFS
		IFS=$(echo -en "\n")
	exec 3<&0
	exec 0<"$FILE"
	##### Setting Interrupts ######
	let msk=1;
while read -r line
do
pid=`echo $line | cut -d: -f1`
m=`bc <<!
	    obase=16; $msk
!
    ` 
echo 0$m > /proc/irq/$pid/smp_affinity
echo $m
echo $pid
let msk*ActiveCoreLocation
done

	done


