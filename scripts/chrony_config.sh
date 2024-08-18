#!/bin/bash

# DEBUG MODE
if [ $DEBUG == "true" ]; then
  set -x
fi

cat >chrony.conf<<EOF
server 192.168.7.1 iburst
driftfile /var/lib/chrony/drift
logdir /var/log/chrony
log measurements statistics tracking
makestep 1.0 3
rtcsync
EOF

chrony_base64=`base64 -w0 chrony.conf`

for X in master worker; do
cat << EOF > ./99-${X}-chrony-configuration.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: ${X}
  name: 99-${X}-chrony-configuration
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 3.1.0
    networkd: {}
    passwd: {}
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${chrony_base64}
        mode: 420
        overwrite: true
        path: /etc/chrony.conf
  osImageURL: ""
EOF
done


oc apply -f 99-master-chrony-configuration.yaml
oc apply -f 99-worker-chrony-configuration.yaml
