#!/bin/bash

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
fi

should_cleanup_before_startup=0
deploy_suffix=""
cert_env="dev"
for i in "$@"
do
    if [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "antinex" ]]; then
        cert_env="an"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    fi
done

use_path="."
if [[ ! -e deployment.yml ]]; then
    use_path="./api"
fi

anmt "----------------------------------------------------------------------------------"
anmt "deploying api with cert_env=${cert_env}: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/api"
inf ""

inf "applying secrets"
kubectl apply -f ${use_path}/secrets.yml
inf ""

deploy_file=${use_path}/deployment${deploy_suffix}.yml
warn "applying deployment: ${deploy_file}"
kubectl apply -f ${deploy_file}
inf ""

inf "applying service"
kubectl apply -f ${use_path}/service.yml
inf ""

inf "applying ingress cert_env: ${cert_env}"
kubectl apply -f ${use_path}/ingress-${cert_env}.yml
inf ""

good "done deploying: api"
