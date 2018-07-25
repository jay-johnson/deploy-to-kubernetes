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

warn "------------------------------------------"
warn "deleting worker"
inf ""

inf "deleting deployment: worker"
kubectl delete deployment worker
inf ""

inf "deleting secrets: worker"
kubectl delete secret worker-secret
inf ""

good "done deleting: worker"
