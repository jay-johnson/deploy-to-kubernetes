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
    ceph-mds-85b4fbb478-9fhf4                   1/1     Running     1          8m25s
    ceph-mds-keyring-generator-92fbx            0/1     Completed   0          8m25s
    ceph-mgr-588577d89f-758qx                   1/1     Running     0          8m25s
    ceph-mgr-keyring-generator-xjqn4            0/1     Completed   0          8m25s
    ceph-mon-cd2mr                              3/3     Running     0          8m25s
    ceph-mon-check-549b886885-jsx9k             1/1     Running     0          8m25s
    ceph-mon-keyring-generator-rlvjh            0/1     Completed   0          8m25s
    ceph-mon-mc75f                              3/3     Running     0          8m25s
    ceph-mon-r2kdj                              3/3     Running     0          8m25s
    ceph-namespace-client-key-generator-qhmcz   0/1     Completed   0          8m25s
    ceph-osd-dev-vdb-6xbr9                      1/1     Running     0          8m25s
    ceph-osd-dev-vdb-lmhcc                      1/1     Running     0          8m25s
    ceph-osd-dev-vdb-vlfw2                      1/1     Running     0          8m25s
    ceph-osd-keyring-generator-429cj            0/1     Completed   0          8m25s
    ceph-rbd-provisioner-5cf47cf8d5-9fplr       1/1     Running     0          8m25s
    ceph-rbd-provisioner-5cf47cf8d5-gcqrr       1/1     Running     0          8m25s
    ceph-rgw-7b9677854f-k6hj7                   1/1     Running     0          8m25s
    ceph-rgw-keyring-generator-8cv49            0/1     Completed   0          8m25s
    ceph-storage-keys-generator-bvw8d           0/1     Completed   0          8m25s

Check Cluster Status
====================

With the cluster running you can quickly check the cluster status with:

::

    ./cluster-status.sh
    --------------------------------------------------
    Getting Ceph cluster status:

    kubectl -n ceph exec -ti ceph-mon-gtx7h -c ceph-mon -- ceph -s
    cluster:
        id:     6cd2b8fb-4a50-43c0-9495-02c9a4438c87
        health: HEALTH_OK

    services:
        mon: 3 daemons, quorum master1.example.com,master2.example.com,master3.example.com
        mgr: master2.example.com(active)
        mds: cephfs-1/1/1 up  {0=mds-ceph-mds-85b4fbb478-vj2vs=up:active}
        osd: 3 osds: 3 up, 3 in
        rgw: 1 daemon active

    data:
        pools:   6 pools, 48 pgs
        objects: 208 objects, 3359 bytes
        usage:   324 MB used, 284 GB / 284 GB avail
        pgs:     48 active+clean


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

OSD Issues
==========

Take a look at the ``osd-dev-vdb`` pod logs

::

    ./logs-osd-prepare-pod.sh

OSD Pod Prepare is Unable to Zap
--------------------------------

To fix this error below, make sure the ``ceph-overrides.yaml`` is using the correct ``/dev/vdb`` path:

::

    Traceback (most recent call last):
    File "/usr/sbin/ceph-disk", line 9, in <module>
        load_entry_point('ceph-disk==1.0.0', 'console_scripts', 'ceph-disk')()
    File "/usr/lib/python2.7/dist-packages/ceph_disk/main.py", line 5717, in run
        main(sys.argv[1:])
    File "/usr/lib/python2.7/dist-packages/ceph_disk/main.py", line 5668, in main
        args.func(args)
    File "/usr/lib/python2.7/dist-packages/ceph_disk/main.py", line 4737, in main_zap
        zap(dev)
    File "/usr/lib/python2.7/dist-packages/ceph_disk/main.py", line 1681, in zap
        raise Error('not full block device; cannot zap', dev)
    ceph_disk.main.Error: Error: not full block device; cannot zap: /dev/vdb1

OSD unable to find IP Address
-----------------------------

To fix this error below, make sure to either remove the ``network`` definitions in the ``ceph-overrides.yaml``.

::

    + exec /usr/bin/ceph-osd --cluster ceph -f -i 2 --setuser ceph --setgroup disk
    2019-02-24 08:53:40.592021 7f4313687e00 -1 unable to find any IP address in networks '172.21.0.0/20' interfaces ''

Cluster Status Tools
====================

Show All
--------

::

    ./ceph/show-ceph-all.sh

Show Cluster Status
-------------------

::

    ./ceph/show-ceph-status.sh

::

    ----------------------------------------------
    Getting Ceph status:
    kubectl -n ceph exec -it ceph-rgw-7b9677854f-k6hj7 -- ceph status
    cluster:
        id:     384880f1-23f3-4a83-bff8-93624120a4cf
        health: HEALTH_OK

    services:
        mon: 3 daemons, quorum master1.example.com,master2.example.com,master3.example.com
        mgr: master3.example.com(active)
        mds: cephfs-1/1/1 up  {0=mds-ceph-mds-85b4fbb478-9fhf4=up:active}
        osd: 3 osds: 3 up, 3 in
        rgw: 1 daemon active

    data:
        pools:   6 pools, 48 pgs
        objects: 208 objects, 3359 bytes
        usage:   324 MB used, 284 GB / 284 GB avail
        pgs:     48 active+clean

Show Ceph DF
------------

::

    ./ceph/show-ceph-df.sh

::

    ----------------------------------------------
    Getting Ceph df:
    kubectl -n ceph exec -it ceph-rgw-7b9677854f-k6hj7 -- ceph df
    GLOBAL:
        SIZE     AVAIL     RAW USED     %RAW USED
        284G      284G         323M          0.11
    POOLS:
        NAME                    ID     USED     %USED     MAX AVAIL     OBJECTS
        .rgw.root               1      1113         0        92261M           4
        cephfs_data             2         0         0        92261M           0
        cephfs_metadata         3      2246         0        92261M          21
        default.rgw.control     4         0         0        92261M           8
        default.rgw.meta        5         0         0        92261M           0
        default.rgw.log         6         0         0        92261M           0

Show Ceph OSD Status
--------------------

::

    ./ceph/show-ceph-osd-status.sh

::

    Getting Ceph osd status:
    kubectl -n ceph exec -it ceph-rgw-7b9677854f-k6hj7 -- ceph osd status
    +----+---------------------+-------+-------+--------+---------+--------+---------+-----------+
    | id |         host        |  used | avail | wr ops | wr data | rd ops | rd data |   state   |
    +----+---------------------+-------+-------+--------+---------+--------+---------+-----------+
    | 0  | master2.example.com |  107M | 94.8G |    1   |    18   |    0   |    13   | exists,up |
    | 1  | master1.example.com |  107M | 94.8G |    3   |   337   |    0   |     0   | exists,up |
    | 2  | master3.example.com |  108M | 94.8G |    5   |   315   |    1   |   353   | exists,up |
    +----+---------------------+-------+-------+--------+---------+--------+---------+-----------+

Show Ceph Rados DF
------------------

::

    ./ceph/show-ceph-rados-df.sh

::

    Getting Ceph rados df:
    kubectl -n ceph exec -it ceph-rgw-7b9677854f-k6hj7 -- rados df
    POOL_NAME           USED OBJECTS CLONES COPIES MISSING_ON_PRIMARY UNFOUND DEGRADED RD_OPS RD   WR_OPS WR
    .rgw.root           1113       4      0     12                  0       0        0     12 8192      4 4096
    cephfs_data            0       0      0      0                  0       0        0      0    0      0    0
    cephfs_metadata     2246      21      0     63                  0       0        0      0    0     42 8192
    default.rgw.control    0       8      0     24                  0       0        0      0    0      0    0

    total_objects    33
    total_used       323M
    total_avail      284G
    total_space      284G

Uninstall
=========

To uninstall the ceph cluster and leave the mounted KVM disks ``/dev/vdb`` untouched:

::

    ./_uninstall.sh

Uninstall and Reformat KVM Images
---------------------------------

To uninstall the ceph cluster and reformat the mounted KVM disks ``/dev/vdb``:

.. warning:: Running this will destroy all data across the cluster by reformatting the /dev/vdb block devices in each vm

::

    ./_uninstall.sh -f
