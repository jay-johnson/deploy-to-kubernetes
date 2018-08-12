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

access_key="trexaccesskey"
secret_key="trex123321"
storage_class="rook-ceph-block"
storage_size="5Gi"
should_cleanup_before_startup=0
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
object_store=""
username="trex"
display_name="trex"
namespace="default"
use_helm="0"
debug="0"
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "cephs3" ]]; then
        storage_type="ceph"
        object_store="ceph"
    elif [[ "${i}" == "minio" ]]; then
        storage_type="ceph"
        object_store="rook-minio"
    elif [[ "${i}" == "-d" ]]; then
        debug="1"
    elif [[ "${i}" == "clean_on_start" ]]; then
        should_cleanup_before_startup="1"
    elif [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    fi
done

use_path="."
if [[ ! -e ingress-dev.yml ]]; then
    use_path="./minio"
fi
secrets_path="${use_path}/secrets"

anmt "----------------------------------------------------------------------------------------------"
anmt "deploying minio with storage type ${storage_class} from: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/minio"

anmt "Want to learn more about Minio work while you wait?"
inf ""
anmt "- How Minio works with Helm: https://docs.minio.io/docs/deploy-minio-on-kubernetes.html"
anmt "- How Minio Object Stores work: https://rook.io/docs/rook/master/minio-object-store.html"
anmt "- How Minio works with Boto3 AWS client: https://docs.minio.io/docs/how-to-use-aws-sdk-for-python-with-minio-server.html"
inf ""

# Deploying Minio with Helm is much easier
# https://docs.minio.io/docs/deploy-minio-on-kubernetes.html

access_key_file="${secrets_path}/default_access_keys.yml"
inf "deploying access key secrets: ${access_key_file}"
kubectl apply -n ${namespace} -f ${access_key_file}
inf ""

if [[ "${use_helm}" == "0" ]]; then
    test_exists=$(kubectl get pod -n ${namespace} | grep minio | wc -l)
    if [[ "${test_exists}" == "0" ]]; then
        deploy_file=${use_path}/deployment-${cert_env}.yml
        inf "deploying minio with: ${deploy_file}"
        kubectl apply -f ${deploy_file} -n ${namespace}
        inf ""
    else
        inf "minio is already running"
    fi
else
    test_exists=$(helm ls minio | grep minio | wc -l)
    if [[ "${test_exists}" == "0" ]]; then
        inf "deploying minio with helm"
        helm install \
            --name minio \
            --set accessKey=${access_key} \
            --set secretKey=${secret_key} \
            --set persistence.storageClass=${storage_class} \
            --set persistence.size=${storage_size} \
            stable/minio
    else
        inf "minio using helm is already running"
    fi
fi

service_file=${use_path}/cluster-internal-service.yml
inf "applying minio service using: kubectl apply -f ${service_file}"
kubectl apply -f ${service_file}

ingress_file=${use_path}/ingress-${cert_env}.yml
inf "applying minio ingress cert_env ${cert_env} using: kubectl apply -f ${ingress_file}"
kubectl apply -f ${ingress_file}

good "done deploying: minio with cert_env ${cert_env}"
