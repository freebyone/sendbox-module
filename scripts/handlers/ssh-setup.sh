#!/bin/bash

set -e

echo "=========================================="
echo "SSH Key Exchange"
echo "=========================================="

HOSTNAME=$(hostname)
echo "Running on: $HOSTNAME"

if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    apt-get update > /dev/null 2>&1
    apt-get install -y sshpass > /dev/null 2>&1
fi

exchange_keys() {
    local target_node=$1
    local target_ip=$2
    
    if [ "$target_node" = "$HOSTNAME" ]; then
        return 0
    fi
    
    echo "Exchanging with $target_node..."
    
    ssh-keyscan -H $target_node >> /home/vagrant/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -H $target_ip >> /home/vagrant/.ssh/known_hosts 2>/dev/null
    
    if sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no vagrant@$target_node > /dev/null 2>&1; then
        echo "✅ $target_node: keys exchanged"
        return 0
    else
        echo "⚠️  $target_node: will retry later"
        return 1
    fi
}

echo "Starting SSH key exchange..."
echo "Note: Some nodes might not be ready yet - this is normal"

exchange_keys "node1" "192.168.56.10"
exchange_keys "node2" "192.168.56.11" 
exchange_keys "node3" "192.168.56.12"

echo ""
echo "=========================================="
echo "SSH setup attempt completed"
echo "=========================================="
echo "If some exchanges failed, don't worry!"
echo "You can run this manually later:"
echo "  vagrant provision --provision-with ssh-setup"
echo "=========================================="