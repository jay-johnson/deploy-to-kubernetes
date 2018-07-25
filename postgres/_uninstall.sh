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

warn "-----------------------------------------"
warn "deleting postgres"
inf ""

good "deleting postgres service: primary"
kubectl delete svc primary
inf ""

good "deleting postgres service: postgres-primary"
kubectl delete svc postgres-primary
inf ""

good "deleting pod: primary"
kubectl delete pod primary
inf ""

good "deleting pvc: primary-pgdata"
kubectl delete pvc primary-pgdata
inf ""

good "deleting pv: primary-pgdata"
kubectl delete pv primary-pgdata
inf ""

good "done deleting: postgres"
