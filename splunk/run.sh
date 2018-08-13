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

should_cleanup_before_startup=0
cert_env="dev"
extra_params=""
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
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
    use_path="./splunk"
fi

anmt "------------------------------------------------------------"
anmt "deploying splunk with cert_env=${cert_env}: https://hub.docker.com/r/splunk/splunk/"
inf ""

inf "applying secrets"
kubectl apply -f ${use_path}/secrets.yml
inf ""

inf "applying API and HEC service"
kubectl apply -f ${use_path}/service.yml
inf ""

inf "applying Web dashboard service"
kubectl apply -f ${use_path}/web-service.yml
inf ""

inf "applying TCP service"
kubectl apply -f ${use_path}/tcp-service.yml
inf ""

# Optional ingress files

# inf "applying API and HEC ingresses"
# kubectl apply -f ${use_path}/ingress.yml
# inf ""

# inf "applying TCP endpoint ingress"
# kubectl apply -f ${use_path}/tcp-ingress.yml
# inf ""

inf "applying Web dashboard endpoint ingress cert_env: ${cert_env}"
kubectl apply -f ${use_path}/web-ingress-${cert_env}.yml
inf ""

inf "applying deployment: ${use_path}/deployment.yml"
kubectl apply -f ${use_path}/deployment.yml
inf ""

good "done deploying: splunk"
