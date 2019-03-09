#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
up_found_colors="../tools/bash_colors.sh"
if [[ "${DISABLE_COLORS}" == "" ]] && [[ "${found_colors}" != "" ]] && [[ -e ${found_colors} ]]; then
    . ${found_colors}
elif [[ "${DISABLE_COLORS}" == "" ]] && [[ "${up_found_colors}" != "" ]] && [[ -e ${up_found_colors} ]]; then
    . ${up_found_colors}
else
    inf() {
        echo "$@"
    }
    anmt() {
        echo "$@"
    }
    good() {
        echo "$@"
    }
    err() {
        echo "$@"
    }
    critical() {
        echo "$@"
    }
    warn() {
        echo "$@"
    }
fi

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

# https://www.cyberciti.biz/faq/how-to-add-disk-image-to-kvm-virtual-machine-with-virsh-command/
nodes="master1.example.com master2.example.com master3.example.com"

function check_mounts() {
    anmt "--------------------------------"
    anmt "Checking mounted /dev paths on the cluster vms"
    for node in $nodes; do
        good " - ${node} has: df -Th | grep 'vdb'"
        ssh root@${node} "df -Th | grep vdb"
        good " - ${node} done partitioning with parted /dev/vdb"
        anmt "--------------------------------"
    done
}

function delete_partitions_and_reformat_disks() {
    for node in $nodes; do

        check_if_mounted=$(ssh root@${node} "df -Th /var/lib/ceph 2> /dev/null" | grep vdb1 | wc -l)
        check_if_partitioned=$(ssh root@${node} "parted /dev/vdb print | grep -A 10 Number | grep -E 'MB|GB' | wc -l")

        # Unmount device if mounted

        if [[ "${check_if_mounted}" != "0" ]]; then
            anmt "${node} - /dev/vdb1 umount"
            ssh root@${node} "umount /dev/vdb1"
            echo "${node} - sleeping to let umount finish"
            sleep 2
            check_if_mounted=$(ssh root@${node} "df -Th /var/lib/ceph 2> /dev/null" | grep vdb1 | wc -l)
            if [[ "${check_if_mounted}" != "0" ]]; then
                err "unable to umount /dev/vdb1 on node: ${node} - stopping"
                exit 1
            fi
        else
            anmt "${node} - /dev/vdb1 is not mounted"
        fi

        # Partition device if partitioned

        if [[ "${check_if_partitioned}" != "0" ]]; then
            anmt "${node} - already partitioned - deleting partitions: ${check_if_partitioned}"
            ssh root@${node} "parted -s /dev/vdb rm 1 >> /dev/null 2>&1"
            ssh root@${node} "parted -s /dev/vdb rm 2 >> /dev/null 2>&1"
        else
            good "no partitions: ${check_if_partitioned}"
        fi

        good "${node} - using parted to partition /dev/vdb"
        # https://unix.stackexchange.com/questions/38164/create-partition-aligned-using-parted/49274#49274
        ssh root@${node} "parted -a optimal /dev/vdb mkpart ceph 0% 100%"
        sleep 2

        anmt "${node} - checking /dev/vdb partitions"
        check_if_partitioned=$(ssh root@${node} "parted /dev/vdb print | grep -A 10 Number | grep -E 'MB|GB' | wc -l")
        if [[ "${check_if_partitioned}" != "1" ]]; then
            err "Failed automated parted partitioning - please manually delete /dev/vdb partitions on ${node} with the commands and retry: "
            ssh root@${node} "parted /dev/vdb print"
            anmt "ssh root@${node}"
            anmt "parted /dev/vdb"
            exit 1
        fi

        # ceph recommends xfs filesystems
        # http://docs.ceph.com/docs/jewel/rados/configuration/filesystem-recommendations/
        anmt "${node} - formatting /dev/vdb1 as xfs"
        ssh root@${node} "mkfs.xfs -f /dev/vdb1"

        # anmt "${node} - formatting /dev/vdb2 as xfs"
        # ssh root@${node} "mkfs.xfs -f /dev/vdb2"

        anmt "${node} - removing previous mountpoint if exists: /var/lib/ceph"
        ssh root@${node} "rm -rf /var/lib/ceph >> /dev/null"

        anmt "${node} - creating /dev/vdb1 mountpoint: /var/lib/ceph"
        ssh root@${node} "mkdir -p -m 775 /var/lib/ceph >> /dev/null"

        # ssh root@${node} "umount /dev/vdb1"
        # anmt "${node} - mounting /dev/vdb1 to /var/lib/ceph"
        # ssh root@${node} "mount /dev/vdb1 /var/lib/ceph"

        # check_disk_filesystem=$(ssh root@${node} "df -Th /var/lib/ceph | grep vdb | grep xfs | wc -l")
        # if [[ "${check_disk_filesystem}" == "0" ]]; then
        #     err "Failed to mount ${node}:/dev/vdb1 as xfs filesystem to /var/lib/ceph"
        #     anmt "Please fix this node and retry:"
        #     anmt "ssh root@${node}"
        # fi

        # test_exists=$(ssh root@${node} "cat /etc/fstab | grep vdb1 | grep xfs | wc -l")
        # if [[ "${test_exists}" == "0" ]]; then
        #     anmt "adding /dev/vdb1 to /etc/fstab"
        #     ssh root@${node} "echo \"/dev/vdb1 /var/lib/ceph  xfs     defaults    0 0\" >> /etc/fstab"
        # fi

        anmt "${node} - checking mounts"
        ssh root@${node} "fdisk -l /dev/vdb"
        anmt "--------------------------------------------"
    done
}

delete_partitions_and_reformat_disks
