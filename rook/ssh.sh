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
app_name="rook-ceph-tools"
pod_name=$(kubectl get pods -n ${use_namespace} | awk '{print $1}' | grep ${app_name} | head -1)

good "kubectl exec -it -n ${use_namespace} ${app_name} /bin/bash"

kubectl exec -it \
    -n ${use_namespace} \
    ${app_name} \
    /bin/bash
