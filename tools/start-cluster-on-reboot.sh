#!/bin/bash

start_clean="1"
start_registry="1"

# Start the Stock Analysis Engine on reboot
# https://github.com/AlgoTraders/stock-analysis-engine
start_ae="0"
start_docker_compose_in_repo="/opt/sa"

# Start antinex on the cluster with: start_antinex="1"
# 0 = do not deploy and leave the cluster empty
# on startup
# https://github.com/jay-johnson/deploy-to-kubernetes
start_antinex="0"

# assumes ssh root access
ssh_user="root"
# to each of these fqdns:
nodes="master1.example.com master2.example.com master3.example.com"

export PATH=${PATH}:/usr/bin:/snap/bin
export KUBECONFIG=/opt/k8/config

log=/tmp/boot.log
virsh list >> /dev/null 2>&1
virsh_ready=$?
cur_date=$(date)
while [[ "${virsh_ready}" != "0" ]]; do
    echo "${cur_date} - sleeping before starting vms" >> ${log}
    sleep 10
    virsh list >> /dev/null 2>&1
    virsh_ready=$?
    cur_date=$(date)
done

echo "starting vms"

vms="bastion m1 m2 m3"
for vm in $vms; do
    running_test=$(virsh list | grep ${vm} | wc -l)
    if [[ -e /data/kvm/disks/${vm}.xml ]]; then
        if [[ "${running_test}" == "0" ]]; then
            echo "importing ${vm}" >> ${log}
            virsh define /data/kvm/disks/${vm}.xml 2>&1
        fi
    fi
    running_test=$(virsh list | grep ${vm} | grep running | wc -l)
    if [[ "${running_test}" == "0" ]]; then
        echo "setting autostart for vm with: virsh autostart ${vm}" >> ${log}
        virsh autostart ${vm} >> ${log} 2>&1
        echo "starting vm: virsh start ${vm}" >> ${log}
        virsh start ${vm} >> ${log} 2>&1
    else
        echo " - ${vm} already runnning" >> ${log}
    fi
done

if [[ "${start_clean}" == "1" ]]; then
    start_antinex="0"
    start_ae="0"
    start_registry=1
fi

echo "-----------------------------" >> ${log}
date >> ${log}
echo "Starting flags:" >> ${log}
echo "clean=${start_clean}" >> ${log}
echo "antinex=${start_antinex}" >> ${log}
echo "ae=${start_ae}" >> ${log}
echo "-----------------------------" >> ${log}
cat ${log}

if [[ "${start_registry}" == "1" ]]; then
    echo "starting docker containers" >> ${log}
    echo "cd ${start_docker_compose_in_repo}" >> ${log}
    cd ${start_docker_compose_in_repo}
    echo " - checking docker" >> ${log}
    systemctl status docker >> ${log} 2>&1
    echo " - starting registry" >> ${log}
    ./compose/start.sh -r >> ${log} 2>&1

    cur_date=$(date)
    not_done=$(docker inspect registry | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
    while [[ "${not_done}" == "0" ]]; do
        echo "${cur_date} - sleeping to let the docker registry start" >> ${log}
        sleep 10
        not_done=$(docker inspect registry | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
        cur_date=$(date)
    done

    cur_date=$(date)
    echo "${cur_date} - docker registry in running state:"
    docker ps | grep registry
fi

echo "deploying kubernetes cluster" >> ${log}
date >> ${log}
cd /opt/deploy-to-kubernetes/ >> ${log}

echo "check login to vms: ${nodes}" >> ${log}
no_sleep_yet="0"
for fqdn in ${nodes}; do
    ssh ${ssh_user}@${fqdn} "date"
    cur_date=$(date)
    not_done=$?
    if [[ "${not_done}" != "0" ]]; then
        echo "${cur_date} - sleeping to let ${fqdn} start" >> ${log}
        sleep 10
        no_sleep_yet="1"
        ssh ${ssh_user}@${fqdn} "date"
        not_done=$?
        cur_date=$(date)
    fi
done

# there's probably a cleaner way to detect the vm's can start running k8...
if [[ "${no_sleep_yet}" == "0" ]]; then
    cur_date=$(date)
    echo "${cur_date} - sleeping to let vms start" >> ${log}
    sleep 30
    cur_date=$(date)
    echo "${cur_date} - sleeping to let vms start" >> ${log}
    sleep 30
    cur_date=$(date)
    echo "${cur_date} - sleeping to let vms start" >> ${log}
    sleep 30
fi

if [[ "${start_antinex}" == "1" ]]; then
    ./multihost/_reset-cluster-using-ssh.sh >> ${log}
else
    echo "----------------------------------------" >> ${log}
    echo "deploying empty cluster with: " >> ${log}
    echo "./multihost/_clean_reset_install.sh labels=new-ceph" >> ${log}
    ./multihost/_clean_reset_install.sh labels=new-ceph >> ${log}
    echo "----------------------------------------" >> ${log}
fi
echo "done starting cluster" >> ${log}
date >> ${log}

echo "syncing kube config: ${KUBECONFIG}" >> ${log}
scp -i /opt/k8/id_rsa root@master1.example.com:/etc/kubernetes/admin.conf ${KUBECONFIG} >> ${log}

if [[ ! -e ${KUBECONFIG} ]]; then
    echo "failed to sync kube config from master1.example.com - stopping" >> ${log}
    exit 1
fi

echo "getting nodes" >> ${log}
/usr/bin/kubectl get nodes -o wide >> ${log}
date >> ${log}

echo "getting pods" >> ${log}
/usr/bin/kubectl get pods >> ${log}

if [[ "${}" == "1" ]]; then
else
    echo "not deploying antinex" >> ${log}
fi

if [[ "${start_ae}" == "1" ]]; then
    echo "creating ae namespace" >> ${log}
    /usr/bin/kubectl create namespace ae >> ${log}

    cd ${start_docker_compose_in_repo}
    ./helm/handle-reboot.sh ./helm/ae/values.yaml /opt/k8/config -c ${start_docker_compose_in_repo} >> ${log} 2>&1

    echo "installing AE secrets" >> ${log}
    /usr/bin/kubectl apply -f ./k8/secrets/secrets.yml >> ${log}

    echo " - starting redis and minio" >> ${log}
    ./compose/start.sh -a >> ${log} 2>&1
    echo " - starting ae stack" >> ${log}
    ./compose/start.sh -s >> ${log} 2>&1
    docker ps >> ${log} 2>&1

    cur_date=$(date)
    not_done=$(docker inspect redis | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
    while [[ "${not_done}" == "0" ]]; do
        echo "${cur_date} - sleeping to let the docker redis start" >> ${log}
        sleep 10
        not_done=$(docker inspect redis | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
        cur_date=$(date)
    done

    cur_date=$(date)
    not_done=$(docker inspect ae-workers | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
    while [[ "${not_done}" == "0" ]]; do
        echo "${cur_date} - sleeping to let the docker ae-workers start" >> ${log}
        sleep 10
        not_done=$(docker inspect ae-workers | grep -i status | sed -e 's/"/ /g' | awk '{print $3}' | grep -i running | wc -l)
        cur_date=$(date)
    done

    if [[ -e ./k8/deploy_build_from_latest.sh ]]; then
        echo "deploying latest datasets from s3 to k8 and local docker redis" >> ${log}
        ./k8/deploy_build_from_latest.sh >> ${log} 2>&1
    fi
else
    echo "not deploying AE" >> ${log}
fi

echo "done" >> ${log}
