#! /bin/bash

#sed '/ListenAddress 192.168.100.1/a ListenAddress 192.168.200.1' /etc/ssh/sshd_config > tmp && mv -f tmp /etc/ssh/sshd_config
echo "ListenAddress 192.168.200.1" >> /etc/ssh/sshd_config
systemctl restart sshd
systemctl status sshd
