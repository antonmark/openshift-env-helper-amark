#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for i in $(seq 0 2); do
  "$SCRIPT_DIR/libvirt_undefine_domain.sh" "ocp4-master${i}"
done
