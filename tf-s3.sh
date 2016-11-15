#!/usr/bin/env bash

./bin/terraform remote config \
    -backend=s3 \
    -backend-config="bucket=hoblitt.com" \
    -backend-config="key=network/terraform.tfstate" \
    -backend-config="region=us-west-2"
