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

inf ""
anmt "----------------------------------------------"
good "Getting all Ceph reports:"

use_path="./"
if [[ -e ./ceph/show-ceph-status.sh ]]; then
    use_path="./ceph"
fi

files="show-ceph-status.sh show-ceph-rados-df.sh show-ceph-df.sh show-ceph-osd-status.sh show-pods.sh"
for f in ${files}; do
    ${use_path}/${f}
done
