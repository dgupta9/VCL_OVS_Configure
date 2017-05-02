#! /bin/bash

# OVS installation steps reference
# http://supercomputing.caltech.edu/blog/index.php/2016/05/03/open-vswitch-installation-on-centos-7-2/

echo "**********************************************************************************"
echo "				Install openvswitch package				"
echo "**********************************************************************************"
sleep 1
# Install pre-requisites
yum -y install make gcc openssl-devel autoconf automake rpm-build redhat-rpm-config python-devel openssl-devel kernel-devel kernel-debug-devel libtool wget

# Build rpm
mkdir -p ~/rpmbuild/SOURCES
wget http://openvswitch.org/releases/openvswitch-2.5.2.tar.gz
scp openvswitch-2.5.2.tar.gz ~/rpmbuild/SOURCES/
tar xfz openvswitch-2.5.2.tar.gz
sed 's/openvswitch-kmod, //g' openvswitch-2.5.2/rhel/openvswitch.spec > openvswitch-2.5.2/rhel/openvswitch_no_kmod.spec
rpmbuild -bb --nocheck ./openvswitch-2.5.2/rhel/openvswitch_no_kmod.spec

# Install openvswitch from the rpm
yum localinstall -y ~/rpmbuild/RPMS/x86_64/openvswitch-2.5.2-1.x86_64.rpm 

# Start openvswitch
systemctl start openvswitch.service
chkconfig openvswitch on
systemctl status openvswitch.service
ovs-vsctl -V
ovs-vsctl show
