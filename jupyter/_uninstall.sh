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
warn "deleting jupyter"
inf ""

good "kubectl delete ingress: jupyter-ingress"
kubectl delete ingress jupyter-ingress
inf ""

good "kubectl delete service: jupyter-svc"
kubectl delete svc jupyter-svc
inf ""

good "kubectl delete deployment: jupyter"
kubectl delete deployment jupyter
inf ""

inf "deleting secrets: jupyter"
kubectl delete secret jupyter-secret
inf ""

good "done deleting: jupyter"
