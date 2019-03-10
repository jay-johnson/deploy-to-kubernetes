#!/bin/bash

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
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
