#!/bin/bash

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
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
