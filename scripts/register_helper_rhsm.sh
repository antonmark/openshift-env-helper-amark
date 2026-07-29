#!/bin/bash
if [ "$DEBUG" != "false" ]; then
  set -x
fi

HELPER_IP=${1}

# Collect credentials: prompt interactively unless RHN_PROMPT=false,
# in which case RHN_USERNAME and RHN_PASSWORD must be set in the environment.
if [ "${RHN_PROMPT}" != "false" ]; then
  read -p "RHN Username: " RHN_USERNAME
  read -s -p "RHN Password: " RHN_PASSWORD
  echo
fi

if [ -z "${RHN_USERNAME}" ] || [ -z "${RHN_PASSWORD}" ]; then
  echo "ERROR: RHN_USERNAME and RHN_PASSWORD must be set (or RHN_PROMPT left as true to prompt)." >&2
  exit 1
fi

# Run subscription-manager over SSH so the password never touches a local file.
# Under Simple Content Access (SCA), auto-attach is a no-op; AppStream (ansible-core)
# is available after register without enabling the old ansible-2.9 repo.
ssh -o "StrictHostKeyChecking=no" root@"${HELPER_IP}" \
  "subscription-manager register --auto-attach --username='${RHN_USERNAME}' --password='${RHN_PASSWORD}' || \
   subscription-manager identity >/dev/null"
