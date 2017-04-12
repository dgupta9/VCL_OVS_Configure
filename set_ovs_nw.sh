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

#sed  '/192.168.100.1 mn/c\192.168.200.1 mn' /etc/hosts > tmp && mv -f tmp /etc/hosts
#until virsh list --all | grep management | awk '{print $3}' | grep -m 1 "running"; do sleep 1 ; done
until ping -c 1 mn > /dev/null 2>&1; echo $? | grep -m 1 "0"; do sleep 3 ; done
virsh edit managementnode <<'END'
:%s/private/ovs_private
:wq
END
#virsh shutdown managementnode
until nc -z mn 22 > /dev/null 2>&1; echo $? | grep -m 1 "0"; do sleep 3 ; done
ssh mn shutdown -h now
until virsh list --all | grep management | awk '{print $3}' | grep -m 1 "shut"; do sleep 3 ; done
sleep 3
virsh start managementnode
sleep 15

# Handle dnsmasq. See config files in /var/lib/libvirt/dnsmasq/
ps -ef | grep "dnsmasq/private" | grep -v grep | awk '{print $2}' | xargs kill
ifconfig virbr0 0 down
ifconfig ovs_br0 192.168.100.10 up
systemctl restart hostonly_sshd
systemctl status hostonly_sshd
sed "s/\bvirbr0\b/ovs_br0/g" /etc/sysconfig/iptables > tmp && mv -f tmp /etc/sysconfig/iptables
systemctl restart iptables
systemctl status iptables

