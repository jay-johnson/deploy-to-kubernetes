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
app_name="api"
pod_name=$(kubectl get pods -n ${use_namespace} | awk '{print $1}' | grep ${app_name} | head -1)

warn "searching splunk with: ${@}"
warn "with command:"
warn "kubectl exec -it ${pod_name} -n ${use_namespace} echo 'starting search' && /bin/bash -c \"source /opt/venv/bin/activate && sp ${@}\""

kubectl exec -it \
    ${pod_name} \
    -n ${use_namespace} \
    echo 'starting search' && /bin/bash -c "source /opt/venv/bin/activate && sp ${@}"

good "done searching"

exit 0
