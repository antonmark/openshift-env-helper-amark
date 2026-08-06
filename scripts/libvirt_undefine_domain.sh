#!/bin/bash
# Usage: libvirt_undefine_domain.sh <domain-name>
#
# Safely destroys and undefines a libvirt domain, handling common edge cases:
#   - domain already shut off (destroy is a no-op)
#   - domain does not exist (exit 0 immediately)
#   - qemu holding disk open briefly after destroy (retries undefine)
#
# Exit 1 if the domain still exists after all retries.

DOMAIN=${1:?Usage: $0 <domain-name>}

# Nothing to do if domain is not known to libvirt
if ! virsh dominfo "$DOMAIN" >/dev/null 2>&1; then
  echo "$DOMAIN: not found, skipping"
  exit 0
fi

# Destroy (force off) — ignore "domain is not running"
virsh destroy "$DOMAIN" 2>&1 | grep -v "is not running" || true

# Wait for shut off (up to 30 s)
WAIT=0
until virsh domstate "$DOMAIN" 2>/dev/null | grep -q "shut off"; do
  if [ "$WAIT" -ge 30 ]; then
    echo "$DOMAIN: still not shut off after ${WAIT}s" >&2
    break
  fi
  sleep 2
  WAIT=$((WAIT + 2))
done

# Retry undefine up to 5 times (qemu may still hold disk handles briefly)
for attempt in 1 2 3 4 5; do
  if virsh undefine "$DOMAIN" --remove-all-storage 2>&1; then
    echo "$DOMAIN: undefined"
    exit 0
  fi
  echo "$DOMAIN: undefine attempt $attempt failed, retrying in 3s..." >&2
  sleep 3
done

# Final check
if virsh dominfo "$DOMAIN" >/dev/null 2>&1; then
  echo "$DOMAIN: ERROR - domain still exists after all retries" >&2
  exit 1
fi
exit 0
