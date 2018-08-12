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

should_cleanup_before_startup=0
cert_env="dev"
storage_type="ceph"
for i in "$@"
do
    if [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "nfs" ]]; then
        storage_type="nfs"
    elif [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    fi
done

pg_service_name="pgadmin4-http"
pg_deployment_dir="$(pwd)/postgres/.pgdeployment"
pg_repo="https://github.com/CrunchyData/crunchy-containers.git"

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

anmt "----------------------------------------------------------------------------------"
if [[ "${storage_type}" == "ceph" ]]; then
    # https://github.com/CrunchyData/crunchy-containers/blob/2188a6ac5338d47fa0fa31f16a8f3a2e6e3f2db2/examples/kube/pgadmin4-http/pgadmin4-http-pvc-sc.json
    export CCP_STORAGE_CLASS="rook-ceph-block"
    anmt "deploying pgAdmin4 with cert_env=${cert_env}: ${pg_repo}"
    warn "storage class: ${CCP_STORAGE_CLASS}"
else
    anmt "deploying pgAdmin4 with cert_env=${cert_env}: ${pg_repo}"
fi
inf ""
    
inf "applying secrets: ./pgadmin/secrets.yml" 
kubectl apply -f ./pgadmin/secrets.yml
inf ""

source ./postgres/primary-db-${storage_type}.sh
test_svc_pg_exists=$(kubectl get pods | grep ${pg_service_name} | wc -l)
if [[ "${test_svc_pg_exists}" == "0" ]]; then
    if [[ ! -e ${pg_deployment_dir}/examples/kube/${pg_service_name}/pgadmin4-http.json ]]; then
        good "Installing Crunchy Containers Repository with command:"
        inf "git clone ${pg_repo} ${pg_deployment_dir}"
        git clone ${pg_repo} ${pg_deployment_dir}
        if [[ ! -e ${pg_deployment_dir}/examples/kube/${pg_service_name}/pgadmin4-http.json ]]; then
            err "Failed to clone Crunchy pgAdmin Deployment repository to: ${pg_deployment_dir} - please confirm it exists"
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
        git checkout ./examples/kube/${pg_service_name}/pgadmin4-http.json
        git checkout ./examples/kube/primary/primary.json
        git pull
        popd
    fi

    inf "${pg_service_name} - installing deployment"
    cp ./pgadmin/crunchy-template-http.json ${pg_deployment_dir}/examples/kube/${pg_service_name}/pgadmin4-http.json
    pushd ${pg_deployment_dir}/examples/kube/${pg_service_name}
    ./run.sh
    popd
else
    inf "Detected running Crunchy pgAdmin: svc/${pg_service_name}"
fi

inf "applying ingress cert_env: ${cert_env} with ./pgadmin/ingress-${cert_env}.yml" 
kubectl apply -f ./pgadmin/ingress-${cert_env}.yml
inf ""

inf ""
inf "Checking if pgAdmin is ready"
inf ""

not_done=0
while [[ "${not_done}" == "1" ]]; do
    test_pg_svc=$(kubectl get services | grep ${pg_service_name} | wc -l)
    if [[ "${test_pg_svc}" != "0" ]]; then
        inf "Exposing pgAdmin service: ${pg_service_name}"
        kubectl expose service ${pg_service_name} --type=LoadBalancer --name=pgadmin
        inf ""
        not_done="0"
    fi
    sleep 1
done

good "done deploying: pgAdmin"
