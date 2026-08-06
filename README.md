# OpenShift Env Helper

## Overview

This helps you to deploy a OpenShift Cluster on KVM using ocp4-helpernode. This makefile create helper node, a bootstrap, three master nodes, 2 worker nodes and 3 ocs nodes.

## Architecture

TBD

It creates network on KVM named 'openshift4' and use CIDR '192.168.7.0/24'. There is no way to configure the CIDR and network name so far.
The instances name also fixed and can not modify.
- ocp4-aHelper
- ocp4-bootstrap
- ocp4-master0
- ocp4-master1
- ocp4-master2
- ocp4-worker0
- ocp4-worker1
- ocp4-odf0
- ocp4-odf1
- ocp4-odf2

## Tested resources (not the requirements)

- cpu: 8
- memory: 256GB
- storage: 2TB

## Prerequisites

You need to install follosing modules before executing the makefile.

- sshpass
- ansible
- git
- wget
- virt

You also need to prepare some files and configs as below:

- pull-secret : download from the website (https://console.redhat.com/openshift/install/pull-secret) and put the pull-secret the current directory as 'pull-secret' file. You need to login a Red Hat account.
- ssh public key : In order to login helper node, this makefile use default ssh-key in /root/.ssh/id_rsa.pub file. Please make sure generating the ssh-key.

## Quick Start

See [CHEATSHEET.md](CHEATSHEET.md) for common make targets and variables.

To deploy OpenShift Cluster, execute the following command.

```[shell]
# make all
```

RHSM registration runs automatically after the helper node boots (`make helper_register`). By default you will be prompted interactively for your Red Hat username and password — the credentials are passed directly over SSH and are never written to a file on the host or on the VM.

For non-interactive use (e.g. CI), export credentials before running make:

```[shell]
# export RHN_PROMPT=false RHN_USERNAME=myuser RHN_PASSWORD=mypass
# make all
```

To deploy OpenShift cluster with OCS, execute the following command.

```[shell]
# make all INSTALL_ODF=true
```

After deploying OpenShift Cluster with OCS, you can set up OpenShift Container registry as follow:

```
# make setup_registry INSTALL_ODF=true
```

## Remove environment

If you do not need the envirnoment anymore, you can delete all the staff executing the following command.

```[shell]
# make flclean
```

## To-do list

- Fix start_vms.sh logic
- 