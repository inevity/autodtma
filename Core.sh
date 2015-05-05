### !/bin/bash
				##############################################
				##						  ##
				## Developed By Raoufehsadat Hashemian 2011 ##
				##          rhashem@ucalgary.ca		  ##
				##						  ##
				##############################################
#http://people.ucalgary.ca/~dkrishna/LT2012/
###########################################################################################################
### The purpose of this script is to run a set of tests (an experiment) to measure the performance of a  ###
### multi-core Web server.												###
### The performance testing process includes:									###
###	1) Setting up the experiment confuration parameters							###
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
###	01) Name of the experiment											###
### 	02) File that contains active cores list (Experiment Param 1)						###
###    03) File that contains request rates list 								###
###    04) Number of clients (excluding current host)								###
###    05) File that contains client IP addresses								###
###	06) Number of cores (Experiment Param 2)									###
###	07) Active Cores Location (2:Different, 4:Same) (Experiment Param 3)					###
###	08) Web Server IP address											###
###	09) Web Server port numbers list										###
###	10) URI of the resuest (- if non-session based)								###
###	11) Number of connections (Number of sessions if sessionbased workloads)				###
###	12) Number of Sessions (0 if the workload is not session based) (Experiment Param 4)		###
###	13) Use process affinity? (0:No 1:Yes) (Experiment Param 5)						###
###	14) Use HW monitoring? (0:No 1:Yes) (Experiment Param 6)						###
###	15) Profiler?	(0:Oprofile 1:Perf 2:ICPM) (Experiment Param 7)						###
############################################################################################################

######### Constant Parameters ############

###Local client ID###
Local="5"
### Your user name in all clients and server must be the same###
username="root"
### Number of NIC cards ###
NICnum=1
### NIC cards name ###
NICnames=",eth2"

######### IIIIIIIIIIIIIIIIIII ############

testname=$1
corefile=$2
ratefile=$3
NumberofClients=$4
clientfile=$5
TotalCores=$6
ActiveCoreLocation=$7
serverip=$8
serverports=$9


shift 9

#### Last Seven Inputs ####
uri=$1
connections=$2
Sessionbased=$3
affinity=$4
HWmonitor=$5
Profiler=$6



##################################
##### Opening clients IP file ####
##################################

FILE=""
# Make sure we get file name as command line argument
# Else read it from standard input device
if [ "$clientfile" == "" ]; then
   FILE="/dev/stdin"
   echo "You should Enter correct file name as the  argument"
else
   FILE="$clientfile"
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
echo Clients file is Now open
########
sleep 1
########
for (( c=1; c<=$NumberofClients; c++ ))
do
	read -r line
	Clientsip[c]=$line
done

############################################
##### Setting up experiment parameters #####
############################################

echo "***"
echo "MySQL Will be running at core $sqlcore"
echo "***"

if [ $Sessionbased -eq 1 ]; then
	if [ $ActiveCoreLocation -eq 2 ]; then
		sqlcore=$((TotalCores - 1))
	else
		sqlcore=$((TotalCores - 1 ))
		sqlcore=$((sqlcore * 2 ))
	fi
	lightynum=$((TotalCores -2))
else
	lightynum=$TotalCores
fi
#lightynum=web server process num


cp $ratefile ./rates.txt 
cp $ratefile ./ProfilerRates.txt

#####################################################
##### Running experiment parameter setup script #####
#####################################################
# for server settings 
./Setting.sh $corefile $TotalCores $ActiveCoreLocation $serverip $lightynum $Sessionbased $affinity $NICnum $NICnames
exit 1

if [ $Sessionbased -eq 1 ]; then
	echo "Generaating and Copying Session file ..."
	if [$connections -gt 10000 ]; then
		./SessionfileDist.sh 10000 192.168.0.151 192.168.0.152 192.168.0.154
	else
		./SessionfileDist.sh $connections 192.168.0.151 192.168.0.152 192.168.0.154
	fi
	echo "Starting Mysql ..."
	./startmysql.sh $sqlcore $serverip 
	sleep 5
fi

##################################
##### Opening The Rates File #####
##################################

FILE=""
# Make sure we get file name as command line argument
# Else read it from standard input device
if [ "$ratefile" == "" ]; then
   FILE="/dev/stdin"
   echo "You should Enter the name of rates file as the second argument"
else
   FILE="$ratefile"
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
echo Rate file is Now open
sleep 1


#####################################
##### Pick up next request rate #####
#####################################

while read -r line
do

	rate=`echo $line | cut -d, -f1`
	testtime=`echo $line | cut -d, -f2`

	#############################################################################################
	##### Cleaning up: Stopping any process which may be still running from previouse tests #####
	#############################################################################################

ssh -t -t $username@$serverip <<EOF
sudo killall lighttpd
sudo killall collectl
sudo killall irqbalance
sudo killall irmon.sh
sudo killall httpd
sudo killall php-cgi
sudo service mysql stop
sudo opcontrol --shutdown
sudo killall perf_2.6.35-28
sudo killall perf
sudo killall apache2
sudo killall pcm.x
sleep 3
exit
EOF

	###############################
	##### Starting Web server #####
	###############################

ssh -t -t $username@$serverip <<EOF
echo Restarting Web Servers ...
sudo lighttpd -f /etc/lighttpd/doc/config/lighttpd.conf  start
sleep 1
exit
EOF



	if [ $affinity -ne 0 ]; then
ssh -t -t $username@$serverip <<EOF
sudo ./Affinity.sh $lightynum $ActiveCoreLocation
sleep 1
exit
EOF
	else
		echo "No Affinity Setting"
		sleep 10
	fi
	##############################
	##### Starting DB server #####
	##############################

	if [ $Sessionbased -eq 1 ]; then
		echo "Starting Mysql ..."
		./startmysql.sh $sqlcore $serverip 
	fi


	#####################################
	##### Starting Monitoring tools #####
	#####################################

### CPU utilization Monitor ###

ssh -t -t $username@$serverip <<EOF
collectl   -c 3650  --export ./rsh >> ~/UtilLog/util-$testname-$rate.csv &
sleep 1
exit
EOF


### Hardware Monitor ###

	if [ $HWmonitor -eq 1 ]; then
		case "$Profiler" in 
		0)
OPevents=$(cat ./events.txt)
ssh -t -t $username@$serverip <<EOF
sudo opcontrol  --no-vmlinux --separate=cpu  $OPevents --session-dir=~/OpLog/op-$testname-$rate 
sudo opcontrol --start-daemon
exit
EOF
sleep 6
ssh -t -t $username@$serverip <<EOF
sudo opcontrol --start
sleep 3
exit
EOF
		;;
		1)
Perfevents=$(cat ./events.txt)
ssh -t -t $username@$serverip <<EOF
sudo perf_2.6.35-28 record  $Perfevents -a sleep $testtime &
exit
EOF
		;;
		2)
ssh -t -t $username@$serverip <<EOF
sudo ~/IntelPCM/pcm.x 1 -nc -ns -nsys  &
exit
EOF
		;;
		*)
		echo "Iligal Profiler Code"
		;;
		esac

	fi


	#########################################
	##### Running the distributed tests #####
	#########################################

	echo "Running Local Client"

	./httperf.sh $rate $testname-$Local.csv $testname-$Local.txt $Local $uri $connections $Sessionbased $serverports $serverip&

	echo "Running Other Clients"
	
	for (( c=1; c<=$NumberofClients; c++ ))
	do
	echo "Now we are running the test on Client ${Clientsip[c]}"
ssh -t -t $username@${Clientsip[c]} <<EOF
~/httperf.sh $rate $testname-$c.csv $testname-$c.txt $c $uri $connections $Sessionbased $serverports $serverip&
disown -h
exit
EOF
	done
####### Waiting till the test is finished #########
	sleep $testtime
	sleep 10


	#####################################
	##### Stopping Monitoring tools #####
	#####################################

if [ $HWmonitor -eq 1 ]; then

case "$Profiler" in 
		0)
ssh -t -t $username@$serverip <<EOF
sudo opcontrol --stop
sudo opreport --merge=cpu,lib --session-dir=~/OpLog/op-$testname-$rate | grep -E 'lighttpd|no-vmlinux' >> ~/ProfileLog/profiler-$testname-$rate.csv 
sleep 3
exit
EOF
		;;
		1)
		echo "Perf data collection ends"
ssh -t -t $username@$serverip <<EOF
sudo perf_2.6.35-28 report  -n -t, -C lighttpd > ~/ProfileLog/profiler-$testname-$rate.csv
sleep 1
exit
EOF
		;;
		2)
ssh -t -t $username@$serverip <<EOF
sudo killall pcm.x
cp ~/out.csv ~/ProfileLog/profiler-$testname-$rate.csv
exit
EOF
		;;
		*)
		echo "Iligal Profiler Code"
		;;
		esac

fi


done

#############################
##### End of tests loop #####
#############################


########################################################
##### Data collection and result management taskes #####
########################################################

pass=","
for (( c=1; c<=$NumberofClients; c++ ))
	do
	pass="$pass${Clientsip[c]},"
	done


./FileCollector.sh $testname $serverip $NumberofClients $pass

if [ $Sessionbased -eq 1 ]; then
./GraphGenerator.sh $testname $TotalCores $ActiveCoreLocation jpeg 200 $connections ./
else
./GraphGenerator.sh $testname $TotalCores 2 jpeg $Sessionbased $connections ./
fi

if [ $HWmonitor -eq 1 ]; then

case "$Profiler" in 
0)
./OprofileOutputParser  $testname
1)
echo "copying Perf Rates file"
cp ./PerfRates.txt ./RUNs/$testname/PerfRates.txt
echo "copying Perf Events file"
cp ./perfevent.txt ./RUNs/$testname/perfevent.txt
cd  RUNs/$testname
./PerfOutputParser  $testname
;;
2)
./IPCMOutputParser  $testname 
;;
*)
echo "Iligal Profiler Code"
;;
esac

fi


exec 0<&3
IFS=$BAKIFS

echo "*******************************End Of the Test $testname*******************************************"
