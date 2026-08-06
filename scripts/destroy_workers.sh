#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORKER_NUM=${1:-2}
LAST=$(( WORKER_NUM - 1 ))

for i in $(seq 0 "$LAST"); do
  "$SCRIPT_DIR/libvirt_undefine_domain.sh" "ocp4-worker${i}"
done
