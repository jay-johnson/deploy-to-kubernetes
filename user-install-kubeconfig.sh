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
anmt "installing kubernetes config for user on $(hostname) to $HOME/.kube/config"

mkdir -p $HOME/.kube
if [[ -e $HOME/.kube/config ]]; then
    rm -f $HOME/.kube/config >> /dev/null 2>&1
fi

if [[ -e /etc/kubernetes/admin.conf ]]; then
    sudo chmod 666 /etc/kubernetes/admin.conf
fi

good "installing admin kubernetes config credentials using sudo"
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

inf "listing tokens:"
kubeadm token list

inf "listing pods:"
kubectl get pods

inf "listing nodes:"
kubectl get nodes

good "done installing kubernetes config credentials: ${HOME}/.kube/config"

exit 0
