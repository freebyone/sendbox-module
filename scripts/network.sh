#!/bin/bash

set -e

echo "=== Starting network configuration ==="

sleep 10

HOSTNAME=$(hostname)
INTERNAL_IP=$(hostname -I | awk '{print $2}')

echo "Waiting for network interfaces to be ready..."
while [ -z "$INTERNAL_IP" ]; do
    sleep 5
    INTERNAL_IP=$(hostname -I | awk '{print $2}')
    echo "Waiting for internal IP..."
done

sudo tee /etc/resolv.conf > /dev/null << EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
search local
EOF

sudo chattr +i /etc/resolv.conf 2>/dev/null || true

sudo tee /etc/hosts > /dev/null << EOF
127.0.0.1 localhost
127.0.1.1 $HOSTNAME

# Cluster nodes
192.168.56.10 node1
192.168.56.11 node2
192.168.56.12 node3

EOF

sudo systemctl stop systemd-resolved 2>/dev/null || true
sudo systemctl disable systemd-resolved 2>/dev/null || true

cat << EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      optional: true
    eth1:
      dhcp4: false
      addresses: [$INTERNAL_IP/24]
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      optional: true
EOF

sudo netplan generate
sudo netplan apply

sleep 10

echo "=== Network configuration completed ==="