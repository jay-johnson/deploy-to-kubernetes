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
cert_env="dev"
extra_params=""
for i in "$@"
do
    if [[ "${i}" == "splunk" ]] || [[ "${i}" == "splunk/" ]]; then
        if [[ "${extra_params}" == "" ]]; then
            extra_params="splunk"
        else
            extra_params="${extra_params} splunk"
        fi
    elif [[ "${i}" == "-r" ]] || [[ "${i}" == "r" ]] || [[ "${i}" == "reload" ]]; then
        should_cleanup_before_startup=1
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    fi
done

# generate new x509 SSL TLS keys, CA, certs and csr files using this command:
# cd ansible; ansible-playbook -i inventory_dev create-x509s.yml
#
# you can reload all certs any time with command:
# ./ansible/deploy-secrets.sh -r
anmt "loading included TLS secrets from: ./ansible/secrets/"
./ansible/deploy-secrets.sh -r

anmt "starting postgres"
./postgres/run.sh

anmt "starting pgadmin with cert_env: ${cert_env}"
./pgadmin/run.sh ${cert_env}

anmt "starting ingress"
./ingress/run.sh 

anmt "starting redis"
./redis/run.sh 

for param in $extra_params; do
    if [[ "${param}"  == "splunk" ]]; then
        anmt "starting splunk with cert_env: ${cert_env}"
        ./splunk/run.sh ${cert_env}
    fi
done

exit 0
