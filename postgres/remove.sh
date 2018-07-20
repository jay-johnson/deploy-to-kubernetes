#!/bin/bash

kubectl delete service primary
kubectl delete pod primary
kubectl delete pvc primary-pgdata
kubectl delete pv primary-pgdata
