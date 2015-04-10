#!/bin/sh

collectl   -c 3650  --export /home/rhashem/Documents/UtilLog/collectl_percore.ph > /home/rhashem/Documents/UtilLog/$1 &

