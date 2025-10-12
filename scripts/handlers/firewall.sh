#!/bin/bash

set -e

echo "=== Starting firewall configuration ==="

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp

sudo ufw allow from 192.168.56.0/24

sudo ufw allow 2375/tcp
sudo ufw allow 2376/tcp

echo "y" | sudo ufw enable

sudo ufw status verbose

echo "=== Firewall configuration completed ==="