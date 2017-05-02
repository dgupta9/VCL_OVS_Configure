#! /bin/bash

# VXLAN reference: http://networkstatic.net/configuring-vxlan-and-gre-tunnels-on-openvswitch/
# iptables reference: http://ask.xmodulo.com/open-port-firewall-centos-rhel.html

if [ "$#" -lt 5 ] || [ "$1" -lt 2 ]; then # Minimum 2 sandboxes are required
    echo "Illegal usage. Please run it as \"./vxlan.sh <num_sandboxes>(min. 2) <IP array>\""
    exit 1
fi

my_private_IP="$(ifconfig eth0 | grep -w "inet" | cut -d 'i' -f 2 | cut -d ' ' -f 2)"
my_public_IP="$(ifconfig eth1 | grep -w "inet" | cut -d 'i' -f 2 | cut -d ' ' -f 2)"
num_sandboxes="$1"
shift # Only have IP arrays as the command line arguments
ips=("$@") # Create array to store private and public IPs of the sandboxes
ips_private=( "${ips[@]:0:$num_sandboxes}" )
ips_public=( "${ips[@]:$num_sandboxes:$num_sandboxes}" )

echo "My private IP is $my_private_IP"
echo "My public IP is $my_public_IP"
echo "Number of sandboxes =$num_sandboxes"
echo "Private IPs are ${ips_private[@]}"
echo "Public IPs are ${ips_public[@]}"

echo "**********************************************************************************"
echo "			Setup VXLAN tunnels to other Sandboxes				"
echo "**********************************************************************************"
sleep 1

iptables -I INPUT -p udp -m udp --dport 4789 -j ACCEPT
service iptables save

for ((i=0; i<${#ips_private[@]}; i++));
do
    if [ "${ips_private[$i]}" != "$my_private_IP" ]; then # satya: Add a check for public as well
         ovs-vsctl add-port ovs_br0 vx$i -- set interface vx$i type=vxlan options:remote_ip="${ips_private[$i]}"
         ovs-vsctl add-port ovs_br1 vp$i -- set interface vp$i type=vxlan options:remote_ip="${ips_public[$i]}"
         echo "Tunneling from $my_private_IP to ${ips_private[$i]}"
         echo "Tunneling from $my_public_IP to ${ips_public[$i]}"
    fi
done
