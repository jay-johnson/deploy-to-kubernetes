#!/bin/bash

image_dir="/cephdata"
size="100G"

if [[ ${1} != "" ]]; then
    image_dir=${1}
fi

if [[ ${2} != "" ]]; then
    size=${2}
fi

if [[ ! -e ${image_dir} ]]; then
    sudo mkdir -p -m 775 ${image_dir}
fi

nodes="m1 m2 m3"
for node in $nodes; do
    node_dir=${image_dir}/${node}
    if [[ ! -e ${node_dir} ]]; then
        sudo mkdir -p -m 775 ${node_dir}
    fi
    image_name="k8-centos-${node}"
    image_path="${node_dir}/${image_name}"
    if [[ ! -e ${image_path} ]]; then
        echo "creating hdd image at: ${image_path} size: ${size}"
        echo "qemu-img create -f qcow2 ${image_path} ${size}"
        sudo qemu-img create -f qcow2 ${image_path} ${size}
    else
        echo " - already have image: ${image_path}"
        ls -lrth ${image_path}
    fi
done
