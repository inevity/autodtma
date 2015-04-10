#!/bin/bash
				##############################################
				##						  ##
				## Developed by Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
###########################################################################################################
### The purpose of this script is to set the affinity setting of Lighttpd web server processes on a	###
### multi-core Web server.												###
### Input Parameters: 												###
###	01) Number of cores (Experiment Param 2)									###
###	02) Active Cores Location (2:Different, 4:Same) (Experiment Param 3)					###
############################################################################################################

proc=$1;
ActiveCoreLocation=$2

#################################################################
tm=$((proc +1 ))
base=2

pidof lighttpd > temp.txt
map=1;
for (( j=0 ; j<base; j++ ))
do
if [ $j -gt 0 ]; then 
if [ $((base / 2)) -eq $j ]; then
if [ $proc -gt 1 ]; then
map=2;
fi
fi
fi 
for (( i = 1 ;  i <=proc;  i++  ))
do
tk=$(( j * tm ))
k=$(( $i + $tk ))
pid=`cut -d' ' -f$k  temp.txt`
if [ $i -eq 9 ]; then
map=$((map>>8))
fi
m=`bc <<!
	    obase=16; $map
!
    ` 
echo $m
echo `taskset --pid 0x0$m  $pid`
echo the Process  $pid was set to core by the affinity: $map
let map*=ActiveCoreLocation
done
done
###############################################################
