#! /bin/bash

# Add ovs private and public bridges
ovs-vsctl add-br ovs_br0
#ovs-vsctl add-br ovs_br1

# Define ovs private and public networks
virsh net-define ./ovs_private.xml
virsh net-start ovs_private
virsh net-autostart ovs_private

#virsh net-define ./ovs_public.xml
#virsh net-start ovs_public
#virsh net-autostart ovs_public

scp mn_nw.sh mn:/root/

ssh mn << EOF
  chmod 755 ./mn_nw.sh
  ./mn_nw.sh
EOF
# Need to add code to make eth0 IP as static

sed  '/192.168.100.1 mn/c\192.168.200.1 mn' /etc/hosts > tmp && mv -f tmp /etc/hosts
virsh dumpxml managementnode > /tmp/mn.xml
virsh shutdown managementnode
sed "s/\bprivate\b/ovs_private/g" /tmp/mn.xml > tmp && mv -f tmp /tmp/mn.xml
sed "s/\bvirbr0\b/ovs_br0/g" /tmp/mn.xml > tmp && mv -f tmp /tmp/mn.xml
virsh undefine managementnode
sleep 5 # Need to change this
virsh create /tmp/mn.xml

# Handle dnsmasq. See config files in /var/lib/libvirt/dnsmasq/
ps -ef | grep "dnsmasq/private" | grep -v grep | awk '{print $2}' | xargs kill
ifconfig virbr0 0 down
ifconfig ovs_br0 192.168.100.10 up
systemctl restart hostonly_sshd
systemctl status hostonly_sshd
sed "s/\bvirbr0\b/ovs_br0/g" /etc/sysconfig/iptables > tmp && mv -f tmp /etc/sysconfig/iptables
systemctl restart iptables
systemctl status iptables

