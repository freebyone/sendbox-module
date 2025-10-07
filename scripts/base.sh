#!/bin/bash

set -e

echo "=== Starting base configuration ==="

sudo apt-get update || true
sleep 5
sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

sudo apt-get install -y \
    curl \
    wget \
    vim \
    git \
    htop \
    net-tools \
    iotop \
    nethogs \
    ntp \
    ntpdate \
    openssh-server \
    ufw \
    tree \
    jq \
    sshpass \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

sudo timedatectl set-ntp true || true
sudo systemctl enable ntp || true
sudo systemctl start ntp || true

sudo locale-gen en_US.UTF-8 || true
sudo update-locale LANG=en_US.UTF-8 || true

sudo mkdir -p /cluster/{shared,data,logs}
sudo chown -R vagrant:vagrant /cluster

cat << 'EOF' | sudo tee /etc/motd

=== Cluster Node ===
Hostname: $(hostname)
IP: $(hostname -I | awk '{print $2}')
Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',') || "Not installed"

EOF

echo "=== Base configuration completed ==="