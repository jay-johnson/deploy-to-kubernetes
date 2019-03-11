#!/bin/bash

start_clean="0"
start_registry="1"

# Start the Stock Analysis Engine on reboot
# https://github.com/AlgoTraders/stock-analysis-engine
start_ae="1"
# AE with ceph - work in progress
start_ae_ceph="0"
start_docker_compose_in_repo="/opt/sa"

# Start antinex on the cluster with: start_antinex="1"
# 0 = do not deploy and leave the cluster empty
# on startup
# https://github.com/jay-johnson/deploy-to-kubernetes
start_antinex="1"

# assumes ssh root access
ssh_user="root"
# to each of these fqdns:
nodes="master1.example.com master2.example.com master3.example.com"
vms="bastion m1 m2 m3"

export PATH=${PATH}:/usr/bin:/snap/bin
export KUBECONFIG=/opt/k8/config

if [[ -e /opt/sa/analysis_engine/scripts/common_bash.sh ]]; then
    source /opt/sa/analysis_engine/scripts/common_bash.sh
elif [[ -e ${start_docker_compose_in_repo}/analysis_engine/scripts/common_bash.sh ]]; then
    source ${start_docker_compose_in_repo}/analysis_engine/scripts/common_bash.sh
elif [[ -e ./analysis_engine/scripts/common_bash.sh ]]; then
    source ./analysis_engine/scripts/common_bash.sh
fi

cur_date=$(date)
anmt "---------------------------------------------------------"
anmt "${cur_date} - starting vms and kubernetes cluster"

virsh list >> /dev/null 2>&1
virsh_ready=$?
while [[ "${virsh_ready}" != "0" ]]; do
    anmt "${cur_date} - sleeping before starting vms"
    sleep 10
    virsh list >> /dev/null 2>&1
    virsh_ready=$?
    cur_date=$(date)
done

anmt "starting vms: ${vms}"
for vm in $vms; do
    running_test=$(virsh list | grep ${vm} | wc -l)
    if [[ -e /data/kvm/disks/${vm}.xml ]]; then
        if [[ "${running_test}" == "0" ]]; then
            anmt "importing ${vm}"
            virsh define /data/kvm/disks/${vm}.xml 2>&1
        fi
    fi
    running_test=$(virsh list | grep ${vm} | grep running | wc -l)
    if [[ "${running_test}" == "0" ]]; then
        anmt "setting autostart for vm with: virsh autostart ${vm}"
        virsh autostart ${vm}
        anmt "starting vm: virsh start ${vm}"
        virsh start ${vm}
    else
        good " - ${vm} already runnning"
    fi
done

if [[ "${start_clean}" == "1" ]]; then
    start_antinex="0"
    start_ae="0"
    start_registry=1
fi

anmt "-----------------------------"
date
anmt "Starting flags:"
anmt "clean=${start_clean}"
anmt "antinex=${start_antinex}"
anmt "ae=${start_ae}"
anmt "-----------------------------"

if [[ "${start_registry}" == "1" ]]; then
    anmt "starting docker containers"
    inf "cd ${start_docker_compose_in_repo}"
    cd ${start_docker_compose_in_repo}
    inf " - checking docker"
    systemctl status docker
    inf " - starting registry"
    ./compose/start.sh -r

    cur_date=$(date)
    not_done=$(docker inspect registry | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
    while [[ "${not_done}" == "0" ]]; do
        inf "${cur_date} - sleeping to let the docker registry start"
        sleep 10
        not_done=$(docker inspect registry | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
        cur_date=$(date)
    done

    cur_date=$(date)
    anmt "${cur_date} - docker registry in running state:"
    docker ps | grep registry
fi

anmt "deploying kubernetes cluster"
date
cd /opt/deploy-to-kubernetes/

anmt "check login to vms: ${nodes}"
no_sleep_yet="0"
for fqdn in ${nodes}; do
    test_ssh=$(ssh ${ssh_user}@${fqdn} "date" 2>&1)
    not_done=$(echo "${test_ssh}" | grep 'ssh: ' | wc -l)
    cur_date=$(date)
    while [[ "${not_done}" != "0" ]]; do
        inf "${cur_date} - sleeping to let ${fqdn} start"
        sleep 10
        no_sleep_yet="1"
        test_ssh=$(ssh ${ssh_user}@${fqdn} "date" 2>&1)
        not_done=$(echo "${test_ssh}" | grep 'ssh: ' | wc -l)
        cur_date=$(date)
    done
done

# there's probably a cleaner way to detect the vm's can start running k8...
if [[ "${no_sleep_yet}" == "0" ]]; then
    cur_date=$(date)
    inf "${cur_date} - sleeping to let vms start 2 min left"
    sleep 60
    cur_date=$(date)
    inf "${cur_date} - sleeping to let vms start 1 min left"
    sleep 60
    cur_date=$(date)
    good "${cur_date} - done sleeping"
fi

if [[ "${start_antinex}" == "1" ]]; then
    anmt "----------------------------------------"
    anmt "deploying antinex:"
    ./multihost/_reset-cluster-using-ssh.sh
    anmt "----------------------------------------"
else
    anmt "----------------------------------------"
    anmt "deploying empty cluster with: "
    anmt "./multihost/_clean_reset_install.sh labels=new-ceph"
    ./multihost/_clean_reset_install.sh labels=new-ceph
    anmt "----------------------------------------"
fi
anmt "done starting cluster"
date

anmt "syncing kube config: ${KUBECONFIG}"
scp -i /opt/k8/id_rsa root@master1.example.com:/etc/kubernetes/admin.conf ${KUBECONFIG}

if [[ ! -e ${KUBECONFIG} ]]; then
    err "failed to sync kube config from master1.example.com - stopping"
    exit 1
fi

anmt "getting nodes"
kubectl get nodes -o wide
date

anmt "getting pods"
kubectl get pods

if [[ "${start_ae}" == "1" ]]; then
    anmt "----------------------------------------"
    anmt "deploying ae to cluster"

    inf "creating ae namespace"
    kubectl create namespace ae

    cd ${start_docker_compose_in_repo}

    anmt "applying secrets"
    kubectl apply -f ./k8/secrets/secrets.yml

    if [[ -e ./k8/secrets/default-secrets.yml ]]; then
        anmt "installing AE secrets namespace: default"
        kubectl apply -f ./k8/secrets/default-secrets.yml
    fi

    if [[ "${start_ae_ceph}" == "1" ]]; then
        if [[ -e ./k8/secrets/ae-secrets.yml ]]; then
            anmt "installing AE secrets namespace: ae"
            kubectl apply -f ./k8/secrets/ae-secrets.yml
        fi
        anmt "starting AE with helm and ceph"
        ./helm/handle-reboot.sh ./helm/ae/values.yaml /opt/k8/config -c ${start_docker_compose_in_repo}
    fi

    inf " - starting docker redis and minio"
    ./compose/start.sh -a
    inf " - starting docker ae stack"
    ./compose/start.sh -s
    docker ps

    cur_date=$(date)
    not_done=$(docker inspect redis | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
    while [[ "${not_done}" == "0" ]]; do
        inf "${cur_date} - sleeping to let the docker redis start"
        sleep 10
        not_done=$(docker inspect redis | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
        cur_date=$(date)
    done

    cur_date=$(date)
    not_done=$(docker inspect ae-workers | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
    while [[ "${not_done}" == "0" ]]; do
        inf "${cur_date} - sleeping to let the docker ae-workers start"
        sleep 10
        not_done=$(docker inspect ae-workers | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
        cur_date=$(date)
    done

    if [[ -e ./k8/deploy-latest.sh ]]; then
        anmt "deploying latest datasets from s3 to k8 and local docker redis"
        ./k8/deploy-latest.sh
    fi
else
    inf "not deploying AE"
fi

anmt "done"
anmt "---------------------------------------------------------"
