#!/bin/bash

if [ ${INSTALL_ODF} != "true" ]; then
 echo "## Skip deploy odf nodes ##"
 exit 0
fi

WORK_DIR=./ocp4-workingdir
ODF_NUM=$1

if (( $ODF_NUM >= 3 )); then
  for ((i=0;i<=$ODF_NUM-1;i++))
  do
    virt-install --name="ocp4-odf${i}" --vcpus=12 --ram=65536 \
    --disk path=/home/ocp4-odf${i}.qcow2,bus=virtio,cache=none,format=qcow2,size=120 \
    --disk path=/home/odf-odf${i}.qcow2,bus=virtio,cache=none,format=qcow2,size=500 \
    --os-variant rhel8.0 --network network=${NETWORK_NAME},model=virtio --graphics vnc,listen=0.0.0.0 --noautoconsole --check disk_size=off \
    --boot hd,network,menu=on --print-xml > ${WORK_DIR}/ocp4-odf$i.xml
    virsh define --file ${WORK_DIR}/ocp4-odf$i.xml
  done

fi