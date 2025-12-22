#!/bin/bash

echo "=== Updating dynamic configuration on Jump Host ==="

NODE_COUNT=5
JUMP_HOST_IP="192.168.56.100"
NODE_IP_BASE="192.168.56"
NODE_IP_START=10
HIGH_NODE_ENABLED=true
HIGH_NODE_INDEX=1
HIGH_NODE_CPU=3
HIGH_NODE_MEM=6144
DEFAULT_NODE_CPU=1
DEFAULT_NODE_MEM=2048

cat > /etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 jump

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# Cluster nodes
${JUMP_HOST_IP} jump
EOF

for i in $(seq 0 $((NODE_COUNT-1))); do
    node_ip="${NODE_IP_BASE}.$((NODE_IP_START + i))"
    node_name="node$((i+1))"
    echo "${node_ip} ${node_name}" >> /etc/hosts
done

echo "Updated /etc/hosts with ${NODE_COUNT} nodes"

cat > /home/vagrant/.ssh/config <<EOF
# SSH Configuration for cluster nodes
EOF

for i in $(seq 0 $((NODE_COUNT-1))); do
    node_ip="${NODE_IP_BASE}.$((NODE_IP_START + i))"
    node_name="node$((i+1))"
    cat >> /home/vagrant/.ssh/config <<SSHCONFIG
Host ${node_name}
    HostName ${node_ip}
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 5

SSHCONFIG
done

chmod 600 /home/vagrant/.ssh/config
chown vagrant:vagrant /home/vagrant/.ssh/config
echo "Updated SSH config with ${NODE_COUNT} nodes"

cp /vagrant/scripts/check-cluster.sh /home/vagrant/check-cluster.sh
chmod +x /home/vagrant/check-cluster.sh
chown vagrant:vagrant /home/vagrant/check-cluster.sh

echo "alias cluster-status='/home/vagrant/check-cluster.sh'" >> /home/vagrant/.bashrc
echo "alias cs='/home/vagrant/check-cluster.sh'" >> /home/vagrant/.bashrc
echo "alias show-cluster-config='/home/vagrant/check-cluster.sh --show-config'" >> /home/vagrant/.bashrc
echo "alias scc='/home/vagrant/check-cluster.sh --show-config'" >> /home/vagrant/.bashrc

echo "=== Dynamic configuration completed ==="
echo "Total nodes configured: ${NODE_COUNT}"
if [ "$HIGH_NODE_ENABLED" = "true" ]; then
    echo "High node configuration: Node${HIGH_NODE_INDEX} with ${HIGH_NODE_CPU} CPUs and ${HIGH_NODE_MEM}MB RAM"
else
    echo "High node: DISABLED (all nodes have equal resources)"
fi
echo "Node IP range: ${NODE_IP_BASE}.${NODE_IP_START} - ${NODE_IP_BASE}.$((NODE_IP_START + NODE_COUNT - 1))"
echo ""
echo -e "\033[1;36m=== IMPORTANT: CLUSTER MANAGEMENT COMMANDS ===\033[0m"
echo "To check cluster status: vagrant ssh jump --command '/home/vagrant/check-cluster.sh'"
echo "To show node configuration: vagrant ssh jump --command '/home/vagrant/check-cluster.sh --show-config'"
echo "Or from jump host: ./check-cluster.sh"
echo "Quick aliases:"
echo "  'cluster-status' or 'cs' - check cluster status"
echo "  'show-cluster-config' or 'scc' - show node configuration"
echo ""
echo "SSH to nodes:"
for i in $(seq 1 $NODE_COUNT); do
    echo "  ssh node${i}"
done