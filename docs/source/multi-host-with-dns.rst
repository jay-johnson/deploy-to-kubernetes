Managing a Multi-Host Kubernetes Cluster with an External DNS Server
--------------------------------------------------------------------

This guide is for managing a multi-host Kubernetes cluster deployed across 3 CentOS 7 vms. Once running, you can access the sample applications from outside the cluster with the included DNS nameserver (bind9).

Overview
========
    
Set up 3 CentOS 7 vms and run an external DNS (using bind9) for a distributed, multi-host Kubernetes cluster that is accessible on the domain: ``example.com``

Background
==========

Why did you make this?

Before using DNS, I was stuck managing and supporting many DHCP IP addresses in ``/etc/hosts`` like below. This ended up being way more time consuming than necessary. So I made this guide for adding a DNS server over a multi-host Kubernetes cluster.

::

    ##############################################################
    #
    # find the MAC using: ifconfig | grep -A 3 enp | grep ether | awk '{print $2}'
    #
    # MAC address:  08:00:27:37:80:e1
    192.168.0.101   m1 master1 master1.example.com api.example.com ceph.example.com mail.example.com minio.example.com pgadmin.example.com s3.example.com www.example.com
    #
    # MAC address:  08:00:27:21:80:19
    192.168.0.102   m2 master2 master2.example.com jupyter.example.com
    #
    # MAC address:  08:00:27:21:80:29
    192.168.0.103   m3 master3 master3.example.com splunk.example.com

Allocate VM Resources
=====================

#.  Each vm should have at least 70 GB hard drive space

#.  Each vm should have at least 2 CPU cores and 4 GB memory

#.  Each vm should have a bridge network adapter that is routeable

#.  Take note of each vm's bridge network adapter's MAC address (this will help finding the vm's IP address in a router's web app or using network detection tools)

Install CentOS 7
================

Install CentOS 7 on each vm and `here is the CentOS 7 DVD download page <http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-DVD-1804.iso>`__

#.  Additional notes

    - I use the `multihost/_reset-cluster-using-ssh.sh script <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/_reset-cluster-using-ssh.sh>`__ to reset the cluster using ssh.

    - I recently moved from running on Virtualbox with Ubuntu 18.04 to KVM with CentOS 7, and am tracking the changes in the ``multihost`` directory. This includes how each vm's bridge network adapter uses a ``ifcg-eth0`` interface and starter scripts to make this process repeatable. Please note, it will continue to be a work in progress.

        - `create a vm with kvm <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/kvm/create-centos-vm.sh>`__
        - `start m1 vm <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/kvm/start-m1.sh>`__
        - `start m2 vm <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/kvm/start-m2.sh>`__
        - `start m3 vm <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/kvm/start-m3.sh>`__
        - `m1 directory <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/m1>`__
        - `m2 directory <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/m2>`__
        - `m3 directory <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/m3>`__

Prepare VMs
===========

#.  This command needs to run as root and will prepare the CentOS vm for running Kubernetes.

    Use this `script to prepare a CentOS 7 vm <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/centos/prepare.sh>`__ for running in this cluster.

    ::

        ./centos/prepare.sh

#.  Confirm Kube Proxy Kernel Modules are Loaded

    The vanilla CentOS 7 installer does not install the required kernel modules. By running the ``centos/prepare-vm.sh`` script, each vm's kernel should support the required kube proxy kernel odules:

    ::

        lsmod | grep ip_vs
        ip_vs_sh               12688  0
        ip_vs_wrr              12697  0
        ip_vs_rr               12600  0
        ip_vs                 141473  6 ip_vs_rr,ip_vs_sh,ip_vs_wrr
        nf_conntrack          133053  9 ip_vs,nf_nat,nf_nat_ipv4,nf_nat_ipv6,xt_conntrack,nf_nat_masquerade_ipv4,nf_conntrack_netlink,nf_conntrack_ipv4,nf_conntrack_ipv6
        libcrc32c              12644  5 xfs,ip_vs,libceph,nf_nat,nf_conntrack

Install Kubernetes
==================

Install Kubernetes on each vm using your own tool(s) of choice or the `deploy to kubernetes tool I wrote <https://github.com/jay-johnson/deploy-to-kubernetes#install>`__. This repository builds each vm in the cluster as a master node, and will use kubeadm join to add **master2.example.com** and **master3.example.com** to the initial, primary node **master1.example.com**.

Start All Kubernetes Cluster VMs
--------------------------------

#.  Start Kubernetes on the Master 1 VM

    Once Kubernetes is running on your initial, primary master vm (mine is on **master1.example.com**), you can prepare the cluster with the commands:

    ::

        # ssh into your initial, primary vm
        ssh 192.168.0.101

    If you're using the `deploy-to-kubernetes repository <https://github.com/jay-johnson/deploy-to-kubernetes>`__ to run an AI stack on Kubernetes, then the following commands will start the master 1 vm for preparing the cluster to run the stack:

    ::

        # make sure this repository is cloned on all cluster nodes to: /opt/deploy-to-kubernetes
        # git clone https://github.com/jay-johnson/deploy-to-kubernetes.git /opt/deploy-to-kubernetes
        sudo su
        # for preparing to run the example.com cluster use:
        cert_env=dev; cd /opt/deploy-to-kubernetes; ./tools/reset-flannel-cni-networks.sh; ./tools/cluster-reset.sh ; ./user-install-kubeconfig.sh

#.  Confirm only 1 Cluster Node is in the Ready State

    ::

        kubectl get nodes -o wide --show-labels

#.  Print the Cluster Join Command on Master 1

    ::

        kubeadm token create --print-join-command

#.  Join Master 2 to Master 1

    ::

        ssh 192.168.0.102
        sudo su
        kubeadm join 192.168.0.101:6443 --token <token> --discovery-token-ca-cert-hash <hash>
        exit

#.  Join Master 3 to Master 1

    ::

        ssh 192.168.0.103
        sudo su
        kubeadm join 192.168.0.101:6443 --token <token> --discovery-token-ca-cert-hash <hash>
        exit

Verify the Cluster has 3 Ready Nodes
====================================

#.  Set up your host for using kubectl

    ::

        sudo apt-get install -y kubectl

#.  Copy the Kubernetes Config from Master 1 to your host

    ::

        mkdir -p 775 ~/.kube/config >> /dev/null
        scp 192.168.0.101:/root/.kube/config ~/.kube/config

#.  Verify the 3 nodes (vms) are in a Status of Ready in the Kubernetes cluster

    ::

        kubectl get nodes -o wide --show-labels
        NAME                  STATUS    ROLES     AGE       VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION               CONTAINER-RUNTIME   LABELS
        master1.example.com   Ready     master    7h        v1.11.2   192.168.0.101   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://18.6.1     backend=disabled,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,ceph=enabled,datascience=disabled,frontend=enabled,kubernetes.io/hostname=master1.example.com,minio=enabled,node-role.kubernetes.io/master=,splunk=disabled
        master2.example.com   Ready     <none>    7h        v1.11.2   192.168.0.102   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://18.6.1     backend=enabled,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,ceph=enabled,datascience=enabled,frontend=enabled,kubernetes.io/hostname=master2.example.com,minio=disabled,splunk=disabled
        master3.example.com   Ready     <none>    7h        v1.11.2   192.168.0.103   <none>        CentOS Linux 7 (Core)   3.10.0-862.11.6.el7.x86_64   docker://18.6.1     backend=enabled,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,ceph=enabled,datascience=disabled,frontend=disabled,kubernetes.io/hostname=master3.example.com,minio=disabled,splunk=enabled

Deploy a Distributed AI Stack to a Multi-Host Kubernetes Cluster
----------------------------------------------------------------

This will deploy the `AntiNex AI stack <https://github.com/jay-johnson/deploy-to-kubernetes#deploying-a-distributed-ai-stack-to-kubernetes-on-centos>`__ to the new multi-host Kubernetes cluster.

Deploy Cluster Resources
========================

#.  ssh into the master 1 host:

    ::

        ssh 192.168.0.101

#.  Install Go

    The Postgres and pgAdmin containers require running as root with Go installed on the master 1 host:

    ::

        # note this has only been tested on CentOS 7:
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

#.  Deploy the stack's resources:

    ::

        cert_env=dev
        cd /opt/deploy-to-kubernetes; ./deploy-resources.sh splunk ceph ${cert_env}
        exit

Start the AI Stack
==================

#.  Run the Start command

    ::

        cert_env=dev
        ./start.sh splunk ceph ${cert_env}

#.  Verify the Stack is Running

    .. note:: This may take a few minutes to download all images and sync files across the cluster.

    ::

        NAME                                READY     STATUS    RESTARTS   AGE
        api-774765b455-nlx8z                1/1       Running   0          4m
        api-774765b455-rfrcw                1/1       Running   0          4m
        core-66994c9f4d-nq4sh               1/1       Running   0          4m
        jupyter-577696f945-cx5gr            1/1       Running   0          4m
        minio-deployment-7fdcfd6775-pmdww   1/1       Running   0          5m
        nginx-5pp8n                         1/1       Running   0          5m
        nginx-dltv8                         1/1       Running   0          5m
        nginx-kxn7l                         1/1       Running   0          5m
        pgadmin4-http                       1/1       Running   0          5m
        primary                             1/1       Running   0          5m
        redis-master-0                      1/1       Running   0          5m
        redis-metrics-79cfcb86b7-k9584      1/1       Running   0          5m
        redis-slave-7cd9cdc695-jgcsk        1/1       Running   2          5m
        redis-slave-7cd9cdc695-qd5pl        1/1       Running   2          5m
        redis-slave-7cd9cdc695-wxnqh        1/1       Running   2          5m
        splunk-5f487cbdbf-dtv8f             1/1       Running   4          4m
        worker-59bbcd44c6-sd6t5             1/1       Running   0          4m

#.  Verify Minio is Deployed

    ::

        kubectl describe po minio | grep "Node:"
        Node:               master1/192.168.0.101

#.  Verify Ceph is Deployed

    ::

        kubectl describe -n rook-ceph-system po rook-ceph-agent | grep "Node:"
        Node:               master3/192.168.0.103
        Node:               master1/192.168.0.101
        Node:               master2/192.168.0.102

#.  Verify the API is Deployed

    ::

        kubectl describe po api | grep "Node:"
        Node:               master2/192.168.0.102
        Node:               master1/192.168.0.101

#.  Verify Jupyter is Deployed

    ::

        kubectl describe po jupyter | grep "Node:"
        Node:               master2/192.168.0.102

#.  Verify Splunk is Deployed

    ::

        kubectl describe po splunk | grep "Node:"
        Node:               master3/192.168.0.103

Set up an External DNS Server for a Multi-Host Kubernetes Cluster
-----------------------------------------------------------------

Now that you have a local, 3 node Kubernetes cluster, you can set up a bind9 DNS server for making the public-facing frontend nginx ingresses accessible to browsers or other clients on an internal network (like a home lab).

#.  Determine the Networking IP Addresses for VMs

    For this guide the 3 vms use the included netplan yaml files for statically setting their IPs:

    - `m1 with static ip: 192.168.0.101 <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/m1/01-network-manager-all.yaml>`__
    - `m2 with static ip: 192.168.0.102 <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/m2/01-network-manager-all.yaml>`__
    - `m3 with static ip: 192.168.0.103 <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/m3/01-network-manager-all.yaml>`__

    .. warning:: If you do not know each vm's IP address, and you are ok with having a **network sniffing tool** installed on your host like `arp-scan <https://linux.die.net/man/1/arp-scan>`__, then you can use this command to find each vm's IP address from the vm's bridge network adapter's MAC address:

        ::

            arp-scan -q -l --interface <NIC name like enp0s3> | sort | uniq | grep -i "<MAC address>" | awk '{print $1}'

#.  Install DNS

    Pick a vm to be the primary DNS server. For this guide, I am using ``master1.example.com`` with IP: ``192.168.0.101``.

    For DNS this guide uses the `ISC BIND server <https://www.isc.org/downloads/bind/>`__. Here is how to install BIND on CentOS 7:

    ::

        sudo apt install -y bind9 bind9utils bind9-doc dnsutils

#.  Build the Forward Zone File

    Depending on how you want your `Kubernetes affinity (decision logic for determining where applications are deployed) <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity>`__ the forward zone will need to have the correct IP addresses configured to help maximize your available hosting resources. For example, I have my ``master1.example.com`` vm with 3 CPU cores after noticing how much the original 2 cores were being 100% utilized.
    
    The included `forward zone file <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/fwd.example.com.db>`__ uses the ``example.com`` domain outlined below and needs to be saved as the ``root`` user to the location:

    ::

        /etc/bind/fwd.example.com.db

    Based off the original ``/etc/hosts`` file from above, my forward zone file looks like:

    ::

        ;
        ; BIND data file for example.com
        ;
        $TTL    604800
        @   IN  SOA example.com. root.example.com. (
                        20     ; Serial
                    604800     ; Refresh
                    86400     ; Retry
                    2419200     ; Expire
                    604800 )   ; Negative Cache TTL
        ;
        ;@  IN  NS  localhost.
        ;@  IN  A   127.0.0.1
        ;@  IN  AAAA    ::1

        ;Name Server Information
                IN      NS      ns1.example.com.
        ;IP address of Name Server
        ns1     IN      A       192.168.0.101

        ;Mail Exchanger
        example.com.   IN     MX   10   mail.example.com.

        ;A - Record HostName To Ip Address
        @        IN       A      192.168.0.101
        api      IN       A      192.168.0.101
        ceph     IN       A      192.168.0.101
        master1  IN       A      192.168.0.101
        mail     IN       A      192.168.0.101
        minio    IN       A      192.168.0.101
        pgadmin  IN       A      192.168.0.101
        www      IN       A      192.168.0.101
        api      IN       A      192.168.0.102
        jenkins  IN       A      192.168.0.102
        jupyter  IN       A      192.168.0.102
        aejupyter  IN       A      192.168.0.102
        master2  IN       A      192.168.0.102
        master3  IN       A      192.168.0.103
        splunk   IN       A      192.168.0.103

    .. note:: The API has two A records for placement on two of the vms ``192.168.0.103`` and ``192.168.0.102``

#.  Verify the Forward Zone File

    ::

        named-checkzone example.com /etc/bind/fwd.example.com.db
        zone example.com/IN: loaded serial 20
        OK

#.  Build the Reverse Zone File

    Depending on how you want your `Kubernetes affinity (decision logic for determining where applications are deployed) <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity>`__ the reverse zone will need to have the correct IP addresses configured to help maximize your available hosting resources.
    
    The included `reverse zone file <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/multihost/rev.example.com.db>`__ uses the ``example.com`` domain outlined below and needs to be saved as the ``root`` user to the location:

    ::

        /etc/bind/rev.example.com.db

    Based off the original ``/etc/hosts`` file from above, my reverse zone file looks like:

    ::

        ;
        ; BIND reverse zone data file for example.com
        ;
        $TTL    604800
        @   IN  SOA example.com. root.example.com. (
                        20     ; Serial
                    604800     ; Refresh
                    86400     ; Retry
                    2419200     ; Expire
                    604800 )   ; Negative Cache TTL
        ;
        ;@  IN  NS  localhost.
        ;1.0.0  IN  PTR localhost.

        ;Name Server Information
                IN      NS     ns1.example.com.
        ;Reverse lookup for Name Server
        101     IN      PTR    ns1.example.com.
        ;PTR Record IP address to HostName
        101     IN      PTR    api.example.com.
        101     IN      PTR    example.com
        101     IN      PTR    ceph.example.com.
        101     IN      PTR    mail.example.com.
        101     IN      PTR    master1.example.com.
        101     IN      PTR    minio.example.com.
        101     IN      PTR    pgadmin.example.com.
        101     IN      PTR    www.example.com.
        102     IN      PTR    api.example.com.
        102     IN      PTR    jupyter.example.com.
        102     IN      PTR    aejupyter.example.com.
        102     IN      PTR    jenkins.example.com.
        102     IN      PTR    master2.example.com.
        103     IN      PTR    master3.example.com.
        103     IN      PTR    splunk.example.com.

    .. note:: The API has two A records for placement on two of the vms ``101`` and ``102``

#.  Verify the Reverse Zone File

    ::

        named-checkzone 0.168.192.in-addr.arpa /etc/bind/rev.example.com.db
        zone 0.168.192.in-addr.arpa/IN: loaded serial 20
        OK

#.  Restart and Enable Bind9 to Run on VM Restart

    ::

        systemctl restart bind9
        systemctl enable bind9

#.  Check the Bind9 status

    ::

        systemctl status bind9

#.  From another host set up the Netplan yaml file

    Here is the ``192.168.0.101`` vm's ``/etc/sysconfig/network-scripts/ifcfg-eth0`` network interface file that uses the external BIND server for DNS. Please edit this file as root and according to your vm's networking IP address and static vs dhcp requirements.

    ::

        /etc/sysconfig/network-scripts/ifcfg-eth0
        TYPE="Ethernet"
        PROXY_METHOD="none"
        BROWSER_ONLY="no"
        BOOTPROTO="none"
        DEFROUTE="yes"
        IPV4_FAILURE_FATAL="no"
        IPV6INIT="yes"
        IPV6_AUTOCONF="yes"
        IPV6_DEFROUTE="yes"
        IPV6_FAILURE_FATAL="no"
        IPV6_ADDR_GEN_MODE="stable-privacy"
        NAME="eth0"
        UUID="747d880d-0c18-5a9f-c0a5-e9e80cd6be46"
        DEVICE="eth0"
        ONBOOT="yes"
        IPADDR="192.168.0.101"
        PREFIX="24"
        GATEWAY="192.168.0.1"
        DNS1="192.168.0.100"
        DNS2="8.8.8.8"
        DNS3="8.8.4.4"
        IPV6_PRIVACY="no" 

#.  Verify the Cluster DNS Alias Records

    The Django REST API web application has two alias records:

    ::

        dig api.example.com | grep IN | tail -2
        api.example.com.	7193	IN	A	192.168.0.101
        api.example.com.	7193	IN	A	192.168.0.102

    Rook Ceph dashboard has one alias record:

    ::

        dig ceph.example.com | grep IN | tail -1
        ceph.example.com.	604800	IN	A	192.168.0.101

    Minio S3 has one alias record:

    ::

        dig minio.example.com | grep IN | tail -1
        minio.example.com.	604800	IN	A	192.168.0.101

    Jupyter has one alias record:

    ::

        dig jupyter.example.com | grep IN | tail -1
        jupyter.example.com.	604800	IN	A	192.168.0.102

    pgAdmin has one alias record:

    ::

        dig pgadmin.example.com | grep IN | tail -1
        pgadmin.example.com.	604800	IN	A	192.168.0.101

    The Kubernetes master 1 vm has one alias record:

    ::

        dig master1.example.com | grep IN | tail -1
        master1.example.com.	7177	IN	A	192.168.0.101

    The Kubernetes master 2 vm has one alias record:

    ::

        dig master2.example.com | grep IN | tail -1
        master2.example.com.	604800	IN	A	192.168.0.102

    The Kubernetes master 3 vm has one alias record:

    ::

        dig master3.example.com | grep IN | tail -1
        master3.example.com.	604800	IN	A	192.168.0.103

Start using the Stack
---------------------

With the DNS server ready, you can now migrate the database and create the first user ``trex`` to start using the stack.

Run a Database Migration
========================

Here is a video showing how to apply database schema migrations in the cluster:

.. raw:: html

    <a href="https://asciinema.org/a/193491?autoplay=1" target="_blank"><img src="https://asciinema.org/a/193491.png"/></a>

To apply new Django database migrations, run the following command:

::

    # from /opt/deploy-to-kubernetes
    ./api/migrate-db.sh

Create a User
=============

Create the user ``trex`` with password ``123321`` on the REST API.

::

    ./api/create-user.sh

Deployed Web Applications
-------------------------

Once the stack is deployed, here are the hosted web application urls. These urls are made accessible by the included `nginx-ingress <https://github.com/nginxinc/kubernetes-ingress>`__.

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

Train AI with Django REST API
-----------------------------

Please refer to the `Training AI with the Django REST API <https://github.com/jay-johnson/deploy-to-kubernetes#training-ai-with-the-django-rest-api>`__ for continuing to examine how to run a `distributed AI stack on Kubernetes <https://deploy-to-kubernetes.readthedocs.io/en/latest/#training-ai-with-the-django-rest-api>`__.

Next Steps
----------

- `Add Heptio's Ark for disaster recovery <https://github.com/heptio/ark>`__
- `Add Jenkins into the stack using Helm <https://github.com/helm/charts/tree/master/stable/jenkins#jenkins-helm-chart>`__

More Information
================

After seeing high CPU utilization across the cluster, this guide was moved from Ubuntu 18.04 vms to CentOS 7. 
