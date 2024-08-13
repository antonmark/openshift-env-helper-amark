#!/bin/bash
if [ "$DEBUG" != "false" ]; then
  set -x
fi

if [ "$RHN_PROMPT" != "false" ]; then
  read -p "RHN Username: " USERNAME
  read -s -p "Password: " PASSWORD
else
  USERNAME=$2
  PASSWORD=$3
fi

cat << EOF >>  ${WORK_DIR}/helper-ks.cfg
%post --log=/root/registration_results.out
subscription-manager register --auto-attach --username=${USERNAME} --password=${PASSWORD}
subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
sed -i -e 's/^subscription-manager.*//g' original-ks.cfg
%end
EOF
