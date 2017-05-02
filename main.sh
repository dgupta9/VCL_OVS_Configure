#! /bin/bash

if [ "$#" -ne 1 ] || ([ "$1" != "master" ] && [ "$1" != "slave" ]); then
    echo "Illegal usage. Please run it as \"./main.sh <master/slave>\""
    exit 1
fi

sandbox_private="./sandbox_private_config"
sandbox_public="./sandbox_public_config"
my_private_IP="$(ifconfig eth0 | grep -w "inet" | cut -d 'i' -f 2 | cut -d ' ' -f 2)"
my_public_IP="$(ifconfig eth1 | grep -w "inet" | cut -d 'i' -f 2 | cut -d ' ' -f 2)"
num_sandboxes="$(cat "$sandbox_private" | sed '/^\s*#/d;/^\s*$/d' | wc -l)"
ips_private=() # Create array to store private IPs of the sandboxes
ips_public=() # Create array to store public IPs of the sandboxes

echo "My private IP is $my_private_IP"
echo "My public IP is $my_public_IP"
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


if [ "$1" == "master" ]; then # Look for the config files in the CWD if it is master
     get_IP_array "private" "$sandbox_private"
     get_IP_array "public" "$sandbox_public"
else # Look for the config files in the /etc directory which is copied from master
     get_IP_array "private" "/etc/sandbox_private_config"
     get_IP_array "public" "/etc/sandbox_public_config"
fi

for ((i=0; i<${#ips_public[@]}; i++));
do
    ip_private=`echo "${ips_private[$i]}" | cut -d "=" -f2` # Cut only IP addresses
    ip_public=`echo "${ips_public[$i]}" | cut -d "=" -f2` # Cut only IP addresses
    ips_private[$i]=${ip_private// } # Remove trailing characters if any
    ips_public[$i]=${ip_public// } # Remove trailing characters if any
    if [ "${ips_private[$i]}" == "$my_private_IP" ]; then
         sandbox_no="$i"
    fi
    if [ "$1" == "master" ]; then
         echo "**********************************************************************************"
         echo "                  Copy config files to all the sandboxes                          "
         echo "**********************************************************************************"
         sleep 1
         scp "$sandbox_private" "${ips_public[$i]}":/etc/
         scp "$sandbox_public" "${ips_public[$i]}":/etc/
    fi
done

./install_ovs.sh
./set_ovs_nw.sh "$1" "$sandbox_no"
./vxlan.sh "$num_sandboxes" "${ips_private[@]}" "${ips_public[@]}"
./cleanup.sh
