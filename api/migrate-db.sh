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

user=antinex
pw=antinex
db=webapp

use_namespace="default"
app_name="api"
pod_name=$(kubectl get pods -n ${use_namespace} | awk '{print $1}' | grep ${app_name} | head -1)

warn "-----------------------------------------"
warn "starting database migrations: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/api/migrate-db.sh"
warn "with command:"
warn "kubectl exec -it ${pod_name} -n ${use_namespace} /bin/bash /opt/antinex/api/run-migrations.sh"

kubectl exec -it \
    ${pod_name} \
    -n ${use_namespace} \
    /bin/bash /opt/antinex/api/run-migrations.sh

good "done migrations"

exit 0
