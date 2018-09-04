#!/bin/bash

create_vm="1"
vm_name="m1"
default_disk_location=/data/kvm/disks
use_img=${default_disk_location}/${vm_name}.qcow2

if [[ -e ${use_img} ]]; then
    test_exists=$(virsh list --all | grep ${vm_name} | wc -l)
    if [[ "${test_exists}" == "1" ]]; then
        echo ""
        echo "starting ${vm_name}"
        virsh start ${vm_name}
        create_vm="0"
    else
        echo ""
        echo "importing ${vm_name}"
        virt-install \
            --import \
            --name ${vm_name} \
            --virt-type=kvm \
            --ram 10240 \
            --cpu host \
            --vcpus=3 \
            --os-variant=rhel7 \
            --virt-type=kvm \
            --hvm \
            --network=bridge=br0,model=virtio \
            --disk path=${use_img},size=80,bus=virtio,format=qcow2
        create_vm="0"
    fi
fi

if [[ "${create_vm}" == "1" ]]; then
    echo ""
    echo "creating ${vm_name}"
    virt-install \
        --name ${vm_name} \
        --virt-type=kvm \
        --ram 10240 \
        --cpu host \
        --vcpus=3 \
        --os-variant=rhel7 \
        --virt-type=kvm \
        --hvm \
        --network=bridge=br0,model=virtio \
        --graphics vnc \
        --disk path=${use_img},size=80,bus=virtio,format=qcow2
fi
