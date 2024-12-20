#!/bin/bash -e

# Usage: ./update-image.sh <new-image-tag>

script_dir="$(dirname "$0")"
sed -i "s,\(quay.io/redhat-services-prod/hcm-eng-prod-tenant/cicd-tools\):[a-z0-9]*,\1:${1},g" "${script_dir}"/{tasks,pipelines}/*.yaml
