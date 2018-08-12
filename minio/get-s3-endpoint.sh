#!/bin/bash

namespace="default"
svc_name="minio"
endpoint=$(kubectl -n ${namespace} describe service minio | grep -i endpoint | awk '{print $2}')
echo "${endpoint}"
