#!/bin/bash
if [ "$DEBUG" != "false" ]; then
  set -x
fi

WORKER_NUM=${1}
ODF_NUM=${2}

EXPECTED_NUM_NODES=$(expr $WORKER_NUM + $ODF_NUM + 3)
TOTAL_WAIT=0
NUM_CSR=$(oc get csr|grep -i pending|wc -l)

while [ $NUM_CSR -gt 0 ];
do
  echo "$NUM_CSR pending CSR's. Approving..."
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
  echo "Waiting for 10 seconds."
  sleep 10
  NUM_CSR=$(oc get csr|grep -i pending|wc -l)
done

echo "All CSR's approved or none waiting."

CURRENT_NUM_NODES=$(oc get nodes|grep -v NAME|wc -l)

if [ $CURRENT_NUM_NODES -ne $EXPECTED_NUM_NODES ];
then
  echo "Waiting 2 minutes for remaining nodes to join.."
  while [ $CURRENT_NUM_NODES -ne $EXPECTED_NUM_NODES ] || [ $TOTAL_WAIT -lt 120 ];
  do
    CURRENT_NUM_NODES=$(oc get nodes|grep -v NAME|wc -l)
    TOTAL_WAIT=$(expr $TOTAL_WAIT + 5)
    sleep 5
    NUM_CSR=$(oc get csr|grep -i pending|wc -l)
    if [ $NUM_CSR -gt 0 ]; then
      echo "$NUM_CSR pending CSR's. Approving..."
      oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
      NUM_CSR=$(oc get csr|grep -i pending|wc -l)
    fi
  done
fi
  echo "All nodes have joined (Current: $CURRENT_NUM_NODES / Expected: $EXPECTED_NUM_NODES). Approving remaining CSR's."
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
  exit 0

if [ $TOTAL_WAIT -ge 120 ] && [ $CURRENT_NUM_NODES -lt $EXPECTED_NUM_NODES ];
then
  echo "WARNING: Waited 2 minutes and remaining nodes have not joined."
  exit 1
fi
