# https://crunchydata.github.io/crunchy-containers/getting-started/kubernetes-and-openshift/#_single_primary
# sudo apt install golang-go
# go get github.com/blang/expenv
# mkdir -p -m 777 /opt/antinex
# git clone https://github.com/CrunchyData/crunchy-containers.git /opt/antinex/crunchy
# on ubuntu 18.04:
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

export PROJECT="default"
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
if [[ "${CCPROOT}" == "" ]]; then
    export CCPROOT="$(pwd)/.pgdeployment"
fi
export CCP_IMAGE_PREFIX="crunchydata"
export CCP_IMAGE_TAG="centos7-10.4-1.8.3"
export CCP_PGADMIN_IMAGE_TAG="centos7-10.3-1.8.2"
export CCP_CLI="kubectl"
export CCP_SECURITY_CONTEXT='"supplementalGroups": [65534]'
export CCP_STORAGE_PATH="/data/k8/postgres"
export CCP_STORAGE_MODE="ReadWriteMany"
export CCP_STORAGE_CAPACITY="400M"

export PG_DEPLOYMENT_DIR="${CCPROOT}"
export PG_USER="antinex"
export PG_PASSWORD="antinex"
export PG_DATABASE="webapp"
export PG_PRIMARY_PASSWORD="123321"
export PG_SVC_NAME="primary"
export PG_REPO="https://github.com/CrunchyData/crunchy-containers.git"

export PGADMIN_DEPLOYMENT_DIR="${CCPROOT}"
export PGADMIN_REPO="https://github.com/CrunchyData/crunchy-containers.git"
export PGADMIN_SVC_NAME="pgadmin4-http"
export PGADMIN_SETUP_EMAIL="admin@admin.com"
export PGADMIN_SETUP_PASSWORD="123321"
