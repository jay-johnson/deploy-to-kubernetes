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

use_namespace="ceph"
pg_num=100

anmt "--------------------------------------------------"
anmt "Creating Keyring for Ceph cluster storageClass ceph-rbd:"
inf ""
pod_name=$(kubectl get pods --ignore-not-found -n ${use_namespace} | grep -v keyring- | grep "ceph-mon-" | awk '{print $1}' | tail -1)
if [[ "${pod_name}" == "" ]]; then
    err "Did not find a ceph-mon pod running - please check ceph:"
    err "kubectl get pods -n ${use_namespace}"
    exit 1
else
    good "kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- bash"
    key_secret_raw=$(kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- ceph auth get-or-create-key client.k8s mon 'allow r' osd 'allow rwx pool=rbd')
    key_secret_raw=$(kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- ceph auth get-key client.k8s | base64)
    good "created pvc-ceph-client-key with value: ${key_secret_raw}"
    use_path="."
    secret_file=./pvc-ceph-client-key-secret.yml
    if [[ -e ./ceph/template-pvc-ceph-client-key-secret.yml ]]; then
        use_path="./ceph"
    fi
    secret_file=${use_path}/pvc-ceph-client-key-secret.yml
    cp ${use_path}/template-pvc-ceph-client-key-secret.yml ${secret_file}
    sed -i "s/REPLACE_WITH_KEYRING_KEY/${key_secret_raw}/g" ${secret_file}
    if [[ -e /opt/k8/config ]]; then
        export KUBE_CONFIG=/opt/k8/config
    fi

    inf "deleting secret if exists: ${secret_file}"
    kubectl delete --ignore-not-found -f ${secret_file}

    inf "applying secret: ${secret_file}"
    kubectl apply -f ${secret_file}

    inf "getting secret: ${secret_file}"
    kubectl get secret -n ceph pvc-ceph-client-key

    anmt "creating new secret"
    kubectl -n ceph get secrets/pvc-ceph-client-key -o json | jq '.metadata.namespace = "default"' | kubectl create -f -

    anmt "creating osd pool"
    kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- ceph osd pool create rbd ${pg_num}

    anmt "initializing osd"
    kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- rbd pool init rbd

    good "pvc-ceph-client-key installed with value: ${key_secret_raw}"
fi
