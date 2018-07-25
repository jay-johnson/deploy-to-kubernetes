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

# install guide from
# https://github.com/nginxinc/kubernetes-ingress/blob/master/docs/installation.md#installing-the-ingress-controller

namespace="default"
use_path="."
if [[ ! -e ./ns-and-sa.yml ]]; then
    use_path="./ingress"
fi

anmt "-----------------------------------------------------------------------"
anmt "deploying nginx-ingress: https://github.com/nginxinc/kubernetes-ingress"
inf ""

inf "building service account"
kubectl apply -f ${use_path}/ns-and-sa.yml -n ${namespace}
inf ""

inf "creating secrets"
kubectl apply -f ${use_path}/default-server-secret.yml -n ${namespace}
inf ""

inf "creating config map"
kubectl apply -f ${use_path}/nginx-config.yml -n ${namespace}
inf ""

inf "assigning rbac rules"
kubectl apply -f ${use_path}/rbac.yml -n ${namespace}
inf ""

# Deployment. Use a Deployment if you plan to dynamically change the number of Ingress controller replicas.
#
# DaemonSet. Use a DaemonSet for deploying the Ingress controller on every node or a subset of nodes.
# If you created a daemonset, ports 80 and 443 of the Ingress controller container are 
# mapped to the same ports of the node where the container is running. To access the
# Ingress controller, use those ports and an IP address of any node of the cluster
# where the Ingress controller is running.

inf "deploying as DaemonSet"
kubectl apply -f ${use_path}/nginx-ingress.yml -n ${namespace}
inf ""

inf "getting pods"
kubectl get pods -n ${namespace}
inf ""

good "done deploying: nginx-ingress"
