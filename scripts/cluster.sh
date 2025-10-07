#!/bin/bash

set -e

echo "=== Starting cluster configuration ==="

if ! id "clusteruser" &>/dev/null; then
    sudo useradd -m -s /bin/bash -G docker,sudo clusteruser
    echo "clusteruser:clusterpass" | sudo chpasswd
fi

if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f /home/vagrant/.ssh/id_rsa
fi

cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

sudo chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub
chmod 600 /home/vagrant/.ssh/authorized_keys

exchange_ssh_keys() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt to exchange SSH keys..."
        
        for node in node1 node2 node3; do
            if [ "$node" != "$(hostname)" ]; then

                ssh-keyscan -H $node >> /home/vagrant/.ssh/known_hosts 2>/dev/null || true
                
                if sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no -o ConnectTimeout=5 vagrant@$node 2>/dev/null; then
                    echo "✓ Successfully exchanged keys with $node"
                else
                    echo "⚠ Failed to exchange with $node on attempt $attempt"
                fi
            fi
        done
        
        local success_count=0
        for node in node1 node2 node3; do
            if [ "$node" != "$(hostname)" ]; then
                if ssh -o ConnectTimeout=2 -o BatchMode=yes vagrant@$node "echo connected" 2>/dev/null; then
                    ((success_count++))
                fi
            fi
        done
        
        if [ $success_count -eq 2 ]; then
            echo "✓ SSH key exchange completed successfully"
            break
        fi
        
        ((attempt++))
        sleep 10
    done
}

sudo tee /usr/local/bin/exchange-keys > /dev/null << 'EOF'
#!/bin/bash
echo "Starting manual SSH key exchange..."
for node in node1 node2 node3; do
    if [ "$node" != "$(hostname)" ]; then
        echo "Exchanging with $node..."
        ssh-keyscan -H $node >> /home/vagrant/.ssh/known_hosts 2>/dev/null
        sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no vagrant@$node
    fi
done
echo "Key exchange completed"
EOF

sudo chmod +x /usr/local/bin/exchange-keys

sudo tee /home/vagrant/.ssh/config > /dev/null << EOF
Host node1
    HostName node1
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ConnectTimeout 5
    StrictHostKeyChecking no

Host node2
    HostName node2
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ConnectTimeout 5
    StrictHostKeyChecking no

Host node3
    HostName node3
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    ConnectTimeout 5
    StrictHostKeyChecking no
EOF

sudo chown vagrant:vagrant /home/vagrant/.ssh/config
chmod 600 /home/vagrant/.ssh/config

exchange_ssh_keys

cat << 'EOF' >> /home/vagrant/.bashrc

# Cluster aliases
alias nodes='echo "Node1: 192.168.56.10, Node2: 192.168.56.11, Node3: 192.168.56.12"'
alias cluster-status='for node in node1 node2 node3; do echo "=== \$node ==="; ssh \$node "hostname -I && docker ps"; done'
alias check-connectivity='for node in node1 node2 node3; do ping -c 2 \$node && echo "\$node: OK" || echo "\$node: FAIL"; done'
alias fix-ssh='/usr/local/bin/exchange-keys'

EOF

echo "=== Cluster configuration completed ==="