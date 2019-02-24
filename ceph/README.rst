Running a Ceph Cluster on Kubernetes
====================================

This installer was built to replace Rook-Ceph after hitting cluster stability after ~30 days in 2019. The steps are taken from the Ceph Helm installer:

http://docs.ceph.com/docs/mimic/start/kube-helm/

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

