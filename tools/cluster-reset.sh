#!/bin/bash

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
fi

test_user=$(whoami)
if [[ "${test_user}" != "root" ]]; then
    err "please run as root"
    exit 1
fi

anmt "---------------------------------------------"
inf "running: kubeadm reset -f"

kubeadm reset -f

if [[ "${1}" == "fast" ]]; then
    anmt "running: ./tools/fast-prepare.sh"
    ./tools/fast-prepare.sh
elif [[ "${1}" == "clean" ]]; then
    anmt "running: ./prepare.sh clean"
    ./prepare.sh clean
else
    anmt "running: ./prepare.sh splunk ceph"
    ./prepare.sh splunk ceph
fi

inf "done - running: kubeadm reset and prepare"
anmt "---------------------------------------------"

exit 0
