#! /bin/bash

sed "s/\bBOOTPROTO=dhcp\b/BOOTPROTO=none/g" /etc/sysconfig/network-scripts/ifcfg-eth0 > tmp && mv -f tmp /etc/sysconfig/network-scripts/ifcfg-eth0
echo "DEVICE=eth0" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPADDR=192.168.100.1" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
