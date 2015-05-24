#!/bin/bash
set -x
i=5
for pid in `ps -ef |grep fc-cache |grep squid |awk '{print $2'}`
do 
     taskset -cp $i  $pid
     i=$(($i+1))
done

i=2
for ngpid in `pidof nginx`
do
    i=$(($i+1))
    taskset -cp $i $ngpid
done
