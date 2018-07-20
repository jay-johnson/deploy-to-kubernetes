Deploy to Kubernetes
--------------------

This is a work in progress guide for installing a kubernetes cluster with helm on a single Ubuntu host (validated on Ubuntu 18.04). Once the cluster is running, you can deploy the following docker containers:

- `Redis <https://hub.docker.com/r/bitnami/redis/>`__
- `Postgres <https://github.com/CrunchyData/crunchy-containers>`__

In Progress
===========

- `Django REST API with JWT and Swagger <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt>`__
- `Django REST API Celery Workers <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt/blob/master/openshift/worker/deployment.yaml>`__
- `Jupyter <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt/blob/master/openshift/jupyter/deployment.yaml>`__
- `Core Celery Workers <https://github.com/jay-johnson/antinex-core>`__
- `Network Pipeline Receiver <https://github.com/jay-johnson/network-pipeline>`__
- `pgAdmin4 <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt/blob/master/openshift/pgadmin4/crunchy-template-http.json>`__

Getting Started
---------------

Overview
========

This guide installs the following systems and NFS volumes to prepare the host for running containers and automatically running them on host startup:

- Kubernetes
- Helm and Tiller
- Flannel CNI
- NFS Client and Server
- NFS Volumes mounted at: ``/data/k8/redis``, ``/data/k8/postgres``, ``/data/k8/pgadmin``

Install
=======

Run this as root.

::

    sudo su
    ./prepare.sh

Validate
--------

#.  Install Kubernetes Config

    Run as your user

    ::

        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

    Or use the script:

    ::

        ./user-install-kubeconfig.sh

#.  Check the Kubernetes Version

    ::

        kubectl version
        Client Version: version.Info{Major:"1", Minor:"11", GitVersion:"v1.11.1", GitCommit:"b1b29978270dc22fecc592ac55d903350454310a", GitTreeState:"clean", BuildDate:"2018-07-17T18:53:20Z", GoVersion:"go1.10.3", Compiler:"gc", Platform:"linux/amd64"}
        The connection to the server localhost:8080 was refused - did you specify the right host or port?

#.  Confirm the Kubernetes Pods Are Running

    ::

        kubectl get pods -n kube-system

    ::

        NAME                            READY     STATUS    RESTARTS   AGE
        coredns-78fcdf6894-gcm2w        1/1       Running   0          34m
        coredns-78fcdf6894-wjpp2        1/1       Running   0          34m
        etcd-turbo                      1/1       Running   0          33m
        kube-apiserver-turbo            1/1       Running   0          33m
        kube-controller-manager-turbo   1/1       Running   0          33m
        kube-flannel-ds-cgcq7           1/1       Running   0          34m
        kube-proxy-f26hh                1/1       Running   0          34m
        kube-scheduler-turbo            1/1       Running   0          33m
        tiller-deploy-759cb9df9-khvfz   1/1       Running   0          34m

#.  Check Helm Verison

    ::

        helm version
        Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
        Server: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}

Deploy Redis
------------

::

    ./redis/install-with-helm.sh

Or manually with the commands:

::

    echo "deploying persistent volume for redis" 
    kubectl apply -f ./redis/pv.yml
    echo "deploying Bitnami redis stable with helm" 
    helm install \
        --name redis stable/redis \
        --set rbac.create=true \
        --values ./redis/redis.yml

Confirm Connectivity
====================

The following commands assume you have ``redis-tools`` installed (``sudo apt-get install redis-tools``).

::

    redis-cli -h $(kubectl describe pod redis-master-0 | grep IP | awk '{print $NF}') -p 6379
    10.244.0.81:6379> info
    10.244.0.81:6379> exit

Debug Redis Cluster
===================

#.  Examine Redis Master

    ::

        kubectl describe pod redis-master-0

#.  Examine Persistent Volume Claim

    ::

        kubectl get pvc
        NAME                        STATUS    VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
        redis-data-redis-master-0   Bound     redis-pv   10G        RWO                           17s

#.  Examine Persistent Volume

    ::

        kubectl get pv
        NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                               STORAGECLASS   REASON    AGE
        redis-pv   10G        RWO            Retain           Bound     default/redis-data-redis-master-0                            19s

Possible Errors
===============

#.  Create the Persistent Volumes

    ::

        Warning  FailedMount       2m               kubelet, dev       MountVolume.SetUp failed for volume "redis-pv" : mount failed: exit status 32

    ::

        ./tools/create-pvs.sh

Delete Redis
============

::

    helm del --purge redis
    release "redis" deleted

Delete Persistent Volume and Claim
==================================

#.  Delete Claim

    ::

        kubectl delete pvc redis-data-redis-master-0

#.  Delete Volume

    ::

        kubectl delete pv redis-pv
        persistentvolume "redis-pv" deleted

Deploy Postgres
---------------

Install Go
==========

Using Crunchy Data's postgres containers requires having go installed:

::

    # note this has only been tested on ubuntu 18.04:
    sudo apt install golang-go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    go get github.com/blang/expenv

Start
=====

::

    ./postgres/deploy.sh

Debug Postgres
==============

#.  Examine Postgres

    ::

        kubectl describe pod primary

        Type    Reason     Age   From               Message
        ----    ------     ----  ----               -------
        Normal  Scheduled  2m    default-scheduler  Successfully assigned default/primary to dev
        Normal  Pulling    2m    kubelet, dev       pulling image "crunchydata/crunchy-postgres:centos7-10.4-1.8.3"
        Normal  Pulled     2m    kubelet, dev       Successfully pulled image "crunchydata/crunchy-postgres:centos7-10.4-1.8.3"
        Normal  Created    2m    kubelet, dev       Created container
        Normal  Started    2m    kubelet, dev       Started container

#.  Examine Persistent Volume Claim

    ::

        kubectl get pvc
        NAME                        STATUS    VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   AGE
        primary-pgdata              Bound     primary-pgdata   400M       RWX                           4m
        redis-data-redis-master-0   Bound     redis-pv         10G        RWO                           32m

#.  Examine Persistent Volume

    ::

        kubectl get pv
        NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                               STORAGECLASS   REASON    AGE
        primary-pgdata   400M       RWX            Retain           Bound     default/primary-pgdata                                       3m
        redis-pv         10G        RWO            Retain           Bound     default/redis-data-redis-master-0                            32m

#.  Check the NFS Server IP

    If you see something about ``mount -t nfs <IP>:/data/k8/postgres``` when running ``describe pod primary`` like:

    ::

        Mounting arguments: --description=Kubernetes transient mount for /var/lib/kubelet/pods/6c1bfb39-8be2-11e8-8381-0800270864a8/volumes/kubernetes.io~nfs/primary-pgdata --scope -- mount -t nfs 192.168.0.35:/data/k8/postgres /var/lib/kubelet/pods/6c1bfb39-8be2-11e8-8381-0800270864a8/volumes/kubernetes.io~nfs/primary-pgdata

    Then please delete the pv, pvc and primary postgres deployment before recreating the pv with the correct host ip address.

    ::

        kubectl delete service primary
        kubectl delete pod primary
        kubectl delete pvc primary-pgdata
        kubectl delete pv primary-pgdata

    ::

        export CCP_NFS_IP=<NFS Server's IP Address>
        ./postgres/deploy.sh

Reset Cluster
-------------

Run as root:

::

    sudo su
    kubeadm reset -f

License
-------

Apache 2.0 - Please refer to the LICENSE_ for more details

.. _License: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/LICENSE
