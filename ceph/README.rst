Running a Distributed Ceph Cluster on a Kubernetes Cluster
==========================================================

Overview
--------

This guide `automates installing a native ceph cluster inside a running kubernetes native cluster <http://docs.ceph.com/docs/mimic/start/kube-helm/>`__. It requires creating and attaching 3 additional hard drive disk images to 3 kubernetes cluster vms (tested on 3 CentOS 7 vm's). This guide assumes your kubernetes cluster is using ``kvm`` with ``virsh`` for running the ``attach-disk`` commands (it was tested with kubernetes version ``1.13.3``).

By default, the disk images will be installed at: ``/cephdata/m[123]/k8-centos-m[123]``. These disks will be automatically partitioned and formatted using `ceph zap <http://docs.ceph.com/docs/mimic/ceph-volume/lvm/zap/>`__, and zap will format each disk using the `recommended XFS filesystem <http://docs.ceph.com/docs/jewel/rados/configuration/filesystem-recommendations/>`__.

.. note:: This is a work in progress and things will likely change. This guide will be updated as progress proceeds.

Background
----------

This installer was built to replace Rook-Ceph after encountering cluster stability issues after ~30 days of uptime in 2019. The steps are taken from the Ceph Helm installer:

http://docs.ceph.com/docs/mimic/start/kube-helm/

Add the Ceph Mon Cluster Service FQDN to /etc/hosts
===================================================

Before starting, please ensure each kubernetes vm has the following entries in ``/etc/hosts``:

**m1**

::

    sudo echo "192.168.0.101    ceph-mon.ceph.svc.cluster.local" >> /etc/hosts

**m2**

::

    sudo echo "192.168.0.102    ceph-mon.ceph.svc.cluster.local" >> /etc/hosts

**m3**

::

    sudo echo "192.168.0.103    ceph-mon.ceph.svc.cluster.local" >> /etc/hosts

.. note:: Missing this step can result in `some debugging <https://deploy-to-kubernetes.readthedocs.io/en/latest/ceph.html#kubernetes-ceph-cluster-debugging-guide>`__

Build KVM HDD Images
====================

Change to the ``ceph`` directory.

::

    cd ceph

Generate ``100 GB`` hdd images for the ceph cluster with 1 qcow2 image for each of the three vm's:

::

    ./kvm-build-images.sh

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

    ./kvm-attach-images.sh

Format Disks in VM
==================

With automatic ssh root login access, you can run this to partition, mount and format each of the new images:

.. warning:: Please be careful running this as it can delete any previously saved data.

.. warning:: Please be aware that ``fdisk`` can also hang and requires hard rebooting the cluster if orphaned ``fdisk`` processes get stuck. Please let me know if you have a way to get around this. There are many discussions like `the process that would not die <https://www.linuxquestions.org/questions/slackware-14/the-process-that-would-not-die-can%27t-kill-fdisk-378204/>`__ about this issue on the internet.

::

    ./_kvm-format-images.sh

Install Ceph on All Kubernetes Nodes
====================================

Please add ``ceph-common``, ``centos-release-ceph-luminous`` and ``lsof`` to all kubernetes node vm's before deploying ceph.

For additional set up please refer to the official ceph docs:

http://docs.ceph.com/docs/master/install/get-packages/

For CentOS 7 you can run the `./ceph/install-ceph-tools.sh <https://github.com/jay-johnson/deploy-to-kubernetes/blob/master/ceph/install-ceph-tools.sh>`__ script or the commands:

::

    sudo rpm --import "https://download.ceph.com/keys/release.asc"
    sudo yum install -y ceph-common centos-release-ceph-luminous lsof

Deploy Ceph Cluster
===================

Ceph requires running a local Helm repo server (just like the Redis cluster does) and building then installing chart to get the cluster pods running.

::

    ./run.sh

Watch all Ceph Logs with Kubetail
=================================

With `kubetail <https://github.com/johanhaleby/kubetail>`__ installed you can watch all the ceph pods at once with:

::

    ./logs-kt-ceph.sh

or manually with:

::

    kubetail ceph -c cluster-log-tailer -n ceph


Show Pods
=========

View the ceph cluster pods with:

::

    ./show-pods.sh
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

    ./cluster-status.sh
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

Validate a Pod can Mount a Persistent Volume on the Ceph Cluster in Kubernetes
==============================================================================

Run these steps to walk through integration testing your kubernetes cluster can host persistent volumes for pods running on a ceph cluster inside kubernetes. This means your data is backed to an attached storage disk on the host vm in:

.. note:: If any of these steps fail please refer to the `Kubernetes Ceph Cluster Debugging Guide <https://deploy-to-kubernetes.readthedocs.io/en/latest/ceph.html#kubernetes-ceph-cluster-debugging-guide.html>`__

::

    ls /cephdata/*/*
    /cephdata/m1/k8-centos-m1  /cephdata/m2/k8-centos-m2  /cephdata/m3/k8-centos-m3

Create PVC
----------

::

    kubectl apply -f test/pvc.yml

Verify PVC is Bound
-------------------

::

    kubectl get pvc | grep test-ceph
    test-ceph-pv-claim        Bound    pvc-a715256d-38c3-11e9-8e7c-525400275ad4   1Gi        RWO            ceph-rbd          46s

Create Pod using PVC as a mounted volume
----------------------------------------

::

    kubectl apply -f test/mount-pv-in-pod.yml

Verify Pod has Mounted Volume inside Container
----------------------------------------------

::

    kubectl describe pod ceph-tester

Verify Ceph is Handling Data
----------------------------

::

    ./cluster-status.sh

::

    ./show-ceph-osd-status.sh

    ----------------------------------------------
    Getting Ceph osd status:
    kubectl -n ceph exec -it ceph-rgw-7b9677854f-lcr77 -- ceph osd status
    +----+---------------------+-------+-------+--------+---------+--------+---------+-----------+
    | id |         host        |  used | avail | wr ops | wr data | rd ops | rd data |   state   |
    +----+---------------------+-------+-------+--------+---------+--------+---------+-----------+
    | 0  | master2.example.com |  141M | 94.8G |    0   |     0   |    1   |    16   | exists,up |
    | 1  | master1.example.com |  141M | 94.8G |    0   |     0   |    0   |     0   | exists,up |
    | 2  | master3.example.com |  141M | 94.8G |    0   |     0   |    0   |     0   | exists,up |
    +----+---------------------+-------+-------+--------+---------+--------+---------+-----------+

Delete Ceph Tester Pod
----------------------

::

    kubectl delete -f test/mount-pv-in-pod.yml

Recreate Ceph Tester Pod
------------------------

::

    kubectl apply -f test/mount-pv-in-pod.yml

View Logs from Previous Pod
---------------------------

::

    kubectl logs -f $(kubectl get po | grep ceph-tester | awk '{print $1}')

Notice the last entries in the log show the timestamp changed in the logs like:

::

    kubectl logs -f $(kubectl get po | grep ceph-tester | awk '{print $1}')
    total 20
    drwx------    2 root     root         16384 Feb 25 07:31 lost+found
    -rw-r--r--    1 root     root            29 Feb 25 07:33 updated
    Filesystem                Size      Used Available Use% Mounted on
    /dev/rbd0               975.9M      2.5M    957.4M   0% /testing
    last update:
    Mon Feb 25 07:33:34 UTC 2019
    Mon Feb 25 08:29:27 UTC 2019

Cleanup Ceph Tester Pod
-----------------------

::

    kubectl delete -f test/mount-pv-in-pod.yml
    kubectl delete -f test/pvc.yml

Kubernetes Ceph Cluster Debugging Guide
=======================================

The ceph-tester failed to start
-------------------------------

If your integration test fails mounting the test persistent volume follow these steps to try and debug the issue:

Check if the ``ceph-mon`` service is missing a ClusterIP:

::

    get svc -n ceph
    NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    ceph-mon   ClusterIP   None            <none>        6789/TCP   11m
    ceph-rgw   ClusterIP   10.102.90.139   <none>        8088/TCP   11m

See if there is a log in the ``ceph-tester`` showing the error.

::

    kubectl describe po ceph-tester

May show something similar to this for why it failed:

::

    server name not found: ceph-mon.ceph.svc.cluster.local

If ``ceph-mon.ceph.svc.cluster.local`` is not found, manually add it to ``/etc/hosts`` on all nodes.

**m1** node:

::

    # on m1 /etc/hosts add:
    192.168.0.101    ceph-mon.ceph.svc.cluster.local

Confirm connectivity

::

    telnet ceph-mon.ceph.svc.cluster.local 6789

**m2** node:

::

    # on m2 /etc/hosts add:
    192.168.0.102    ceph-mon.ceph.svc.cluster.local

Confirm connectivity

::

    telnet ceph-mon.ceph.svc.cluster.local 6789

**m3** node:

::

    # on m3 /etc/hosts add:
    192.168.0.103    ceph-mon.ceph.svc.cluster.local

Confirm connectivity

::

    telnet ceph-mon.ceph.svc.cluster.local 6789

If connectivity was fixed on all the kubernetes nodes then please ``./_uninstall.sh`` and then reinstall with ``./run.sh``

If not please continue to the next debugging section below.

Orphaned fdisk Processes
------------------------

If you have to use the ``./_uninstall.sh -f`` to uninstall and re-partition the disk images, there is a chance the partition tool ``fdisk`` can hang. If this happens it should hang the ``./_uninstall.sh -f`` and be detected by the user or the script (hopefully).

If your cluster hits this issue I have to reboot my server.

.. note:: This guide does not handle single kubernetes vm outages at the moment.

For the record, here's some attempts to kill this process:

::

    root@master3:~# ps auwwx | grep fdisk
    root     18516  0.0  0.0 112508   976 ?        D    06:33   0:00 fdisk /dev/vdb
    root     21957  0.0  0.0 112704   952 pts/1    S+   06:37   0:00 grep --color fdisk
    root@master3:~# kill -9 18516
    root@master3:~# ps auwwx | grep fdisk
    root     18516  0.0  0.0 112508   976 ?        D    06:33   0:00 fdisk /dev/vdb
    root     22031  0.0  0.0 112704   952 pts/1    S+   06:37   0:00 grep --color fdisk

::

    root@master3:~# strace -p 18516
    strace: Process 18516 attached
    # no more logs after waiting +60 seconds
    strace: Process 18516 attached
    ^C
    ^C
    ^C
    ^C^Z
    [1]+  Stopped                 strace -p 18516
    # so did strace just die by touching that pid?

What is ``fdisk`` using on the filesystem?

Notice multiple ``ssh pipe`` resources are in use below. Speculation here: are those pipes the ``fdisk`` wait prompt over a closed ssh session (I am guessing but who knows)?

::

    root@master3:~# lsof -p 18516
    COMMAND   PID USER   FD   TYPE DEVICE  SIZE/OFF      NODE NAME
    fdisk   18516 root  cwd    DIR  253,0       271 100663361 /root
    fdisk   18516 root  rtd    DIR  253,0       285        64 /
    fdisk   18516 root  txt    REG  253,0    200456  33746609 /usr/sbin/fdisk
    fdisk   18516 root  mem    REG  253,0 106070960      1831 /usr/lib/locale/locale-archive
    fdisk   18516 root  mem    REG  253,0   2173512  33556298 /usr/lib64/libc-2.17.so
    fdisk   18516 root  mem    REG  253,0     20112  33556845 /usr/lib64/libuuid.so.1.3.0
    fdisk   18516 root  mem    REG  253,0    261488  33556849 /usr/lib64/libblkid.so.1.1.0
    fdisk   18516 root  mem    REG  253,0    164240  33556291 /usr/lib64/ld-2.17.so
    fdisk   18516 root    0r  FIFO    0,9       0t0    847143 pipe
    fdisk   18516 root    1w  FIFO    0,9       0t0    845563 pipe
    fdisk   18516 root    2w  FIFO    0,9       0t0    845564 pipe
    fdisk   18516 root    3u   BLK 252,16     0t512      1301 /dev/vdb
    root@master3:~#

Stop ``strace`` that will prevent ``gdb`` tracing next:

::

    root@master3:~# ps auwwx | grep 26177
    root     14082  0.0  0.0 112704   952 pts/0    S+   07:02   0:00 grep --color 26177
    root     26177  0.0  0.0   7188   600 ?        S    06:41   0:00 strace -p 18516
    root@master3:~# kill -9 26177

``gdb`` also hangs when trying `this stackoverflow <https://superuser.com/questions/963612/closing-open-file-without-killing-the-process>`__:

::

    gdb -p 18516
    GNU gdb (GDB) Red Hat Enterprise Linux 7.6.1-110.el7
    Copyright (C) 2013 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
    and "show warranty" for details.
    This GDB was configured as "x86_64-redhat-linux-gnu".
    For bug reporting instructions, please see:
    <http://www.gnu.org/software/gdb/bugs/>.
    Attaching to process 18516

At this point if a vm gets to this point in the kubernetes cluster then the server gets rebooted.

Here are other operational debugging tools that were used with cluster start up below:

Check osd pods
--------------

When setting up new devices with kubernetes you will see the ``osd`` pods failing and here is a tool to describe one of the pods quickly:

::

    ./describe-osd.sh

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

        ./_uninstall.sh -f

#.  Delete Remaining pv's

    ::

        kubectl delete --ignore-not-found pv $(kubectl get pv | grep ceph-rbd | grep -v rook | awk '{print $1}')

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

When debugging ceph ``osd`` issues, please start by reviewing the pod logs with:

::

    ./logs-osd-prepare-pod.sh

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

    ./show-ceph-all.sh

Show Cluster Status
-------------------

::

    ./show-ceph-status.sh

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

    ./show-ceph-df.sh

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

    ./show-ceph-osd-status.sh

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

    ./show-ceph-rados-df.sh

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
