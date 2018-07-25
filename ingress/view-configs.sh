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

use_namespace="default"
app_name="nginx"
pod_name=$(kubectl get pods -n ${use_namespace} | awk '{print $1}' | grep ${app_name} | head -1)

inf ""
anmt "-----------------------------------------"
good "Getting the pgAdmin4 ingress configuration: "
kubectl exec -it \
    ${pod_name} \
    -n ${use_namespace} \
    cat /etc/nginx/conf.d/default-pgadmin-ingress.conf
    
inf ""
anmt "-----------------------------------------"
good "Getting the Jupyter ingress configuration: "
kubectl exec -it \
    ${pod_name} \
    -n ${use_namespace} \
    cat /etc/nginx/conf.d/default-jupyter-ingress.conf

inf ""
anmt "-----------------------------------------"
good "Getting the API ingress configuration: "
kubectl exec -it \
    ${pod_name} \
    -n ${use_namespace} \
    cat /etc/nginx/conf.d/default-api-ingress.conf
