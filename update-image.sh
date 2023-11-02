#!/bin/bash -e

script_dir="$(dirname "$0")"
sed -i "s,quay.io/redhat-user-workloads/rhtap-migration-tenant/bonfire-cicd-tools/.*,${1},g" "${script_dir}"/{tasks,pipelines}/*.yaml
