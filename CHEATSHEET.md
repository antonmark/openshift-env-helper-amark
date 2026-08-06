# Cheat Sheet

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
