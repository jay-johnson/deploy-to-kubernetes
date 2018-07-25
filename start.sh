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

extra_params=""
if [[ "${SPLUNK_USER}" != "" ]] && [[ "${SPLUNK_PASSWORD}" != "" ]] && [[ "${SPLUNK_TCP_ADDRESS}" != "" ]]; then
    extra_params="splunk"
elif [[ "${1}" == "splunk" ]]; then
    extra_params="splunk"
elif [[ "${1}" == "splunk/" ]]; then
    extra_params="splunk"
fi

anmt "starting api: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/api/run.sh ${extra_params}"
./api/run.sh ${extra_params}
inf ""

anmt "starting core: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/core/run.sh ${extra_params}"
./core/run.sh ${extra_params}
inf ""

anmt "starting worker: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/worker/run.sh ${extra_params}"
./worker/run.sh ${extra_params}
inf ""

anmt "starting jupyter: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/jupyter/run.sh ${extra_params}"
./jupyter/run.sh ${extra_params}
inf ""

anmt "getting pods:"
kubectl get pods
inf ""

exit 0
