#!/bin/bash
######### Constant Parameters ############
#set -x
ulimit -n 102400
###Local client ID###
Local="5"
testname=$1
#corefile=$2
ratefile=$2
#NumberofClients=$4
#clientfile=$5
TotalCores=12
#ActiveCoreLocation=$7
serverip=$3
serverports=$4
#shift 9

#### Last Seven Inputs ####
uri=$5
connections=$6
Sessionbased=$7
#affinity=$4
affinity=1
HWmonitor=$8
Profiler=$9
username="root"
############################################
##### Setting up experiment parameters #####
############################################

echo "fc Will be running in totalcores-2  instances,(in fact 6 instances) ,exclude core 0 and one nginx(lscs) cores"
echo "***"

#if [ $Sessionbased -eq 1 ]; then
#        if [ $ActiveCoreLocation -eq 2 ]; then
#                sqlcore=$((TotalCores - 1))
#        else
#                sqlcore=$((TotalCores - 1 ))
#                sqlcore=$((sqlcore * 2 ))
#        fi
#        lightynum=$((TotalCores -2))
#else
#        lightynum=$((TotalCores-2))
#fi
#lightynum=web server process num


cp $ratefile ./rates.txt
cp $ratefile ./ProfilerRates.txt


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
        echo " rate $rate testtime is $testtime"

        #############################################################################################
        ##### Cleaning up: Stopping any process which may be still running from previouse tests #####
        #############################################################################################

ssh -T $username@$serverip <<EOF
killall collectl
killall irqbalance
killall irmon.sh
killall perf
killall pcm.x
service fc stop
sleep 3
exit
EOF

        ###############################
        ##### Starting squid server ,taskset squid and nginx #####
        ###############################

ssh -T $username@$serverip <<EOF
echo "Restarting Web Servers ..."
service fc start
sh ./taskset.sh
sleep 1
exit
EOF



#        if [ $affinity -ne 0 ]; then
#ssh -t -t $username@$serverip <<EOF
#sh ./taskset.sh
#sleep 1
#exit
#EOF
#
#        else
#                echo "No Affinity Setting"
#                sleep 10
#        fi


        ##############################
        ##### Starting DB server #####
        ##############################
#
#        if [ $Sessionbased -eq 1 ]; then
#                echo "Starting Mysql ..."
#                ./startmysql.sh $sqlcore $serverip
#        fi


        #####################################
        ##### Starting Monitoring tools #####
        #####################################
#collectl -sCDNm -c 3650 --rawtoo -P -f ./output backgroug process exit,why?
### CPU utilization Monitor ###

ssh -T $username@$serverip <<EOF
collectl -sCDNm -c 300 --rawtoo  --sep , -F2 -oz -P -f ~/UtilLog/util-$testname-$rate
sleep 1
exit
EOF

### Hardware Monitor ###

        if [ $HWmonitor -eq 1 ]; then
                case "$Profiler" in
                0)
OPevents=$(cat ./events.txt)
ssh -T $username@$serverip <<EOF
opcontrol  --no-vmlinux --separate=cpu  $OPevents --session-dir=~/OpLog/op-$testname-$rate
opcontrol --start-daemon
exit
EOF
sleep 6
ssh -T $username@$serverip <<EOF
opcontrol --start
sleep 3
exit
EOF
                ;;
                1)
Perfevents=$(cat ./events.txt)
ssh -T $username@$serverip <<EOF
perf record -a -g -p squidpid -o $testname-$rate.perf
exit
EOF
                ;;
                2)
ssh -T $username@$serverip <<EOF
 ~/IntelPCM/pcm.x 1 -nc -ns -nsys -csv > pcm.csv &
exit
EOF
                ;;
                *)
                echo "Iligal Profiler Code"
                ;;
                esac

        fi



        sleep 20
        echo "Running Local Client"

        ./httperf.sh $rate $testname-$Local.csv $testname-$Local.txt $Local $uri $connections $Sessionbased $serverports $serverip&

####### Waiting till the test is finished #########
        sleep $testtime
        sleep 30


        #####################################
        ##### Stopping Monitoring tools #####
        #####################################

if [ $HWmonitor -eq 1 ]; then

case "$Profiler" in
                0)
ssh -T $username@$serverip <<EOF
opcontrol --stop
opreport --merge=cpu,lib --session-dir=~/OpLog/op-$testname-$rate | grep -E 'lighttpd|no-vmlinux' >> ~/ProfileLog/profiler-$testname-$rate.csv
sleep 3
exit
EOF
                ;;
                1)
                echo "Perf data collection ends"
ssh -T $username@$serverip <<EOF
killall perf
perf report -n -g -i /root/$testname-$rate.perf >$testname-$rate.report
sleep 1
exit
EOF
                ;;
                2)
ssh -T $username@$serverip <<EOF
killall pcm.x
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

#pass=","
#for (( c=1; c<=$NumberofClients; c++ ))
#        do
#        pass="$pass${Clientsip[c]},"
#        done
#
#
./FileCollector.sh $testname $serverip

if [ $Sessionbased -ge 1 ]; then
#./GraphGenerator.sh $testname $TotalCores $ActiveCoreLocation svg 200 $connections ./RUNs/
./GraphGenerator.sh $testname $TotalCores 2 svg $Sessionbased $connections ./RUNs/
else
./GraphGenerator.sh $testname $TotalCores 2 svg $Sessionbased $connections ./RUNs/
fi

#if [ $HWmonitor -eq 1 ]; then
#
#case "$Profiler" in
#0)
#./OprofileOutputParser  $testname
#1)
#echo "copying Perf Rates file"
#cp ./PerfRates.txt ./RUNs/$testname/PerfRates.txt
#echo "copying Perf Events file"
#cp ./perfevent.txt ./RUNs/$testname/perfevent.txt
#cd  RUNs/$testname
#./PerfOutputParser  $testname
#;;
#2)
#./IPCMOutputParser  $testname
#;;
#*)
#echo "Iligal Profiler Code"
#;;
#esac
#
#fi


exec 0<&3
IFS=$BAKIFS

echo "*******************************End Of the Test $testname*******************************************"

