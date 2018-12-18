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

should_cleanup_before_startup=0
cert_env="dev"
storage_type="ceph"
for i in "$@"
do
    if [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "nfs" ]]; then
        storage_type="nfs"
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    fi
done

anmt "-------------------------------------------------------------"
anmt "deploying redis with persistent volumes using ${storage_type}: https://github.com/helm/charts/tree/master/stable/redis"
inf ""

is_running=$(helm ls redis | grep redis | wc -l)
if [[ "${is_running}" != "0" ]]; then
    good "redis is already running: helm ls redis | grep redis | wc -l"
    exit 0
fi

if [[ "${storage_type}" != "ceph" ]]; then
    inf "deploying persistent volume with ${storage_type} for redis"
    kubectl apply -f ./redis/pv-${storage_type}.yml
    inf ""
else
    inf "deploying persistent volume claim for ${storage_type} to host a redis cluster"
    kubectl apply -f ./redis/pvc-${storage_type}.yml
    inf ""
fi

if [[ "${storage_type}" != "ceph" ]]; then
    good "deploying Bitnami redis stable with helm"
    helm install \
        --name redis stable/redis \
        --set rbac.create=true \
        --values ./redis/redis.yml
else
    good "deploying Bitnami redis stable with helm and persistent volumes using rook with ceph"
    helm install \
        stable/redis \
        --name redis \
        --set rbac.create=true \
        --set persistence.existingClaim=redis-ceph-data \
        --set persistence.storageClass=rook-ceph-block \
        --set persistence.size=30Gi \
        --values ./redis/redis.yml
fi

last_exit=$?
if [[ "${last_exit}" != "0" ]]; then
    inf ""
    err "failed to deploy redis:"
    inf ""
    kubectl describe pod redis-master-0
    inf ""
    exit ${last_exit}
else
    inf ""
    inf "getting pods:"
    kubectl get pods
fi

good "done deploying: redis"

exit 0
