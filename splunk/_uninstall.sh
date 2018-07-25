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

warn "------------------------------------------"
warn "deleting splunk"
inf ""

good "kubectl delete ingresses: splunk-ingress splunk-web-ingress splunk-tcp-ingress"
kubectl delete ingress splunk-ingress
kubectl delete ingress splunk-tcp-ingress
kubectl delete ingress splunk-web-ingress
inf ""

good "kubectl delete services: splunk-svc splunk-web-svc splunk-tcp-svc"
kubectl delete svc splunk-svc
kubectl delete svc splunk-web-svc
kubectl delete svc splunk-tcp-svc
inf ""

good "kubectl delete deployment: splunk"
kubectl delete deployment splunk
inf ""

inf "deleting secrets: splunk-secrets"
kubectl delete secret splunk-secrets
inf ""

good "done deleting: splunk"
