#! /bin/bash

if [ "$#" -ne 2 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./main.sh <master/slave> <sandbox_no>\""
    exit 1
fi
./install_ovs.sh
./set_ovs_nw.sh "$1" "$2"
./vxlan.sh "$1"
#./controller.sh "$1"
./cleanup.sh
