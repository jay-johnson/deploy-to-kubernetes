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

use_namespace="rook-minio-system"
app_name=$(kubectl -n ${use_namespace} get pod --ignore-not-found | grep rook-minio-operator | awk '{print $1}')

anmt "--------------------------------------------------"
anmt "Tailing Rook Minio Operator ${app_name} logs with:"
inf ""
good "kubectl logs -f -n ${use_namespace} ${app_name}"
inf ""
kubectl logs -f -n ${use_namespace} ${app_name}

