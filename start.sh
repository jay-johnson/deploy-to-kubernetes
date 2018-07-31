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

# reload the apps on startup by calling it with:
# ./start.sh -r
#
# reload with splunk enabled:
# ./start.sh -r splunk
# or
# ./start.sh splunk -r

should_cleanup_before_startup=0
cert_env="staging"
extra_params=""
for i in "$@"
do
    if [[ "${i}" == "splunk" ]] || [[ "${i}" == "splunk/" ]]; then
        if [[ "${extra_params}" == "" ]]; then
            extra_params="splunk"
        else
            extra_params="${extra_param} splunk"
        fi
    elif [[ "${i}" == "-r" ]] || [[ "${i}" == "r" ]] || [[ "${i}" == "reload" ]]; then
        should_cleanup_before_startup=1
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    fi
done

if [[ "${should_cleanup_before_startup}" == "1" ]]; then
    warn "deleting apps before start"
    anmt " - deleting api"
    ./api/_uninstall.sh
    anmt " - deleting worker"
    ./worker/_uninstall.sh
    anmt " - deleting core"
    ./core/_uninstall.sh
    anmt " - deleting jupyter"
    ./jupyter/_uninstall.sh
    inf "done"
fi

anmt "starting cert-manager: ${cert_env}"
./cert-manager/run.sh ${cert_env}
inf ""

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
