#!/bin/bash

echo "deploying persistent volume for redis" 
kubectl apply -f ./redis/pv.yml

echo "deploying Bitnami redis stable with helm" 
helm install \
    --name redis stable/redis \
    --set rbac.create=true \
    --values ./redis/redis.yml
last_exit=$?
if [[ "${last_exit}" != "0" ]]; then
    echo ""
    echo "failed to deploy redis:"
    echo ""
    kubectl describe pod redis-master-0
    echo ""
    exit 
    exit ${last_exit}
else
    echo ""
    kubectl get pods
    exit 0
fi
