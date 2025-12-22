#!/bin/bash

echo "=== Setting up SSH on Jump Host ==="

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

# Generate SSH key if not exists
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f /home/vagrant/.ssh/id_rsa -q
fi

chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub

cp /home/vagrant/.ssh/id_rsa.pub /vagrant/jump-host-key.pub
echo "Public key for nodes saved to shared folder"

chown -R vagrant:vagrant /home/vagrant/.ssh

echo "=== SSH setup completed on Jump Host ==="