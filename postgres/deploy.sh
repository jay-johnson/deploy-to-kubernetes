#!/bin/bash

pg_service_name="primary"
pg_deployment_dir="$(pwd)/postgres/.pgdeployment"
pg_repo="https://github.com/jay-johnson/crunchy-containers.git"
include_pgadmin="1"

if [[ "${CCP_NFS_IP}" == "" ]]; then
    if [[ -e ./tools/get-nfs-ip.sh ]]; then
        export CCP_NFS_IP=$(./tools/get-nfs-ip.sh)
    else
        export CCP_NFS_IP="localhost"
    fi
fi
if [[ "${CCP_NAMESPACE}" == "" ]]; then
    export CCP_NAMESPACE="default"
fi
export CCPROOT=${pg_deployment_dir}

echo "Deploying Crunchy Postgres Single Primary Database"
source ./postgres/primary-db.sh
test_svc_pg_exists=$(kubectl get pods | grep primary | wc -l)
if [[ "${test_svc_pg_exists}" == "0" ]]; then
    if [[ ! -e ${pg_deployment_dir}/examples/kube/primary/primary.json ]]; then
        echo "Installing Crunchy Containers Repository with command:"
        echo "git clone ${pg_repo} ${pg_deployment_dir}"
        git clone ${pg_repo} ${pg_deployment_dir}
        if [[ ! -e ${pg_deployment_dir}/examples/kube/primary/primary.json ]]; then
            echo "Failed to clone Crunchy Postgres Deployment repository to: ${pg_deployment_dir} - please confirm it exists"
            ls -lrt ${pg_deployment_dir}
            echo ""
            echo "Tried cloning repository to deployment directory with command:"
            echo "git clone ${pg_repo} ${pg_deployment_dir}"
            echo ""
            exit 1
        else
            echo "Installed Crunchy Containers"
        fi
    else
        pushd ${pg_deployment_dir}
        git checkout ./examples/kube/primary/primary.json
        git pull
        popd
    fi
    cp postgres/crunchy-template.json ${pg_deployment_dir}/examples/kube/primary/primary.json
    pushd ${pg_deployment_dir}/examples/kube/primary
    ./run.sh
    popd
else
    echo "Detected running Crunchy Postgres Database: svc/${pg_service_name}"
fi

echo ""
echo "Checking if Postgres Database is ready"
echo ""

not_done=1
while [[ "${not_done}" == "1" ]]; do
    test_pg_svc=$(kubectl get services | grep 'primary' | wc -l)
    if [[ "${test_pg_svc}" != "0" ]]; then
        echo "Exposing Postgres Database service"
        kubectl expose svc/primary
        echo ""
        not_done="0"
    fi
    sleep 1
done

if [[ -e ./api/show-migrate-cmds.sh ]]; then
    echo "------------------------"
    echo "If you need to run a database migration you can use:"
    echo "./api/show-migrate-cmds.sh"
    echo ""
    echo "which should show the commands to perform the migration:"
    ./api/show-migrate-cmds.sh
    echo "------------------------"
    echo ""
fi

exit 0
