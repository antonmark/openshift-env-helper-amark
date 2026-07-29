#!/bin/bash
# Append a kickstart %post that enables root SSH password login.
# Needed because RHEL defaults to PermitRootLogin prohibit-password, which
# prevents wait_until_helper_running.sh from using sshpass + ssh-copy-id.

KS_CFG=${1:?kickstart path required}

cat << 'EOF' >> "${KS_CFG}"
%post --log=/root/helper_ssh_setup.out
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/99-helper-root.conf << 'EOC'
PermitRootLogin yes
PasswordAuthentication yes
EOC
%end
EOF
