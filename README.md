# OpenShift Env Helper

## Overview

This helps you to deploy a OpenShift Cluster on KVM using ocp4-helpernode. This makefile create helper node, a bootstrap, three master nodes and 2 worker nodes.

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

To deploy OpenShift Cluster, execute the following command.


```[shell]
# make all
```

## Remove environment

If you do not need the envirnoment anymore, you can delete all the staff executing the following command.

```[shell]
# make flclean
```

