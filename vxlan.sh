#! /bin/bash

# VXLAN reference: http://networkstatic.net/configuring-vxlan-and-gre-tunnels-on-openvswitch/
# iptables reference: http://ask.xmodulo.com/open-port-firewall-centos-rhel.html

if [ "$#" -ne 1 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./vxlan.sh <master/slave>\""
    exit 1
fi

sandbox_private="./sandbox_private_config"
my_private_IP="$(ifconfig eth0 | grep -w "inet" | cut -d 'i' -f 2 | cut -d ' ' -f 2)"
num_sandboxes="$(cat "$sandbox_private" | sed '/^\s*#/d;/^\s*$/d' | wc -l)"
ips_private=() # Create array to store private IPs of the sandboxes
ips_public=() # Create array to store public IPs of the sandboxes

echo "My IP is $my_private_IP"
echo "Number of sandboxes =$num_sandboxes"

get_IP_array() {
    while IFS= read -r line # Read a line
    do
        # Check for empty or commented lines
        if [[ $(echo $line | sed '/^\s*#/d;/^\s*$/d') ]]; then
              if [ "$1" == "private" ]; then
                   ips_private+=("$line") # Append line to the array
              else
                   ips_public+=("$line") # Append line to the array
              fi
        fi
    done < "$2"
}


echo "**********************************************************************************"
echo "			Setup VXLAN tunnels to other Sandboxes				"
echo "**********************************************************************************"
sleep 1

iptables -I INPUT -p udp -m udp --dport 4789 -j ACCEPT
service iptables save

get_IP_array "private" "$sandbox_private"

for ((i=0; i<${#ips_private[@]}; i++));
do
    ip_private=`echo "${ips_private[$i]}" | cut -d "=" -f2` # Cut only IP addresses
    ips_private[$i]=${ip_private// } # Remove trailing characters if any
    if [ "${ips_private[$i]}" != "$my_private_IP" ]; then
         ovs-vsctl add-port ovs_br0 vx$i -- set interface vx$i type=vxlan options:remote_ip="${ips_private[$i]}"
         echo "Tunneling from $my_private_IP to ${ips_private[$i]}"
    fi
done

# Increase MTU for physical interfaces to accomodate VXLAN
echo "MTU=1600" >> /etc/sysconfig/network-scripts/ifcfg-eth0
ifdown eth0 && ifup eth0
