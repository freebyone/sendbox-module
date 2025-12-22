#!/bin/bash

echo "=== Setting up Jump Host ==="

cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
Domains=~.
EOF
systemctl restart systemd-resolved
systemctl enable systemd-resolved

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q ansible sshpass git vim curl wget

echo "=== Jump Host setup completed ==="