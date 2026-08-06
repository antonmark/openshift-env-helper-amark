#!/bin/bash
# Usage: remove_network.sh <network-name> [xml-path]
#
# Destroys and undefines a libvirt network by NAME (not by XML path), so the
# network is always cleaned up even if the XML file has already been removed.
# If an optional xml-path is provided, it is deleted after the virsh commands.

NETWORK_NAME=${1:?Usage: $0 <network-name> [xml-path]}
NETWORK_XML=${2:-}

# net-destroy: ignore "network is not active"
virsh net-destroy "$NETWORK_NAME" 2>&1 | grep -v "is not active" || true

# net-undefine: ignore "failed to get network" (already gone)
virsh net-undefine "$NETWORK_NAME" 2>&1 | grep -v "failed to get network" || true

# Remove XML if provided and present
if [ -n "$NETWORK_XML" ] && [ -f "$NETWORK_XML" ]; then
  rm -f "$NETWORK_XML"
fi

exit 0
