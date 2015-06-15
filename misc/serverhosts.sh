#!/bin/bash
#cp hostssquid /usr/local/squid/etc/hosts
echo '10.10.10.66 www.myweb.com' > /usr/local/squid/etc/hosts
echo '10.10.10.254 www.myweb.com' >> /etc/hosts
cp squid.conf /usr/local/squid/etc
sleep 10
service fc restart
