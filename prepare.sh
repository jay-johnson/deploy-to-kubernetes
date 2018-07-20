#!/bin/bash

user_test=$(whoami)
if [[ "${user_test}" != "root" ]]; then
    echo "please run as root"
    exit 1
fi

apt-get update
apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list 
apt-get update

apt-get install -y \
  kubelet \
  kubeadm \
  kubernetes-cni

swapoff -a
# need to still disable swap in: /etc/fstab

# for flannel to work must use the pod network cidr
echo ""
echo "initializing kubernetes cluster"
kubeadm init --pod-network-cidr=10.244.0.0/16

echo "assigning kubernetes admin config"
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "allowing master to host containers"
kubectl taint nodes --all node-role.kubernetes.io/master-

# weave
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

if [[ -e ./tools/create-pvs.sh ]]; then
    echo "creating persistent volumes"
    ./tools/create-pvs.sh
fi

if [[ -e ./helm/install-helm.sh ]]; then
    echo "installing helm"
    ./helm/install-helm.sh
fi

echo "setting up CNI bridge in /etc/sysctl.conf"
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl -p /etc/sysctl.conf

echo "enabling kubelet on restart"
systemctl enable kubelet
