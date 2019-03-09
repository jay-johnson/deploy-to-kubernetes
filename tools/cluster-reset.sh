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

test_user=$(whoami)
if [[ "${test_user}" != "root" ]]; then
    err "please run as root"
    exit 1
fi

warn "---------------------------------------------"

if [[ "${NO_SLEEP_ON_RESET}" != "" ]]; then
    inf ""
    warn "About to reset kubernetes cluster"
    warn " - sleeping for 10 seconds in case you want to cancel"
    sleep 10
else
    warn "Resetting kubernetes cluster"
fi

inf "running: kubeadm reset -f"
kubeadm reset -f

if [[ "${1}" == "clean" ]]; then
    inf "running: ./prepare.sh clean"
    ./prepare.sh clean
else
    inf "running: ./prepare.sh splunk ceph"
    ./prepare.sh splunk ceph
fi
