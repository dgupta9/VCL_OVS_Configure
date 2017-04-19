#! /bin/bash

if [ "$#" -ne 1 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./vxlan.sh <master/slave>\""
    exit 1
fi

echo "**********************************************************************************"
echo "		Add ovs bridges for ovs_private and ovs_public networks			"
echo "**********************************************************************************"
sleep 1
