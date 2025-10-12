#!/bin/bash

set -e

echo "=========================================="
echo "Starting base provisioning for $(hostname)"
echo "=========================================="

echo "Updating package lists..."
apt-get update

echo "Upgrading system packages..."
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "Installing base utilities..."
apt-get install -y \
    curl \
    wget \
    vim \
    git \
    htop \
    net-tools \
    tree \
    openssh-server \
    ufw \
    iotop \
    nethogs \
    ntp \
    ping \
    ntpdate \
    openssh-server \
    jq \
    sshpass \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

echo "Configuring /etc/hosts..."
CURRENT_HOSTNAME=$(hostname)
if ! grep -q "127.0.1.1 $CURRENT_HOSTNAME" /etc/hosts; then
    echo "127.0.1.1 $CURRENT_HOSTNAME" >> /etc/hosts
fi

echo "Creating cluster directories..."
mkdir -p /cluster/{shared,data,logs}
chown -R vagrant:vagrant /cluster

echo "Configuring SSH..."
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chown -R vagrant:vagrant /home/vagrant/.ssh

echo "=========================================="
echo "Base provisioning completed successfully!"
echo "=========================================="