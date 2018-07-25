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

extra_params=""
if [[ "${SPLUNK_USER}" != "" ]] && [[ "${SPLUNK_PASSWORD}" != "" ]] && [[ "${SPLUNK_TCP_ADDRESS}" != "" ]]; then
    extra_params="splunk"
elif [[ "${1}" == "splunk" ]]; then
    extra_params="splunk"
elif [[ "${1}" == "splunk/" ]]; then
    extra_params="splunk"
fi

anmt "starting postgres"
./postgres/run.sh

anmt "starting pgadmin"
./pgadmin/run.sh 

anmt "starting ingress"
./ingress/run.sh 

anmt "starting redis"
./redis/run.sh 

for param in $extra_params; do
    if [[ "${param}"  == "splunk" ]]; then
        anmt "starting splunk"
        ./splunk/run.sh
    fi
done

exit 0
