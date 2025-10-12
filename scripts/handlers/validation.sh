#!/bin/bash

set -e

echo "=== Starting validation checks ==="

HOSTNAME=$(hostname)
INTERNAL_IP=$(hostname -I | awk '{print $2}')

echo "1. Checking hostname and IP..."
echo "Hostname: $HOSTNAME"
echo "Internal IP: $INTERNAL_IP"

echo "2. Checking network connectivity..."
for node in node1 node2 node3; do
    if ping -c 2 $node &> /dev/null; then
        echo "✓ Ping to $node: SUCCESS"
    else
        echo "✗ Ping to $node: FAILED"
    fi
done

echo "3. Checking DNS resolution..."
for node in node1 node2 node3; do
    if getent hosts $node &> /dev/null; then
        echo "✓ DNS resolution for $node: SUCCESS"
    else
        echo "✗ DNS resolution for $node: FAILED"
    fi
done

echo "4. Checking Docker installation..."
if docker --version &> /dev/null; then
    echo "✓ Docker: $(docker --version)"
else
    echo "✗ Docker: NOT INSTALLED"
fi

echo "5. Testing Docker without sudo..."
if docker ps &> /dev/null; then
    echo "✓ Docker without sudo: WORKING"
else
    echo "✗ Docker without sudo: NOT WORKING"
fi

echo "6. Checking SSH keys..."
if [ -f /home/vagrant/.ssh/id_rsa ]; then
    echo "✓ SSH keys: GENERATED"
else
    echo "✗ SSH keys: NOT GENERATED"
fi

echo "7. Checking SSH connectivity between nodes..."
for node in node1 node2 node3; do
    if [ "$node" != "$HOSTNAME" ]; then
        if ssh -o BatchMode=yes -o ConnectTimeout=2 vagrant@$node "echo success" &> /dev/null; then
            echo "✓ SSH to $node: WORKING"
        else
            echo "✗ SSH to $node: FAILED"
            echo "   Run 'fix-ssh' command to repair"
        fi
    fi
done

echo "8. Checking UFW status..."
if sudo ufw status | grep -q "Status: active"; then
    echo "✓ UFW: ACTIVE"
else
    echo "✗ UFW: INACTIVE"
fi

echo "9. Testing Docker hello-world..."
if docker run --rm hello-world &> /dev/null; then
    echo "✓ Docker hello-world: SUCCESS"
else
    echo "✗ Docker hello-world: FAILED"
fi

echo "10. Checking shared folder..."
if [ -d /cluster/shared ]; then
    echo "✓ Shared folder: MOUNTED"

    echo "Test from $HOSTNAME at $(date)" | tee /cluster/shared/test-$HOSTNAME.txt
else
    echo "✗ Shared folder: NOT MOUNTED"
fi

echo "11. Checking NTP synchronization..."
if systemctl is-active ntp &> /dev/null; then
    echo "✓ NTP: ACTIVE"
    if ntpq -p | grep -q "*"; then
        echo "✓ NTP: SYNCHRONIZED"
    else
        echo "⚠ NTP: NOT SYNCHRONIZED (may need time)"
    fi
else
    echo "✗ NTP: INACTIVE"
fi

echo "=== Validation completed ==="

cat << EOF

=== Cluster Node $HOSTNAME Ready ===
Access: vagrant ssh $HOSTNAME
Internal IP: $INTERNAL_IP
Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')

Useful commands:
- cluster-status  # Check all nodes
- check-connectivity  # Test network
- docker ps  # Check containers
- fix-ssh    # Repair SSH connections

If SSH between nodes doesn't work, run 'fix-ssh' on each node.
EOF