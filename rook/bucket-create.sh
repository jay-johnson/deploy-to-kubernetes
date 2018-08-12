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

bucket="common"
use_namespace="rook-ceph"
app_name=""
username="trex"
display_name="trex"
use_basename="default-ceph-user"

if [[ "${1}" != "" ]]; then
    bucket="${1}"
fi
if [[ "${2}" != "" ]]; then
    use_basename="${2}"
else
    use_basename="${username}"
fi

use_path="."
if [[ -e ./rook/ceph/operator.yml ]]; then
    use_path="./rook"
fi

json_filename="${use_basename}.json"
secret_filename="${use_basename}.yml"
external_env_filename="ext-${use_basename}.env"
internal_env_filename="${use_basename}.env"

secrets_path="${use_path}/secrets"
env_dir_path="${use_path}/envs"

json_file="${secrets_path}/${json_filename}"
target_file_path="${secrets_path}/${secret_filename}"
external_env_file="${env_dir_path}/${external_env_filename}"
internal_env_file="${env_dir_path}/${internal_env_filename}"

anmt "------------------------------------"
anmt "creating s3 bucket ${bucket} in ceph"
inf ""

path_to_env_file=${internal_env_file}

if [[ -e ${path_to_env_file} ]]; then
    inf "copying credentials into rook-ceph-tools pod: kubectl cp ${path_to_env_file} rook-ceph/rook-ceph-tools:/creds"
    kubectl cp ${path_to_env_file} rook-ceph/rook-ceph-tools:/creds
    echo "kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c '. /creds && s3cmd mb --no-ssl --host=\${AWS_HOST} --host-bucket=  s3://${bucket}'"
    kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c "echo 'starting' && . /creds && s3cmd mb --no-ssl --host=\${AWS_HOST} --host-bucket=  s3://${bucket}"
    inf ""
else
    err "failed to find valid rook s3 user env file at path: ${path_to_env_file}"
fi
