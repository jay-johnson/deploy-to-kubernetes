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

pg_service_name="primary"
pg_deployment_dir="$(pwd)/postgres/.pgdeployment"
pg_repo="https://github.com/CrunchyData/crunchy-containers.git"
include_pgadmin="1"

should_cleanup_before_startup=0
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "nfs" ]]; then
        storage_type="nfs"
    elif [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    fi
done

if [[ "${storage_type}" == "nfs" ]]; then
    if [[ "${CCP_NFS_IP}" == "" ]]; then
        if [[ -e ./tools/get-nfs-ip.sh ]]; then
            export CCP_NFS_IP=$(./tools/get-nfs-ip.sh)
        else
            export CCP_NFS_IP="localhost"
        fi
    fi
fi

if [[ "${CCP_NAMESPACE}" == "" ]]; then
    export CCP_NAMESPACE="default"
fi
export CCPROOT=${pg_deployment_dir}

anmt "--------------------------------------------------"
if [[ "${storage_type}" == "ceph" ]]; then
    # https://github.com/CrunchyData/crunchy-containers/blob/2188a6ac5338d47fa0fa31f16a8f3a2e6e3f2db2/examples/kube/primary/primary-pvc-sc.json
    export CCP_STORAGE_CLASS="rook-ceph-block"
    export CCP_STORAGE_CAPACITY="5gi"
    export CCP_SECURITY_CONTEXT='"fsGroup":0'
    anmt "deploying postgres single primary database on rook ceph: ${pg_repo}"
    warn "storage class: ${CCP_STORAGE_CLASS}"
    warn "storage capacity: ${CCP_STORAGE_CAPACITY}"
else
    anmt "deploying postgres single primary database: ${pg_repo}"
fi
inf ""

source ./postgres/primary-db-${storage_type}.sh
test_svc_pg_exists=$(kubectl get pods | grep primary | wc -l)
if [[ "${test_svc_pg_exists}" == "0" ]]; then
    if [[ ! -e ${pg_deployment_dir}/examples/kube/primary/primary.json ]]; then
        good "Installing Crunchy Containers Repository with command:"
        inf "git clone ${pg_repo} ${pg_deployment_dir}"
        git clone ${pg_repo} ${pg_deployment_dir}
        if [[ ! -e ${pg_deployment_dir}/examples/kube/primary/primary.json ]]; then
            err "Failed to clone Crunchy Postgres Deployment repository to: ${pg_deployment_dir} - please confirm it exists"
            ls -lrt ${pg_deployment_dir}
            inf ""
            err "Tried cloning repository to deployment directory with command:"
            inf "git clone ${pg_repo} ${pg_deployment_dir}"
            inf ""
            exit 1
        else
            good "Installed Crunchy Containers"
        fi
    else
        pushd ${pg_deployment_dir}
        git checkout ./examples/kube/primary/primary.json
        git checkout ./examples/kube/pgadmin4-http/pgadmin4-http.json
        git pull
        popd
    fi
    cp postgres/crunchy-template.json ${pg_deployment_dir}/examples/kube/primary/primary.json
    pushd ${pg_deployment_dir}/examples/kube/primary
    ./run.sh
    popd
else
    inf "Detected running Crunchy Postgres Database: svc/${pg_service_name}"
fi

inf ""
inf "Checking if Postgres Database is ready"
inf ""

not_done=1
while [[ "${not_done}" == "1" ]]; do
    test_pg_svc=$(kubectl get services | grep 'primary' | wc -l)
    if [[ "${test_pg_svc}" != "0" ]]; then
        inf "Exposing Postgres Database service"
        kubectl expose service primary --type=LoadBalancer --name=postgres-primary
        inf ""
        not_done="0"
    fi
    sleep 1
done

if [[ -e ./api/show-migrate-cmds.sh ]]; then
    inf "------------------------"
    inf "If you need to run a database migration you can use:"
    inf "./api/show-migrate-cmds.sh"
    inf ""
    inf "which should show the commands to perform the migration:"
    ./api/show-migrate-cmds.sh
    inf "------------------------"
    inf ""
fi

good "done deploying: postgres"

exit 0
