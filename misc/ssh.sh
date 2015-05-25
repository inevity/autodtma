#!/bin/bash
ssh -t -t root@10.10.10.253 <<EOF
collectl -sCDNm -c 3000 --rawtoo  --sep , -F2 -oz -P -f ~/UtilLog/util
sleep 10
killall collectl
exit
EOF
