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

anmt "-------------------------------------"
anmt "deploying redis: https://github.com/helm/charts/tree/master/stable/redis"
inf ""

is_running=$(helm ls redis | grep redis | wc -l)
if [[ "${is_running}" != "0" ]]; then
    good "redis is already running: helm ls redis | grep redis | wc -l"
    exit 0
fi

inf "deploying persistent volume for redis" 
kubectl apply -f ./redis/pv.yml

good "deploying Bitnami redis stable with helm" 
helm install \
    --name redis stable/redis \
    --set rbac.create=true \
    --values ./redis/redis.yml

last_exit=$?
if [[ "${last_exit}" != "0" ]]; then
    inf ""
    err "failed to deploy redis:"
    inf ""
    kubectl describe pod redis-master-0
    inf ""
    exit ${last_exit}
else
    inf ""
    inf "getting pods:"
    kubectl get pods
fi

good "done deploying: redis"

exit 0
