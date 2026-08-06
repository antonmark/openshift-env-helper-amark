#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ODF_NUM=${1:-3}

if [ "$ODF_NUM" -lt 1 ]; then
  echo "ODF_NUM=0, skipping ODF domain cleanup"
  exit 0
fi

LAST=$(( ODF_NUM - 1 ))

for i in $(seq 0 "$LAST"); do
  "$SCRIPT_DIR/libvirt_undefine_domain.sh" "ocp4-odf${i}"
done
