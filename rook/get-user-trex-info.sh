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
secure_realm="ceph-storage"
secure_zonegroup="ceph-storage"
insecure_realm="ceph-storage"
insecure_zonegroup="ceph-storage"

if [[ "${1}" != "" ]]; then
    username="${1}"
    display_name="${1}"
fi

inf ""
anmt "----------------------------------------------"
good "Creating Rook User: ${username}"

# http://docs.ceph.com/docs/giant/radosgw/admin/
echo "kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c \"radosgw-admin user info --uid=${username}\""
kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c "radosgw-admin user info --uid=${username}"
