#!/bin/bash

# usage:
#
# sudo su
#
# for dev:
# ./prepare splunk
#
# for prod:
# ./prepare prod splunk

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

should_cleanup_before_startup=1
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
pv_deployment_type="all-pvs"
multihost_labeler="./multihost/run.sh"
is_ubuntu=$(uname -a | grep -i ubuntu | wc -l)
install_on_centos="1"
start_services="1"

for i in "$@"
do
    contains_equal=$(echo ${i} | grep "=")
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "clean" ]]; then
        start_services="0"
    elif [[ "${i}" == "new-ceph" ]]; then
        storage_type="new-ceph"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "nfs" ]]; then
        storage_type="nfs"
    elif [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    elif [[ "${contains_equal}" != "" ]]; then
        first_arg=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $1}')
        second_arg=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $2}')
        if [[ "${first_arg}" == "labeler" ]]; then
            multihost_labeler=${second_arg}
        fi
    elif [[ "${i}" == "nolabeler" ]]; then
        multihost_labeler=""
    elif [[ "${i}" == "--no-install" ]]; then
        install_on_centos="0"
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "antinex" ]]; then
        cert_env="antinex"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    fi
done

inf ""
anmt "---------------------------------------------"

# automating install steps from:
# https://kubernetes.io/docs/setup/independent/install-kubeadm/

if [[ "${is_ubuntu}" == "1" ]]; then
    good "Preparing host for running kubernetes on Ubuntu"

    inf "updating host repositories"
    apt-get update

    inf "installing apt-transport-https"
    apt-get install -y apt-transport-https
    inf ""

    inf "installing google apt key"
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    inf ""

    inf "installing google kubernetes repository"
    test_if_found=$(cat /etc/apt/sources.list.d/kubernetes.list | grep kubernetes-xenial | wc -l)
    if [[ "${test_if_found}" == "0" ]]; then
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
        apt-get update
    fi
    inf ""

    good "installing kubelet kubeadm kubernetes-cni from the google repository"
    apt-get install -y \
        kubelet \
        kubeadm \
        kubernetes-cni
    inf ""

    inf "setting up CNI bridge in /etc/sysctl.conf"
    sysctl net.bridge.bridge-nf-call-iptables=1
    sysctl -p /etc/sysctl.conf
    inf ""

    inf "enabling kubelet on restart"
    systemctl enable kubelet
    inf ""
else
    good "Preparing host for running kubernetes on CentOS"

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
fi
inf ""

# need to still disable swap in: /etc/fstab
warn "turning off swap - please ensure it is disabled in all entries in /etc/fstab"
swapoff -a
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
# updated from GitHub Issue:
# https://github.com/kubernetes/kubernetes/issues/48798
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
# to
kubectl -n kube-system apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
inf ""

# generate new x509 SSL TLS keys, CA, certs and csr files using this command:
# cd ansible; ansible-playbook -i inventory_dev create-x509s.yml
#
# you can reload all certs any time with command:
# ./ansible/deploy-secrets.sh -r
anmt "loading included TLS secrets from: ./ansible/secrets/"
./ansible/deploy-secrets.sh -r

if [[ -e ./helm/run.sh ]]; then
    good "installing helm"
    ./helm/run.sh
    inf ""
fi

# Multi-host mode assumes at least 3 master nodes
# and the deployment uses nodeAffinity labels to
# deploy specific applications to the correct
# hosting cluster node
if [[ "${multihost_labeler}" != "" ]] && [[ -e ${multihost_labeler} ]]; then
    ${multihost_labeler} ${cert_env} ${storage_type} ${extra_params}
fi

if [[ "${start_services}" == "1" ]]; then
    if [[ -e ./pvs/create-pvs.sh ]]; then
        good "creating persistent volumes"
        ./pvs/create-pvs.sh ${cert_env} ${storage_type} ${pv_deployment_type}
        inf ""
    fi
fi

anmt "---------------------------------------------"
anmt "Install the kubernetes config with the following commands or use the ./user-install-kubeconfig.sh:"
inf ""
good "mkdir -p $HOME/.kube"
good "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config"
good "sudo chown \$(id -u):\$(id -g) $HOME/.kube/config"
inf ""

good "done preparing kubernetes"
inf ""
