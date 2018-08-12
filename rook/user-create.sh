#!/bin/bash

# usage: user-create.sh <optional - username> <optional - name for files like default-ceph-user>

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

use_namespace="rook-minio"
app_name=""
username="trex"
display_name="trex"
password="123321"
use_basename="default-user"
object_store="minio"
debug="0"
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "cephs3" ]]; then
        object_store="ceph"
    elif [[ "${i}" == "-d" ]]; then
        debug="1"
    elif [[ "${i}" == "clean_on_start" ]]; then
        should_cleanup_before_startup="1"
    elif [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    fi
done

if [[ "${1}" != "" ]]; then
    username="${1}"
    display_name="${1}"
fi

if [[ "${2}" != "" ]]; then
    use_basename="${2}"
else
    use_basename="${username}"
fi

if [[ "${3}" != "" ]]; then
    password="${3}"
else
    password="${password}"
fi

json_filename="${use_basename}.json"
secret_filename="${use_basename}.yml"
external_env_filename="ext-${use_basename}.env"
internal_env_filename="${use_basename}.env"

use_path="."
if [[ -e ./rook/ceph/operator.yml ]]; then
    use_path="./rook"
fi
secrets_path="${use_path}/secrets"
env_dir_path="${use_path}/envs"

json_file="${secrets_path}/${json_filename}"
target_file_path="${secrets_path}/${secret_filename}"
external_env_file="${env_dir_path}/${external_env_filename}"
internal_env_file="${env_dir_path}/${internal_env_filename}"

if [[ "${object_store}" == "ceph" ]]; then
    # http://docs.ceph.com/docs/giant/radosgw/admin/
    # echo "kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c \"radosgw-admin user create --uid ${username} --display-name \"${display_name}\" --rgw-realm=s3-storage --rgw-zonegroup=s3-storage\""
    kubectl exec -n rook-ceph -it rook-ceph-tools -- /bin/bash -c "radosgw-admin user create --uid ${username} --display-name \"${display_name}\" --rgw-realm=s3-storage --rgw-zonegroup=s3-storage" | sed -e "s|\n||g" > ${json_file}

    if [[ -e ${json_file} ]]; then
        username=$(cat ${json_file} | sed -e 's/"/ /g' | grep user_id | awk '{print $3}'| sed -e "s|\n||g")
        user_access_key=$(cat ${json_file} | sed -e 's/"/ /g' | grep access_key | awk '{print $3}'| sed -e "s|\n||g")
        user_secret_key=$(cat ${json_file} | sed -e 's/"/ /g' | grep secret_key | awk '{print $3}'| sed -e "s|\n||g")
        internal_cluster_host="rook-ceph-rgw-s3-storage.rook-ceph"
        internal_cluster_endpoint=$(${use_path}/get-ceph-s3-endpoint.sh | sed -e "s|\n||g")
        external_cluster_endpoint=$(${use_path}/get-ceph-s3-endpoint.sh | sed -e "s|\n||g")
        external_cluster_host=$(${use_path}/get-ceph-s3-endpoint.sh clusterip | sed -e "s|\n||g")

        encoded_username=$(echo -n "${username}" | base64)
        encoded_password=$(echo -n "${password}" | base64)
        encoded_access_key=$(echo -n "${user_access_key}" | base64)
        encoded_secret_key=$(echo -n "${user_secret_key}" | base64)
        encoded_internal_host=$(echo -n "${internal_cluster_host}" | base64)
        encoded_internal_endpoint=$(echo -n "${internal_cluster_endpoint}" | base64)
        encoded_external_host=$(echo -n "${external_cluster_host}" | base64)
        encoded_external_endpoint=$(echo -n "${external_cluster_endpoint}" | base64)

        cp ${secrets_path}/sample-secrets.yml ${target_file_path}
        
        echo "  username: ${encoded_username}" >> ${target_file_path}
        echo "  password: ${encoded_password}" >> ${target_file_path}
        echo "  access_key: ${encoded_access_key}" >> ${target_file_path}
        echo "  secret_key: ${encoded_secret_key}" >> ${target_file_path}
        echo "  internal_host: ${encoded_internal_host}" >> ${target_file_path}
        echo "  internal_endpoint: ${encoded_internal_endpoint}" >> ${target_file_path}
        echo "  external_host: ${encoded_external_host}" >> ${target_file_path}
        echo "  external_endpoint: ${encoded_external_endpoint}" >> ${target_file_path}

        test_exists=$(kubectl get secrets --ignore-not-found | grep rook.s3.user | wc -l)
        if [[ "${test_exists}" != "0" ]]; then
            kubectl delete secret rook.s3.user
        fi
        good "applying secret: rook.s3.user from secret file: ${target_file_path}"
        kubectl apply -f ${target_file_path}
        inf ""

        anmt "--------------------------------------------------------"
        anmt "Use the External Cluster S3 Endpoint with NodePort with:"
        inf ""
        echo "export AWS_ACCESS_KEY_ID=${user_access_key}" > ${external_env_file}
        echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}" >> ${external_env_file}
        echo "export AWS_HOST=${internal_cluster_host}" >> ${external_env_file}
        echo "export AWS_ENDPOINT=${internal_cluster_endpoint}" >> ${external_env_file}

        echo "source ${external_env_file}"
        echo "# or manually with:"
        echo "export AWS_ACCESS_KEY_ID=${user_access_key}"
        echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}"
        echo "export AWS_HOST=${external_cluster_host}"
        echo "export AWS_ENDPOINT=${external_cluster_endpoint}"
        inf ""

        anmt "--------------------------------------------------------"
        anmt "Use the Internal Cluster S3 Endpoint ClusterIP with:"
        inf ""
        echo "export AWS_ACCESS_KEY_ID=${user_access_key}" > ${internal_env_file}
        echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}" >> ${internal_env_file}
        echo "export AWS_HOST=${internal_cluster_host}" >> ${internal_env_file}
        echo "export AWS_ENDPOINT=${internal_cluster_endpoint}" >> ${internal_env_file}

        echo "source ${internal_env_file}"
        echo "# or manually with:"
        echo "export AWS_ACCESS_KEY_ID=${user_access_key}"
        echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}"
        echo "export AWS_HOST=${internal_cluster_host}"
        echo "export AWS_ENDPOINT=${internal_cluster_endpoint}"
        inf ""
    fi
else
    internal_cluster_host="rook-minigo-rgw-s3-storage"
    internal_cluster_endpoint=$(${use_path}/get-minio-s3-endpoint.sh | sed -e "s|\n||g")
    external_cluster_endpoint=$(${use_path}/get-minio-s3-endpoint.sh | sed -e "s|\n||g")
    external_cluster_host=$(${use_path}/get-minio-s3-endpoint.sh clusterip | sed -e "s|\n||g")

    encoded_username=$(echo -n "${username}" | base64)
    encoded_password=$(echo -n "${password}" | base64)
    encoded_internal_host=$(echo -n "${internal_cluster_host}" | base64)
    encoded_internal_endpoint=$(echo -n "${internal_cluster_endpoint}" | base64)
    encoded_external_host=$(echo -n "${external_cluster_host}" | base64)
    encoded_external_endpoint=$(echo -n "${external_cluster_endpoint}" | base64)

    cp ${secrets_path}/sample-secrets.yml ${target_file_path}
    
    echo "  username: ${encoded_username}" >> ${target_file_path}
    echo "  password: ${encoded_password}" >> ${target_file_path}
    echo "  internal_host: ${encoded_internal_host}" >> ${target_file_path}
    echo "  internal_endpoint: ${encoded_internal_endpoint}" >> ${target_file_path}
    echo "  external_host: ${encoded_external_host}" >> ${target_file_path}
    echo "  external_endpoint: ${encoded_external_endpoint}" >> ${target_file_path}

    test_exists=$(kubectl get secrets --ignore-not-found | grep rook.s3.user | wc -l)
    if [[ "${test_exists}" != "0" ]]; then
        kubectl delete secret rook.s3.user
    fi
    good "applying secret: rook.s3.user from secret file: ${target_file_path}"
    kubectl apply -f ${target_file_path}
    inf ""

    anmt "--------------------------------------------------------"
    anmt "Use the External Cluster S3 Endpoint with NodePort with:"
    inf ""
    echo "export AWS_ACCESS_KEY_ID=${user_access_key}" > ${external_env_file}
    echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}" >> ${external_env_file}
    echo "export AWS_HOST=${internal_cluster_host}" >> ${external_env_file}
    echo "export AWS_ENDPOINT=${internal_cluster_endpoint}" >> ${external_env_file}

    echo "source ${external_env_file}"
    echo "# or manually with:"
    echo "export AWS_ACCESS_KEY_ID=${user_access_key}"
    echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}"
    echo "export AWS_HOST=${external_cluster_host}"
    echo "export AWS_ENDPOINT=${external_cluster_endpoint}"
    inf ""

    anmt "--------------------------------------------------------"
    anmt "Use the Internal Cluster S3 Endpoint ClusterIP with:"
    inf ""
    echo "export AWS_ACCESS_KEY_ID=${user_access_key}" > ${internal_env_file}
    echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}" >> ${internal_env_file}
    echo "export AWS_HOST=${internal_cluster_host}" >> ${internal_env_file}
    echo "export AWS_ENDPOINT=${internal_cluster_endpoint}" >> ${internal_env_file}

    echo "source ${internal_env_file}"
    echo "# or manually with:"
    echo "export AWS_ACCESS_KEY_ID=${user_access_key}"
    echo "export AWS_SECRET_ACCESS_KEY=${user_secret_key}"
    echo "export AWS_HOST=${internal_cluster_host}"
    echo "export AWS_ENDPOINT=${internal_cluster_endpoint}"
    inf ""
fi
