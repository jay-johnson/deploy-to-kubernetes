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

anmt "--------------------------------------------------"
anmt "Tailing Ceph logs with:"
inf ""
inf ""
mon_pod=$(kubectl get pods --ignore-not-found -n ${use_namespace} | grep -v keyring- | grep "ceph-mon-" | awk '{print $1}' | tail -1)
if [[ "${mon_pod}" == "" ]]; then
    err "Did not find a ceph-mon pod running - please check ceph:"
    err "kubectl get pods -n ${use_namespace}"
    exit 1
else
    good "kubectl -n ${use_namespace} logs ${mon_pod} -c cluster-log-tailer"
    kubectl -n ${use_namespace} logs ${mon_pod} -c cluster-log-tailer
fi
