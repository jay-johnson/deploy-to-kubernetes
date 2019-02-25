Deploying a Distributed AI Stack to Kubernetes on CentOS
--------------------------------------------------------

.. image:: https://i.imgur.com/xO4CbfN.png

Install and manage a Kubernetes cluster (version 1.13.3) with helm on a single CentOS 7 vm or in multi-host mode that runs the cluster on 3 CentOS 7 vms. Once running, you can deploy a distributed, scalable python stack capable of delivering a resilient REST service with JWT for authentication and Swagger for development. This service uses a decoupled REST API with two distinct worker backends for routing simple database read and write tasks vs long-running tasks that can use a Redis cache and do not need a persistent database connection. This is handy for not only simple CRUD applications and use cases, but also serving a secure multi-tenant environment where multiple users manage long-running tasks like training deep neural networks that are capable of making near-realtime predictions.

This guide was built for deploying the `AntiNex stack of docker containers <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt>`__ and the `Stock Analysis Engine <https://github.com/AlgoTraders/stock-analysis-engine>`__ on a Kubernetes single host or multi-host cluster.

- `Managing a Multi-Host Kubernetes Cluster with an External DNS Server <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost#managing-a-multi-host-kubernetes-cluster-with-an-external-dns-server>`__
- `Cert Manager with Let's Encrypt SSL support <https://github.com/jetstack/cert-manager>`__
- `A Native Ceph Cluster for Persistent Volume Management with KVM <https://deploy-to-kubernetes.readthedocs.io/en/latest/ceph.html>`__
- `A Third-party Rook Ceph Cluster for Persistent Volumes <https://rook.io/docs/rook/master/ceph-quickstart.html>`__
- `Minio S3 Object Store <https://docs.minio.io/docs/deploy-minio-on-kubernetes.html>`__
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

.. note:: Please ensure for single-vm hosting that the CentOS machine has at least 4 CPU cores and more than 8 GB ram. Here is a screenshot of the CPU utilization during AI training with only 3 cores:

    .. image:: https://i.imgur.com/KQ7MBdM.png

Overview
========

This guide installs the following systems and a storage solution `Rook with Ceph cluster (default) <https://github.com/rook/rook/tree/master/cluster/examples/kubernetes/ceph>`__ or NFS volumes to prepare the host for running containers and automatically running them on host startup:

- Kubernetes
- Helm and Tiller
- `Minio S3 Storage <https://docs.minio.io/docs/deploy-minio-on-kubernetes.html>`__
- `Persistent Storage Volumes using Rook with Ceph cluster <https://github.com/rook/rook/tree/master/cluster/examples/kubernetes/ceph>`__ or optional NFS Volumes mounted at: ``/data/k8/redis``, ``/data/k8/postgres``, ``/data/k8/pgadmin``
- Flannel CNI

Install
=======

Here is a video showing how to prepare the host to run a local Kubernetes cluster:

.. image:: https://asciinema.org/a/193463.png
    :target: https://asciinema.org/a/193463?autoplay=1
    :alt: Install Kubernetes

Preparing the host to run Kubernetes requires run this as root

::

    sudo su
    ./prepare.sh

.. note:: This has only been tested on CentOS 7 and Ubuntu 18.04 and requires commenting out all swap entries in ``/etc/fstab`` to work

.. warning:: This guide used to install the cluster on Ubuntu 18.04, but after seeing high CPU utilization after a few days of operation this guide was moved to CentOS 7. The specific issues on Ubuntu were logged in ``journalctl -xe`` and appeared to be related to "volumes not being found" and "networking disconnects".

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

Deploy Redis and Postgres and the Nginx Ingress
-----------------------------------------------

Here is a video showing how to deploy Postgres, Redis, Nginx Ingress, and the pgAdmin4 as pods in the cluster:

.. image:: https://asciinema.org/a/193476.png
    :target: https://asciinema.org/a/193476?autoplay=1
    :alt: Deploy Redis and Postgres and the Nginx Ingress

.. note:: Postgres, pgAdmin4 and Redis use Rook Ceph to persist data

Here are the commands to deploy Postgres, Redis, Nginx Ingress, and pgAdmin4 in the cluster:

.. note:: Please ensure helm is installed and the tiller pod in the ``kube-system`` namespace is the ``Running`` state or Redis will encounter deployment issues

Install Go using the `./tools/install-go.sh script <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/tools/install-go.sh>`__ or with the commands:

::

    # note go install has only been tested on CentOS 7 and Ubuntu 18.04:
    sudo su
    GO_VERSION="1.11"
    GO_OS="linux"
    GO_ARCH="amd64"
    go_file="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
    curl https://dl.google.com/go/${go_file} --output /tmp/${go_file}
    export GOPATH=$HOME/go/bin
    export PATH=$PATH:$GOPATH:$GOPATH/bin
    tar -C $HOME -xzf /tmp/${go_file}
    $GOPATH/go get github.com/blang/expenv
    # make sure to add GOPATH and PATH to ~/.bashrc

::

    ./user-install-kubeconfig.sh
    ./deploy-resources.sh

If you want to deploy splunk you can add it as an argument:

::

    ./deploy-resources.sh splunk

If you want to deploy splunk with Let's Encrypt make sure to add ``prod`` as an argument:

::

    ./deploy-resources.sh splunk prod

Start Applications
------------------

Here is a video showing how to start the Django REST Framework, Celery Workers, Jupyter, and the AntiNex Core as pods in the cluster:

.. image:: https://asciinema.org/a/193485.png
    :target: https://asciinema.org/a/193485?autoplay=1
    :alt: Start Applications

Start all applications as your user with the command:

::

    ./start.sh

If you want to deploy the splunk-ready application builds, you can add it as an argument:

::

    ./start.sh splunk

If you want to deploy the splunk-ready application builds integrated with Let's Encrypt TLS encryption, just add ``prod`` as an argument:

::

    ./start.sh splunk prod

.. note:: The `Cert Manager <https://github.com/jetstack/cert-manager>`__ is set to staging mode by default and requires the ``prod`` argument to prevent accidentally getting blocked due to Lets Encrypt rate limits

Confirm Pods are Running
========================

Depending on how fast your network connection is the initial container downloads can take a few minutes. Please wait until all pods are ``Running`` before continuing.

::

    kubectl get pods

Run a Database Migration
------------------------

Here is a video showing how to apply database schema migrations in the cluster:

.. image:: https://asciinema.org/a/193491.png
    :target: https://asciinema.org/a/193491?autoplay=1
    :alt: Run a Database Migration

To apply new Django database migrations, run the following command:

::

    ./api/migrate-db.sh

Add Ingress Locations to /etc/hosts
-----------------------------------

When running locally (also known in these docs as ``dev`` mode), all ingress urls need to resolve on the network. Please append the following entries to your local ``/etc/hosts`` file on the ``127.0.0.1`` line:

::

    sudo vi /etc/hosts

Append the entries to the existing ``127.0.0.1`` line:

::

    127.0.0.1   <leave-original-values-here> api.example.com jupyter.example.com pgadmin.example.com splunk.example.com s3.example.com ceph.example.com minio.example.com

Using the Minio S3 Object Store
-------------------------------

By default, the Kubernetes cluster has a `Minio S3 object store running on a Ceph Persistent Volume <https://docs.minio.io/docs/deploy-minio-on-kubernetes.html>`__. S3 is a great solution for distributing files, datasets, configurations, static assets, build artifacts and many more across components, regions, and datacenters using an S3 distributed backend. Minio can also replicate some of the `AWS Lambda event-based workflows <https://aws.amazon.com/lambda/>`__ with `Minio bucket event listeners <https://docs.minio.io/docs/python-client-api-reference>`__.

For reference, Minio was deployed using this script:

::

    ./minio/run.sh

View the Verification Tests on the Minio Dashboard
==================================================

Login with:

- access key: ``trexaccesskey``
- secret key: ``trex123321``

https://minio.example.com/minio/s3-verification-tests/

Test Minio S3 with Bucket Creation and File Upload and Download
===============================================================

#.  Run from inside the API container

    ::

        ./api/ssh.sh
        source /opt/venv/bin/activate && run_s3_test.py

    Example logs:

    ::

        creating test file: run-s3-test.txt
        connecting: http://minio-service:9000
        checking bucket=s3-verification-tests exists
        upload_file(run-s3-test.txt, s3-verification-tests, s3-worked-on-2018-08-12-15-21-02)
        upload_file(s3-verification-tests, s3-worked-on-2018-08-12-15-21-02, download-run-s3-test.txt)
        download_filename=download-run-s3-test.txt contents: tested on: 2018-08-12 15:21:02
        exit

#.  Run from outside the Kubernetes cluster

    .. note:: This tool requires the python ``boto3`` pip is installed

    ::

        source ./minio/envs/ext.env
        ./minio/run_s3_test.py

#.  Verify the files were uploaded to Minio

    https://minio.example.com/minio/s3-verification-tests/

Using the Rook Ceph Cluster
---------------------------

By default, the Kubernetes cluster is running a `Rook Ceph cluster for storage <https://rook.io/docs/rook/master/ceph-quickstart.html>`__ which provides HA persistent volumes and claims.

You can review the persistent volumes and claims using the Ceph Dashboard:

https://ceph.example.com

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

View Minio S3 Object Storage
----------------------------

Login with:

- access key: ``trexaccesskey``
- secret key: ``trex123321``

https://minio.example.com

View Ceph
---------

https://ceph.example.com

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

.. image:: https://i.imgur.com/0hcMfti.png
    :target: https://asciinema.org/a/193494?autoplay=1
    :alt: Train a Deep Neural Network on Kubernetes

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
        NAME                      STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
        redis-ceph-data           Bound     pvc-1a88e3a6-9df8-11e8-8047-0800270864a8   8Gi        RWO            rook-ceph-block   46m

#.  Examine Persistent Volume

    ::

        kubectl get pv
        NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                             STORAGECLASS      REASON    AGE
        pvc-1a88e3a6-9df8-11e8-8047-0800270864a8   8Gi        RWO            Delete           Bound     default/redis-ceph-data           rook-ceph-block             46m

Possible Errors
===============

#.  Create the Persistent Volumes

    ::

        Warning  FailedMount       2m               kubelet, dev       MountVolume.SetUp failed for volume "redis-pv" : mount failed: exit status 32

    ::

        ./pvs/create-pvs.sh

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

Using Crunchy Data's postgres containers requires having go installed. Go can be installed using the `./tools/install-go.sh script <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/tools/install-go.sh>`__ or with the commands:

::

    # note go install has only been tested on CentOS 7 and Ubuntu 18.04:
    sudo su
    GO_VERSION="1.11"
    GO_OS="linux"
    GO_ARCH="amd64"
    go_file="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
    curl https://dl.google.com/go/${go_file} --output /tmp/${go_file}
    export GOPATH=$HOME/go/bin
    export PATH=$PATH:$GOPATH:$GOPATH/bin
    tar -C $HOME -xzf /tmp/${go_file}
    $GOPATH/go get github.com/blang/expenv
    # make sure to add GOPATH and PATH to ~/.bashrc

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
        NAME                      STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
        pgadmin4-http-data        Bound     pvc-19031825-9df8-11e8-8047-0800270864a8   400M       RWX            rook-ceph-block   46m
        primary-pgdata            Bound     pvc-17652595-9df8-11e8-8047-0800270864a8   400M       RWX            rook-ceph-block   46m


#.  Examine Persistent Volume

    ::

        kubectl get pv
        NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                             STORAGECLASS      REASON    AGE
        pvc-17652595-9df8-11e8-8047-0800270864a8   400M       RWX            Delete           Bound     default/primary-pgdata            rook-ceph-block             47m
        pvc-19031825-9df8-11e8-8047-0800270864a8   400M       RWX            Delete           Bound     default/pgadmin4-http-data        rook-ceph-block             47m

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

Or if you want to use Let's Encrypt for SSL:

::

    ./splunk/run.sh prod

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

Create your own self-signed x509 TLS Keys, Certs and Certificate Authority with Ansible
---------------------------------------------------------------------------------------

If you have openssl installed you can use this ansible playbook to create your own certificate authority (CA), keys and certs.

#.  Create the CA, Keys and Certificates

    ::

        cd ansible
        ansible-playbook -i inventory_dev create-x509s.yml

#.  Check the CA, x509, keys and certificates for the client and server were created

    ::

        ls -l ./ssl

Deploying Your Own x509 TLS Encryption files as Kubernetes Secrets
------------------------------------------------------------------

This is a work in progress, but in ``dev`` mode the cert-manager is not in use. Instead the cluster utilizes pre-generated x509s TLS SSL files created with the `included ansible playbook create-x509s.yml <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/ansible/create-x509s.yml>`__. Once created, you can deploy them as Kubernetes secrets using the `deploy-secrets.sh <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/ansible/deploy-secrets.sh>`__ script and reload them at any time in the future.

Deploy Secrets
==============

Run this to create the TLS secrets:

::

    ./ansible/deploy-secrets.sh

List Secrets
============

::

    kubectl get secrets | grep tls
    tls-ceph                kubernetes.io/tls                     2         36m
    tls-client              kubernetes.io/tls                     2         36m
    tls-database            kubernetes.io/tls                     2         36m
    tls-docker              kubernetes.io/tls                     2         36m
    tls-jenkins             kubernetes.io/tls                     2         36m
    tls-jupyter             kubernetes.io/tls                     2         36m
    tls-k8                  kubernetes.io/tls                     2         36m
    tls-kafka               kubernetes.io/tls                     2         36m
    tls-kibana              kubernetes.io/tls                     2         36m
    tls-minio               kubernetes.io/tls                     2         36m
    tls-nginx               kubernetes.io/tls                     2         36m
    tls-pgadmin             kubernetes.io/tls                     2         36m
    tls-phpmyadmin          kubernetes.io/tls                     2         36m
    tls-rabbitmq            kubernetes.io/tls                     2         36m
    tls-redis               kubernetes.io/tls                     2         36m
    tls-restapi             kubernetes.io/tls                     2         36m
    tls-s3                  kubernetes.io/tls                     2         36m
    tls-splunk              kubernetes.io/tls                     2         36m
    tls-webserver           kubernetes.io/tls                     2         36m

Reload Secrets
==============

If you want to deploy new TLS secrets at any time, use the ``reload`` argument with the ``deploy-secrets.sh`` script. Doing so will delete the original secrets and recreate all of them using the new TLS values:

::

    ./ansible/deploy-secrets.sh -r

Deploy Cert Manager with Let's Encrypt
--------------------------------------

Use these commands to manage the `Cert Manager with Let's Encrypt SSL support <https://github.com/jetstack/cert-manager>`__ within Kubernetes. By default, the cert manager is deployed only in ``prod`` mode. If you run it in production mode, then it will install real, valid x509 certificates from `Let's Encrypt <https://letsencrypt.org/>`__ into the nginx-ingress automatically.

Start with Let's Encrypt x509 SSL Certificates
==============================================

Start the cert manager in ``prod`` mode to enable Let's Encrypt TLS Encryption with the command:

::

    ./start.sh prod

Or manually with the command:

::

    ./cert-manager/run.sh prod

If you have splunk you can just add it to the arguments:

::

    ./start.sh splunk prod

View Logs
=========

When using the production mode, make sure to view the logs to ensure you are not being blocked due to rate limiting:

::

    ./cert-manager/logs.sh

Stop the Cert Manager
---------------------

If you notice things are not working correctly, you can quickly prevent yourself from getting blocked by stopping the cert manager with the command:

::

    ./cert-manager/_uninstall.sh

.. note:: If you get blocked due to rate-limits it will show up in the cert-manager logs like:

   ::

        I0731 07:53:43.313709       1 sync.go:273] Error issuing certificate for default/api.antinex.com-tls: error getting certificate from acme server: acme: urn:ietf:params:acme:error:rateLimited: Error finalizing order :: too many certificates already issued for exact set of domains: api.antinex.com: see https://letsencrypt.org/docs/rate-limits/
        E0731 07:53:43.313738       1 sync.go:182] [default/api.antinex.com-tls] Error getting certificate 'api.antinex.com-tls': secret "api.antinex.com-tls" not found

Debugging
=========

To reduce debugging issues, the cert manager ClusterIssuer objects use the same name for staging and production mode. This is nice because you do not have to update all the annotations to deploy on production vs staging:

The cert manager starts and defines the issuer name for both production and staging as: 

::

    --set ingressShim.defaultIssuerName=letsencrypt-issuer

Make sure to set any nginx ingress annotations that need Let's Encrypt SSL encryption to these values:

::

    annotations:
      kubernetes.io/tls-acme: "true"
      kubernetes.io/ingress.class: "nginx"
      certmanager.k8s.io/cluster-issuer: "letsencrypt-issuer"

Troubleshooting
---------------

Customize Minio and How to Troubleshoot
---------------------------------------

Change the Minio Access and Secret Keys
=======================================

#.  Change the secrets file: ``minio/secrets/default_access_keys.yml``

    Change the ``access_key`` and ``secret_key`` values after generating the new base64 string values for the secrets file:

    ::

        echo -n "NewAccessKey" | base64
        TmV3QWNjZXNzS2V5
        # now you can replace the access_key's value in the secrets file with the string: TmV3QWNjZXNzS2V5

    ::

        echo -n "NewSecretKey" | base64
        TmV3U2VjcmV0S2V5
        # now you can replace the secret_key's value in the secrets file with the string: TmV3QWNjZXNzS2V5

#.  Deploy the secrets file

    ::

        kubectl apply -f ./minio/secrets/default_access_keys.yml

#.  Restart the Minio Pod

    ::

        kubectl delete pod -l app=minio

If you have changed the default access and secret keys, then you will need to export the following environment variables as needed to make sure the ``./minio/run_s3_test.py`` test script works:

::

    export S3_ACCESS_KEY=<minio access key: trexaccesskey - default>
    export S3_SECRET_KEY=<minio secret key: trex123321 - default>
    export S3_REGION_NAME=<minio region name: us-east-1 - default>
    export S3_ADDRESS=<minio service endpoint: external address found with the script ./minio/get-s3-endpoint.sh and the internal cluster uses the service: minio-service:9000>
    # examples of setting up a minio env files are in: ./minio/envs

View the Minio Dashboard
========================

Login with:

- access key: ``trexaccesskey``
- secret key: ``trex123321``

https://minio.example.com

Get S3 Internal Endpoint
========================

If you want to use the Minio S3 service within the cluster please use the endpoint:

::

    minio-service:9000

or source the internal environment file:

::

    source ./minio/envs/int.env

Get S3 External Endpoint
========================

If you want to use the Minio S3 service from outside the cluser please use the endpoint provided by the script:

::

    ./minio/get-s3-endpoint.sh
    # which for this documentation was the minio service's Endpoints:
    # 10.244.0.103:9000

or source the external environment file:

::

    source ./minio/envs/ext.env

Debugging Steps
===============

#.  Load the Minio S3 external environment variables:

    ::

        source ./minio/envs/ext.env

#.  Run the S3 Verification test script

    ::

        ./minio/run_s3_test.py
        
#.  Confirm Verification Keys are showing up in this Minio S3 bucket

    https://minio.example.com/minio/s3-verification-tests/

    If not please use the describe tools in ``./minio/describe-*.sh`` to grab the logs and `please file a GitHub issue <https://github.com/jay-johnson/deploy-to-kubernetes/issues>`__

Describe Pod
============

::

    ./minio/describe-service.sh

Describe Service
================

::

    ./minio/describe-service.sh

Describe Ingress
================

::

    ./minio/describe-ingress.sh

Uninstall Minio
===============

::

    ./minio/_uninstall.sh

Ceph Troubeshooting
-------------------

Please refer to the `Rook Common Issues <https://github.com/rook/rook/blob/master/Documentation/common-issues.md#common-issues>`__ for the latest updates on how to use your Rook Ceph cluster.

.. note:: By default Ceph is not hosting the S3 solution unless ``cephs3`` is passed in as an argument to ``deploy-resource.sh``.

There are included troubleshooting tools in the ``./rook`` directory with an overview of each below:

Validate Ceph System Pods are Running
=====================================

::

    ./rook/view-system-pods.sh 
    
    ----------------------------------------- 
    Getting the Rook Ceph System Pods: 
    kubectl -n rook-ceph-system get pod 
    NAME                                  READY     STATUS    RESTARTS   AGE
    rook-ceph-agent-g9vzm                 1/1       Running   0          7m
    rook-ceph-operator-78d498c68c-tbsdf   1/1       Running   0          7m
    rook-discover-h9wj9                   1/1       Running   0          7m

Validate Ceph Pods are Running
==============================

::

    ./rook/view-ceph-pods.sh 
    
    ----------------------------------------- 
    Getting the Rook Ceph Pods: 
    kubectl -n rook-ceph get pod 
    NAME                                  READY     STATUS      RESTARTS   AGE
    rook-ceph-mgr-a-9c44495df-7jksz       1/1       Running     0          6m
    rook-ceph-mon0-rxxsl                  1/1       Running     0          6m
    rook-ceph-mon1-gqblg                  1/1       Running     0          6m
    rook-ceph-mon2-7xfsq                  1/1       Running     0          6m
    rook-ceph-osd-id-0-7d4d4c8794-kgr2d   1/1       Running     0          6m
    rook-ceph-osd-prepare-dev-kmsn9       0/1       Completed   0          6m
    rook-ceph-tools                       1/1       Running     0          6m

Validate Persistent Volumes are Bound
=====================================

::

    kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                             STORAGECLASS      REASON    AGE
    pvc-03e6e4ef-9df8-11e8-8047-0800270864a8   1Gi        RWO            Delete           Bound     default/certs-pv-claim            rook-ceph-block             46m
    pvc-0415de24-9df8-11e8-8047-0800270864a8   1Gi        RWO            Delete           Bound     default/configs-pv-claim          rook-ceph-block             46m
    pvc-0441307f-9df8-11e8-8047-0800270864a8   1Gi        RWO            Delete           Bound     default/datascience-pv-claim      rook-ceph-block             46m
    pvc-0468ef73-9df8-11e8-8047-0800270864a8   1Gi        RWO            Delete           Bound     default/frontendshared-pv-claim   rook-ceph-block             46m
    pvc-04888222-9df8-11e8-8047-0800270864a8   1Gi        RWO            Delete           Bound     default/staticfiles-pv-claim      rook-ceph-block             46m
    pvc-1c3e359d-9df8-11e8-8047-0800270864a8   10Gi       RWO            Delete           Bound     default/minio-pv-claim            rook-ceph-block             46m

Validate Persistent Volume Claims are Bound
===========================================

::

    kubectl get pvc
    NAME                      STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    certs-pv-claim            Bound     pvc-03e6e4ef-9df8-11e8-8047-0800270864a8   1Gi        RWO            rook-ceph-block   47m
    configs-pv-claim          Bound     pvc-0415de24-9df8-11e8-8047-0800270864a8   1Gi        RWO            rook-ceph-block   47m
    datascience-pv-claim      Bound     pvc-0441307f-9df8-11e8-8047-0800270864a8   1Gi        RWO            rook-ceph-block   47m
    frontendshared-pv-claim   Bound     pvc-0468ef73-9df8-11e8-8047-0800270864a8   1Gi        RWO            rook-ceph-block   47m
    minio-pv-claim            Bound     pvc-1c3e359d-9df8-11e8-8047-0800270864a8   10Gi       RWO            rook-ceph-block   46m

Create a Persistent Volume Claim
================================

Going forward, Ceph will automatically create a persistent volume if one is not available for binding to an available Persistent Volume Claim. To create a new persistent volume, just create a claim and verify the Rook Ceph cluster created the persistent volume and both are bound to each other.

::

    kubectl apply -f pvs/pv-staticfiles-ceph.yml

Verify the Persistent Volume is Bound
=====================================

::

    kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                          STORAGECLASS      REASON    AGE
    pvc-77afbc7a-9ade-11e8-b293-0800270864a8   20Gi       RWO            Delete           Bound     default/staticfiles-pv-claim   rook-ceph-block             2s

Verify the Persistent Volume Claim is Bound
===========================================

::

    kubectl get pvc
    NAME                   STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
    staticfiles-pv-claim   Bound     pvc-77afbc7a-9ade-11e8-b293-0800270864a8   20Gi       RWO            rook-ceph-block   11s


Describe Persistent Volumes
===========================

::

    kubectl describe pv pvc-c88fc37b-9adf-11e8-9fae-0800270864a8
    Name:            pvc-c88fc37b-9adf-11e8-9fae-0800270864a8
    Labels:          <none>
    Annotations:     pv.kubernetes.io/provisioned-by=ceph.rook.io/block
    Finalizers:      [kubernetes.io/pv-protection]
    StorageClass:    rook-ceph-block
    Status:          Bound
    Claim:           default/certs-pv-claim
    Reclaim Policy:  Delete
    Access Modes:    RWO
    Capacity:        20Gi
    Node Affinity:   <none>
    Message:         
    Source:
        Type:       FlexVolume (a generic volume resource that is provisioned/attached using an exec based plugin)
        Driver:     ceph.rook.io/rook-ceph-system
        FSType:     xfs
        SecretRef:  <nil>
        ReadOnly:   false
        Options:    map[clusterNamespace:rook-ceph image:pvc-c88fc37b-9adf-11e8-9fae-0800270864a8 pool:replicapool storageClass:rook-ceph-block]
    Events:         <none>

Show Ceph Cluster Status
========================

::

    ./rook/show-ceph-status.sh 
    
    ---------------------------------------------- 
    Getting the Rook Ceph Status with Toolbox: 
    kubectl -n rook-ceph exec -it rook-ceph-tools ceph status 
    cluster:
        id:     7de1988c-03ea-41f3-9930-0bde39540552
        health: HEALTH_OK
    
    services:
        mon: 3 daemons, quorum rook-ceph-mon2,rook-ceph-mon0,rook-ceph-mon1
        mgr: a(active)
        osd: 1 osds: 1 up, 1 in
    
    data:
        pools:   1 pools, 100 pgs
        objects: 12 objects, 99 bytes
        usage:   35443 MB used, 54756 MB / 90199 MB avail
        pgs:     100 active+clean

Show Ceph OSD Status
====================

::

    ./rook/show-ceph-osd-status.sh 
    
    ---------------------------------------------- 
    Getting the Rook Ceph OSD Status with Toolbox: 
    kubectl -n rook-ceph exec -it rook-ceph-tools ceph osd status 
    +----+-------------------------------------+-------+-------+--------+---------+--------+---------+-----------+
    | id |                 host                |  used | avail | wr ops | wr data | rd ops | rd data |   state   |
    +----+-------------------------------------+-------+-------+--------+---------+--------+---------+-----------+
    | 0  | rook-ceph-osd-id-0-7d4d4c8794-kgr2d | 34.6G | 53.4G |    0   |     0   |    0   |     0   | exists,up |
    +----+-------------------------------------+-------+-------+--------+---------+--------+---------+-----------+
 
Show Ceph Free Space
====================

::

    ./rook/show-ceph-df.sh 

    ---------------------------------------------- 
    Getting the Rook Ceph df with Toolbox: 
    kubectl -n rook-ceph exec -it rook-ceph-tools ceph df 
    GLOBAL:
        SIZE       AVAIL      RAW USED     %RAW USED 
        90199M     54756M       35443M         39.29 
    POOLS:
        NAME            ID     USED     %USED     MAX AVAIL     OBJECTS 
        replicapool     1        99         0        50246M          12 

Show Ceph RDOS Free Space
=========================

::

    ./rook/show-ceph-rados-df.sh 
    
    ---------------------------------------------- 
    Getting the Rook Ceph rados df with Toolbox: 
    kubectl -n rook-ceph exec -it rook-ceph-tools rados df 
    POOL_NAME   USED OBJECTS CLONES COPIES MISSING_ON_PRIMARY UNFOUND DEGRADED RD_OPS RD   WR_OPS WR   
    replicapool   99      12      0     12                  0       0        0    484 381k     17 7168 

    total_objects    12
    total_used       35443M
    total_avail      54756M
    total_space      90199M

Out of IP Addresses
===================

Flannel can exhaust all available ip addresses in the CIDR network range. When this happens please run the following command to clean up the local cni network files:

::

    ./tools/reset-flannel-cni-networks.sh

AntiNex Stack Status
--------------------

Here are the AntiNex repositories, documentation and build reports:

.. list-table::
   :header-rows: 1

   * - Component
     - Build
     - Docs Link
     - Docs Build
   * - `REST API <https://github.com/jay-johnson/train-ai-with-django-swagger-jwt>`__
     - .. image:: https://travis-ci.org/jay-johnson/train-ai-with-django-swagger-jwt.svg?branch=master
           :alt: Travis Tests
           :target: https://travis-ci.org/jay-johnson/train-ai-with-django-swagger-jwt.svg
     - `Docs <http://antinex.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex/badge/?version=latest
           :alt: Read the Docs REST API Tests
           :target: https://readthedocs.org/projects/antinex/badge/?version=latest
   * - `Core Worker <https://github.com/jay-johnson/antinex-core>`__
     - .. image:: https://travis-ci.org/jay-johnson/antinex-core.svg?branch=master
           :alt: Travis AntiNex Core Tests
           :target: https://travis-ci.org/jay-johnson/antinex-core.svg
     - `Docs <http://antinex-core-worker.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-core-worker/badge/?version=latest
           :alt: Read the Docs AntiNex Core Tests
           :target: http://antinex-core-worker.readthedocs.io/en/latest/?badge=latest
   * - `Network Pipeline <https://github.com/jay-johnson/network-pipeline>`__
     - .. image:: https://travis-ci.org/jay-johnson/network-pipeline.svg?branch=master
           :alt: Travis AntiNex Network Pipeline Tests
           :target: https://travis-ci.org/jay-johnson/network-pipeline.svg
     - `Docs <http://antinex-network-pipeline.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-network-pipeline/badge/?version=latest
           :alt: Read the Docs AntiNex Network Pipeline Tests
           :target: https://readthedocs.org/projects/antinex-network-pipeline/badge/?version=latest
   * - `AI Utils <https://github.com/jay-johnson/antinex-utils>`__
     - .. image:: https://travis-ci.org/jay-johnson/antinex-utils.svg?branch=master
           :alt: Travis AntiNex AI Utils Tests
           :target: https://travis-ci.org/jay-johnson/antinex-utils.svg
     - `Docs <http://antinex-ai-utilities.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-ai-utilities/badge/?version=latest
           :alt: Read the Docs AntiNex AI Utils Tests
           :target: http://antinex-ai-utilities.readthedocs.io/en/latest/?badge=latest
   * - `Client <https://github.com/jay-johnson/antinex-client>`__
     - .. image:: https://travis-ci.org/jay-johnson/antinex-client.svg?branch=master
           :alt: Travis AntiNex Client Tests
           :target: https://travis-ci.org/jay-johnson/antinex-client.svg
     - `Docs <http://antinex-client.readthedocs.io/en/latest/>`__
     - .. image:: https://readthedocs.org/projects/antinex-client/badge/?version=latest
           :alt: Read the Docs AntiNex Client Tests
           :target: https://readthedocs.org/projects/antinex-client/badge/?version=latest

Reset Cluster
-------------

Here is a video showing how to reset the local Kubernetes cluster.

.. image:: https://asciinema.org/a/193472.png
    :target: https://asciinema.org/a/193472?autoplay=1
    :alt: Reset Cluster

Please be careful as these commands will shutdown all containers and reset the Kubernetes cluster.

Run as root:

::

    sudo su
    kubeadm reset -f
    ./prepare.sh

Or use the file:

::

    sudo su
    ./tools/cluster-reset.sh

Or the full reset and deploy once ready:

::

    sudo su
    cert_env=dev; ./tools/reset-flannel-cni-networks.sh; ./tools/cluster-reset.sh ; ./user-install-kubeconfig.sh ; sleep 30; ./deploy-resources.sh splunk ${cert_env}
    exit
    # as your user
    ./user-install-kubeconfig.sh
    # depending on testing vs prod:
    # ./start.sh splunk
    # ./start.sh splunk prod

Development
-----------

Right now, the python virtual environment is only used to bring in ansible for running playbooks, but it will be used in the future with the kubernetes python client as I start using it more and more.

::

    virtualenv -p python3 /opt/venv && source /opt/venv/bin/activate && pip install -e .

Testing
-------

::

    py.test

or

::

    python setup.py test

License
-------

Apache 2.0 - Please refer to the LICENSE_ for more details

.. _License: https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/LICENSE
