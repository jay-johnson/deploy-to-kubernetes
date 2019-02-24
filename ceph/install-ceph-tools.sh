#!/bin/bash

echo "installing ceph from steps on: http://docs.ceph.com/docs/master/install/get-packages/"
sudo rpm --import "https://download.ceph.com/keys/release.asc"
sudo yum install -y ceph-common

