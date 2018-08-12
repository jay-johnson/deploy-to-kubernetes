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

use_namespace="rook-ceph"
app_name=""

inf ""
anmt "-----------------------------------------"
good "Getting the Rook Ceph System Pods:"
inf "kubectl get secret -n rook-ceph --ignore-not-found | grep tls-s3-ceph"
kubectl get secret -n rook-ceph --ignore-not-found | grep tls-s3-ceph
