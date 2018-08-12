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

file_count=$(ls ${use_path}/ssl/ | grep "_key.pem" | wc -l)
if [[ "${file_count}" == "0" ]]; then
    files=$(ls ${use_path}/secrets/ | grep "${secret_prefix}*")
    inf "importing default secrets: ${files}"
    for i in ${files}; do
        base_secret_name=$(echo ${i} | sed -e 's/.yml//g')
        secret_name="${base_secret_name}"
        yml_file=${use_path}/secrets/${secret_name}.yml
        inf " - checking yaml_file=${yml_file} for secret: ${secret_name}"
        if [[ -e ${yml_file} ]]; then
            if [[ "${should_cleanup_before_startup}" == "1" ]]; then
                test_exists=$(kubectl get secrets --ignore-not-found | grep ${secret_name} | wc -l)
                if [[ "${test_exists}" != "0" ]]; then
                    inf " - deleting previous secret: ${secret_name}"
                    kubectl delete secret ${secret_name}
                fi
            fi
            inf " - importing default secret ${secret_name} from ${yml_file}"
            kubectl apply -f ${yml_file}
            if [[ $? -ne 0 ]]; then
                inf ""
                err "Failed import default secret ${secret_name} from ${yml_file} with: kubectl kubectl apply -f ${yml_file}"
                inf ""
                inf "If you want to reload all the keys use:"
                inf "./ansible/deploy-secrets.sh -r"
                inf ""
                exit 1
            fi
        else
            err " - no action taken for secret: ${secret_name} - did not find yaml_file=${yml_file}"
        fi
    done
else
    files=$(ls ${use_path}/ssl/ | grep "_key.pem" | grep -v "_private")
    inf "importing secrets: ${files}"
    for i in ${files}; do
        key_file=${use_path}/ssl/${i}
        cert_file=$(echo "${key_file}" | sed -e 's/_key.pem/_cert.pem/g')
        base_secret_name=$(echo ${i} | sed -e 's/_key.pem//g' | sed -e 's/_server//g')
        secret_name="${secret_prefix}${base_secret_name}"
        yml_file=${use_path}/secrets/${secret_name}.yml
        namespace="default"
        if [[ -e ${key_file} ]] && [[ -e ${cert_file} ]]; then
            inf " - found key=${key_file} cert=${cert_file}"
            if [[ "${should_cleanup_before_startup}" == "1" ]]; then
                test_exists=$(kubectl get secrets --ignore-not-found | grep ${secret_name} | wc -l)
                if [[ "${test_exists}" != "0" ]]; then
                    inf " - deleting previous secret: ${secret_name}"
                    kubectl delete secret ${secret_name}
                fi
            fi
            if [[ "${secret_name}" == "tls-s3" ]];then
                namespace="rook-ceph"
                if [[ "${should_cleanup_before_startup}" == "1" ]]; then
                    test_exists=$(kubectl get secrets -n ${namespace} --ignore-not-found | grep ${secret_name} | wc -l)
                    if [[ "${test_exists}" != "0" ]]; then
                        inf " - deleting previous secret -n ${namespace}: ${secret_name}"
                        kubectl delete secret -n ${namespace} ${secret_name}
                    fi
                fi
                inf " - kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file} --namespace=${namespace}"
                kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file} --namespace=${namespace}
                namespace="default"
            else
                namespace="default"
            fi
            inf " - kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file} --namespace=${namespace}"
            kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file} --namespace=${namespace}
            if [[ $? -ne 0 ]]; then
                inf ""
                err "Failed - kubectl create secret tls ${secret_name} --cert=${cert_file} --key=${key_file} --namespace=${namesapce}"
                inf ""
                inf "If you want to reload all the keys use:"
                inf "./ansible/deploy-secrets.sh -r"
                inf ""
                exit 1
            else
                inf " - creating ${secret_name} yaml file: ${yml_file}"
                kubectl get secret ${secret_name} -o yaml > ${yml_file}
                if [[ ! -e ${yml_file} ]]; then
                    inf ""
                    err "Failed to output secret to yaml file: kubectl get secret ${secret_name} -o yaml > ${yml_file}"
                    inf ""
                    exit 1
                fi
            fi
        else
            inf " - checking yaml_file=${yml_file} for secret: ${secret_name}"
            if [[ -e ${yml_file} ]]; then
                if [[ "${should_cleanup_before_startup}" == "1" ]]; then
                    test_exists=$(kubectl get secrets --ignore-not-found | grep ${secret_name} | wc -l)
                    if [[ "${test_exists}" != "0" ]]; then
                        inf " - deleting previous secret: ${secret_name}"
                        kubectl delete secret ${secret_name}
                    fi
                fi
                inf " - importing default secret ${secret_name} from ${yml_file}"
                kubectl apply -f ${yml_file}
                if [[ $? -ne 0 ]]; then
                    inf ""
                    err "Failed import default secret ${secret_name} from ${yml_file} with: kubectl kubectl apply -f ${yml_file}"
                    inf ""
                    inf "If you want to reload all the keys use:"
                    inf "./ansible/deploy-secrets.sh -r"
                    inf ""
                    exit 1
                fi
            else
                inf " - no action taken for secret: ${secret_name} - no (key_file=${key_file} and cert_file=${cert_file}) and no yaml_file=${yml_file} found"
            fi
        fi
        inf ""
    done
fi

good "done deploying: secrets"
