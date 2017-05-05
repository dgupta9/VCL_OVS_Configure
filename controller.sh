#! /bin/bash

if [ "$#" -lt 1 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./controller.sh <master/slave> [<controller-vm hostname/IP>]\""
    exit 1
fi

if [ "$1" == "master" ]; then
ssh mn << EOF
    scp /root/install_controller.sh "$2":/root/
    ssh "$2" << EOFF
         chmod 755 /root/install_controller.sh
         /root/install_controller.sh
EOFF
EOF
fi

#ovs-vsctl set-controller ovs_br0 tcp:192.168.200.193:6633
#ovs-vsctl set-controller ovs_br1 tcp:192.168.200.193:6633
