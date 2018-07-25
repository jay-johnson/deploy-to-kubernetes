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

deploy_suffix=""
if [[ "${1}" == "splunk" ]]; then
    deploy_suffix="-splunk"
fi

use_path="."
if [[ ! -e deployment.yml ]]; then
    use_path="./worker"
fi

anmt "----------------------------------------------------------------------------------------"
anmt "deploying worker: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/worker"
inf ""

inf "applying secrets"
kubectl apply -f ${use_path}/secrets.yml
inf ""

deploy_file=${use_path}/deployment${deploy_suffix}.yml
warn "applying deployment: ${deploy_file}"
kubectl apply -f ${deploy_file}
inf ""

good "done deploying: worker"
