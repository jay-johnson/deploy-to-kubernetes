#!/bin/bash

# usage:
#
# sudo su
# ./tools/fast-prepare.sh

if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
fi

user_test=$(whoami)
if [[ "${user_test}" != "root" ]]; then
    err "please run as root"
    exit 1
fi

inf ""
anmt "---------------------------------------------"

# automating install steps from:
# https://kubernetes.io/docs/setup/independent/install-kubeadm/

good "preparing host=$(hostname) for running kubernetes on CentOS"

if [[ ! -e /etc/yum.repos.d/kubernetes.repo ]]; then
    inf "installing kubernetes repo"
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
fi

setenforce 0
inf "installing kubernetes"
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
inf "installing kubernetes"
systemctl enable kubelet && systemctl start kubelet

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

inf ""

# need to still disable swap in: /etc/fstab
warn "turning off swap - please ensure it is disabled in all entries in /etc/fstab"
swapoff -a
inf ""

# for flannel to work must use the pod network cidr
inf ""
good "initializing kubernetes cluster on host=$(hostname)"
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
# updated from GitHub Issue:
# https://github.com/kubernetes/kubernetes/issues/48798
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
# to
kubectl -n kube-system apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
inf ""

anmt "---------------------------------------------"
anmt "Install the kubernetes config with the following commands or use the ./user-install-kubeconfig.sh:"
inf ""
good "mkdir -p $HOME/.kube"
good "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config"
good "sudo chown \$(id -u):\$(id -g) $HOME/.kube/config"
inf ""
inf ""

good "done preparing kubernetes on host=$(hostname)"

exit 0
