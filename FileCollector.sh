#!/bin/bash
			        ##############################################
				##						  ##
				## Developed by Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
################################################################################
#This Script Connects to ALL Client machines and the Server, 			###
#Collect Files related to current test and Save them on Main(RG5) Client.	###
################################################################################
#set -x
testname=$1
serverip=$2
#clients=$3
#clientsip=$4
username='root'
Home='./RUNs/'
SHomeU='~/UtilLog/util-'
SHomeP='~/ProfileLog/profiler-'
CHome='~/RUNs/'

mkdir -p $Home$testname
#mkdir $testname

##### Copying server data #####

echo "Connecting to the server ..."
scp $username@$serverip:$SHomeU$testname* $Home$testname
scp $username@$serverip:$SHomeP$testname-* $Home$testname

##### Copying local data #####
# 5 mean this machine is client 5.
echo "Moving local data ..."
#mv $Home*$testname-5.txt $Home$testname/
cp *$testname-5.txt $Home$testname/
#mv $Home*$testname-5.csv $Home$testname/
cp *$testname-5.csv $Home$testname/

##### Copying other Clients' data #####

#echo "Connecting to other clients' ..."
#OLDIFS=$IFS
#IFS=","
#read -a array <<< "$(printf "%s" "$clientsip")"
#IFS=$OLDIFS
#
#for (( c=1; c<=$clients; c++ ))
#	do
#	echo "Connecting to the client: ${array[c]} ..."
#	scp $username@${array[$c]}:$CHome*$testname-$c.txt $Home$testname
#	scp $username@${array[$c]}:$CHome$testname-$c.csv $Home$testname
#	done
#
