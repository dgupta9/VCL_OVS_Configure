#! /bin/bash

if [ "$#" -ne 2 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./set_ovs_nw.sh <master/slave> <sandbox_no>\""
    exit 1
fi

sandbox_num="$2"

echo "**********************************************************************************"
echo "		Add ovs bridges for ovs_private and ovs_public networks			"
echo "**********************************************************************************"
sleep 1
# Add ovs private and public bridges
ovs-vsctl add-br ovs_br0
ovs-vsctl add-br ovs_br1

# Define ovs private and public networks
virsh net-define ./ovs_private.xml
virsh net-start ovs_private
virsh net-autostart ovs_private

virsh net-define ./ovs_public.xml
virsh net-start ovs_public
virsh net-autostart ovs_public

echo "**********************************************************************************"
echo "			Connect management node to OVS bridges				"
echo "**********************************************************************************"
sleep 1
if [ "$1" == "master" ]; then
    scp mn_nw.sh mn:/root/
    scp mn_dhcp.sh mn:/root/
    scp /var/lib/libvirt/dnsmasq/private.* mn:/var/lib/dnsmasq/
    scp /var/lib/libvirt/dnsmasq/nat.* mn:/var/lib/dnsmasq/
    ssh mn << EOF
      chmod 755 ./mn_nw.sh
      ./mn_nw.sh
EOF

    until ping -c 1 mn > /dev/null 2>&1; echo $? | grep -m 1 "0"; do sleep 3 ; done
    virsh edit managementnode <<'END'
    :%s/private/ovs_private
    :%s/nat/ovs_public
    :wq
END
    until ssh -q mn exit; echo $? | grep -m 1 "0"; do sleep 3 ; done
    ssh mn << EOF
      shutdown -h now
EOF
    until virsh list --all | grep management | awk '{print $3}' | grep -m 1 "shut"; do sleep 3 ; done
    virsh start managementnode
    sleep 10
else # If it is a slave, destroy management node
    virsh destroy managementnode
fi

ps -ef | grep "dnsmasq/private" | grep -v grep | awk '{print $2}' | xargs kill
ps -ef | grep "dnsmasq/nat" | grep -v grep | awk '{print $2}' | xargs kill
ifconfig virbr0 0 down
ifconfig virbr1 0 down
if [ "$1" == "master" ]; then
    ifconfig ovs_br0 192.168.100."$((10+$sandbox_num))" up
    ifconfig ovs_br1 192.168.200."$((10+$sandbox_num))" up
else
    ifconfig ovs_br0 192.168.100."$((10+$sandbox_num))" up
    ifconfig ovs_br1 192.168.200."$((10+$sandbox_num))" up
    sed "s/\b192.168.100.10\b/192.168.100."$((10+$sandbox_num))"/g" /etc/ssh/hostonly_sshd_config > tmp && mv -f tmp /etc/ssh/hostonly_sshd_config
    iptables -t nat -D PREROUTING -s 192.168.100.1/32 -d 192.168.100.10/32 -i virbr0 -p tcp -m tcp --dport 22 -j REDIRECT --to-ports 24
    iptables -t nat -I PREROUTING 5 -s 192.168.100.1/32 -d 192.168.100."$((10+$sandbox_num))"/32 -i virbr0 -p tcp -m tcp --dport 22 -j REDIRECT --to-ports 24
    service iptables save
fi
systemctl restart hostonly_sshd
systemctl status hostonly_sshd
sed "s/\bvirbr0\b/ovs_br0/g" /etc/sysconfig/iptables > tmp && mv -f tmp /etc/sysconfig/iptables
sed "s/\bvirbr1\b/ovs_br1/g" /etc/sysconfig/iptables > tmp && mv -f tmp /etc/sysconfig/iptables
systemctl restart iptables
systemctl status iptables

if [ "$1" == "master" ]; then
    echo "**********************************************************************************"
    echo "			Starting DHCP server ovs_* networks				"
    echo "**********************************************************************************"
    sleep 1
    until ssh -q mn exit; echo $? | grep -m 1 "0"; do sleep 3 ; done
    ssh mn << EOF
      route add default gw 192.168.200.10 eth1
      chmod 755 ./mn_dhcp.sh
      ./mn_dhcp.sh
EOF
fi
