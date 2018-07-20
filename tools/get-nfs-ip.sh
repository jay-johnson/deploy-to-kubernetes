#!/bin/bash

if [[ "${USE_IP_ADDRESS}" != "" ]]; then
    echo ${USE_IP_ADDRESS}
else
    echo "localhost"
fi
