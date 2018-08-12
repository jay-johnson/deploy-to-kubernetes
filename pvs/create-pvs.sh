#!/bin/bash

# use the bash_colors.sh file
found_colors="./tools/bash_colors.sh"
up_found_colors="./tools/bash_colors.sh"
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

user_test=$(whoami)
if [[ "${user_test}" != "root" ]]; then
    err "please run as root"
    exit 1
fi

should_cleanup_before_startup=1
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
pv_deployment_type="all-pvs"
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "nfs" ]]; then
        storage_type="nfs"
    elif [[ "${i}" == "all-pvs" ]]; then
        pv_deployment_type="all-pvs"
    elif [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    fi
done

# install nfs and create volumes
function install_nfs() {

    inf ""
    inf "------------------------------------------------"
    inf "installing NFS for persistent volumes"
    inf ""

    restart_nfs=0
    project_dir=/data/k8
    install_check=$(dpkg -l | grep nfs-common | wc -l)
    if [[ "${install_check}" == "0" ]]; then
        inf "installing nfs-common"
        apt-get install nfs-common
        restart_nfs=1
    fi
    install_check=$(dpkg -l | grep nfs-kernel-server | wc -l)
    if [[ "${install_check}" == "0" ]]; then
        inf "installing nfs-kernel-server"
        apt-get install nfs-kernel-server
        restart_nfs=1
    fi

    if [[ ! -e ${project_dir}/postgres ]]; then
        mkdir -p -m 777 ${project_dir}/postgres
        inf "installing nfs mounts: postgres"
        chown nobody:nogroup ${project_dir}/postgres
        restart_nfs=1
    fi

    if [[ ! -e ${project_dir}/pgadmin ]]; then
        inf "installing nfs mounts: pgadmin"
        mkdir -p -m 777 ${project_dir}/pgadmin
        chown nobody:nogroup ${project_dir}/pgadmin
        restart_nfs=1
    fi

    if [[ ! -e ${project_dir}/redis ]]; then
        inf "installing nfs mounts: redis"
        mkdir -p -m 777 ${project_dir}/redis
        chown nobody:nogroup ${project_dir}/redis
        restart_nfs=1
    fi

    test_pgadmin_nfs=$(cat /etc/exports | grep k8 | grep pgadmin | grep 10.0.0.0 | wc -l)
    if [[ "${test_pgadmin_nfs}" == "0" ]]; then
        inf "installing 10.0.0.0 nfs mounts for pgadmin"
        echo '/data/k8/pgadmin 10.0.0.0/24(rw,sync,no_subtree_check)' >> /etc/exports
        restart_nfs=1
    fi
    test_pgadmin_nfs=$(cat /etc/exports | grep k8 | grep pgadmin | grep localhost | wc -l)
    if [[ "${test_pgadmin_nfs}" == "0" ]]; then
        inf "installing localhost nfs mounts for pgadmin"
        echo '/data/k8/pgadmin localhost(rw,sync,no_subtree_check)' >> /etc/exports
        restart_nfs=1
    fi

    test_postgres_nfs=$(cat /etc/exports | grep k8 | grep postgres | grep 10.0.0.0 | wc -l)
    if [[ "${test_postgres_nfs}" == "0" ]]; then
        inf "installing 10.0.0.0 nfs mounts for postgres"
        echo '/data/k8/postgres 10.0.0.0/24(rw,sync,no_subtree_check)' >> /etc/exports
        restart_nfs=1
    fi
    test_postgres_nfs=$(cat /etc/exports | grep k8 | grep postgres | grep localhost | wc -l)
    if [[ "${test_postgres_nfs}" == "0" ]]; then
        inf "installing localhost nfs mounts for postgres"
        echo '/data/k8/postgres localhost(rw,sync,no_subtree_check)' >> /etc/exports
        restart_nfs=1
    fi

    test_redis_nfs=$(cat /etc/exports | grep k8 | grep redis | grep 10.0.0.0 | wc -l)
    if [[ "${test_redis_nfs}" == "0" ]]; then
        inf "installing 10.0.0.0 nfs mounts for redis"
        echo '/data/k8/redis 10.0.0.0/24(rw,sync,no_subtree_check)' >> /etc/exports
        restart_nfs=1
    fi
    test_redis_nfs=$(cat /etc/exports | grep k8 | grep redis | grep localhost | wc -l)
    if [[ "${test_redis_nfs}" == "0" ]]; then
        inf "installing localhost nfs mounts for redis"
        echo '/data/k8/redis localhost(rw,sync,no_subtree_check)' >> /etc/exports
        restart_nfs=1
    fi

    if [[ "${restart_nfs}" == "1" ]]; then
        inf "enabling nfs server for reboots"
        systemctl enable nfs-kernel-server
        inf "restarting nfs server"
        systemctl restart nfs-kernel-server
    fi
}

# install Rook Operator and Storage Cluser for Persistent Volumes
function install_rook_with_ceph() {
    inf ""
    inf "------------------------------------------------"
    inf "installing Rook with Ceph for persistent volumes"
    inf ""
    storage_type=${1}
    cert_env=${2}
    clean_up_at_start=${3}
    if [[ "${clean_up_at_start}" == "1" ]]; then
        if [[ -e /var/lib/rook ]]; then
            inf "cleaning /var/lib/rook at startup"
            rm -rf /var/lib/rook
            inf ""
        fi
        ./rook/run.sh ${storage_type} ${cert_env} clean_on_start
    else
        ./rook/run.sh ${storage_type} ${cert_env}
    fi
    inf ""

    if [[ "${pv_deployment_type}" == "all-pvs" ]]; then
        inf "deploying all persistent volumes"
        inf ""
        inf "creating certs volume: ./pvs/pv-certs-${storage_type}.yml"
        kubectl apply -f ./pvs/pv-certs-${storage_type}.yml
        inf ""
        inf "creating configs volume: ./pvs/pv-configs-${storage_type}.yml"
        kubectl apply -f ./pvs/pv-configs-${storage_type}.yml
        inf ""
        inf "creating data science volume: ./pvs/pv-datascience-${storage_type}.yml"
        kubectl apply -f ./pvs/pv-datascience-${storage_type}.yml
        inf ""
        inf "creating frontend shared volume: ./pvs/pv-frontendshared-${storage_type}.yml"
        kubectl apply -f ./pvs/pv-frontendshared-${storage_type}.yml
        inf ""
        inf "creating static files volume: ./pvs/pv-staticfiles-${storage_type}.yml"
        kubectl apply -f ./pvs/pv-staticfiles-${storage_type}.yml
        inf ""
        inf "checking persistent volumes"
        kubectl get pv
        inf ""
        inf "checking persistent volume claims"
        kubectl get pvc
        inf ""
    fi

    if [[ "${storage_type}" == "cephs3" ]]; then
        chmod 666 ./rook/envs/*.env
        chmod 666 ./rook/secrets/*.json
    fi
    chmod 666 ./rook/secrets/*.yml
}

if [[ "${storage_type}" == "ceph" ]]; then
    install_rook_with_ceph ${storage_type} ${cert_env} ${should_cleanup_before_startup}
elif [[ "${storage_type}" == "cephs3" ]]; then
    install_rook_with_ceph ${storage_type} ${cert_env} ${should_cleanup_before_startup}
else
    install_nfs
fi

good "done creating persistent volumes for storage_type: ${storage_type}"

exit 0
