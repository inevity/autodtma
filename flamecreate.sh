#!/bin/bash
#perffiles=/root/ProfileLog/profiler-$testname-$rate-perf.data
perfdata=$1
perf script -f comm,pid,tid,ip,sym,dso -i ./Prof/$perfdata |./FlameGraph/stackcollapse-perf.pl -pid > ./Prof/c$perfdata
squidpids=`awk -F';' '{print $1}' ./Prof/c$perfdata |uniq|cut -d '-' --fields=2`
for squidpid in $squidpids
  do
     grep $squidpid  ./Prof/c$perfdata |./FlameGraph/flamegraph.pl > ./FlameGraph/$perfdata-$squidpid.svg
done
   

