Running a Distributed Ceph Cluster on a Kubernetes Cluster
==========================================================

Overview
--------

This guide `automates the install of a native ceph cluster inside a running kubernetes native cluster <http://docs.ceph.com/docs/mimic/start/kube-helm/>`__. It requires creating and attaching 3 additional hard drive disk images (each ``100 GB``) to each of your kubernetes cluster vms (tested on 3 CentOS 7). This guide assumes your kubernetes cluster is using ``kvm`` with ``virsh`` for running the ``attach-disk`` commands.

By default, the disk images will be installed at: ``/cephdata/m[123]/k8-centos-m[123]``. These disks will be automatically partitioned and formatted using `ceph zap <http://docs.ceph.com/docs/mimic/ceph-volume/lvm/zap/>`__, and zap will format each disk using the `recommended XFS filesystem <http://docs.ceph.com/docs/jewel/rados/configuration/filesystem-recommendations/>`__.

.. note:: This is a work in progress.

Background
----------

This installer was built to replace Rook-Ceph after hitting cluster stability after ~30 days in 2019. The steps are taken from the Ceph Helm installer:

http://docs.ceph.com/docs/mimic/start/kube-helm/

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

    ./ceph/_kvm-format-images.sh

Install Ceph on All Kubernetes Nodes
====================================

Please add ``ceph-common`` to all nodes before deploying ceph.

For additional set up please refer to the official ceph docs:

http://docs.ceph.com/docs/master/install/get-packages/

For CentOS 7 you can run:

::

    echo "installing ceph from steps on: http://docs.ceph.com/docs/master/install/get-packages/"
    sudo rpm --import "https://download.ceph.com/keys/release.asc"
    sudo yum install -y ceph-common

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
    ceph-mds-85b4fbb478-wjmxb                   1/1     Running     1          4m38s
    ceph-mds-keyring-generator-pvh4l            0/1     Completed   0          4m38s
    ceph-mgr-588577d89f-w8p8v                   1/1     Running     1          4m38s
    ceph-mgr-keyring-generator-76l5r            0/1     Completed   0          4m38s
    ceph-mon-429mk                              3/3     Running     0          4m39s
    ceph-mon-6fvv6                              3/3     Running     0          4m39s
    ceph-mon-75n4t                              3/3     Running     0          4m39s
    ceph-mon-check-549b886885-cb64q             1/1     Running     0          4m38s
    ceph-mon-keyring-generator-q26p2            0/1     Completed   0          4m38s
    ceph-namespace-client-key-generator-bbvt2   0/1     Completed   0          4m38s
    ceph-osd-dev-vdb-96v7h                      1/1     Running     0          4m39s
    ceph-osd-dev-vdb-g9zkg                      1/1     Running     0          4m39s
    ceph-osd-dev-vdb-r5fxr                      1/1     Running     0          4m39s
    ceph-osd-keyring-generator-6pg77            0/1     Completed   0          4m38s
    ceph-rbd-provisioner-5cf47cf8d5-kbfvt       1/1     Running     0          4m38s
    ceph-rbd-provisioner-5cf47cf8d5-pwj4s       1/1     Running     0          4m38s
    ceph-rgw-7b9677854f-8d7s5                   1/1     Running     1          4m38s
    ceph-rgw-keyring-generator-284kp            0/1     Completed   0          4m38s
    ceph-storage-keys-generator-bc6dq           0/1     Completed   0          4m38s

Check Cluster Status
====================

With the cluster running you can quickly check the cluster status with:

::

    ./ceph/cluster-status.sh
    --------------------------------------------------
    Getting Ceph cluster status:

    kubectl -n ceph exec -ti ceph-mon-check-549b886885-cb64q -c ceph-mon -- ceph -s
    cluster:
        id:     aa06915f-3cf6-4f74-af69-9afb41bf464d
        health: HEALTH_OK

    services:
        mon: 3 daemons, quorum master1.example.com,master2.example.com,master3.example.com
        mgr: master2.example.com(active)
        mds: cephfs-1/1/1 up  {0=mds-ceph-mds-85b4fbb478-wjmxb=up:active}
        osd: 3 osds: 3 up, 3 in
        rgw: 1 daemon active

    data:
        pools:   7 pools, 148 pgs
        objects: 208 objects, 3359 bytes
        usage:   325 MB used, 284 GB / 284 GB avail
        pgs:     148 active+clean

Debugging
=========

When setting up new devices with kubernetes you will see the ``osd`` pods failing and here is a tool to describe one of the pods quickly.

::

    ./ceph/describe-osd.sh

Watch all Ceph Logs with Kubetail
---------------------------------

When testing a configuration change or debugging something it can help to see what all the pods are doing using `kubetail <https://github.com/johanhaleby/kubetail>`__

::

    ./ceph/logs-kt-ceph.sh

or manually with:

::

    kubetail ceph -c cluster-log-tailer -n ceph

Watch the Ceph Mon Logs with Kubetail
-------------------------------------

::

    kubetail ceph-mon -c cluster-log-tailer -n ceph

Attach Successful but Mounting a Ceph PVC fails
-----------------------------------------------

Even if the cluster is stable, your pv's can attach but fail to mount due to:

::

    Events:
    Type     Reason                  Age                 From                          Message
    ----     ------                  ----                ----                          -------
    Normal   Scheduled               3m25s               default-scheduler             Successfully assigned default/busybox-mount to master3.example.com
    Normal   SuccessfulAttachVolume  3m25s               attachdetach-controller       AttachVolume.Attach succeeded for volume "pvc-907ae639-3880-11e9-85a5-525400275ad4"
    Warning  FailedMount             82s                 kubelet, master3.example.com  Unable to mount volumes for pod "busybox-mount_default(24ac4333-3881-11e9-85a5-525400275ad4)": timeout expired waiting for volumes to attach or mount for pod "default"/"busybox-mount". list of unmounted volumes=[storage]. list of unattached volumes=[storage default-token-6f9vj]
    Warning  FailedMount             45s (x8 over 109s)  kubelet, master3.example.com  MountVolume.WaitForAttach failed for volume "pvc-907ae639-3880-11e9-85a5-525400275ad4" : fail to check rbd image status with: (executable file not found in $PATH), rbd output: ()

To fix this please:

#.  Install ``ceph-common`` on each kubernetes node.

#.  Uninstall the ceph cluster with:

    ::

        ./ceph/_uninstall.sh -f

#.  Delete Remaining pv's

    ::

        kubectl delete --ignore-not-found pv $(kubectl get pv | grep ceph-rbd | grep -v rook | awk '{print $1}')

Previous Cluster Cleanup Failed
-------------------------------

Please run the ``_uninstall.sh`` if you see this kind of error when running the ``cluster-status.sh``:

::

    ./ceph/cluster-status.sh
    --------------------------------------------------
    Getting Ceph cluster status:

    kubectl -n ceph exec -ti ceph-mon-p9tvw -c ceph-mon -- ceph -s
    2019-02-24 06:02:12.468777 7f90f6509700  0 librados: client.admin authentication error (1) Operation not permitted
    [errno 1] error connecting to the cluster
    command terminated with exit code 1

OSD Issues
==========

When debugging ceph ``osd`` issues, please start by reviewing the pod logs with:

::

    ./ceph/logs-osd-prepare-pod.sh

OSD Pool Failed to Initialize
-----------------------------

Depending on how many disks and the capacity of the ceph cluster, your first time creating the ``osd pool`` startup may hit an error during this command:

::

    kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- ceph osd pool create rbd 256

With an error like:

::

    creating osd pool
    Error ERANGE:  pg_num 256 size 3 would mean 840 total pgs, which exceeds max 600 (mon_max_pg_per_osd 200 * num_in_osds 3)
    command terminated with exit code 34
    initializing osd
    rbd: error opening default pool 'rbd'
    Ensure that the default pool has been created or specify an alternate pool name.
    command terminated with exit code 2

Please reduce the number at the end of the ``ceph osd pool create rbd 256`` to:

::

    kubectl -n ceph exec -ti ${pod_name} -c ceph-mon -- ceph osd pool create rbd 100

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

    ./ceph/_uninstall.sh

Uninstall and Reformat KVM Images
---------------------------------

To uninstall the ceph cluster and reformat the mounted KVM disks ``/dev/vdb``:

.. warning:: Running this will destroy all data across the cluster by reformatting the /dev/vdb block devices in each vm

::

    ./ceph/_uninstall.sh -f
