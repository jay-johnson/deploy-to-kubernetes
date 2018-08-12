#!/bin/bash

svc_name="rook-ceph-rgw-s3-secure"
ip_address=$(kubectl -n rook-ceph get svc ${svc_name} | grep rgw | awk '{print $3}')
port=443

echo "${ip_address}:${port}"

export AWS_HOST="${svc_name}.rook-ceph"
export AWS_ENDPOINT="${ip_address}:${port}"
export AWS_ACCESS_KEY_ID=<accessKey>
export AWS_SECRET_ACCESS_KEY=<secretKey>

