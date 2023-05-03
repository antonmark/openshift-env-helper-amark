#!/bin/bash

## DEBUG MODE
if [ $DEBUG == "true" ]; then
  set -x
fi


curl -LO https://github.com/containous/traefik/releases/download/v2.1.1/traefik_v2.1.1_linux_amd64.tar.gz
tar zxvf traefik_v2.1.1_linux_amd64.tar.gz
mv traefik /usr/local/bin
mkdir -p /etc/traefik
mkdir -p /etc/traefik/conf.d
chown root:root /usr/local/bin/traefik
chmod 755 /usr/local/bin/traefik
restorecon -irv /usr/local/bin/traefik
rm -f CHANGELOG.md
rm -f LICENSE.md
rm -f traefik_v2.1.1_linux_amd64.tar.gz


cat << 'EOF' > /etc/systemd/system/traefik.service
[Unit]
Description=Traefik
After=network.target
[Service]
Type=simple
PIDFile=/run/traefik.pid
ExecStart=/usr/local/bin/traefik
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
chown root:root /etc/systemd/system/traefik.service
chmod 644 /etc/systemd/system/traefik.service

cat << 'EOF' > /etc/traefik/traefik.toml
[log]
level = "DEBUG"
[accessLog]
[entryPoints]
[entryPoints.api]
  address = ":6443"
[entryPoints.https]
  address = ":443"
[providers]
[providers.file]
  directory = "/etc/traefik/conf.d"
  watch = true
EOF

cat << 'EOF' > /etc/traefik/conf.d/exp-ocp.toml
[tcp.routers]
[tcp.routers.exp-ocp4-api]
  entryPoints = ["api"] #entry points are shared among the clusters
  rule = "HostSNI(`api.ocp4.cluster.lab`)"
  service = "service-exp-ocp4-api"
  [tcp.routers.exp-ocp4-api.tls]
  passthrough = true
[tcp.routers.exp-ocp4-https]
  entryPoints = ["https"]
  rule = "HostSNI(`oauth-openshift.apps.ocp4.cluster.lab`,`console-openshift-console.apps.ocp4.cluster.lab`)"
  service = "service-exp-ocp4-https"
  [tcp.routers.exp-ocp4-https.tls]
  passthrough = true
[tcp.services]
[tcp.services.service-exp-ocp4-api.loadBalancer]
[[tcp.services.service-exp-ocp4-api.loadBalancer.servers]]
  address = "192.168.7.77:6443"
[tcp.services.service-exp-ocp4-https.loadBalancer]
[[tcp.services.service-exp-ocp4-https.loadBalancer.servers]]
  address = "192.168.7.77:443"
EOF

sed -i "s/ocp4.cluster.lab/${CLUSTER_NAME}.${CLUSTER_DOMAIN}/g" /etc/traefik/conf.d/exp-ocp.toml

systemctl daemon-reload
systemctl start traefik.service
