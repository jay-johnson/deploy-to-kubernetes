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
warn "deleting api"
inf ""

inf "deleting ingress: api-ingress"
kubectl delete ingress api-ingress
inf ""

inf "deleting service: api-svc"
kubectl delete svc api-svc
inf ""

inf "deleting deployment: api"
kubectl delete deployment api
inf ""

inf "deleting secrets: api"
kubectl delete secret api-secret
inf ""

good "done deleting: api"
