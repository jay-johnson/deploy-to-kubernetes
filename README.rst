Deploy to Kubernetes
--------------------

This is a work in progress guide for installing a kubernetes cluster with helm on a single Ubuntu host (validated on Ubuntu 18.04). Once the cluster is running, you can deploy the following docker containers:

- `Redis <https://hub.docker.com/r/bitnami/redis/>`__

In Progress
===========

- `Postgres <https://github.com/CrunchyData/crunchy-containers>`__
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
