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

secret_prefix="tls-"
should_cleanup_before_startup=0
for i in "$@"
do
    if [[ "${i}" == "-r" ]] || [[ "${i}" == "r" ]] || [[ "${i}" == "reload" ]]; then
        should_cleanup_before_startup=1
    fi
done

use_path="."
if [[ ! -e create-x509s.yml ]]; then
    use_path="./ansible"
fi

anmt "----------------------------------------------------------------------------------"
anmt "deploying secrets"
inf ""

files=$(ls ${use_path}/ssl/ | grep "_key.pem")
inf "importing secrets: ${files}"
for i in ${files}; do
    key_file=${use_path}/ssl/${i}
    cert_file=$(echo "${key_file}" | sed -e 's/_key.pem/_cert.pem/g')
    base_secret_name=$(echo ${i} | sed -e 's/_key.pem//g' | sed -e 's/_server//g')
    secret_name="${secret_prefix}${base_secret_name}"
    inf " - checking key=${key_file} cert=${cert_file}"
    if [[ -e ${key_file} ]] && [[ -e ${cert_file} ]]; then
        if [[ "${should_cleanup_before_startup}" == "1" ]]; then
            test_exists=$(kubectl get secrets | grep ${secret_name} | wc -l)
            if [[ "${test_exists}" != "0" ]]; then
                inf " - deleting previous secret: ${secret_name}"
                kubectl delete secret ${secret_name}
            fi
        fi
        inf " - kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file}"
        kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file}
        if [[ $? -ne 0 ]]; then
            inf ""
            err "Failed - kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file}"
            inf ""
            inf "If you want to reload all the keys use:"
            inf "./ansible/deploy-secrets.sh -r"
            inf ""
            exit 1
        fi
    fi
    inf ""
done

good "done deploying: secrets"
