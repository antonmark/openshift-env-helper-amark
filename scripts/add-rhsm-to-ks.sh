read -p "RHN Username: " USERNAME
read -s -p "Password: " PASSWORD

cat << EOF >>  ${WORK_DIR}/helper-ks.cfg
%post --log=/root/registration_results.out
subscription-manager register --auto-attach --username=${USERNAME} --password=${PASSWORD}
subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
%end
EOF
