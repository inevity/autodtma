#!/bin/bash
#perffiles=/root/ProfileLog/profiler-$testname-$rate-perf.data
for perfdata in /root/ProfileLog/*.data 
do
#  perf script -f comm,pid,tid,ip,sym,dso -i $perfdata |./FlameGraph/stackcollapse-perf.pl -pid |awk -F';' '{print $1}'|uniq|cut -d '-' --fields=2
   perf script -f comm,pid,tid,ip,sym,dso -i $perfdata |./FlameGraph/stackcollapse-perf.pl -pid > c$perfdata
   squidpids=`awk -F';' '{print $1}'|uniq|cut -d '-' --fields=2`
   for squidpid in $squidpids
   do
       grep $squidpid  c$perfdata |./FlameGraph/flamegraph.pl > $squidpid.$perfdata.svg
   done
done
   

