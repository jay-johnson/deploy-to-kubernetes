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

warn "------------------------------------------"
warn "deleting ceph"
inf ""

verbose=0
namespace="ceph"
format_images="0"

if [[ "${1}" == "-f" ]]; then
    format_images="1"
fi

test_helm=$(helm list | grep ceph | wc -l)
if [[ "${test_helm}" != "0" ]]; then
    good "deleting from helm:" 
    inf "helm delete --purge ceph"
    helm delete --purge ceph
    inf ""
fi

test_hem_repo=$(helm repo list | grep ceph | wc -l)
if [[ "${test_hem_repo}" != "0" ]]; then
    good "removing ceph from helm"
    inf "helm repo remove ceph"
    helm repo remove ceph
    inf ""
fi

resources_to_delete="job daemonset deployment pod configmap secret"
for res in ${resources_to_delete}; do
    if [[ "${verbose}" == "1" ]]; then
        inf ""
        inf "finding ${res} in ${namespace} to delete:"
        inf "kubectl get ${res} --ignore-not-found -n ${namespace} | awk '{print \$1}'"
    fi
    del_items=$(kubectl get ${res} --ignore-not-found -n ${namespace} | awk '{print $1}')
    for d in ${del_items}; do
        if [[ "${verbose}" == "1" ]]; then
            inf " - kubectl delete ${res} --ignore-not-found -n ${namespace} ${d}"
        fi
        # kubectl delete ${res} --ignore-not-found -n ${namespace} ${d}
    done
done

found_ns=$(kubectl get namespace --ignore-not-found ceph | grep -v rook | wc -l)
if [[ "${found_ns}" != "0" ]]; then
    kubectl delete namespace --ignore-not-found ceph
fi

kubectl delete storageclass --ignore-not-found ceph-rbd
kubectl delete secret --ignore-not-found pvc-ceph-client-key

use_path="."
if [[ -e ./ceph/test-mounts.yml ]]; then
    use_path="./ceph"
fi
test_mount_path="${use_path}/test-mounts.yml"
test_pvc_path="${use_path}/test-pvc.yml"
if [[ -e ${test_mount_path} ]]; then
    kubectl delete --ignore-not-found -f ${test_mount_path}
fi
if [[ -e ${test_pvc_path} ]]; then
    kubectl delete --ignore-not-found -f ${test_pvc_path}
fi

inf "deleting any orphaned ceph pv's"
kubectl delete --ignore-not-found pv $(kubectl get pv | grep ceph-rbd | grep -v rook | awk '{print $1}')

if [[ "${format_images}" == "1" ]]; then
    ${use_path}/_kvm-format-images.sh
    last_status=$?
    if [[ "${last_status}" != "0" ]]; then
        err "Stopping due to error during ${use_path}/_kvm-format-images.sh"
        exit 1
    fi
fi

anmt "--------------------------------"
anmt "Cleaning ceph volumes on cluster vms"
hosts_to_clean="master1.example.com master2.example.com master3.example.com"
for h in ${hosts_to_clean}; do
    good " - ${h} uninstalling ceph volumes"
    ssh root@${h} "rm -rf /var/lib/ceph-helm" >> /dev/null 2>&1
    ssh root@${h} "rm -rf /var/lib/ceph/*" >> /dev/null 2>&1
    ssh root@${h} "rm -rf /etc/ceph" >> /dev/null 2>&1
    ssh root@${h} "ls -l /var/lib/ceph/*" >> /dev/null 2>&1
done
inf ""

rm -f ceph-helm/ceph/ceph-*.tgz >> /dev/null 2>&1
rm -f ceph-helm/ceph/helm-toolkit-*.tgz >> /dev/null 2>&1

good "done deleting: ceph"
