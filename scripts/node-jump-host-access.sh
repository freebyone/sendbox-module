#!/bin/bash

NODE_NAME="${NODE_NAME:-node1}"

echo "=== Setting up SSH access for Jump Host on ${NODE_NAME} ==="

mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh

counter=0
while [ ! -f /vagrant/jump-host-key.pub ] && [ $counter -lt 180 ]; do
  echo "Waiting for jump host key... ($counter/180 seconds)"
  sleep 10
  counter=$((counter + 10))
done

if [ -f /vagrant/jump-host-key.pub ]; then
  cat /vagrant/jump-host-key.pub >> /home/vagrant/.ssh/authorized_keys
  chmod 600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
  echo "=== Jump Host SSH access configured on ${NODE_NAME} ==="
else
  echo "ERROR: Jump host key not found after waiting 3 minutes"
  echo "Trying to continue anyway..."
fi