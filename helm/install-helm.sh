#!/bin/bash

# run as root
echo "installing helm"
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

echo "setting up helm and tiller"
./helm/setup-helm-with-tiller.sh
