#!/bin/bash
#cp hostssquid /usr/local/squid/etc/hosts
echo '10.10.10.66' > /usr/local/squid/etc/hosts
echo '10.10.10.254 www.myweb.com' >> /etc/hosts
cp squid.conf /usr/local/squid/etc
service fc restart
