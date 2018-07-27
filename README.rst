Deploy a Distributed Stack to Kubernetes
----------------------------------------

.. image:: https://i.imgur.com/qiyhAq9.png

Install and manage a Kubernetes cluster with helm on a single Ubuntu host. Once running, you can deploy a distributed, scalable python stack capable of delivering a resilient REST service with JWT for authentication and Swagger for development. This service uses a decoupled REST API with two distinct worker backends for routing simple database read and write tasks vs long-running tasks that can use a Redis cache and do not need a persistent database connection. This is handy for not only simple CRUD applications and use cases, but also serving a secure multi-tenant environment where multiple users manage long-running tasks like training deep neural networks that are capable of making near-realtime predictions.

This guide was built for deploying the `AntiNex stack of docker containers <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt>`__ on a Kubernetes cluster:

- `Redis <https://hub.docker.com/r/bitnami/redis/>`__
- `Postgres <https://github.com/CrunchyData/crunchy-containers>`__
- `Django REST API with JWT and Swagger <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/api/deployment.yml>`__
- `Django REST API Celery Workers <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/worker/deployment.yml>`__
- `Jupyter <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/jupyter/deployment.yml>`__
- `Core Celery Workers <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/core/deployment.yml>`__
- `pgAdmin4 <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/pgadmin/crunchy-template-http.json>`__
- `(Optional) Splunk with TCP and HEC Service Endpoints <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/splunk/deployment.yml>`__

Getting Started
---------------

.. note:: Please ensure the Ubuntu host has at least 4 CPU cores and more than 8 GB ram. Here is a screenshot from a recent AI training test with only 3 cores:

    .. image:: https://i.imgur.com/KQ7MBdM.png

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

Here is a video showing how to prepare the host to run a local Kubernetes cluster:

.. raw:: html

    <a href="https://asciinema.org/a/193463?autoplay=1" target="_blank"><img src="https://asciinema.org/a/193463.png"/></a>

Preparing the host to run Kubernetes requires run this as root

::

    sudo su
    ./prepare.sh

.. note:: This has only been tested on Ubuntu 18.04 and requires commenting out all swap entries in ``/etc/fstab`` to work

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
        coredns-78fcdf6894-k8srv        1/1       Running   0          4m
        coredns-78fcdf6894-xx8bt        1/1       Running   0          4m
        etcd-dev                        1/1       Running   0          3m
        kube-apiserver-dev              1/1       Running   0          3m
        kube-controller-manager-dev     1/1       Running   0          3m
        kube-flannel-ds-m8k9w           1/1       Running   0          4m
        kube-proxy-p4blg                1/1       Running   0          4m
        kube-scheduler-dev              1/1       Running   0          3m
        tiller-deploy-759cb9df9-wxvp8   1/1       Running   0          4m

    Or you can use the script:

    ::

        ./tools/pods-system.sh
        kubectl get pods -n kube-system
        NAME                            READY     STATUS    RESTARTS   AGE
        coredns-78fcdf6894-k8srv        1/1       Running   0          4m
        coredns-78fcdf6894-xx8bt        1/1       Running   0          4m
        etcd-dev                        1/1       Running   0          3m
        kube-apiserver-dev              1/1       Running   0          3m
        kube-controller-manager-dev     1/1       Running   0          3m
        kube-flannel-ds-m8k9w           1/1       Running   0          4m
        kube-proxy-p4blg                1/1       Running   0          4m
        kube-scheduler-dev              1/1       Running   0          3m
        tiller-deploy-759cb9df9-wxvp8   1/1       Running   0          4m

#.  Check Helm Verison

    ::

        helm version
        Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
        Server: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}

Deploy Redis and Postgres and the Nginx Ingress
-----------------------------------------------

Here is a video showing how to deploy Postgres, Redis, Nginx Ingress, and the pgAdmin4 as pods in the cluster:

.. raw:: html

    <a href="https://asciinema.org/a/193476?autoplay=1" target="_blank"><img src="https://asciinema.org/a/193476.png"/></a>

.. note:: Postgres, pgAdmin4 and Redis use persistent volumes to store data outside the Kubernetes cluster using NFS-mounted volumes

Here are the commands to deploy Postgres, Redis, Nginx Ingress, and pgAdmin4 in the cluster:

.. note:: Please ensure helm is installed and the tiller pod in the ``kube-system`` namespace is the ``Running`` state or Redis will encounter deployment issues

::

    # note this has only been tested on Ubuntu 18.04:
    sudo su
    apt install golang-go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    go get github.com/blang/expenv
    ./user-install-kubeconfig.sh
    ./deploy-resources.sh

If you want to deploy splunk you can add it as an argument:

::

    ./deploy-resources.sh splunk

Start Applications
------------------

Here is a video showing how to start the Django REST Framework, Celery Workers, Jupyter, and the AntiNex Core as pods in the cluster:

.. raw:: html

    <a href="https://asciinema.org/a/193485?autoplay=1" target="_blank"><img src="https://asciinema.org/a/193485.png"/></a>

Start all applications as your user with the command:

::

    ./start.sh

If you want to deploy the splunk-ready application builds, you can add it as an argument:

::

    ./start.sh splunk

Confirm Pods are Running
========================

Depending on how fast your network connection is the initial container downloads can take a few minutes. Please wait until all pods are ``Running`` before continuing.

::

    kubectl get pods

Run a Database Migration
------------------------

Here is a video showing how to apply database schema migrations in the cluster:

.. raw:: html

    <a href="https://asciinema.org/a/193491?autoplay=1" target="_blank"><img src="https://asciinema.org/a/193491.png"/></a>

To apply new Django database migrations, run the following command:

::

    ./api/migrate-db.sh

Add Ingress Locations to /etc/hosts
-----------------------------------

When running locally, all ingress urls need to resolve on the network. Please append the following entries to your local ``/etc/hosts`` file on the ``127.0.0.1`` line:

::

    sudo vi /etc/hosts

Append the entries to the existing ``127.0.0.1`` line:

::

    127.0.0.1   <leave-original-values-here> api.example.com jupyter.example.com pgadmin.example.com splunk.example.com splunkapi.example.com splunktcp.example.com

Create a User
-------------

Create the user ``trex`` with password ``123321`` on the REST API.

::

    ./api/create-user.sh

Deployed Web Applications
-------------------------

Here are the hosted web application urls. These urls are made accessible by the included nginx-ingress.

View Django REST Framework
--------------------------

Login with:

- user: ``trex``
- password: ``123321``

https://api.example.com

View Swagger
------------

Login with:

- user: ``trex``
- password: ``123321``

https://api.example.com/swagger

View Jupyter
------------

Login with:

- password: ``admin``

https://jupyter.example.com

View pgAdmin
------------

Login with:

- user: ``admin@admin.com``
- password: ``123321``

https://pgadmin.example.com

View Splunk
-----------

Login with:

- user: ``trex``
- password: ``123321``

https://splunk.example.com

Training AI with the Django REST API
------------------------------------

These steps install the `AntiNex python client <https://github.com/jay-johnson/antinex-client>`__ for training a deep neural network to predict attack packets from recorded network data (all of which is already included in the docker containers).

#.  Create a virtual environment and install the client

    ::

        virtualenv -p python3 /opt/venv && source /opt/venv/bin/activate
        pip install antinex-client

#.  Watch the application logs


    From a separate terminal, you can tail the Django REST API logs with the command:

    ::

        ./api/logs.sh

    From a separate terminal, you can tail the Django Celery Worker logs with the command:

    ::

        ./worker/logs.sh

    From a separate terminal, you can tail the AntiNex Core Worker logs with the command:

    ::

        ./core/logs.sh

    .. note::  Use ``ctrl + c`` to stop these log tailing commands

Train a Deep Neural Network on Kubernetes
-----------------------------------------

With virtual environment set up, we can use the client to train a deep neural network with the included datasets:

.. note:: this can take a few minutes to finish depending on your hosting resources

::

    ai -a https://api.example.com -u trex -p 123321 -s -f ./tests/scaler-full-django-antinex-simple.json

While you wait, here is a video showing the training and get results:

.. raw:: html

    <a href="https://asciinema.org/a/193494?autoplay=1" target="_blank"><img src="https://i.imgur.com/0hcMfti.png"/></a>

Get the AI Job Record
---------------------

::

    ai_get_job.py -a https://api.example.com -u trex -p 123321 -i 1

Get the AI Training Job Results
-------------------------------

::

    ai_get_results.py -a https://api.example.com -u trex -p 123321 -i 1 -s

Standalone Deployments
----------------------

Below are steps to manually deploy each component in the stack with Kubernetes.

Deploy Redis
------------

::

    ./redis/run.sh

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

    # note this has only been tested on Ubuntu 18.04:
    sudo apt install golang-go
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    go get github.com/blang/expenv

Start
=====

Start the `Postgres container <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/postgres/deployment.yml>`__ within Kubernetes:

::

    ./postgres/run.sh

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
        ./postgres/run.sh

Deploy pgAdmin
--------------

Please confirm go is installed with the `Install Go section <https://github.com/jay-johnson/deploy-to-kubernetes#install-go>`__.

Start
=====

Start the `pgAdmin4 container <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/pgadmin/deployment.yml>`__ within Kubernetes:

::

    ./pgadmin/run.sh

Get Logs
========

::

    ./pgadmin/logs.sh

SSH into pgAdmin
================

::

    ./pgadmin/ssh.sh

Deploy Django REST API
----------------------

Use these commands to manage the `Django REST Framework pods <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/api/deployment.yml>`__ within Kubernetes.

Start
=====

::

    ./api/run.sh

Run a Database Migration
========================

To apply a django database migration run the following command:

::

    ./api/migrate-db.sh

Get Logs
========

::

    ./api/logs.sh

SSH into the API
================

::

    ./api/ssh.sh

Deploy Django Celery Workers
----------------------------

Use these commands to manage the `Django Celery Worker pods <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/worker/deployment.yml>`__ within Kubernetes.

Start
=====

::

    ./worker/run.sh

Get Logs
========

::

    ./worker/logs.sh

SSH into the Worker
===================

::

    ./worker/ssh.sh

Deploy AntiNex Core
-------------------

Use these commands to manage the `Backend AntiNex Core pods <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/core/deployment.yml>`__ within Kubernetes.

Start
=====

::

    ./core/run.sh

Get Logs
========

::

    ./core/logs.sh

SSH into the API
================

::

    ./core/ssh.sh

Deploy Jupyter
--------------

Use these commands to manage the `Jupyter pods <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/jupyter/deployment.yml>`__ within Kubernetes.

Start
=====

::

    ./jupyter/run.sh

Login to Jupyter
================

Login with:

- password: ``admin``

https://jupyter.example.com

Get Logs
========

::

    ./jupyter/logs.sh

SSH into Jupyter
================

::

    ./jupyter/ssh.sh

Deploy Splunk
-------------

Use these commands to manage the `Splunk container <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/splunk/deployment.yml>`__ within Kubernetes.

Start
=====

::

    ./splunk/run.sh

Login to Splunk
===============

Login with:

- user: ``trex``
- password: ``123321``

https://splunk.example.com

Searching in Splunk
-------------------

Here is the splunk searching command line tool I use with these included applications:

https://github.com/jay-johnson/spylunking

With search example documentation:

https://spylunking.readthedocs.io/en/latest/scripts.html#examples

Search using Spylunking
-----------------------

Find logs in splunk using the ``sp`` command line tool:

::

    sp -q 'index="antinex" | reverse' -u trex -p 123321 -a $(./splunk/get-api-fqdn.sh) -i antinex

Find Django REST API Logs in Splunk
-----------------------------------

::

    sp -q 'index="antinex" AND name=api | head 20 | reverse' -u trex -p 123321 -a $(./splunk/get-api-fqdn.sh) -i antinex

Find Django Celery Worker Logs in Splunk
----------------------------------------

::

    sp -q 'index="antinex" AND name=worker | head 20 | reverse' -u trex -p 123321 -a $(./splunk/get-api-fqdn.sh) -i antinex

Find Core Logs in Splunk
------------------------

::

    sp -q 'index="antinex" AND name=core | head 20 | reverse' -u trex -p 123321 -a $(./splunk/get-api-fqdn.sh) -i antinex

Find Jupyter Logs in Splunk
---------------------------

::

    sp -q 'index="antinex" AND name=jupyter | head 20 | reverse' -u trex -p 123321 -a $(./splunk/get-api-fqdn.sh) -i antinex

Example for debugging ``sp`` splunk connectivity from inside an API Pod:

::

    kubectl exec -it api-59496ccb5f-2wp5t -n default echo 'starting search' && /bin/bash -c "source /opt/venv/bin/activate && sp -q 'index="antinex" AND hostname=local' -u trex -p 123321 -a 10.101.107.205:8089 -i antinex"

Get Logs
========

::

    ./splunk/logs.sh

SSH into Splunk
===============

::

    ./splunk/ssh.sh

Deploy Nginx Ingress
--------------------

This project is currently using the `nginx-ingress <https://github.com/nginxinc/kubernetes-ingress>`__ instead of the `Kubernetes Ingress using nginx <https://github.com/kubernetes/ingress-nginx>`__. Use these commands to manage and debug the nginx ingress within Kubernetes.

.. note:: The default Yaml file annotations only work with the `nginx-ingress customizations <https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/customization#customization-of-nginx-configuration>`__

Start
=====

::

    ./ingress/run.sh

Get Logs
========

::

    ./ingress/logs.sh

SSH into the Ingress
====================

::

    ./ingress/ssh.sh

View Ingress Nginx Config
-------------------------

When troubleshooting the nginx ingress, it is helpful to view the nginx configs inside the container. Here is how to view the configs:

::

    ./ingress/view-configs.sh

View a Specific Ingress Configuration
-------------------------------------

If you know the pod name and the namespace for the nginx-ingress, then you can view the configs from the command line with:

::

    app_name="jupyter"
    app_name="pgadmin"
    app_name="api"
    use_namespace="default"
    pod_name=$(kubectl get pods -n ${use_namespace} | awk '{print $1}' | grep nginx | head -1)
    kubectl exec -it ${pod_name} -n ${use_namespace} cat /etc/nginx/conf.d/${use_namespace}-${app_name}-ingress.conf

Deploy Splunk
-------------

Start
=====

To deploy splunk you can add the argument ``splunk`` to the `./deploy-resources.sh splunk <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/deploy-resources.sh>`__ script. Or you can manually run it with the command:

::

    ./splunk/run.sh

Deploy Splunk-Ready Applications
--------------------------------

After deploying the splunk pod, you can deploy the splunk-ready applications with the command:

::

    ./start.sh splunk

Get Logs
========

::

    ./splunk/logs.sh

SSH into Splunk
===============

::

    ./splunk/ssh.sh

View Ingress Config
===================

::

    ./splunk/view-ingress-config.sh

Troubleshooting
---------------

Out of IP Addresses
===================

Flannel can exhaust all available ip addresses in the CIDR network range. When this happens please run the following command to clean up the local cni network files:

::

    ./tools/reset-flannel-cni-networks.sh

Reset Cluster
-------------

Here is a video showing how to reset the local Kubernetes cluster.

.. raw:: html

    <a href="https://asciinema.org/a/193472?autoplay=1" target="_blank"><img src="https://asciinema.org/a/193472.png"/></a>

Please be careful as these commands will shutdown all containers and reset the Kubernetes cluster.

.. note:: All created data should be persisted in the NFS ``/data/k8`` directories

Run as root:

::

    sudo su
    kubeadm reset -f
    ./prepare.sh

Or use the file:

::

    sudo su
    ./tools/cluster-reset.sh

License
-------

Apache 2.0 - Please refer to the LICENSE_ for more details

.. _License: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/LICENSE

