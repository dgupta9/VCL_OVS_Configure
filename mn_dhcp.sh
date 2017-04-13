#! /bin/bash

sed "s/\bvirbr0\b/eth0/g" /var/lib/dnsmasq/private.conf > tmp && mv -f tmp /var/lib/dnsmasq/private.conf
sed "s/\b\/libvirt\/\b/\//g" /var/lib/libvirt/dnsmasq/private.conf > tmp && mv -f tmp /var/lib/libvirt/dnsmasq/private.conf
sed "s/\b\/network\/\b/\//g" /var/lib/libvirt/dnsmasq/private.conf > tmp && mv -f tmp /var/lib/libvirt/dnsmasq/private.conf
firewall-cmd --add-service=dhcp --permanent
firewall-cmd --reload
/sbin/dnsmasq --conf-file=/var/lib/dnsmasq/private.conf --leasefile-ro
