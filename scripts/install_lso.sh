#!/bin/bash

if [ "$INSTALL_ODF" == "false" ]; then
  echo "No need to install Local Sotrage Operator."
  exit 0
fi

echo "Create New Project for local storage"
oc adm new-project openshift-local-storage
oc annotate project openshift-local-storage openshift.io/node-selector=''

oc get node -o name | grep odf | while read NODE
do
  oc label $NODE cluster.ocs.openshift.io/openshift-storage=''
done

echo "Install Operator"
OC_VERSION=$(oc version -o yaml | grep openshiftVersion | grep -o '[0-9]*[.][0-9]*' | head -1)
DEFAULT_CHANNEL=$(oc get packagemanifests -n openshift-marketplace local-storage-operator -o jsonpath='{.status.defaultChannel}')

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: local-operator-group
  namespace: openshift-local-storage
spec:
  targetNamespaces:
    - openshift-local-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: local-storage-operator
  namespace: openshift-local-storage
spec:
  channel: "${DEFAULT_CHANNEL}"
  installPlanApproval: Automatic
  name: local-storage-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "Wait for install succeeded."
RTN=1
while [ $RTN -ne 0 ]; 
do
  oc get csvs -n openshift-local-storage | grep Succeeded > /dev/null 
  RTN=$?
  if [ $RTN -ne 0 ]; then
    echo -n "."
    sleep 5
  fi
done


cat <<EOF | oc apply -f -
apiVersion: "local.storage.openshift.io/v1"
kind: "LocalVolume"
metadata:
  name: "local-disks"
  namespace: "openshift-local-storage"
spec:
  nodeSelector:
    nodeSelectorTerms:
    - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - odf0.ocp4.cluster.lab
          - odf1.ocp4.cluster.lab
          - odf2.ocp4.cluster.lab
  storageClassDevices:
    - storageClassName: "localblock"
      volumeMode: Block
      devicePaths:
        - /dev/vdb
  tolerations:
  - effect: NoSchedule
    key: node.ocs.openshift.io/storage
    value: "true"
EOF


NUM=0
while [ $NUM -lt 3 ]; 
do
  NUM=$(oc get pv | grep localblock | wc -l)
  sleep 5
done

