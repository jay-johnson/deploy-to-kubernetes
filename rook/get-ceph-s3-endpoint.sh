#!/bin/bash

svc_name="rook-ceph-rgw-s3"
service_type="NodePort"
port=80
if [[ "${1}" == "clusterip" ]]; then
    service_type="ClusterIP"
    port=80
fi
ip_address=$(kubectl -n rook-ceph get svc --ignore-not-found | grep ${svc_name} | grep rgw | grep ${service_type} | awk '{print $3}')
echo "${ip_address}:${port}"
