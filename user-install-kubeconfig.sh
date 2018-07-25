#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
if [[ "${DISABLE_COLORS}" == "" ]] && [[ "${found_colors}" != "" ]] && [[ -e ${found_colors} ]]; then
    . ${found_colors}
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

mkdir -p $HOME/.kube
if [[ -e $HOME/.kube/config ]]; then
    rm -f $HOME/.kube/config >> /dev/null 2>&1
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
