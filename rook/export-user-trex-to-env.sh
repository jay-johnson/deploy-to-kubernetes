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

use_namespace="rook-ceph"
app_name=""
username="trex"
display_name="trex"

if [[ "${1}" != "" ]] && [[ "${1}" != "-s" ]]; then
    username="${1}"
    display_name="${1}"
fi

use_path="./rook"
if [[ -e ./ceph/s3-objectstore-dev.yml ]]; then
    use_path="./"
fi

# inf ""
# anmt "----------------------------------------------"
# good "Creating Rook User: ${username}"

# http://docs.ceph.com/docs/giant/radosgw/admin/
# echo "kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c \"radosgw-admin user info --uid=${username}\""
user_id=$(kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c "radosgw-admin user info --uid=${username} | grep ${username} | sed -e 's|\n||g'" | sed -e "s|\n||g")
access_key=$(kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c "radosgw-admin user info --uid=${username} | grep access_key | sed -e 's|\"| |g' | sed -e 's|,||g' | awk '{print \$NF}' | sed -e 's|\n||g'" | sed -e "s|\n||g")
secret_key=$(kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c "radosgw-admin user info --uid=${username} | grep secret_key | sed -e 's|\"| |g' | sed -e 's|,||g' | awk '{print \$NF}' | sed -e 's|\n||g'" | sed -e "s|\n||g")

# Host: The DNS host name where the rgw service is found in the cluster. Assuming you are using the default rook-ceph cluster, it will be rook-ceph-rgw-my-store.rook-ceph.
# kubectl get svc -n rook-ceph
export AWS_HOST=$(${use_path}/get-ceph-s3-endpoint.sh | sed -e "s|\n||g")
# Endpoint: The endpoint where the rgw service is listening. Run kubectl -n rook-ceph get svc rook-ceph-rgw-my-wtore, then combine the clusterIP and the port.
export AWS_ENDPOINT=$(${use_path}/get-ceph-s3-endpoint.sh | sed -e "s|\n||g")
# Access key: The user's access_key as printed above
export AWS_ACCESS_KEY_ID=$(echo "${access_key}" | sed -e "s|\n||g")
# Secret key: The user's secret_key as printed above
export AWS_SECRET_ACCESS_KEY=$(echo "${secret_key}" | sed -e "s|\n||g")

export INSIDE_CLUSTER_AWS_HOST="rook-ceph-rgw-s3-storage.rook-ceph"
export INSIDE_CLUSTER_AWS_ENDPOINT="rook-ceph-rgw-s3-storage.rook-ceph"

if [[ "${1}" != "-s" ]]; then
    echo "export AWS_HOST=${AWS_HOST}"
    echo "export AWS_ENDPOINT=${AWS_ENDPOINT}"
    echo "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
    echo "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
    echo "export INSIDE_CLUSTER_AWS_HOST=${INSIDE_CLUSTER_AWS_HOST}"
    echo "export INSIDE_CLUSTER_AWS_ENDPOINT=${INSIDE_CLUSTER_AWS_ENDPOINT}"
    # inf ""
    # good "create a bucket: "
    # inf "kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c \"s3cmd mb --no-ssl --host=${INSIDE_CLUSTER_AWS_HOST} --host-bucket=  s3://rookbucket\""
    # inf ""
fi

exit 0
