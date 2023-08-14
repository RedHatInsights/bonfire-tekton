#!/bin/bash -e

script_dir="$(dirname "$0")"
sed -i "s,image: .*,image: ${1},g" "${script_dir}"/*.yaml
