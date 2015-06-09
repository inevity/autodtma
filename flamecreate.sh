#!/bin/bash
#perfdata=$1
#cname=$(echo c$perfdata)
#perf script -f comm,pid,tid,ip,sym,dso -i ../Prof/$perfdata |../FlameGraph/stackcollapse-perf.pl -pid > ../Prof/$cname
#squidpids=`awk -F';' '{print $1}' ../Prof/$cname |uniq|cut -d '-' --fields=2`
#for $squidpid in $squidpids
#  do
#     grep $squidpid  ../Prof/$cname |../FlameGraph/flamegraph.pl > ../FlameGraph/$perfdata-$squidpid.svg
#done
#perfdata=$1
#cname=$(echo c$perfdata)
#perf script -f comm,pid,tid,ip,sym,dso -i ./Prof/$perfdata |./FlameGraph/stackcollapse-perf.pl -pid > ./Prof/$cname
#squidpids=`awk -F';' '{print $1}' ./Prof/$cname |uniq|cut -d '-' --fields=2`
#for $squidpid in $squidpids
#  do
#     grep $squidpid  ./Prof/$cname |./FlameGraph/flamegraph.pl > ./FlameGraph/$perfdata-$squidpid.svg
#done

perfdata=$1
cname=$(echo c$perfdata)
#perf script -f comm,pid,tid,ip,sym,dso -i ../Prof/$perfdata |../FlameGraph/stackcollapse-perf.pl -pid > ../Prof/$cname
perf script -f comm,pid,tid,ip,sym,dso -i /root/Prof/$perfdata > /root/Prof/s$perfdata
# notice case!!!! .../root/FlameGraph/stackcollapse-perf.pl -pid /root/Prof/s$perfdata > /root/Prof/$cname
/root/Flamegraph/stackcollapse-perf.pl -pid /root/Prof/s$perfdata > /root/Prof/$cname
squidpids=`awk -F';' '{print $1}' /root/Prof/$cname |uniq|cut -d '-' --fields=2`
for squidpid in $squidpids
  do
     #grep $squidpid  /root/Prof/$cname |/root/FlameGraph/flamegraph.pl > /root/Flamegraph/$perfdata-$squidpid.svg
     grep $squidpid  /root/Prof/$cname > /root/Flamegraph/greppid
     /root/Flamegraph/flamegraph.pl /root/Flamegraph/greppid > /root/Flamegraph/$perfdata-$squidpid.svg
done
