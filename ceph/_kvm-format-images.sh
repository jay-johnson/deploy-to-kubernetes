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

function format_as_xfs() {
    for node in $nodes; do

        ssh root@${node} "umount /dev/vdb1"
        ssh root@${node} "sudo fdisk -l /dev/vdb"

        # https://serverfault.com/questions/258152/fdisk-partition-in-single-line
        anmt "Setting up ${node} partition for /dev/vdb"
        ssh root@${node} "printf \"\nn\np\n1\n\n\nw\nq\n\" | sudo fdisk /dev/vdb"

        # or manually:
        # echo "# run on as root on the vm to format the disk in the vm:"
        # echo "ssh root@${node}"
        # echo "sudo fdisk /dev/vdb"
        # echo "# enter commands:"
        # echo "n"
        # echo "p"
        # echo "1"
        # echo "w"

        # ceph recommends xfs filesystems
        # http://docs.ceph.com/docs/jewel/rados/configuration/filesystem-recommendations/
        anmt "Formatting /dev/vdb1 as xfs"
        ssh root@${node} "mkfs.xfs -f /dev/vdb1"

        anmt "Removing previous mountpoint if exists: ${node}:/var/lib/ceph"
        ssh root@${node} "rm -rf /var/lib/ceph >> /dev/null"

        anmt "Creating /dev/vdb1 mountpoint: /var/lib/ceph"
        ssh root@${node} "mkdir -p -m 775 /var/lib/ceph >> /dev/null"

        # ssh root@${node} "umount /dev/vdb1"
        ssh root@${node} "mount /dev/vdb1 /var/lib/ceph"

        test_exists=$(ssh root@${node} "cat /etc/fstab | grep vdb1 | grep xfs | wc -l")
        if [[ "${test_exists}" == "0" ]]; then
            anmt "Adding /dev/vdb1 to /etc/fstab"
            ssh root@${node} "echo \"/dev/vdb1 /var/lib/ceph  xfs     defaults    0 0\" >> /etc/fstab"
        fi

        anmt "Checking mounts"
        ssh root@${node} "df -h | grep vdb1"
    done
}

function umount_devices() {
    anmt "--------------------------------"
    anmt "Unmounting /dev/vdb devices on the cluster vms"
    for node in $nodes; do
        good " - ${node} umount /dev/vdb and /dev/vdb1"
        ssh root@${node} "umount /dev/vdb1" >> /dev/null 2>&1
        ssh root@${node} "umount /dev/vdb" >> /dev/null 2>&1
    done
}

function partition_devices() {
    anmt "--------------------------------"
    anmt "Partitioning /dev/vdb devices on the cluster vms"
    for node in $nodes; do
        anmt " - ${node} sleeping umount on /dev/vdb"
        sleep 5
        anmt " - ${node} partitioning with fdisk /dev/vdb"
        ssh root@${node} "printf \"d\n1\nd\nw\nq\n\" | sudo fdisk /dev/vdb"
        sleep 2
        good " - ${node} done partitioning with fdisk /dev/vdb"
        anmt "--------------------------------"
    done
}

function check_mounts() {
    anmt "--------------------------------"
    anmt "Checking mounted /dev paths on the cluster vms"
    for node in $nodes; do
        good " - ${node} has: df -h | grep '/dev'"
        ssh root@${node} "df -h | grep vdb"
        ssh root@${node} "df -h | grep '/dev'"
        good " - ${node} done partitioning with fdisk /dev/vdb"
        anmt "--------------------------------"
    done
}

function check_on_fdisk_orphaned_processes() {
    anmt "--------------------------------"
    anmt "Checking for orphaned fdisk processes on the cluster vms"
    for node in $nodes; do
        num_fdisk=$(ssh root@${node} "ps auwwx | grep fdisk | grep -v grep | grep '/dev/vdb' | wc -l")
        if [[ "${num_fdisk}" != "0" ]]; then
            err " - Error Detected ${node} has fdisk orphans: ${num_fdisk}"
            exit 1
        else
            good " - ${node} has ${num_fdisk} fdisk orphans"
        fi
    done
}

umount_devices
partition_devices
check_mounts
check_on_fdisk_orphaned_processes
