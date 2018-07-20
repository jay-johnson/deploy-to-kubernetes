#!/bin/bash

mkdir -p $HOME/.kube
if [[ -e $HOME/.kube/config ]]; then
    rm -f $HOME/.kube/config
fi
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config && sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "listing tokens"
kubeadm token list
echo "listing pods"
kubectl get pods
echo "listing nodes"
kubectl get nodes
