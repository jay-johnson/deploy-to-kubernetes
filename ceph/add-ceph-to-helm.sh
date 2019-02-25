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

inf "checking if helm is running already"
helm_running=$(ps auwwx | grep helm | grep serve | wc -l)
if [[ "${helm_running}" == "0" ]]; then
    anmt "starting local helm server"
    helm serve &
    anmt " - sleeping"
    sleep 5
    helm_running=$(ps auwwx | grep helm | grep serve | wc -l)
    if [[ "${helm_running}" == "0" ]]; then
        err "failed starting local helm server"
        exit 1
    else
        good "helm is running"
    fi
else
    inf " - helm is already serving charts"
fi
inf ""

anmt "adding ceph repo to the helm charts"
last_dir=$(pwd)
if [[ ! -e ./ceph-overrides.yaml ]]; then
    cd ceph
fi
helm repo add ceph http://localhost:8879/charts
if [[ ! -e ./ceph-helm ]]; then
    git clone https://github.com/ceph/ceph-helm ./ceph-helm
fi
cd ceph-helm/ceph
ls
inf ""

anmt "updating helm repo"
helm repo update
inf ""

inf "building ceph-helm chart"
pwd
make
cd ${last_dir}
inf ""
