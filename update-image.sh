#!/bin/bash -e

# usage: update-image.sh <new tag>

script_dir="$(dirname "$0")"
sed -i "s,\(quay\.io/redhat-services-prod/hcm-eng-prod-tenant/cicd-tools:\)[^[:space:]]*,\1${1},g" "${script_dir}"/{tasks,pipelines}/*.yaml
