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

user_test=$(whoami)
if [[ "${user_test}" != "root" ]]; then
    err "please run as root"
    exit 1
fi

anmt "--------------------------------------------"
anmt "deploying helm and tiller"
inf ""

inf "curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash"
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

inf "setting up helm and tiller: ./helm/install-helm-and-tiller.sh"
./helm/install-helm-and-tiller.sh

good "done deploying: helm and tiller"
