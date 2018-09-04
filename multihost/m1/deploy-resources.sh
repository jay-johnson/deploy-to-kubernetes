#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
up_c="../tools/bash_colors.sh"
if [[ "${DISABLE_COLORS}" == "" ]] && [[ "${found_colors}" != "" ]] && [[ -e ${found_colors} ]]; then
    . ${found_colors}
elif [[ "${DISABLE_COLORS}" == "" ]] && [[ "${up_c}" != "" ]] && [[ -e ${up_c} ]]; then
    . ${up_c}
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
ceph=""
splunk=""
for i in "$@"
do
    if [[ "${i}" == "splunk" ]]; then
        splunk="splunk"
    elif [[ "${i}" == "ceph" ]]; then
        ceph="ceph"
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "antinex" ]]; then
        cert_env="an"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    fi
done

anmt "--------------------------------------------------"
anmt "deploying master 1 - ${splunk} ${ceph} ${cert_env}"
inf ""

if [[ ! -e /opt/deploy-to-kubernetes ]]; then
    git clone https://github.com/jay-johnson/deploy-to-kubernetes /opt/deploy-to-kubernetes
fi

cd /opt/deploy-to-kubernetes
export KUBECONFIG=/etc/kubernetes/admin.conf
export GOPATH=$HOME/go/bin
export PATH=$PATH:$GOPATH:$GOPATH/bin

inf "installing expenv"
go get github.com/blang/expenv

anmt "deploying resources: /opt/deploy-to-kubernetes/deploy-resources.sh ${splunk} ${ceph} ${cert_env}"
cd /opt/deploy-to-kubernetes
/opt/deploy-to-kubernetes/deploy-resources.sh ${splunk} ${ceph} ${cert_env}

good "done deploying master 1 resources"
