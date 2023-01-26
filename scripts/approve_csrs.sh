#!/bin/bash
if [ "$DEBUG" != "false" ]; then
  set -x
fi

WORKER_NUM=${1}
ODF_NUM=${2}

NODE_NUM=$(expr $WORKER_NUM + $ODF_NUM)
TOTAL_WAIT=0
NUM=0

while [ $NUM -lt $NODE_NUM ] || [ $TOTAL_WAIT < 1200 ];
do
  NUM=$(oc get nodes|grep Ready|wc -l)
  TOTAL_WAIT=$(expr $TOTAL_WAIT + 5)
  sleep 5
done

if [ $NUM -qe $NODE_NUM ];
then
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
  sleep 5
  # just in case of an API issue
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
fi
  echo "Warning: Some nodes are not ready or have not joined the cluster."
  exit 1
