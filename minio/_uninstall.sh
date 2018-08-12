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

namespace="default"

warn "--------------"
warn "deleting minio"
inf ""

test_exists=$(kubectl get ing -n ${namespace} --ignore-not-found | grep minio-ingress | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting ingress minio-ingress"
	kubectl delete ingress minio-ingress
	inf ""
fi

test_exists=$(kubectl get ing -n ${namespace} --ignore-not-found | grep minio-s3-ingress | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting ingress minio-s3-ingress"
	kubectl delete ingress minio-s3-ingress
	inf ""
fi

test_exists=$(kubectl get ing -n ${namespace} --ignore-not-found | grep s3-ingress | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting ingress s3-ingress"
	kubectl delete ingress s3-ingress
	inf ""
fi

test_exists=$(helm ls minio | grep minio | wc -l)
if [[ "${test_exists}" != "0" ]]; then
	inf "deleting minio with helm"
	helm delete --purge minio
	inf ""
fi

test_exists=$(kubectl get deployment -n ${namespace} --ignore-not-found | grep minio-deployment | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting minio deployment"
	kubectl delete deployment minio-deployment
	inf ""
fi

test_exists=$(kubectl get pvc | grep minio | grep -v 'No resources' | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting pvc minio"
	kubectl delete pvc minio
	inf ""
fi

test_exists=$(kubectl get pvc | grep minio-pv-claim | grep -v 'No resources' | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting pvc minio-pv-claim"
	kubectl delete pvc minio-pv-claim
	inf ""
fi

test_exists=$(kubectl get svc -n ${namespace} --ignore-not-found | grep "minio-service" | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting svc minio-service"
	kubectl delete svc minio-service
	inf ""
fi

test_exists=$(kubectl get svc -n ${namespace} --ignore-not-found | grep minio | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting svc minio"
	kubectl delete svc minio
	inf ""
fi

test_exists=$(kubectl get secret -n ${namespace} --ignore-not-found | grep minio-s3-access | wc -l)
if [[ "${test_exists}" != "0" ]]; then 
	inf "deleting secret minio-s3-access"
	kubectl delete secret minio-s3-access
	inf ""
fi

good "done deleting: minio"
