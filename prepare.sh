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

user_test=$(whoami)
if [[ "${user_test}" != "root" ]]; then
    err "please run as root"
    exit 1
fi

inf ""
anmt "---------------------------------------------"
good "Preparing host for running kubernetes"

inf "updating host repositories"
apt-get update
inf ""

inf "installing apt-transport-https"
apt-get install -y apt-transport-https
inf ""

inf "installing google apt key"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
inf ""

inf "installing google kubernetes repository"
test_if_found=$(cat /etc/apt/sources.list.d/kubernetes.list | grep apt.kubernetes.io | wc -l)
if [[ "${test_if_found}" == "0" ]]; then
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
fi
apt-get update
inf ""

good "installing kubelet kubeadm kubernetes-cni from the google repository"
apt-get install -y \
    kubelet \
    kubeadm \
    kubernetes-cni
inf ""

inf "turning off swap - please ensure it is disable in /etc/fstab"
swapoff -a
# need to still disable swap in: /etc/fstab
inf ""

# for flannel to work must use the pod network cidr
inf ""
good "initializing kubernetes cluster"
kubeadm init --pod-network-cidr=10.244.0.0/16
inf ""

inf "assigning kubernetes admin config"
export KUBECONFIG=/etc/kubernetes/admin.conf
inf ""

inf "allowing master to host containers"
kubectl taint nodes --all node-role.kubernetes.io/master-
inf ""

good "installing kubernets CNI addon"
# weave
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
inf ""

if [[ -e ./tools/create-pvs.sh ]]; then
    good "creating persistent volumes"
    ./tools/create-pvs.sh
    inf ""
fi

if [[ -e ./helm/run.sh ]]; then
    good "installing helm"
    ./helm/run.sh
    inf ""
fi

inf "setting up CNI bridge in /etc/sysctl.conf"
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl -p /etc/sysctl.conf
inf ""

inf "enabling kubelet on restart"
systemctl enable kubelet
inf ""

anmt "---------------------------------------------"
anmt "Install the kuberenets config with the following commands or use the ./user-install-kubeconfig.sh:"
inf ""
good "mkdir -p $HOME/.kube"
good "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config"
good "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
inf ""

good "done preparing kubernetes"
inf ""
