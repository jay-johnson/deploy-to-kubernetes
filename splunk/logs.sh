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

use_namespace="default"
app_name="splunk"
pod_name=$(kubectl get pods -n ${use_namespace} | awk '{print $1}' | grep ${app_name} | head -1)

good "kubectl logs -f ${pod_name} -n ${use_namespace}"

kubectl logs \
    -f ${pod_name} \
    -n ${use_namespace}
