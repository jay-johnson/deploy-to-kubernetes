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
        echo "missing hdd image at: ${image_path} size: ${size}"
        echo "please generate them manually or with the ./ceph/kvm-build-images.sh script"
        exit 1
    else
        echo "detaching image: ${image_path} to ${node} with:"
        echo "virsh detach-disk ${node} \
            ${image_path}"
        virsh detach-disk ${node} \
            ${image_path} \
	    --persistent
    fi
done
