export DEBUG = false
WORKER_NUM = 2
export INSTALL_ODF = false
export RHN_PROMPT = true # Change to false if you wish to hardcode your RHN credentials below
OCP_VERSION=''

# If RHN_PROMPT is set to false populate the following varibles appropriately
RHN_USERNAME = USERNAME
RHN_PASSWORD = PASSWORD

ODF_NUM = 3

YUM_MODULES = ansible git
MAKE_HOME = $(shell pwd)
export WORK_DIR = $(MAKE_HOME)/ocp4-workingdir
HOME_DIR = $$HOME

export NETWORK_NAME = openshift4

# This changes the ClusterID. E.g. api.<clusterid>.cluster.lab
export CLUSTER_NAME = ocp4
# This changes the cluster domain used with ClusterID
export CLUSTER_DOMAIN = cluster.lab

VIRSH_NETNAME = $(NETWORK_NAME)
export NETWORK_CIDR = 192.168.7
PRIVATE_NETWORK_NAME = ocp4-private
PRIVATE_NETWORK_CIDR = 192.168.4

SSH_PUB_KEY = $(shell cat $(HOME_DIR)/.ssh/id_rsa.pub)

HELPER_NODE = ocp4-aHelper
HELPER_IP = $(NETWORK_CIDR).77
HELPER_ISO = rhel-8-x86_64-dvd.iso
SSH_PUB_BASTION = $(HOME_DIR)/.ssh/id_rsa.pub

LIBVIRT_ISO_DIR = /var/lib/libvirt/ISO/

all: deploy_ocp install_lso install_ocs
deploy_ocp: prepare network helper ocp
helper: helper_deploy helper_wait helper_start
ocp: ocp_prepare ocp_install
ocp_prepare: masters bootstrap workers odfs setup_helper generate_vars copy_vars run_playbook copy_pullsecret copy_install_script
ocp_install: run_install start_vms wait_bootstrap_complete stop_bootstrap approve_csrs wait_install_complete approve_csrs reverse_proxy chrony_config
ocs_install: install_lso install_ocs

prepare:
	echo "Nothing to do"

network:
	# Define Network
	pwd
	wget -P $(WORK_DIR) https://raw.githubusercontent.com/RedHatOfficial/ocp4-helpernode/master/docs/examples/virt-net.xml

	sed -i -e "s@<name>openshift4</name>@<name>$(NETWORK_NAME)</name>@g" $(WORK_DIR)/virt-net.xml
	sed -i -e "s@<bridge name='openshift4' stp='on' delay='0'/>@<bridge name='$(NETWORK_NAME)' stp='on' delay='0'/>@g" $(WORK_DIR)/virt-net.xml

	virsh net-define --file $(WORK_DIR)/virt-net.xml
	virsh net-autostart $(VIRSH_NETNAME)
	virsh net-start $(VIRSH_NETNAME)


helper_deploy:
	##TODO Why cannot sshkey be inserted the vm?
	# Deploy Helper node
	wget https://raw.githubusercontent.com/redhat-cop/ocp4-helpernode/main/docs/examples/helper-ks8.cfg -O  $(WORK_DIR)/helper-ks.cfg

	# Modify dnsnameserver
	sed -i -e "s/8.8.8.8/$(NETWORK_CIDR).1/g" $(WORK_DIR)/helper-ks.cfg
	sed -i -e "s/192.168.7.77/$(HELPER_IP)/g" $(WORK_DIR)/helper-ks.cfg
	sed -i -e "s/192.168.7.1/$(NETWORK_CIDR).1/g" $(WORK_DIR)/helper-ks.cfg

	./scripts/add-rhsm-to-ks.sh $(WORK_DIR) $(RHN_USERNAME) $(RHN_PASSWORD)

	# Add ssh key to helper-ks.cfg
	#ansible localhost -m lineinfile -a "path=$(WORK_DIR)/helper-ks.cfg insertafter='rootpw --plaintext changeme' line='sshkey --username=root $(SSH_PUB_KEY)'"

	virt-install --name=$(HELPER_NODE) --vcpus=2 --ram=8192 \
	--disk path=/home/$(HELPER_NODE).qcow2,bus=virtio,size=50 \
	--os-variant rhel8.0 --network network=openshift4,model=virtio \
	--boot hd,menu=on --location /var/lib/libvirt/ISO/$(HELPER_ISO) \
	--initrd-inject $(WORK_DIR)/helper-ks.cfg --extra-args "inst.ks=file:/helper-ks.cfg" --graphics vnc,listen=0.0.0.0 --noautoconsole
	@sleep 5

helper_wait:
	## Cant exit loop with some reasons..
	# Wait until helper node is stopped.
	./scripts/check_helper_running.sh $(HELPER_NODE)

helper_start:
	##TODO it is not good
	virsh start $(HELPER_NODE)
	# Wait for succeeding connect with ssh
	./scripts/wait_until_helper_running.sh $(HELPER_IP) $(SSH_PUB_BASTION)


masters:
	./scripts/create_masters.sh

bootstrap:
	./scripts/create_bootstrap.sh

workers:
	./scripts/create_workers.sh $(WORKER_NUM)

odfs:
	./scripts/create_odf.sh

setup_helper:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) dnf -y install ansible-core git
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) ansible-galaxy collection install community.crypto
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) ansible-galaxy collection install ansible.posix

	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) git clone https://github.com/RedHatOfficial/ocp4-helpernode
	#ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) git clone -b image_url https://github.com/kanekoh/ocp4-helpernode
	scp -o "StrictHostKeyChecking=no" ./files/bashrc root@$(HELPER_IP):/tmp/bashrc
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "cat /tmp/bashrc >> ~/.bashrc"

generate_vars:
	./scripts/generate_vars.sh $(WORK_DIR) $(OCP_VERSION) $(WORKER_NUM)

copy_vars:
	scp -o "StrictHostKeyChecking=no" $(WORK_DIR)/vars.yaml root@$(HELPER_IP):~/ocp4-helpernode/

run_playbook:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "cd ocp4-helpernode; ansible-playbook -e @vars.yaml tasks/main.yml"

copy_pullsecret:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) mkdir -p ~/.openshift
	scp -o "StrictHostKeyChecking=no" ./pull-secret root@$(HELPER_IP):~/.openshift/pull-secret

copy_install_script:
	scp -o "StrictHostKeyChecking=no" ./scripts/install.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install.sh

run_install:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "oc completion bash > /etc/bash_completion.d/oc_bash_completion"
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "NETWORK_CIDR=$(NETWORK_CIDR) CLUSTER_DOMAIN=$(CLUSTER_DOMAIN) CLUSTER_NAME=$(CLUSTER_NAME) ./install.sh"

start_vms:
	./scripts/start_vms.sh $(WORKER_NUM)


wait_bootstrap_complete:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) openshift-install wait-for bootstrap-complete --log-level debug --dir ./ocp4

stop_bootstrap:
	virsh shutdown ocp4-bootstrap

approve_csrs:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "echo export KUBECONFIG=/root/ocp4/auth/kubeconfig >> .bashrc"
	scp -o "StrictHostKeyChecking=no" ./scripts/approve_csrs.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x approve_csrs.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./approve_csrs.sh $(WORKER_NUM) $(ODF_NUM)"

reverse_proxy:
	./scripts/reverse_proxy.sh

chrony_config:
	scp -o "StrictHostKeyChecking=no" ./scripts/chrony_config.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x chrony_config.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) ./chrony_config.sh"

wait_install_complete:
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) openshift-install wait-for install-complete --dir ./ocp4

install_lso:
	scp -o "StrictHostKeyChecking=no" ./scripts/install_lso.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_lso.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) CLUSTER_DOMAIN=$(CLUSTER_DOMAIN) CLUSTER_NAME=$(CLUSTER_NAME) ./install_lso.sh"

install_ocs:
	scp -o "StrictHostKeyChecking=no" ./scripts/install_odf.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x install_odf.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./install_odf.sh"

setup_registry:
	scp -o "StrictHostKeyChecking=no" ./scripts/create_pvc.sh root@$(HELPER_IP):~/
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) chmod +x create_pvc.sh
	ssh -o "StrictHostKeyChecking=no" root@$(HELPER_IP) "DEBUG=$(DEBUG) INSTALL_ODF=$(INSTALL_ODF) ./create_pvc.sh"

attach_additional_network:
	./scripts/add_additional_network.sh $(PRIVATE_NETWORK_NAME) $(PRIVATE_NETWORK_CIDR)
	./scripts/attach_additional_interface.sh

detach_additional_network:
	./scripts/detach_additional_interface.sh

restart_vms:
	./scripts/restart_domains.sh

clean:
	rm -f $(WORK_DIR)/*
	ssh-keygen -R $(NETWORK_CIDR).77

helper_clean:
	-virsh destroy $(HELPER_NODE)
	-virsh undefine $(HELPER_NODE) --remove-all-storage

odf_clean:
	-./scripts/destroy_odf.sh

worker_clean:
	-./scripts/destroy_workers.sh $(WORKER_NUM)

master_clean:
	-./scripts/destroy_masters.sh

bootstrap_clean:
	-./scripts/destroy_bootstrap.sh

network_clean:
	./scripts/remove_network.sh $(WORK_DIR)/virt-net.xml

additional_network_clean:
	./scripts/remove_additional_network.sh

flclean: odf_clean worker_clean master_clean bootstrap_clean helper_clean additional_network_clean network_clean clean
