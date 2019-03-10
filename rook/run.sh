#!/bin/bash

# use the bash_colors.sh file
if [[ -e /opt/deploy-to-kubernetes/tools/bash_colors.sh ]]; then
    source /opt/deploy-to-kubernetes/tools/bash_colors.sh
elif [[ -e ./tools/bash_colors.sh ]]; then
    source ./tools/bash_colors.sh
elif [[ -e ../tools/bash_colors.sh ]]; then
    source ../tools/bash_colors.sh
fi

should_cleanup_before_startup=0
deploy_suffix=""
cert_env="dev"
storage_type="ceph"
object_store=""
username="trex"
display_name="trex"
debug="0"
dashboard_enabled="1"
for i in "$@"
do
    if [[ "${i}" == "prod" ]]; then
        cert_env="prod"
    elif [[ "${i}" == "ceph" ]]; then
        storage_type="ceph"
    elif [[ "${i}" == "cephs3" ]]; then
        storage_type="ceph"
        object_store="ceph"
    elif [[ "${i}" == "minio" ]]; then
        storage_type="ceph"
        object_store="rook-minio"
    elif [[ "${i}" == "-d" ]]; then
        debug="1"
    elif [[ "${i}" == "clean_on_start" ]]; then
        should_cleanup_before_startup="1"
    elif [[ "${i}" == "splunk" ]]; then
        deploy_suffix="-splunk"
    elif [[ "${i}" == "-nodashboard" ]]; then
        dashboard_enabled="0"
    elif [[ "${i}" == "antinex" ]]; then
        cert_env="an"
    elif [[ "${i}" == "qs" ]]; then
        cert_env="qs"
    elif [[ "${i}" == "redten" ]]; then
        cert_env="redten"
    fi
done

use_path="."
if [[ ! -e deployment.yml ]]; then
    use_path="./rook"
fi
secrets_path="${use_path}/secrets"
use_storage_path="${use_path}/${storage_type}"
minio_storage_path="${use_path}/minio"

anmt "----------------------------------------------------------------------------------------------"
anmt "deploying rook with storage type ${storage_type} from: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/rook"
inf ""

ceph_operator_file=${use_storage_path}/operator.yml
inf "creating ceph operator: ${ceph_operator_file}"
kubectl apply -f ${ceph_operator_file}
inf ""

inf ""
anmt "Want to learn more about Rook, Ceph and Ceph S3 work while you wait?"
inf ""
anmt "- How Ceph Volumes work: https://rook.io/docs/rook/master/minio-object-store.htm://rook.io/docs/rook/master/ceph-quickstart.html"
anmt "- (if using cephs3) How Ceph Object Stores work: https://github.com/rook/rook/blob/master/design/object-store.md"
inf ""

cur_date=$(date)
inf "${cur_date} - waiting for rook ${storage_type} operator to enter the Running state"
num_sleeps=0
not_ready="0"
while [[ "${not_ready}" == "0" ]]; do
    test_rook_agent=$(kubectl -n rook-ceph-system get pod --ignore-not-found | grep rook-ceph-agent | awk '{print $3}' | grep -i running | wc -l)
    test_rook_op=$(kubectl -n rook-ceph-system get pod --ignore-not-found | grep rook-ceph-operator | awk '{print $3}' | grep -i running | wc -l)
    test_rook_disc=$(kubectl -n rook-ceph-system get pod --ignore-not-found | grep rook-discover | awk '{print $3}' | grep -i running | wc -l)
    if [[ "${test_rook_agent}" == "0" ]] || [[ "${test_rook_op}" == "0" ]] || [[ "${test_rook_disc}" == "0" ]]; then
        cur_date=$(date)
        let num_sleeps+=1
        modulus_sleep=$((${num_sleeps}%30))
        if [[ "${debug}" == "1" ]]; then
            inf "${cur_date} - still waiting on system pods sleep count: ${num_sleeps}"
        elif [[ "${modulus_sleep}" == "0" ]]; then
            inf "${cur_date} - still waiting on system pods"
            num_sleeps=0
        elif [[ $num_sleeps -gt 500 ]]; then
            inf ""
            err "Failed waiting for rook and ceph system pods to enter a valid Running state"
            inf ""
            ${use_path}/view-system-pods.sh
            echo "" >> /tmp/boot.log
            echo "rook ceph agent:" >> /tmp/boot.log
            kubectl -n rook-ceph-system get pod --ignore-not-found | grep rook-ceph-agent >> /tmp/boot.log
            echo "" >> /tmp/boot.log
            echo "rook ceph operator:" >> /tmp/boot.log
            kubectl -n rook-ceph-system get pod --ignore-not-found | grep rook-ceph-operator >> /tmp/boot.log
            echo "" >> /tmp/boot.log
            echo "rook ceph discover:" >> /tmp/boot.log
            kubectl -n rook-ceph-system get pod --ignore-not-found | grep rook-discover >> /tmp/boot.log
            echo "" >> /tmp/boot.log
            echo "rook ceph system pods:" >> /tmp/boot.log
            ${use_path}/view-system-pods.sh >> /tmp/boot.log
            inf ""
            exit 1 
        fi
        sleep 1
    else
        inf "${cur_date} - rook and ceph system pods are Running"
        not_ready=1
    fi
done

inf ""
${use_path}/view-system-pods.sh
inf ""

cluster_file=${use_storage_path}/cluster.yml
inf "creating cluster: ${cluster_file}"
kubectl apply -f ${cluster_file}
inf ""

cur_date=$(date)
inf "${cur_date} - waiting for rook ${storage_type} cluster pods to enter the Running state"
num_sleeps=0
not_ready="0"
while [[ "${not_ready}" == "0" ]]; do
    test_ceph_mgr=$(kubectl -n rook-ceph get pod --ignore-not-found | grep rook-ceph-mgr | awk '{print $3}' | grep -i running | wc -l)
    test_ceph_mon=$(kubectl -n rook-ceph get pod --ignore-not-found | grep rook-ceph-mon | awk '{print $3}' | grep -i running | wc -l)
    test_ceph_osd=$(kubectl -n rook-ceph get pod --ignore-not-found | grep rook-ceph-osd | awk '{print $3}' | grep -i running | wc -l)
    if [[ "${test_ceph_mgr}" == "0" ]] || [[ "${test_ceph_mon}" == "0" ]] || [[ "${test_ceph_osd}" == "0" ]]; then
        cur_date=$(date)
        let num_sleeps+=1
        modulus_sleep=$((${num_sleeps}%30))
        if [[ "${debug}" == "1" ]]; then
            inf "${cur_date} - still waiting on cluster pods sleep count: ${num_sleeps}"
        elif [[ "${modulus_sleep}" == "0" ]]; then
            inf "${cur_date} - still waiting on cluster pods"
            num_sleeps=0
        elif [[ $num_sleeps -gt 1200 ]]; then
            inf ""
            err "Failed waiting for rook and ceph pods to enter a valid Running state"
            inf ""
            ${use_path}/view-ceph-pods.sh
            inf ""
            exit 1 
        fi
        sleep 1
    else
        inf "${cur_date} - rook and ceph pods are Running"
        not_ready=1
    fi
done

inf ""
${use_path}/view-ceph-pods.sh
inf ""

secret_namespace="rook-ceph"
is_ready="0"
storageclass_file=${use_storage_path}/storageclass.yml
inf "creating storage class: ${storageclass_file}"
kubectl apply -f ${storageclass_file}
inf ""

test_secret=$(kubectl get secrets ${secret_namespace} --ignore-not-found | grep tls-ceph | wc -l)
if [[ "${test_secret}" == "0" ]]; then
    tls_secret_org=./ansible/secrets/tls-ceph.yml
    tls_secret=${secrets_path}/tls-ceph.yml
    if [[ ! -e ${tls_secret} ]]; then
        cp ${tls_secret_org} ${tls_secret}
        sed -i "s/namespace: default/namespace: ${secret_namespace}/g" ${tls_secret}
    else
        inf "deleting previous tls-ceph secret: kubectl delete -f ${tls_secret}"
        kubectl delete -f ${tls_secret}
    fi
    if [[ -e ${tls_secret} ]]; then
        inf "creating tls s3 secret for secure storage in namespace: kubectl apply -f ${tls_secret} --namespace=${secret_namespace}"
        kubectl apply -f ${tls_secret} --namespace=${secret_namespace}
        inf ""
    fi
    test_secret=$(kubectl get secrets --ignore-not-found -n ${secret_namespace} | grep tls-ceph | wc -l)
    if [[ "${test_secret}" == "0" ]]; then
        err "failed creating tls secret: kubectl apply -f ${tls_secret} --namespace=${secret_namespace}"
        is_ready="0"
    else
        inf "created tls secret: ${tls_secret}"
        is_ready="1"
    fi
else
    is_ready="1"
fi

if [[ "${object_store}" == "cephs3" ]]; then
    deploy_object_store_file=${use_storage_path}/s3-objectstore-${cert_env}.yml
    if [[ "${is_ready}" == "1" ]]; then
        if [[ -e ${deploy_object_store_file} ]]; then
            inf "creating ${cert_env} s3 storage: ${deploy_object_store_file}"
            kubectl apply -f ${deploy_object_store_file}
            inf ""
        else
            err "failed creating ${cert_env} storage - was not able to deploy object store file: ${deploy_object_store_file} for use with command: kubectl apply -f ${deploy_object_store_file}"
        fi
    else
        err "failed waiting on ${cert_env} storage - was not able to deploy object store file: ${deploy_object_store_file} for use with command: kubectl apply -f ${deploy_object_store_file}"
    fi

    cur_date=$(date)
    inf "${cur_date} - waiting for rook s3-storage objects to enter the Running state"
    num_sleeps=0
    not_ready="0"
    while [[ "${not_ready}" == "0" ]]; do
        test_ceph_rgw=$(kubectl -n rook-ceph get pod --ignore-not-found | grep rook-ceph-rgw | awk '{print $3}' | grep -i running | wc -l)
        if [[ "${test_ceph_rgw}" == "0" ]] || [[ "${test_ceph_mon}" == "0" ]] || [[ "${test_ceph_osd}" == "0" ]]; then
            cur_date=$(date)
            let num_sleeps+=1
            modulus_sleep=$((${num_sleeps}%30))
            if [[ "${debug}" == "1" ]]; then
                inf "${cur_date} - still waiting on rook-ceph-rgw sleep count: ${num_sleeps}"
            elif [[ "${modulus_sleep}" == "0" ]]; then
                inf "${cur_date} - still waiting on rook-ceph-rgw pods"
                num_sleeps=0
            elif [[ $num_sleeps -gt 1200 ]]; then
                inf ""
                err "Failed waiting for rook-ceph-rgw pods to enter a valid Running state"
                inf ""
                ${use_path}/view-ceph-pods.sh
                inf ""
                exit 1 
            fi
            sleep 1
        else
            inf "${cur_date} - rook-ceph-rgw pods are Running"
            not_ready=1
        fi
    done

    inf "creating ${cert_env} service rook-ceph-rgw-s3-storage: kubectl apply -f ${use_storage_path}/service-objectstore-${cert_env}.yml"
    kubectl apply -f ${use_storage_path}/service-objectstore-${cert_env}.yml
    inf ""

    cur_date=$(date)
    inf "${cur_date} - waiting for rook rook-ceph-rgw-s3-storage to enter the Running state"
    num_sleeps=0
    not_ready="0"
    while [[ "${not_ready}" == "0" ]]; do
        test_ceph_tools=$(kubectl -n rook-ceph get pod --ignore-not-found | grep rook-ceph-rgw-s3-storage | awk '{print $3}' | grep -i running | wc -l)
        if [[ "${test_ceph_tools}" == "0" ]]; then
            cur_date=$(date)
            let num_sleeps+=1
            modulus_sleep=$((${num_sleeps}%30))
            if [[ "${debug}" == "1" ]]; then
                inf "${cur_date} - still waiting on rook-ceph-rgw-s3-storage sleep count: ${num_sleeps}"
            elif [[ "${modulus_sleep}" == "0" ]]; then
                inf "${cur_date} - still waiting on rook-ceph-rgw-s3-storage pods"
                num_sleeps=0
            elif [[ $num_sleeps -gt 1200 ]]; then
                inf ""
                err "Failed waiting for rook-ceph-rgw-s3-storage pods to enter a valid Running state"
                inf ""
                ${use_path}/view-ceph-pods.sh
                inf ""
                exit 1 
            fi
            sleep 1
        else
            inf "${cur_date} - rook-ceph-rgw-s3-storage pods are Running"
            not_ready=1
        fi
    done
elif [[ "${object_store}" == "rook-minio" ]]; then

    test_exists=$(kubectl get pod -n rook-minio-system --ignore-not-found | grep rook-minio-operator | wc -l)
    if [[ "${test_exists}" == "0" ]]; then
        deploy_operator_file=${minio_storage_path}/operator.yml
        inf "deploying minio operator: ${deploy_operator_file}"
        kubectl create -f ${deploy_operator_file}
    else
        inf "minio operator already running"
    fi

    inf "deploying minio object store"
    minio_namespace="rook-minio"
    deploy_object_store_file=${minio_storage_path}/s3-objectstore-${cert_env}.yml
    test_secret=$(kubectl get secrets ${minio_namespace} --ignore-not-found | grep tls-minio | wc -l)
    if [[ "${test_secret}" == "0" ]]; then
        tls_secret_org=./ansible/secrets/tls-minio.yml
        tls_secret=${secrets_path}/tls-minio.yml
        if [[ ! -e ${tls_secret} ]]; then
            cp ${tls_secret_org} ${tls_secret}
            sed -i "s/namespace: default/namespace: ${minio_namespace}/g" ${tls_secret}
        else
            inf "deleting previous tls-minio secret: kubectl delete -f ${tls_secret}"
            kubectl delete -f ${tls_secret}
        fi
        if [[ -e ${tls_secret} ]]; then
            inf "creating tls s3 secret for secure storage in namespace: kubectl apply -f ${tls_secret} --namespace=${minio_namespace}"
            kubectl apply -f ${tls_secret} --namespace=${minio_namespace}
            kubectl apply -f ${tls_secret} --namespace=rook-minio-system
            inf ""
        fi
        test_secret=$(kubectl get secrets --ignore-not-found -n ${minio_namespace} | grep tls-minio | wc -l)
        if [[ "${test_secret}" == "0" ]]; then
            err "failed creating tls secret: kubectl apply -f ${tls_secret} --namespace=${minio_namespace}"
            is_ready="0"
        else
            inf "created tls secret: ${tls_secret}"
            is_ready="1"
        fi
    else
        is_ready="1"
    fi

    if [[ "${is_ready}" == "1" ]]; then
        if [[ -e ${deploy_object_store_file} ]]; then
            inf "creating ${cert_env} s3 storage: ${deploy_object_store_file}"
            kubectl apply -f ${deploy_object_store_file}
            inf ""
        else
            err "failed creating ${cert_env} storage - was not able to deploy object store file: ${deploy_object_store_file} for use with command: kubectl apply -f ${deploy_object_store_file}"
        fi
    else
        err "failed waiting on ${cert_env} storage - was not able to deploy object store file: ${deploy_object_store_file} for use with command: kubectl apply -f ${deploy_object_store_file}"
    fi

    deploy_user_creds="${use_path}/user-deploy-creds.sh"
    inf "deploying user credentials: ${deploy_user_creds}"
    ${deploy_user_creds}
    inf ""

    cur_date=$(date)
    inf "${cur_date} - waiting for rook-minio-operator pods to enter the Running state"
    num_sleeps=0
    not_ready="0"
    while [[ "${not_ready}" == "0" ]]; do
        test_minio_rgw=$(kubectl -n rook-minio-system get pod --ignore-not-found | grep rook-minio-operator | awk '{print $3}' | grep -i running | wc -l)
        if [[ "${test_minio_rgw}" == "0" ]] || [[ "${test_minio_mon}" == "0" ]] || [[ "${test_minio_osd}" == "0" ]]; then
            cur_date=$(date)
            let num_sleeps+=1
            modulus_sleep=$((${num_sleeps}%30))
            if [[ "${debug}" == "1" ]]; then
                inf "${cur_date} - still waiting on rook-minio-operator sleep count: ${num_sleeps}"
            elif [[ "${modulus_sleep}" == "0" ]]; then
                inf "${cur_date} - still waiting on rook-minio-operator pods"
                num_sleeps=0
            elif [[ $num_sleeps -gt 1200 ]]; then
                inf ""
                err "Failed waiting for rook-minio-operator pods to enter a valid Running state"
                inf ""
                ${use_path}/view-minio-pods.sh
                inf ""
                exit 1 
            fi
            sleep 1
        else
            inf "${cur_date} - rook-minio-operator pods are Running"
            not_ready=1
        fi
    done

    inf "applying ${cert_env} minio-service: kubectl apply -f ${minio_storage_path}/service-objectstore-${cert_env}.yml"
    kubectl apply -f ${minio_storage_path}/service-objectstore-${cert_env}.yml
    inf ""

    ingress_file=${minio_storage_path}/ingress-${cert_env}.yml
    inf "applying minio ingress: kubectl apply -f ${ingress_file}"
    kubectl apply -f ${ingress_file}
fi
inf ""

toolbox_file=${use_storage_path}/toolbox.yml
inf "create toolbox: ${toolbox_file}"
kubectl apply -f ${toolbox_file}
inf ""

cur_date=$(date)
inf "${cur_date} - waiting for rook toolbox to enter the Running state"
num_sleeps=0
not_ready="0"
while [[ "${not_ready}" == "0" ]]; do
    test_ceph_tools=$(kubectl -n rook-ceph get pod --ignore-not-found | grep rook-ceph-tools | awk '{print $3}' | grep -i running | wc -l)
    if [[ "${test_ceph_tools}" == "0" ]]; then
        cur_date=$(date)
        let num_sleeps+=1
        modulus_sleep=$((${num_sleeps}%30))
        if [[ "${debug}" == "1" ]]; then
            inf "${cur_date} - still waiting on rook-ceph-tools sleep count: ${num_sleeps}"
        elif [[ "${modulus_sleep}" == "0" ]]; then
            inf "${cur_date} - still waiting on rook-ceph-tools pods"
            num_sleeps=0
        elif [[ $num_sleeps -gt 1200 ]]; then
            inf ""
            err "Failed waiting for rook-ceph-tools pods to enter a valid Running state"
            inf ""
            ${use_path}/view-ceph-pods.sh
            inf ""
            exit 1 
        fi
        sleep 1
    else
        inf "${cur_date} - rook-ceph-tools pods are Running"
        not_ready=1
    fi
done

# ingress needed for dashboard
if [[ "${dashboard_enabled}" == "1" ]]; then
    ingress_file=${use_storage_path}/ingress-${cert_env}.yml
    inf "deploying ceph dashboard using service file: ${ingress_file}"
    kubectl apply -f ${ingress_file}
    inf ""
fi

if [[ "${storage_type}" == "cephs3" ]]; then
    # https://rook.io/docs/rook/master/object.html
    # http://docs.ceph.com/docs/giant/radosgw/admin/
    inf "creating new default user ${username} with: "
    good "${use_path}/user-create.sh ${username}"
    ${use_path}/user-create.sh ${username}
    inf ""

    inf "create bucket with: ${use_path}/bucket-create.sh"
    ${use_path}/bucket-create.sh common
    inf ""
fi

good "done deploying: rook with ${storage_type} and cert_env: ${cert_env}"
