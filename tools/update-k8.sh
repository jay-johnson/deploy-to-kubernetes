#!/bin/bash

echo ""
echo "installing kubernetes updates on $(hostname) with command:"
echo "yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes"
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
