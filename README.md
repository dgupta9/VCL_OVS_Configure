# SDN Overlay Network with VCL and Open vSwitch

VCL stands for Virtual Computing Lab. It is a free and open-source cloud computing platform for delivering dedicated and custom environments to users. VCL can be used to create a simple VM or a high performance computing environment (HPC). The user interface consists of a self-service web portal. Using the portal, users select from a list of customized environments and make reservations. VCL uses linux bridges (linux based software bridges) to facilitate communication among virtual machines and the management node. The management node runs as a VM on the KVM hypervisor which has all the VCL code, the database and controls all the VMs on the private network. There are two networks named private and NAT, each associated with a separate linux bridge. The private network is an internal network that is used for the VMs to communicate with the management node. The NAT network is a public network that provides internet connectivity to the VMs to communicate to the outside world.

The primary objective of the project is to replace the standard Linux bridges in the KVM hypervisor of VCL Sandbox 2.4.2 by Open vSwitches for bringing more programmability into the system. The VCL Sandbox 2.4.2 is an environment which is setup for this project. The sandbox is a nested virtual environment. It consists of a bare metal machine which runs a VMware hypervisor on top to provide virtualization. A VM on this machine has KVM hypervisor installed which spawns new VMs which comprise of the management node and guest machines. We replicate this sandbox and use multiple sandboxes in our project connected to each other by a VXLAN overlay network for scalability.

A single management node in the master sandbox is able to manage the virtual machines in the slave sandboxes by using VXLAN tunneling protocol for ease of management. An OpenFlow controller running on a VM in the master sandbox controls the operation of the Open vSwitches in the sandboxes.

# System environment:

The project is implemented on VCL 2.4.2 Sandbox images available through NCSU Virtual Computing Lab (VCL) environment.

The Sandbox reservation provides access to a Centos 7.2 box labelled vmhost1. vmhost1 has a KVM hypervisor and has relevant iptables rules to route traffic to and from the VMs running on it. The VMs are managed by virt-manager which is a GUI provided by libvirt. 
A special node called the managementnode (mn) has 2 interfaces connected to the private and nat Linux bridges on the hypervisor. mn also runs the vcld daemon which is responsible for managing the VMs. It also hosts a http server and a maria database.

The architecuture of VCL is described in https://vcl.apache.org/info/architecture.html

# Steps: 

The script is run in one master sandbox and at least one slave sandbox. Create a reservation for a VCL 2.4.2 Sandbox image in VCL and clone this repository in all the sandboxes. Follow the steps as described below:

Master:
./main.sh master 0

Slave:
./slave slave [0,1,2,.....]

Once the main script is run, it calls the following scripts:
1) install.sh
->Install Open vSwitch on Master and Slave sandboxes.

2) set_ovs_nw.sh
->Create private and public bridges (ovs_br0 and ovs_br1).
->Define networks for OVS from XML files (ovs_private & ovs_public).
->Shut down Slave MN:
->Connect managementnode to ovs_private and ovs_public.
->Kill DHCP server on vmhost. Start two DHCP servers on managementnode (for VM private and public addresses).
->Change Iptables rule – replace virbr0->ovs_br0 and virbr1->ovs_br1 in vmhost1.

3) vxlan.sh
->Create VXLAN tunnels. Read Ips from sandbox_private_config and sandbox_public_config

4) cleanup.sh
Cleans any files created while running the script

Once the script is run, on a browser type, "http://<master_sandbox_public_ip>". You will be redirected to the http server running on mn. Here follow these steps:

Edit VM host profile – change network type from private-> ovs_private and nat-> ovs_public.

Add a new computer (vmhost2) and add VMs to this.

Configure NAT host for VMs as vmhost1.

Reserve VMs and connect to them via SSH.
