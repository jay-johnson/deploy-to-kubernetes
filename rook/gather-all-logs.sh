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

new_logs_zip=/tmp/rook-logs.gz

anmt "----------------------------"
anmt "Gathering all Rook Ceph logs"

all_pods=""
# https://github.com/rook/rook/blob/764781d7da39f125407d33f62778d30c4dd4f545/Documentation/advanced-configuration.md#log-collection
(for p in $(kubectl -n rook-ceph get pods -o jsonpath='{.items[*].metadata.name}')
do
    for c in $(kubectl -n rook-ceph get pod ${p} -o jsonpath='{.spec.containers[*].name}')
    do
        echo ""
        anmt "BEGIN logs from pod: ${p} ${c}"
        kubectl -n rook-ceph logs -c ${c} ${p}
        good "END logs from pod: ${p} ${c}"
        echo ""
        all_pods="${p} ${all_pods}"
    done
done
for i in $(kubectl -n rook-ceph-system get pods -o jsonpath='{.items[*].metadata.name}')
do
    echo ""
    anmt "BEGIN logs from pod: ${i}"
    kubectl -n rook-ceph-system logs ${i}
    good "END logs from pod: ${i}"
    echo ""
    all_pods="${p} ${all_pods}"
# done) | gzip > ${new_logs_zip}
done
echo ""
echo "kubetail -f ${all_pods}") > ${new_logs_zip}

inf ""
anmt "---------------"
anmt "Rook Ceph logs:"
cat ${new_logs_zip}
inf ""
inf "view the logs again with:"
good "cat ${new_logs_zip}"

