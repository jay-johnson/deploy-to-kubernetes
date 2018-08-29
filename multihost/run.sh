#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
up_found_colors="../tools/bash_colors.sh"
if [[ "${DISABLE_COLORS}" == "" ]] && [[ "${found_colors}" != "" ]] && [[ -e ${found_colors} ]]; then
    . ${found_colors}
elif [[ "${DISABLE_COLORS}" == "" ]] && [[ "${up_found_colors}" != "" ]] && [[ -e ${up_found_colors} ]]; then
    . ${up_found_colors}
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

should_cleanup_before_startup=0
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
object_store=""
namespace="default"
labels_for_m1="frontend=enabled backend=disabled datascience=disabled ceph=enabled minio=enabled splunk=disabled"
labels_for_m2="frontend=enabled backend=enabled datascience=enabled ceph=enabled minio=disabled splunk=disabled"
labels_for_m3="frontend=disabled backend=enabled datascience=disabled ceph=enabled minio=disabled splunk=enabled"
all_labels_for_single_host="frontend=enabled backend=enabled datascience=enabled ceph=enabled minio=enabled splunk=enabled"
debug="0"
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "cephs3" ]]; then
        storage_type="ceph"
        object_store="ceph"
    elif [[ "${i}" == "-d" ]]; then
        debug="1"
    elif [[ "${i}" == "clean_on_start" ]]; then
        should_cleanup_before_startup="1"
    elif [[ "${i}" == "antinex" ]]; then
        cert_env="an"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    fi
done

anmt "-------------------------"
anmt "applying multihost labels"

inf ""
inf "detecting if deploying to a Kubernetes cluster deployed over multiple hosts:"
num_nodes=$(kubectl get nodes -o wide | grep Ready | wc -l)
if [[ "${num_nodes}" != "1" ]]; then
    anmt "finding updated multihost labels: kubectl get nodes --show-labels -o wide"
    kubectl get nodes --show-labels -o wide
    inf ""

    inf "getting lables for all cluster nodes"
    test_exists_m1=$(kubectl get nodes --show-labels -o wide | grep master1)
    test_exists_m2=$(kubectl get nodes --show-labels -o wide | grep master2)
    test_exists_m3=$(kubectl get nodes --show-labels -o wide | grep master3)
    inf ""

    for i in $labels_for_m1; do
        label_name=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $1}')
        label_value=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $2}')
        test_exists=$(echo ${test_exists_m1} | grep '${i}' | wc -l)
        inf "Setting master1 label: ${i} with: kubectl label nodes master1 $i --overwrite"
        kubectl label nodes master1 ${i} --overwrite
    done
    inf ""

    for i in $labels_for_m2; do
        label_name=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $1}')
        label_value=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $2}')
        test_exists=$(echo ${test_exists_m2} | grep '${i}' | wc -l)
        inf "Setting master2 label: ${i} with: kubectl label nodes master2 $i --overwrite"
        kubectl label nodes master2 ${i} --overwrite
    done
    inf ""

    for i in $labels_for_m3; do
        label_name=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $1}')
        label_value=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $2}')
        test_exists=$(echo ${test_exists_m3} | grep '${i}' | wc -l)
        inf "Setting master3 label: ${i} with: kubectl label nodes master3 $i --overwrite"
        kubectl label nodes master3 ${i} --overwrite
    done
    inf ""
else
    nodename=$(kubectl get nodes | awk '{print $1}' | tail -1)
    inf " - detected only ${num_nodes} ready node in the Kubernetes cluster named: ${nodename} - setting labels"
    test_exists_m1=$(kubectl get nodes --show-labels -o wide | grep ${nodename})
    for i in $all_labels_for_single_host; do
        label_name=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $1}')
        label_value=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $2}')
        test_exists=$(echo ${test_exists_m1} | grep ${i} | wc -l)
        inf "Setting ${nodename} label: ${i} with: kubectl label nodes ${nodename} $i --overwrite"
        kubectl label nodes ${nodename} ${i} --overwrite
    done
fi

good "done applying: multihost labels"
