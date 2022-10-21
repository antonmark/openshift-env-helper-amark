#!/bin/bash

WORK_DIR=./ocp4-workingdir


for i in master{0..2}
do
  virt-install --name="ocp4-${i}" --vcpus=4 --ram=32768 \
  --disk path=/var/lib/libvirt/images/ocp4-${i}.qcow2,bus=virtio,size=120 \
  --os-variant rhel8.0 --network network=${NETWORK_NAME},model=virtio \
  --graphics vnc,port=-1,listen=0.0.0.0 \
  --boot hd,network,menu=on --print-xml > ${WORK_DIR}/ocp4-$i.xml
  virsh define --file ${WORK_DIR}/ocp4-$i.xml
done
