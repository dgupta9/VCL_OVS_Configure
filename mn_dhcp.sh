#! /bin/bash

firewall-cmd --add-service=dhcp --permanent
firewall-cmd --reload

sed "s/\bvirbr0\b/eth0/g" /var/lib/dnsmasq/private.conf > tmp && mv -f tmp /var/lib/dnsmasq/private.conf
sed "s/\b\/libvirt\/\b/\//g" /var/lib/dnsmasq/private.conf > tmp && mv -f tmp /var/lib/dnsmasq/private.conf
sed "s/\b\/network\/\b/\//g" /var/lib/dnsmasq/private.conf > tmp && mv -f tmp /var/lib/dnsmasq/private.conf
ps -ef | grep "dnsmasq" | grep -v grep | awk '{print $2}' | xargs kill
/sbin/dnsmasq --conf-file=/var/lib/dnsmasq/private.conf --leasefile-ro

sed "s/\bvirbr1\b/eth1/g" /var/lib/dnsmasq/nat.conf > tmp && mv -f tmp /var/lib/dnsmasq/nat.conf
sed "s/\b\/libvirt\/\b/\//g" /var/lib/dnsmasq/nat.conf > tmp && mv -f tmp /var/lib/dnsmasq/nat.conf
sed "s/\b\/network\/\b/\//g" /var/lib/dnsmasq/nat.conf > tmp && mv -f tmp /var/lib/dnsmasq/nat.conf
echo "dhcp-option=3,192.168.200.10" >> /var/lib/dnsmasq/nat.conf # Default Gateway
/sbin/dnsmasq --conf-file=/var/lib/dnsmasq/nat.conf --leasefile-ro

# Use the same RSA private key while logging into any sandbox
sed "s/\b192.168.100.10\b/192.168.100.*/g" /root/.ssh/config > tmp && mv -f tmp /root/.ssh/config
