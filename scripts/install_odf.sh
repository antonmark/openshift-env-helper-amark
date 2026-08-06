#!/bin/bash
set -euo pipefail

if [ "${INSTALL_ODF:-false}" == "false" ]; then
  echo "No need to install Container Storage Operator."
  exit 0
fi

if [ "${DEBUG:-false}" == "true" ]; then
  set -x
fi

echo "Create New Project for container storage"
oc adm new-project openshift-storage || true
oc annotate project openshift-storage openshift.io/node-selector='' --overwrite
oc label namespace openshift-storage openshift.io/cluster-monitoring=true --overwrite

echo "Install Operator"
CHANNEL_VERSION=$(oc get packagemanifests -n openshift-marketplace odf-operator -o jsonpath='{.status.defaultChannel}')

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: odf-operator-group
  namespace: openshift-storage
spec:
  targetNamespaces:
    - openshift-storage
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: odf-operator
  namespace: openshift-storage
spec:
  channel: "${CHANNEL_VERSION}"
  installPlanApproval: Automatic
  name: odf-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo "Wait for ocs-operator CSV to succeed (required for StorageCluster)."
until oc get csv -n openshift-storage -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}' \
  | grep -E '^ocs-operator\.' | grep -q 'Succeeded$'; do
  echo -n "."
  sleep 5
done
echo

echo "Wait for StorageCluster CRD to be established."
until oc get crd storageclusters.ocs.openshift.io >/dev/null 2>&1 \
  && [ "$(oc get crd storageclusters.ocs.openshift.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}')" = "True" ]; do
  echo -n "."
  sleep 5
done
echo

# Add storage taint on ODF nodes (idempotent)
oc get node --no-headers | awk '{print $1}' | grep odf | while read -r NODE; do
  oc adm taint nodes "$NODE" node.ocs.openshift.io/storage=true:NoSchedule --overwrite
done

echo "Deploy ODF StorageCluster"
if ! oc apply -f - <<EOF
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  manageNodes: false
  resources:
    mds:
      limits:
        cpu: 3
        memory: 8Gi
      requests:
        cpu: 1
        memory: 8Gi
  monDataDirHostPath: /var/lib/rook
  storageDeviceSets:
    - count: 1
      dataPVCTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 500Gi
          storageClassName: localblock
          volumeMode: Block
      name: ocs-deviceset
      placement: {}
      portable: false
      replica: 3
      resources:
        limits:
          cpu: 2
          memory: 5Gi
        requests:
          cpu: 1
          memory: 5Gi
EOF
then
  echo "ERROR: failed to apply StorageCluster ocs-storagecluster" >&2
  exit 1
fi

if ! oc get storagecluster ocs-storagecluster -n openshift-storage >/dev/null 2>&1; then
  echo "ERROR: StorageCluster ocs-storagecluster was not created" >&2
  exit 1
fi
echo "StorageCluster created; waiting for Ready phase."

until [ "$(oc get storagecluster ocs-storagecluster -n openshift-storage -o jsonpath='{.status.phase}' 2>/dev/null || true)" = "Ready" ]; do
  PHASE=$(oc get storagecluster ocs-storagecluster -n openshift-storage -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
  echo -n ".${PHASE}."
  sleep 10
done
echo
echo "StorageCluster is Ready."

echo "Enable storage console"
oc patch console.operator cluster --type json -p '[{"op": "add", "path": "/spec/plugins", "value": ["odf-console"]}]' || true
