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

use_namespace="ceph"

anmt "--------------------------------------------------"
good "Checking Ceph OSD Pod Mountpoints for /dev/vdb1:"
inf ""
found_failure="0"
osd_pods=$(kubectl get po -n ${use_namespace} | grep osd | awk '{print $1}' | grep -v keyring | sort)
command_to_run="-- df -h /var/lib/ceph/"
for osd in ${osd_pods}; do
    anmt "checking: ${osd}"
    anmt "kubectl -n ${use_namespace} exec -it ${osd} ${command_to_run}"
    found_mount=$(kubectl -n ${use_namespace} exec -it ${osd} ${command_to_run} | grep -v Filesystem | awk '{print $1}')
    if [[ "${found_mount}" != "/dev/vdb1" ]]; then
        err "failed: ${osd} is using ${found_mount}"
        found_failure="1"
    else
        good "confirmed: ${osd} is using ${found_mount}"
    fi
done

if [[ "${found_failure}" == "1" ]]; then
    critical "detected at least one Ceph OSD mount failure"
    critical "Please review the Ceph debugging guide: https://deploy-to-kubernetes.readthedocs.io/en/latest/ceph.html#confirm-ceph-osd-pods-are-using-the-kvm-mounted-disks for more details on how to fix this issue"
    exit 1
else
    good "all Ceph OSD pods: ${osd_pods} are using /dev/vbd1 for storage"
fi

exit 1
