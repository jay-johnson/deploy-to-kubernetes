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
warn "deleting cert-manager"
inf ""

test_exists=$(kubectl get ingress | grep cert-manager-ingress | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting ingress: cert-manager-ingress"
    kubectl delete ingress cert-manager-ingress
    inf ""
fi

test_exists=$(kubectl get ingress -n kube-system | grep cert-manager-ingress | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting ingress: cert-manager-ingress"
    kubectl delete ingress -n kube-system cert-manager-ingress
    inf ""
fi

test_exists=$(kubectl get clusterissuer -n kube-system | grep letsencrypt-staging | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting clusterissuer: letsencrypt-staging"
    kubectl delete clusterissuer -n kube-system letsencrypt-staging
    inf ""
fi

test_exists=$(kubectl get clusterissuer -n kube-system | grep letsencrypt-prod | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting clusterissuer: letsencrypt-prod"
    kubectl delete clusterissuer -n kube-system letsencrypt-prod
    inf ""
fi

test_exists=$(kubectl get issuer -n kube-system | grep letsencrypt-staging | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting issuer: letsencrypt-staging"
    kubectl delete issuer -n kube-system letsencrypt-staging
    inf ""
fi

test_exists=$(kubectl get issuer -n kube-system | grep letsencrypt-prod | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting issuer: letsencrypt-prod"
    kubectl delete issuer -n kube-system letsencrypt-prod
    inf ""
fi

test_exists=$(kubectl get secrets -n kube-system letsencrypt-staging | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting secrets: letsencrypt-staging"
    kubectl delete secrets -n kube-system letsencrypt-staging
    inf ""
fi

test_exists=$(kubectl get secrets -n kube-system letsencrypt-prod | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting secrets: letsencrypt-prod"
    kubectl delete secrets -n kube-system letsencrypt-prod
    inf ""
fi

test_exists=$(kubectl get secrets -n kube-system letsencrypt-secret | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting secrets: letsencrypt-secret"
    kubectl delete secrets -n kube-system letsencrypt-secret
    inf ""
fi

test_exists=$(helm ls | grep cert-manager | wc -l)
if [[ "${test_exists}" != "0" ]]; then
    inf "deleting with helm: cert-manager"
    helm del --purge cert-manager
    inf ""
fi

good "done deleting: cert-manager"
