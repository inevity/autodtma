#!/bin/bash
######### Constant Parameters ############
#set -x
ulimit -n 102400
###Local client ID###
Local="5"
testname1=$1
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
c=0
#while [ $c -lt 4 ] must have space blank!
while [ $c -lt 3 ]
do
     (( c++ ))
#for filesize in 1024 65536 131072 196608 262144 327680 393216 458752 524288 589824 655360 786432 1048576
#for filesize in 612 1024 524288 1048576 10485760 104857600
for filesize in 612 1024
#for filesize in 524288 1048576
#for filesize in 10485760 104857600
do

     while read sizekey filename; do

     if [ $sizekey == $filesize ] ;then
     cp /usr/share/nginx/html/$filename /usr/share/nginx/html/index.html
#     ls -la  /usr/share/nginx/html/index.html
     fi
     done < /root/RUNs/filemap
#above method also not ideal ,wget use B uit,so 612B file cannot deal,we use keyvalue or csv.

#    #bitnum=$(`echo $filesize |wc -c`) why wrong
#    bitnum=`echo $filesize |wc -c` we need a unverisal method to process diffenrent size,B KB MB 
#    case "$bitnum" in
#          4)
#           cp /usr/share/nginx/html/612B /usr/share/nginx/html/index.html
#          ;;
#          5)
#           cp /usr/share/nginx/html/1KB /usr/share/nginx/html/index.html
#          ;;
#          7)
#           cp /usr/share/nginx/html/512KB /usr/share/nginx/html/index.html
#          ;;
#          8)
#           cp /usr/share/nginx/html/1MB /usr/share/nginx/html/index.html
#          ;;
#          9)
#           cp /usr/share/nginx/html/10MB /usr/share/nginx/html/index.html
#          ;;
#          10)
#           cp /usr/share/nginx/html/100MB /usr/share/nginx/html/index.html
#          ;;
#          *)
#           echo "not needed file size "
#          ;;
#    esac

#    cp /usr/share/nginx/index/$filesize /usr/share/nginx/index/index.html
    ansible -u root 10.10.10.254 -m shell -a "/usr/local/squid/bin/refresh_cli -f http://www.myweb.com/index.html"
    #realfsize=$(`wget http://www.myweb.com/index.html --spider --server-response -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`)
    realfsize=`wget http://www.myweb.com/index.html --spider --server-response -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`
    #if [ $realfsize eq $filesize ]
    if [ $realfsize == $filesize ]
    then
       wget http://www.myweb.com/index.html

echo "fc Will be running in totalcores-2  instances,(in fact 6 instances) ,exclude core 0 and one nginx(lscs) cores"
echo "using filesize $filesize,and replicate three times"
      m=$(echo "$testname1-$filesize")
      # filesize not filezize why need put in the while loop
      
      echo "begining test filesize $m"
      echo "***"
     # m=$(echo "$testname1-$filesize")
      #echo "$m"
     testname=$(echo "$m-$c")
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
echo "Rate file is Now open,using filesize $filesize,the $c run" 
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
sh ~/RUNs/misc/taskset.sh
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
#collectl -sCDNm -c 300 --rawtoo  --sep , -F2 -oz -P -f ~/UtilLog/util-$testname-$rate
#collectl -sCDMNZ -c 300 -F1  -i1:5 --procfilt csquid -oTm
#collectl -sCDMNZ -c 300 --rawtoo  --sep , -F1 -oTmz -P -f ~/UtilLog/util-$testname-$rate  -i1:5 --procfilt csquid -oTm



#
#ssh -T $username@$serverip <<EOF
#collectl -sCDmNZ -c 300  -F1 -i1:5 --sep , -oz --procfilt csquid -P -f ~/UtilLog/util-$testname-$rate 
#sleep 1
#exit
#EOF
#
ansible-playbook play.yml --verbose --extra-vars "outfile=/root/UtilLog/util-$testname-$rate ctime=$testtime"



#start test
        sleep 20
        echo "Running Local Client"

        ./httperf.sh $rate $testname-$Local.csv $testname-$Local.txt $Local $uri $connections $Sessionbased $serverports $serverip&




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
#Perfevents=$(cat ./events.txt)
#ssh -T $username@$serverip <<EOF
#perf record -a -g -p squidpid -o $testname-$rate.perf&
#exit
#EOF
#pids=`sshpass -p 'sophnep!@#' ps -ef |grep fc-cache |grep squid |awk '{print $2'}|tr '\n' ','`
#pids=`ps -ef |grep fc-cache |grep squid |awk '{print $2'}|tr '\n' ','`
#ansible-playbook prof.yml --verbose --extra-vars "pids=$pids outfile=/root/util$testname-$rate ctime=$testtime"
#ansible-playbook flamecreate.yml -v --verbose --extra-vars "outfile=/root/Prof/perf$testname-$rate" 
ansible-playbook prof.yml -v --verbose --extra-vars "outfile=/root/Prof/perf$testname-$rate ctime=$testtime" 
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
####### Waiting till the monitor and test is finished #########
        echo sleep and testing 
        sleep $testtime
        sleep 30


        #####################################
#        ##### Stopping Monitoring tools ,for now we use time in perf ,no need kill perf  #####
#        #####################################
#
#if [ $HWmonitor -eq 1 ]; then
#
#case "$Profiler" in
#                0)
#ssh -T $username@$serverip <<EOF
#opcontrol --stop
#opreport --merge=cpu,lib --session-dir=~/OpLog/op-$testname-$rate | grep -E 'lighttpd|no-vmlinux' >> ~/ProfileLog/profiler-$testname-$rate.csv
#sleep 3
#exit
#EOF
#                ;;
#                1)
#                echo "Perf data collection ends"
#ssh -T $username@$serverip <<EOF
#killall perf
#perf report -n -g -i /root/$testname-$rate.perf >$testname-$rate.report
#sleep 1
#exit
#EOF
#                ;;
#                2)
#ssh -T $username@$serverip <<EOF
#killall pcm.x
#cp ~/out.csv ~/ProfileLog/profiler-$testname-$rate.csv
#exit
#EOF
#                ;;
#                *)
#                echo "Iligal Profiler Code"
#                ;;
#                esac
#
#
#
#fi
#


echo process this perf data to svg on squid sever

#ansible-playbook flamecreate.yml -v --verbose --extra-vars "outfile=/root/Prof/perf$testname-$rate" 
ansible-playbook flamecreate.yml -v --verbose --extra-vars "outfile=perf$testname-$rate" 


done
# for all rates for a filesize 




#############################
##### End of tests loop of a filesize  #####

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

if [ $HWmonitor -eq 1 ]; then

case "$Profiler" in
0)
./OprofileOutputParser  $testname
;;
1)
#echo "copying Perf Rates file"
#cp ./PerfRates.txt ./RUNs/$testname/PerfRates.txt
#echo "copying Perf Events file"
#cp ./perfevent.txt ./RUNs/$testname/perfevent.txt
#cd  RUNs/$testname
#./PerfOutputParser  $testname
#need genarate svg on the server
#perffiles=/root/ProfileLog/profiler-$testname-$rate-perf.data

#cd /root/Prof
#for perfdata in /root/Prof/perf*
#do
##  perf script -f comm,pid,tid,ip,sym,dso -i $perfdata |./FlameGraph/stackcollapse-perf.pl -pid |awk -F';' '{print $1}'|uniq|cut -d '-' --fields=2
#   perf script -f comm,pid,tid,ip,sym,dso -i $perfdata |./FlameGraph/stackcollapse-perf.pl -pid > c$perfdata
#   squidpids=`awk -F';' '{print $1}' c$perfdata |uniq|cut -d '-' --fields=2`
#   for squidpid in $squidpids
#   do
#       grep $squidpid  c$perfdata |./FlameGraph/flamegraph.pl > $perfdata-$squidpid.svg
#   done
#done
echo perf output in dir Flamegraph
;;
2)
./IPCMOutputParser  $testname
;;
*)
#echo "Iligal Profiler Code"
;;
esac

fi


exec 0<&3
IFS=$BAKIFS









     else
       echo "wrong real file size $realfsize ,need size $filesize"
#       exit
       continue
     fi

done
#for all filesize


done 
# for replication

##############################
###### End of tests loop #####
##############################
#
#
#########################################################
###### Data collection and result management taskes #####
#########################################################
#
##pass=","
##for (( c=1; c<=$NumberofClients; c++ ))
##        do
##        pass="$pass${Clientsip[c]},"
##        done
##
##
#./FileCollector.sh $testname $serverip
#
#if [ $Sessionbased -ge 1 ]; then
##./GraphGenerator.sh $testname $TotalCores $ActiveCoreLocation svg 200 $connections ./RUNs/
#./GraphGenerator.sh $testname $TotalCores 2 svg $Sessionbased $connections ./RUNs/
#else
#./GraphGenerator.sh $testname $TotalCores 2 svg $Sessionbased $connections ./RUNs/
#fi
#
##if [ $HWmonitor -eq 1 ]; then
##
##case "$Profiler" in
##0)
##./OprofileOutputParser  $testname
##1)
##echo "copying Perf Rates file"
##cp ./PerfRates.txt ./RUNs/$testname/PerfRates.txt
##echo "copying Perf Events file"
##cp ./perfevent.txt ./RUNs/$testname/perfevent.txt
##cd  RUNs/$testname
##./PerfOutputParser  $testname
##;;
##2)
##./IPCMOutputParser  $testname
##;;
##*)
##echo "Iligal Profiler Code"
##;;
##esac
##
##fi
#
#
#exec 0<&3
#IFS=$BAKIFS
#
echo "*******************************End Of the Test $testname1*******************************************"
#
