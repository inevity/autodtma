#!/bin/bash
set -x 
testname=test
rate=7
testtime=20
#pids=`sshpass -p 'sophnep!@#' ps -ef |grep fc-cache |grep squid |awk '{print $2'}|tr '\n' ','`
#pids=`ps -ef |grep fc-cache |grep squid |awk '{print $2'}|tr '\n' ','`
#ansible-playbook prof.yml --verbose --extra-vars "pids=$pids outfile=/root/util$testname-$rate ctime=$testtime"
ansible-playbook prof.yml -v --verbose --extra-vars "outfile=/root/util$testname-$rate ctime=$testtime"
