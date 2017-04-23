#! /bin/bash

# VXLAN reference: http://networkstatic.net/configuring-vxlan-and-gre-tunnels-on-openvswitch/
# iptables reference: http://ask.xmodulo.com/open-port-firewall-centos-rhel.html

if [ "$#" -ne 1 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./vxlan.sh <master/slave>\""
    exit 1
fi

sandbox_info_file="./sandbox_config"
my_IP="$(ifconfig eth1 | grep -w "inet" | cut -d 'i' -f 2 | cut -d ' ' -f 2)"
num_sandboxes="$(cat "$sandbox_info_file" | sed '/^\s*#/d;/^\s*$/d' | wc -l)"

echo "My IP is $my_IP"
echo "Number of sandboxes =$num_sandboxes"

get_IP_array() {
    ips=() # Create array to store IPs of the sandboxes
    while IFS= read -r line # Read a line
    do
        # Check for empty or commented lines
        if [[ $(echo $line | sed '/^\s*#/d;/^\s*$/d') ]]; then
              ips+=("$line") # Append line to the array
        fi
    done < "$1"
}


echo "**********************************************************************************"
echo "			Setup VXLAN tunnels to other Sandboxes				"
echo "**********************************************************************************"
sleep 1

iptables -I INPUT -p udp -m udp --dport 4789 -j ACCEPT
service iptables save

get_IP_array "$sandbox_info_file"

for ((i=0; i<${#ips[@]}; i++));
do
    ip=`echo "${ips[$i]}" | cut -d "=" -f2` # Cut only IP addresses
    ips[$i]=${ip// } # Remove trailing characters if any
    if [ "${ips[$i]}" != "$my_IP" ]; then
         ovs-vsctl add-port ovs_br0 vx$i -- set interface vx$i type=vxlan options:remote_ip="${ips[$i]}"
         echo "Tunneling from $my_IP to ${ips[$i]}"
    fi
done

# Increase MTU for physical interfaces to accomodate VXLAN
echo "MTU=1600" >> /etc/sysconfig/network-scripts/ifcfg-eth0
ifdown eth0 && ifup eth0
