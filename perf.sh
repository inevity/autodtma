#!/bin/bash
set -x
ssh -T root@192.168.1.158 <<EOF
perf record -a -g -p 997 -o testname-rate.perf &
sleep 15
killall perf
exit
EOF
