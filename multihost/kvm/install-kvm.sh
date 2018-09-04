#!/bin/bash

if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
fi

user=jay
inf "anmt installing kvm"
apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager

nic_name=$(ifconfig | grep -E "enp|ens" | sed -e 's/:/ /g' | awk '{print $1}' | head -1)

echo "" >> /etc/network/interfaces
echo "auto br0" >> /etc/network/interfaces
echo "iface br0 inet dhcp" >> /etc/network/interfaces
echo "      bridge_ports ${nic_name}" >> /etc/network/interfaces
echo "      bridge_stp off" >> /etc/network/interfaces
echo "      bridge_maxwait 0" >> /etc/network/interfaces

adduser ${user} libvirt
adduser ${user} libvirt-qemu

good "done installing kvm with support for bridge network adapters"
