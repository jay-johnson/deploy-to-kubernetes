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

should_cleanup_before_startup=0
extra_params=""
multihost_labeler="./multihost/run.sh"
cert_env="dev"
storage_type="ceph"
redeploy_secrets="0"
db_type="postgres"
db_admin="pgadmin"
ingress="nginx"
pubsub="redis"
s3_storage="minio"
for i in "$@"
do
    contains_equal=$(echo ${i} | grep "=")
    if [[ "${i}" == "splunk" ]] || [[ "${i}" == "splunk/" ]]; then
        if [[ "${extra_params}" == "" ]]; then
            extra_params="splunk"
        else
            extra_params="${extra_params} splunk"
        fi
    elif [[ "${i}" == "-r" ]] || [[ "${i}" == "r" ]] || [[ "${i}" == "reload" ]]; then
        should_cleanup_before_startup=1
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "nfs" ]]; then
        storage_type="nfs"
    elif [[ "${i}" == "onlyceph" ]]; then
        db_type=""
        db_admin=""
        pubsub=""
    elif [[ "${contains_equal}" != "" ]]; then
        first_arg=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $1}')
        second_arg=$(echo ${i} | sed -e 's/=/ /g' | awk '{print $2}')
        if [[ "${first_arg}" == "labeler" ]]; then
            multihost_labeler=${second_arg}
        fi
    elif [[ "${i}" == "nolabeler" ]]; then
        multihost_labeler=""
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "antinex" ]]; then
        cert_env="antinex"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    fi
done

# Multi-host mode assumes at least 3 master nodes
# and the deployment uses nodeAffinity labels to
# deploy specific applications to the correct
# hosting cluster node
if [[ "${multihost_labeler}" != "" ]] && [[ -e ${multihost_labeler} ]]; then
    ${multihost_labeler} ${cert_env} ${storage_type} ${extra_params}
fi

if [[ "${redeploy_secrets}" == "1" ]]; then
    # generate new x509 SSL TLS keys, CA, certs and csr files using this command:
    # cd ansible; ansible-playbook -i inventory_dev create-x509s.yml
    #
    # you can reload all certs any time with command:
    # ./ansible/deploy-secrets.sh -r
    anmt "loading included TLS secrets from: ./ansible/secrets/"
    ./ansible/deploy-secrets.sh -r
fi

if [[ "${db_type}" == "postgres" ]]; then
    anmt "starting postgres: ${cert_env} ${storage_type}"
    ./postgres/run.sh ${cert_env} ${storage_type}
    if [[ "${db_admin}" == "pgadmin" ]]; then
        anmt "starting pgadmin: ${cert_env} ${storage_type}"
        ./pgadmin/run.sh ${cert_env} ${storage_type}
    fi
fi

if [[ "${ingress}" == "nginx" ]]; then
    anmt "starting ingress: ${cert_env} ${storage_type}"
    ./ingress/run.sh ${cert_env} ${storage_type}
fi

if [[ "${pubsub}" == "redis" ]]; then
    anmt "starting redis: ${cert_env} ${storage_type}"
    ./redis/run.sh ${cert_env} ${storage_type}
fi

if [[ "${s3_storage}" == "minio" ]]; then
    anmt "starting minio: ${cert_env} ${storage_type}"
    ./minio/run.sh ${cert_env} ${storage_type}
elif [[ "${s3_storage}" == "cephs3" ]]; then
    anmt "starting ceph s3: ${cert_env} ${storage_type}"
    ./rook/run.sh ${cert_env} ${storage_type} ${s3_storage}
fi

for param in $extra_params; do
    if [[ "${param}" == "splunk" ]]; then
        anmt "starting splunk with cert_env: ${cert_env} ${storage_type}"
        ./splunk/run.sh ${cert_env} ${storage_type}
    fi
done

exit 0
