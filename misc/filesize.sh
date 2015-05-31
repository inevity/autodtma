#!/bin/bash
set -x 
for filesize in 612 1024 524288 1048576 10485760 104857600
do
    #bitnum=$(`echo $filesize |wc -c`)
    bitnum=`echo $filesize |wc -c`
    case "$bitnum" in
          4)
           cp /usr/share/nginx/html/612B /usr/share/nginx/html/index.html
          ;;
          5)
           cp /usr/share/nginx/html/1KB /usr/share/nginx/html/index.html
          ;;
          7)
           cp /usr/share/nginx/html/512KB /usr/share/nginx/html/index.html
          ;;
          8)
           cp /usr/share/nginx/html/1MB /usr/share/nginx/html/index.html
          ;;
          9)
           cp /usr/share/nginx/html/10MB /usr/share/nginx/html/index.html
          ;;
          10)
           cp /usr/share/nginx/html/100MB /usr/share/nginx/html/index.html
          ;;
          *)
           echo "not needed file size "
          ;;
    esac

#    cp /usr/share/nginx/index/$filesize /usr/share/nginx/index/index.html
    ansible -u root 10.10.10.254 -m shell -a "/usr/local/squid/bin/refresh_cli -f http://www.myweb.com/index.html"
    #realfsize=$(`wget http://www.myweb.com/index.html --spider --server-response -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`)
    realfsize=`wget http://www.myweb.com/index.html --spider --server-response -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`
    #if [ $realfsize eq $filesize ]
    if [ $realfsize == $filesize ]
    then
       wget http://www.myweb.com/index.html
    else
       echo "wrong real file size $realfsize ,need size $filesize"
#       exit
       continue
     fi
done
