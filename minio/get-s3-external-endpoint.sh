#!/bin/bash

namespace="default"
svc_name="minio-external"
endpoint=$(kubectl -n ${namespace} describe service ${svc_name} | grep -i endpoints | awk '{print $NF}')
echo "${endpoint}"
