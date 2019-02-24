#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
up_found_colors="../tools/bash_colors.sh"
if [[ "${DISABLE_COLORS}" == "" ]] && [[ "${found_colors}" != "" ]] && [[ -e ${found_colors} ]]; then
    . ${found_colors}
elif [[ "${DISABLE_COLORS}" == "" ]] && [[ "${up_found_colors}" != "" ]] && [[ -e ${up_found_colors} ]]; then
    . ${up_found_colors}
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

storage_class="ceph-block"
storage_size="5Gi"
should_cleanup_before_startup=0
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
object_store=""
username="trex"
display_name="trex"
namespace="ceph"
helm_running="0"
debug="0"
for i in "$@"
do
    if [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "-d" ]]; then
        debug="1"
    elif [[ "${i}" == "clean_on_start" ]]; then
        should_cleanup_before_startup="1"
    fi
done

use_path="."
if [[ ! -e ./ceph-overrides.yaml ]]; then
    use_path="./ceph"
fi
secrets_path="${use_path}/secrets.yml"

anmt "----------------------------------------------------------------------------------------------"
anmt "deploying ceph with storage type ${storage_class} from: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/ceph"

anmt "Want to learn more about Ceph work while you wait?"
inf ""
anmt "- Ceph intro: http://docs.ceph.com/docs/mimic/start/intro/"
anmt "- Ceph storage clusters work: http://docs.ceph.com/docs/mimic/rados/"
anmt "- Ceph architecture: http://docs.ceph.com/docs/mimic/architecture/"
anmt "- Ceph S3 Object Store: http://docs.ceph.com/docs/mimic/radosgw/s3/"
anmt "- Ceph S3 with python: http://docs.ceph.com/docs/mimic/radosgw/s3/python/"
anmt "- Ceph deploy with Helm: http://docs.ceph.com/docs/mimic/start/kube-helm/"
inf ""

# Deploying Ceph with Helm
# http://docs.ceph.com/docs/mimic/start/kube-helm/

test_ns=$(kubectl get namespaces | grep ceph | grep -v rook | wc -l)
if [[ "${test_ns}" == "0" ]]; then
    inf "creating namespace"
    inf "kubectl create namespace ${namespace}"
    kubectl create namespace ${namespace}
    inf ""
fi

inf "creating roles based access controls"
inf "kubectl create -f ${use_path}/rbac.yaml"
kubectl create -f ${use_path}/rbac.yaml
inf ""

if [[ -e ${secrets_path} ]]; then
    inf "deploying secrets: ${secrets_path}"
    kubectl apply -n ${namespace} -f ${secrets_path}
    inf ""
fi

inf "checking what should be an empty namespace for: ${namespace} pods"
inf "kubectl get pods -n ${namespace}"
kubectl get pods -n ${namespace}
inf ""

helm_has_ceph_chart=$(helm repo list | grep ceph | wc -l)
if [[ "${helm_has_ceph_chart}" == "0" ]]; then
    inf ""
    inf "adding ceph to helm repo"
    ${use_path}/add-ceph-to-helm.sh
    inf ""
else
    inf "found ceph in local chart repo"
fi

pwd
inf "installing ceph with helm:"
inf "helm install --name=ceph ceph/ceph --namespace=${namespace} -f ${use_path}/values.yml -f ${use_path}/ceph-overrides.yaml"
# use the overrides file if your nodes have a dedicated device like /dev/sda or /dev/sdb
# helm install --name=ceph ceph/ceph --namespace=${namespace} -f ${use_path}/values.yml -f ${use_path}/ceph-overrides.yaml
helm install --name=ceph ceph/ceph --namespace=${namespace} -f ${use_path}/values.yml
inf ""

inf ""
inf ""
inf ""
anmt "checking ceph cluster status:"
inf "kubectl -n ${namespace} exec -ti ceph-mon-cppdk -c ceph-mon -- ceph -s"
kubectl -n ${namespace} exec -ti ceph-mon-cppdk -c ceph-mon -- ceph -s
inf ""
inf ""
inf ""

inf "checking ${namespace} pods"
inf "kubectl get pods -n ${namespace}"
kubectl get pods -n ${namespace}
inf ""

good "done deploying: ceph into ${namespace} namespace"
