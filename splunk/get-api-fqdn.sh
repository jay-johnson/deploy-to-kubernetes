#!/bin/bash

kubectl describe svc splunk-svc | grep 8089 | grep Endpoint | awk '{print $NF}'
