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

dir_to_check="/var/lib/cni/networks/cbr0"
anmt "-------------------------"
anmt "removing flannel-created cni files in directory: ${dir_to_check}"

cur_dir=$(pwd)
cd ${dir_to_check}
for hash in $(tail -n +1 * | egrep '^[A-Za-z0-9]{64,64}$'); do
    if [ -z $(crictl pods --no-trunc | grep $hash | awk '{print $1}') ]; then
        grep -ilr $hash ./ | xargs rm
    fi;
done
cd ${cur_dir}

anmt "done - removing flannel-created cni files in directory: ${dir_to_check}"
anmt "-------------------------"

exit 0
