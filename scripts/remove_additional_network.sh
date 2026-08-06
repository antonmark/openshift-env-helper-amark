#!/bin/bash

NETWORK_NAME=${PRIVATE_NETWORK_NAME:-ocp4-private}
NETWORK_XML=${WORK_DIR:+${WORK_DIR}/additional_network.xml}

./scripts/remove_network.sh "$NETWORK_NAME" "${NETWORK_XML:-}"

exit 0
