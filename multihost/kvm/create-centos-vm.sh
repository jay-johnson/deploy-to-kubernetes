#!/bin/bash

# requires having kvm installed

# usage: ./multihost/kvm/create-centos-vm.sh m1 /data/kvm/m1.qcow2
# usage: ./multihost/kvm/create-centos-vm.sh m2
# usage: ./multihost/kvm/create-centos-vm.sh m3

default_disk_location="/data/kvm/disks"
test_virt_installed=$(which virt-install | wc -l)
if [[ "${test_virt_installed}" == "0" ]]; then
    echo "Please install kvm before running this script"
    exit 1
fi

if [[ ! -e ${default_disk_location} ]]; then
    mkdir -p -m 777 ${default_disk_location}
fi

if [[ ! -e /data/iso ]]; then
    mkdir -p -m 777 /data/iso
fi

vm_name="m1"
kvm_image_path="${default_disk_location}/${vm_name}.qcow2"
download_url="http://centos.s.uw.edu/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1804.iso"
download_file="/data/iso/centos-7.iso"

if [[ "${1}" != "" ]]; then
    vm_name="${1}"
fi
if [[ "${2}" != "" ]]; then
    kvm_image_path="${2}"
fi
if [[ "${3}" != "" ]]; then
    download_url="${3}"
fi
if [[ "${4}" != "" ]]; then
    download_file="${4}"
fi

if [[ ! -e ${download_file} ]]; then
    echo "downloading: curl ${download_url} --output ${download_file}"
    curl ${download_url} --output ${download_file}
fi

echo "creating ${vm_name} iso: ${download_file} path: ${kvm_image_path}"
virt-install \
    --name ${vm_name} \
    --virt-type=kvm \
    --ram 10240 \
    --cpu host \
    --vcpus=2 \
    --os-type=linux \
    --os-variant=rhel7 \
    --virt-type=kvm \
    --hvm \
    --network=bridge=br0,model=virtio \
    --graphics vnc \
    --cdrom ${download_file} \
    --disk path=${kvm_image_path},size=80,bus=virtio,format=qcow2
