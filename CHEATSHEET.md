# Cheat Sheet

## Per-host setup (ocs1–4)

Copy [`env.example`](env.example) to `.env` on the hypervisor and set `CLUSTER_NAME` / `CLUSTER_DOMAIN` for that box (`libvirt1`…`libvirt4` + `ocpcluster.cc`). `.env` is gitignored; Make loads it automatically.

## Build

```sh
# Deploy cluster
make all

# Deploy cluster with ODF
make all INSTALL_ODF=true

# Non-interactive RHSM (optional)
RHN_PROMPT=false RHN_USERNAME=myuser RHN_PASSWORD=mypass make all

# Set up registry after ODF
make setup_registry INSTALL_ODF=true
```

## Teardown

```sh
# Wipe everything
make flclean
```

## Handy

```sh
# SSH to helper
ssh root@192.168.7.77

# kubeadmin password (on helper)
cat /root/ocp4/auth/kubeadmin-password
```
