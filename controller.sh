#! /bin/bash

if [ "$#" -ne 1 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./controller.sh <master/slave>\""
    exit 1
fi

ovs-vsctl set-controller ovs_br0 tcp:192.168.200.193:6633
ovs-vsctl set-controller ovs_br1 tcp:192.168.200.193:6633
