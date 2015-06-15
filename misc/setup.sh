#!/bin/bash
#we should have config the server and client ip,LAN and WLAN
#tee -a /etc/resolv.conf << EOF
#nameserver 8.8.8.8
#EOF
#
#yum install -y git
git clone https://github.com/inevity/squidpatch.git
#git clone https://github.com/inevity/autodtma.git RUNs 
yum localinstall -y  squidpatch/epel-release-6-8.noarch.rpm
linennnn=`awk 'NF==0 {print NR}' /etc/ansible/hosts |head -1`
sed -ibackup -r -e  "${linennnn}s/.*/10.10.10.254\nlocahost/" /etc/ansible/hosts

tee -a /etc/ansible/hosts << EOF
[alltests]
10.10.10.254
localhost
EOF

rm -fr ~/.ssh/*
ssh-keygen  -t rsa -f ~/.ssh/id_rsa  -N ''
./sshkeyput.sh localhost
./sshkeyput.sh 10.10.10.254
yum install -y ansible
#ansible is not needed on server.
ansible-playbook --verbose -vvvv -f 1 envsetup.yml
#we alse reboot the client meachine,server reboot in envsetup.yml
shutdown -r now
