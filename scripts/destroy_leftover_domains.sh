#!/bin/bash
# Sweep any remaining ocp4-* and odf-* domains and their orphaned disks.
# Run after the count-based destroy scripts as a safety net.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LEFTOVER_DOMAINS=$(virsh list --all --name 2>/dev/null | grep -E '^ocp4-' || true)

if [ -z "$LEFTOVER_DOMAINS" ]; then
  echo "No leftover ocp4-* domains found."
else
  echo "Found leftover domains: $LEFTOVER_DOMAINS"
  for DOMAIN in $LEFTOVER_DOMAINS; do
    "$SCRIPT_DIR/libvirt_undefine_domain.sh" "$DOMAIN"
  done
fi

# Remove orphaned qcow2 disks that virsh did not clean up (e.g. bootstrap
# disk owned by root instead of qemu, or any disk left from an aborted run).
for DISK in /home/ocp4-*.qcow2 /home/odf-*.qcow2; do
  [ -e "$DISK" ] || continue
  echo "Removing orphaned disk: $DISK"
  rm -f "$DISK"
done
