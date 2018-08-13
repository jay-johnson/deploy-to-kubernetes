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

deploy_suffix=""
should_cleanup_before_startup=0
extra_params=""
letsencrypt_suffix="staging"
for i in "$@"
do
    if [[ "${i}" == "staging" ]] || [[ "${i}" == "stg" ]]; then
        letsencrypt_suffix="staging"
    elif [[ "${i}" == "prod" ]]; then
        letsencrypt_suffix="prod"
    elif [[ "${i}" == "-r" ]] || [[ "${i}" == "r" ]] || [[ "${i}" == "reload" ]]; then
        should_cleanup_before_startup=1
    elif [[ "${i}" == "antinex" ]]; then
        letsencrypt_suffix="an"
    elif [[ "${i}" == "qs" ]]; then
        letsencrypt_suffix="qs"
    elif [[ "${i}" == "redten" ]]; then
        letsencrypt_suffix="redten"
    fi
done

use_path="."
if [[ ! -e ./letsencrypt-staging.yml ]]; then
    use_path="./cert-manager"
fi

anmt "----------------------------------------------------------------------------------"
warn "deploying cert-manager: https://github.com/jetstack/cert-manager docs: https://cert-manager.readthedocs.io/en/latest/index.html"
inf ""

secrets_file=${use_path}/secrets-${letsencrypt_suffix}.yml
if [[ -e "${secrets_file}" ]]; then
    inf "applying cert-manager secrets: ${secrets_file}"
    kubectl apply -f ${secrets_file}
    inf ""
fi

test_exists=$(helm ls | grep cert-manager | wc -l)
if [[ "${test_exists}" == "0" ]]; then
    inf "deploying cert-manager with issuer: letsencrypt-${letsencrypt_suffix}"
    helm install \
        --name cert-manager \
        --namespace default \
        --set ingressShim.defaultIssuerName=letsencrypt-issuer \
        --set ingressShim.defaultIssuerKind=ClusterIssuer \
        stable/cert-manager
    inf ""
fi

deploy_file=${use_path}/clusterissuer-${letsencrypt_suffix}.yml
if [[ -e "${deploy_file}" ]]; then
    inf "deploying letsencrypt clusterissuer: ${deploy_file}"
    kubectl apply -f ${deploy_file}
    inf ""
else
    err "failed to find letsencrypt file: ${deploy_file}"
fi

# left in here for debugging if needed:

# ingress_file=${use_path}/ingress-${letsencrypt_suffix}.yml
# if [[ -e "${ingress_file}" ]]; then
#     inf "deploying letsencrypt ingress: ${ingress_file}"
#     kubectl apply -f ${ingress_file}
#     inf ""
# else
#     err "failed to find letsencrypt ingress file: ${ingress_file}"
# fi

# issuer_file=${use_path}/issuer-${letsencrypt_suffix}.yml
# if [[ -e "${issuer_file}" ]]; then
#     inf "deploying letsencrypt issuer file: ${issuer_file}"
#     kubectl apply -f ${issuer_file}
#     inf ""
# else
#     err "failed to find letsencrypt issuer file: ${issuer_file}"
# fi

good "done deploying: cert-manager"
