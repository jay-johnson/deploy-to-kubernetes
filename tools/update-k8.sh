#!/bin/bash

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
fi

anmt "-------------------------"
anmt "installing kubernetes updates on $(hostname) with command:"
inf "yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes"
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

anmt "done - installing kubernetes updates on $(hostname) with command:"
anmt "-------------------------"
