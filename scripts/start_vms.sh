#!/bin/bash
if [ $DEBUG == "true" ]; then
  set -x
fi

WORKER_NUM=$(expr ${1} - 1)

for i in bootstrap
do
  virsh start ocp4-${i}
  echo "Sleeping for 2 minutes..."
  sleep 120
done

for i in master{0..2}
do
  virsh start ocp4-${i}
  sleep 10
done

echo "Sleeping for 2 minutes..."
sleep 120

for i in $(seq 0 ${WORKER_NUM})
do
  virsh start ocp4-worker${i}
  sleep 10
done

if [ ${WORKER_NUM} == "true" ]; then
  echo "Sleeping for 2 minutes..."
  sleep 120
fi

if [ ${INSTALL_ODF} != "true" ]; then
  exit 0
fi

for i in odf{0..2}
do
  virsh start ocp4-${i}
  sleep 10
done
