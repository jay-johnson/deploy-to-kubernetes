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

object_store="minio"

warn "------------------------------------------"
warn "deleting rook ceph"
inf ""

inf "deleting pool and replicapool: kubectl delete -n rook-ceph pool replicapool"
kubectl delete -n rook-ceph pool replicapool
inf ""

inf "deleting storage class: kubectl delete storageclass rook-ceph-block"
kubectl delete storageclass rook-ceph-block
inf ""

ceph_mon_pod_name=$(kubectl -n rook-ceph get pod | grep rook-ceph-mon | awk '{print $1}')
inf "deleting ceph mon pod: kubectl -n rook-ceph get pod | grep rook-ceph-mon | awk '{print \$1}'"
kubectl delete -n rook-ceph pod ${ceph_mon_pod_name}
inf ""

inf "deleting service: kubectl delete objectstore -n rook-ceph rook-ceph-rgw-s3"
kubectl delete service -n rook-ceph rook-ceph-rgw-s3
inf ""

inf "deleting service: kubectl delete objectstore -n rook-ceph rook-ceph-rgw-s3-storage"
kubectl delete service -n rook-ceph rook-ceph-rgw-s3-storage
inf ""

inf "deleting operator: kubectl delete -f ./rook/ceph/operator.yml"
kubectl delete -f ./rook/ceph/operator.yml
inf ""

inf "deleting operator: kubectl delete -f ./rook/ceph/cluster.yml"
kubectl delete -f ./rook/ceph/cluster.yml
inf ""

inf "deleting secrets: kubectl -n rook-ceph delete pod rook-ceph-tools"
kubectl delete pod -n rook-ceph rook-ceph-tools
inf ""

if [[ "${object_store}" == "cephs3" ]]; then
    inf "deleting storageclass: kubectl delete storageclass rook-ceph-block"
    kubectl delete storageclass rook-ceph-block
    inf ""

    inf "deleting s3-storage object store: kubectl delete objectstore -n rook-ceph s3-storage"
    kubectl delete objectstore -n rook-ceph s3-storage
    inf ""

    if [[ -e ./rook/ceph/tls-s3.yml ]]; then
        inf "deleting tls-s3 secret"
        kubectl delete -f ./rook/ceph/tls-s3.yml
        rm -f ./rook/ceph/tls-s3.yml >> /dev/null 2>&1
        inf ""
    fi
elif [[ "${object_store}" == "minio" ]]; then
    inf "deleting minio ingress"
    kubectl delete ing -n rook-minio minio-ingress
    inf ""
    inf "deleting minio service"
    kubectl delete svc -n rook-minio s3-storage
    inf ""
    inf "deleting minio operator"
    kubectl delete -f ./rook/minio/operator.yml
    inf ""
    inf "deleting minio objectstore"
    kubectl delete -n rook-minio objectstore
    inf ""
    inf "deleting minio secret"
    kubectl delete secret rook.s3.user
    inf ""
fi

if [[ -e /var/lib/rook ]]; then
    inf "using sudo to: rm -rf /var/lib/rook for uninstall per https://github.com/rook/rook/blob/master/Documentation/common-issues.md#failing-mon-pod"
    sudo rm -rf /var/lib/rook
    inf""
fi

good "done deleting: rook and ceph"
