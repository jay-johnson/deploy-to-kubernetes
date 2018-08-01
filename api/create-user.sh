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

user="trex"
pw="123321"
email="bugs@antinex.com"
firstname="Guest"
lastname="Guest"
base_url="https://api.example.com"
auth_url="${base_url}/users/"
token_url="${base_url}/api-token-auth/"

if [[ "${1}" != "" ]]; then
    user=${1}
fi
if [[ "${API_USER}" != "" ]]; then
    user=${API_USER}
fi

if [[ "${2}" != "" ]]; then
    pw=${2}
fi
if [[ "${API_PASSWORD}" != "" ]]; then
    pw=${API_PASSWORD}
fi

if [[ "${3}" != "" ]]; then
    email=${3}
fi
if [[ "${API_EMAIL}" != "" ]]; then
    email=${API_EMAIL}
fi

if [[ "${4}" != "" ]]; then
    firstname=${4}
fi
if [[ "${API_FIRSTNAME}" != "" ]]; then
    firstname=${API_FIRSTNAME}
fi

if [[ "${5}" != "" ]]; then
    lastname=${5}
fi
if [[ "${API_LASTNAME}" != "" ]]; then
    lastname=${API_LASTNAME}
fi

if [[ "${API_URL}" != "" ]]; then
    base_url=${API_URL}
fi

user_login_dict="{\"username\":\"${user}\",\"password\":\"${pw}\",\"email\":\"${email}\",\"first\":\"${firstname}\",\"last\":\"${lastname}\"}"

good "Creating user: ${user} on ${auth_url}"
curl -k -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "${user_login_dict}" ${auth_url}
last_status=$?
if [[ "${last_status}" != 0 ]]; then
    inf ""
    err "Failed adding user ${user} with command:"
    inf "curl -k -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '${user_login_dict}' ${auth_url}"
    inf ""
    exit 1
fi

inf ""
inf "Getting token for user: ${user}"
curl -k -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d "${user_login_dict}" "${token_url}"
last_status=$?
if [[ "${last_status}" != 0 ]]; then
    inf ""
    err "Failed getting user ${user} token with command:"
    inf "curl -k -s -ii -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '${user_login_dict}' ${token_url}"
    inf ""
    exit 1
fi

inf ""
good "done creating user: ${user} on ${base_url}"

exit 0
