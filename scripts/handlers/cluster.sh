#!/bin/bash
set -e

echo "=== Starting cluster configuration ==="

if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f /home/vagrant/.ssh/id_rsa
fi

cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

sudo chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub
chmod 600 /home/vagrant/.ssh/authorized_keys

sudo tee /home/vagrant/.ssh/config > /dev/null << EOF
Host node1
    HostName node1
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host node2
    HostName node2
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host node3
    HostName node3
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

sudo chown vagrant:vagrant /home/vagrant/.ssh/config
chmod 600 /home/vagrant/.ssh/config

sudo tee /usr/local/bin/exchange-keys > /dev/null << 'EOF'
#!/bin/bash
echo "=== Manual SSH Key Exchange ==="

HOSTNAME=$(hostname)
echo "Running on $HOSTNAME"

# Ждем доступности всех нод
for node in node1 node2 node3; do
    if [ "$node" != "$HOSTNAME" ]; then
        echo "Waiting for $node to be ready..."
        until ping -c 1 -W 1 $node &> /dev/null; do
            sleep 2
        done
        echo "✓ $node is reachable"
        
        # Обмениваемся ключами
        echo "Exchanging keys with $node..."
        ssh-keyscan -H $node >> /home/vagrant/.ssh/known_hosts 2>/dev/null
        sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no vagrant@$node
    fi
done

echo "=== Key exchange completed ==="
echo "Testing connections:"
for node in node1 node2 node3; do
    if [ "$node" != "$HOSTNAME" ]; then
        ssh $node "echo '✓ Successfully connected to $node from $HOSTNAME'" && \
        echo "✓ $node: SUCCESS" || echo "✗ $node: FAILED"
    fi
done
EOF

sudo chmod +x /usr/local/bin/exchange-keys

echo "=== Cluster configuration completed ==="
echo "Run 'exchange-keys' manually after all nodes are fully provisioned"