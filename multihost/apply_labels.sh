#!/bin/bash

# Make sure to run this before starting: source cluster.env

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
fi

nodes="${K8_NODES}"
labels="${K8_LABELS}"

anmt "-------------------------"
anmt "applying multihost labels"
anmt "labels: ${labels}"
anmt "nodes:  ${nodes}"
anmt "KUBECONFIG: ${KUBECONFIG}"

num_nodes=$(kubectl get nodes -o wide | grep Ready | wc -l)
if [[ "${num_nodes}" == "-" ]]; then
    anmt "unable to detect kubernetes nodes with KUBECONFIG=${KUBECONFIG}"
    inf ""
    exit 1
fi

anmt "detected kubernetes nodes: ${num_nodes}"

for node in ${nodes}; do
    # anmt "getting lables for all cluster nodes"
    node_name=$(kubectl get nodes | grep ${node} | awk '{print $1}')
    for label in $labels; do
        label_name=$(echo ${label} | sed -e 's/=/ /g' | awk '{print $1}')
        label_value=$(echo ${label} | sed -e 's/=/ /g' | awk '{print $2}')
        kubectl label nodes ${node_name} ${label} --overwrite >> /dev/null 2>&1
    done
done
    
anmt "review labels with:"
anmt "kubectl get nodes --show-labels -o wide"

good "done - applying: multihost labels"
anmt "-------------------------"

exit 0
