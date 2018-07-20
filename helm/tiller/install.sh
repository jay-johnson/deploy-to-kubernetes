#!/bin/bash

echo "creating service account for tiller in the kube-system"
kubectl create serviceaccount --namespace kube-system tiller

echo "creating rbac for tiller service account"
kubectl apply -f ./helm/tiller/rbac.yml

echo "creating cluster role binding for tiller"
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
echo "patching any tiller deploys with the service account"
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
echo "listing helm"
helm list
echo "updating helm repo"
helm repo update

echo "initializing helm with tiller service account"
helm init --upgrade --service-account tiller

