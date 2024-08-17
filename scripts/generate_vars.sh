#!/bin/bash

BASEDIR=$(dirname $0)
WORK_DIR=$1
OCP_VERSION=$2
NUM_WORKERS=$3

export BOOTSTRAP_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-bootstrap)



if [[ $OCP_COMPACT == "true" ]]; then
  VARS_SCRIPT=./vars/vars-compact.yaml
  for i in {0..2}
  do
    eval export MASTER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-master${i})
  done
else
  for i in {0..2}
  do
    eval export MASTER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-master${i})
  done
  
  if [ $NUM_WORKERS -gt 0 ]; then
    NUM=$(expr $NUM_WORKERS - 1)
    for i in $(seq 0 $NUM)
    do
      eval export WORKER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-worker${i})
    done
  fi
  
  for i in $(seq 0 $NUM)
  do
    eval export WORKER${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-worker${i})
  done
  
  if [ "${INSTALL_ODF}" == "true" ]; then
    for i in {0..2}
    do
      eval export ODF${i}_MAC=$(${BASEDIR}/get_macaddress.sh ocp4-odf${i})
    done
    VARS_SCRIPT=./vars/vars-odf.yaml
  else
    VARS_SCRIPT=./vars/vars.yaml
  fi
fi

${VARS_SCRIPT} ${WORK_DIR} ${OCP_VERSION}
