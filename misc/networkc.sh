#!/bin/bash

# Shell script input parsing here
clientipi=$1
clientipw=$2


system-config-network-cmd -i <<EOF
DeviceList.Ethernet.eth0.Type=Ethernet
DeviceList.Ethernet.eth0.BootProto=static
DeviceList.Ethernet.eth0.OnBoot=True
DeviceList.Ethernet.eth0.NMControlled=no
DeviceList.Ethernet.eth0.PrimaryDNS=8.8.4.4
DeviceList.Ethernet.eth0.Netmask=255.255.255.0
DeviceList.Ethernet.eth0.IP=${clientipw}
DeviceList.Ethernet.eth0.Gateway=192.168.1.1
ProfileList.default.ActiveDevices.1=eth0
DeviceList.Ethernet.eth4.Type=Ethernet
DeviceList.Ethernet.eth4.BootProto=static
DeviceList.Ethernet.eth4.OnBoot=True
DeviceList.Ethernet.eth4.NMControlled=no
DeviceList.Ethernet.eth4.IP=${clientipi}
ProfileList.default.ActiveDevices.5=eth4
EOF

service network stop
service network start
