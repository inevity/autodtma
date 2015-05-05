### !/bin/bash

				##############################################
				##						  ##
				## Developed by Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
############################################################################################################
### The main purpose of this script is to apply the server settings based on the experiment marameters 	###
### The script is used to divid the interrupts between cores, depending on the number of active cores  	###
### and Active core location using RSS queues of Intel 82576 Dual port Network Interface			###
### The performance testing process includes:									###
###	1) Serring up the experiment confuration parameters							###
###	2) Opening rates file 											###
###	3) For all the request rate values in the rates file:							###
###		-- Run Web server											###
###		-- Run monitoring tools										###
###		-- Run the test using httperf									###
###		-- Stop Web server											###
###		-- Stop monitoring tools										###															###
###	4) Call Result managment scripts										###
###															###
### Input Parameters: 												###
### 	01) File that contains active cores list (Experiment Param 1)						###
###	02) Number of cores (Experiment Param 2)									###
###	03) Active Cores Location (2:Different, 4:Same) (Experiment Param 3)					###
###	04) Web Server IP address											###
###	05) Number of Web server processes										###
###	06) Number of Sessions (0 if the workload is not session based) (Experiment Param 4)		###
###	07) Use process affinity? (0:No 1:Yes) (Experiment Param 5)						###
###	08) Number of NICs (Experiment Param 6)									###
###	09) NICs names  												###
############################################################################################################

corefile=$1
corenum=$2
ActiveCoreLocation=$3
serverip=$4
lightynum=$5
sess=$6
affinity=$7
NICnum=$8
NICnames=$9
#############################################################
### Disabling all the cores (except core 0) on the server ###
#############################################################
for i in 1 2 3 4 5 6 7 8 9 10 11
do
S="echo 0 >/sys/devices/system/cpu/cpu$i/online"
  ssh -t root@$serverip << EOF
  $S
  sleep 0.5
  exit
  exit
EOF
done

###############################
### Opening the cores file ####
###############################

# Store file name
FILE=""
# Make sure we get file name as command line argument
# Else read it from standard input device
if [ "$corefile" == "" ]; then
   FILE="/dev/stdin"
   echo "You should Enter the name of cores file as the first argument"
else
   FILE="$corefile"
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

#################################
### Enabling requested cores ####
#################################


while read -r core
do
echo Enableing Core Number $core ...
ssh  -t root@$serverip  <<EOF
sleep 0.5
echo 1 >/sys/devices/system/cpu/cpu$core/online
sleep 0.5
exit
exit
EOF
done
exec 0<&3
# restore $IFS which was used to determine what the field separators are
IFS=$BAKIFS

################################################
### Restarting NIC and applying the settings ###
################################################

###### Number of RSS Queue is now equal to the number of Lighttpd Processes #####

ssh -t -t root@$serverip  <<EOF
rmmod igb
sleep 1
modprobe igb RSS=$corenum,$corenum
sleep 1
/etc/init.d/networking restart
sleep 10
exit
exit
EOF


###### Just for IPCM Profiler ######

ssh -t -t root@$serverip  <<EOF
modprobe msr
exit
EOF



ssh -t root@$serverip << EOF
/root/SetInterruptsAffinity.sh $NICnum $NICnames $ActiveCoreLocation
sleep 2
exit
exit
EOF



################Lighttpd Moduls (PHP) Setting ########################
#
#if [ $sess -eq 1 ]; then
#ssh -t -t rhashem@$serverip <<EOF
#sudo cp /home/rhashem/Desktop/lightysettings/modules.conf /etc/lighttpd/doc/config/modules.conf
#exit
#EOF
#else
#ssh -t -t rhashem@$serverip <<EOF
#sudo cp /home/rhashem/Desktop/lightysettings/modules_Nocgi.conf /etc/lighttpd/doc/config/modules.conf
#exit
#EOF
#fi

