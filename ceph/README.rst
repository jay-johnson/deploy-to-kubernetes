Running a Ceph Cluster on Kubernetes
====================================

This installer was built to replace Rook-Ceph after hitting cluster stability after ~30 days in 2019. The steps are taken from the Ceph Helm installer:

http://docs.ceph.com/docs/mimic/start/kube-helm/

Set Up
======

This guide is for setting up a ceph cluster inside kubernetes and using attached disk images that are attached to 3 CentOS 7 vm's running in KVM.

By default, the disk images will be installed at: ``/cephdata/m[123]/k8-centos-m[123]``.

Build KVM HDD Images
====================

Generate ``100 GB`` hdd images for the ceph cluster with 1 qcow2 image for each of the three vm's:

::

    ./ceph/kvm-build-images.sh

The files are saved here:

::

    /cephdata/
    ├── m1
    │   └── k8-centos-m1
    ├── m2
    │   └── k8-centos-m2
    └── m3
        └── k8-centos-m3

Attach KVM Images to VMs
========================

This will attach each ``100 GB`` image to the correct vm: ``m1``, ``m2`` or ``m3``

::

    ./ceph/kvm-attach-images.sh

Format Disks in VM
==================

With automatic ssh root login access, you can run this to partition, mount and format each of the new images:

.. warning:: Please be careful running this as it can delete any previously saved data.

::

    ./_kvm-format-images.sh

Deploy Ceph Cluster
===================

Ceph requires running a local Helm repo server (just like the Redis cluster does) and building then installing chart to get the cluster pods running.

::

    ./ceph/run.sh

Show Cluster Logs
=================

::

    ./ceph/logs.sh

Show Pods
=========

::

    ./ceph/show-pods.sh

::

    --------------------------------------------------
    Getting Ceph pods with:

    kubectl get pods -n ceph

    NAME                                        READY   STATUS      RESTARTS   AGE
    ceph-mds-85b4fbb478-pcssx                   0/1     Running     0          15s
    ceph-mds-keyring-generator-2qdm6            0/1     Completed   0          15s
    ceph-mgr-588577d89f-l8wxs                   0/1     Running     0          15s
    ceph-mgr-keyring-generator-wf2b4            0/1     Completed   0          15s
    ceph-mon-89dpz                              3/3     Running     0          15s
    ceph-mon-95h5c                              2/3     Running     0          15s
    ceph-mon-check-549b886885-55kj7             1/1     Running     0          15s
    ceph-mon-clqh4                              3/3     Running     0          15s
    ceph-mon-keyring-generator-m76bg            0/1     Completed   0          15s
    ceph-namespace-client-key-generator-pzxjx   0/1     Completed   0          15s
    ceph-osd-keyring-generator-rzspv            0/1     Completed   0          15s
    ceph-rbd-provisioner-5cf47cf8d5-4ntbb       1/1     Running     0          15s
    ceph-rbd-provisioner-5cf47cf8d5-5rzdp       1/1     Running     0          15s
    ceph-rgw-7b9677854f-lm7zm                   0/1     Running     0          15s
    ceph-rgw-keyring-generator-fg85h            0/1     Completed   0          15s
    ceph-storage-keys-generator-dgqsz           0/1     Completed   0          15s

Check Cluster Status
====================

With the cluster running you can quickly check the cluster status with:

::

    ./cluster-status.sh

Debugging
=========

When setting up new devices with kubernetes you will see the ``osd`` pods failing and here is a tool to describe one of the pods quickly.

::

    ./describe-osd.sh

Previous Cluster Cleanup Failed
-------------------------------

Please run the ``_uninstall.sh`` if you see this kind of error when running the ``cluster-status.sh``:

::

    ./cluster-status.sh
    --------------------------------------------------
    Getting Ceph cluster status:

    kubectl -n ceph exec -ti ceph-mon-p9tvw -c ceph-mon -- ceph -s
    2019-02-24 06:02:12.468777 7f90f6509700  0 librados: client.admin authentication error (1) Operation not permitted
    [errno 1] error connecting to the cluster
    command terminated with exit code 1


