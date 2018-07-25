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

dir_to_check="/var/lib/cni/networks/cbr0"
anmt "----------------------------------------------------"
critical "removing flannel-created cni files in directory: ${dir_to_check}"

cur_dir=$(pwd)
cd ${dir_to_check}
for hash in $(tail -n +1 * | egrep '^[A-Za-z0-9]{64,64}$'); do
    if [ -z $(crictl pods --no-trunc | grep $hash | awk '{print $1}') ]; then
        grep -ilr $hash ./ | xargs rm
    fi;
done
cd ${cur_dir}
