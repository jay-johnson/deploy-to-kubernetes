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
warn "deleting pgadmin"
inf ""

good "kubectl delete ingress: pgadmin-ingress"
kubectl delete ingress pgadmin-ingress
inf ""

good "kubectl delete service: pgadmin4-http"
kubectl delete svc pgadmin4-http
inf ""

good "kubectl delete pod: pgadmin4-http"
kubectl delete pod pgadmin4-http
inf ""

good "kubectl delete pvc: pgadmin4-http-data"
kubectl delete pvc pgadmin4-http-data
inf ""

good "kubectl delete pv: pgadmin4-http-data"
kubectl delete pv pgadmin4-http-data
inf ""

inf "deleting secrets: pgadmin-secrets"
kubectl delete secret pgadmin-secrets
inf ""

inf "deleting secrets: pgadmin4-http-secrets"
kubectl delete secret pgadmin4-http-secrets
inf ""

good "done deleting: pgadmin"
