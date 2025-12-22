#!/bin/bash

NODE_NAME="${NODE_NAME:-node1}"
IS_HIGH_NODE="${IS_HIGH_NODE:-false}"
HIGH_NODE_CPU="${HIGH_NODE_CPU:-3}"
HIGH_NODE_MEM="${HIGH_NODE_MEM:-6144}"
DEFAULT_CPU="${DEFAULT_CPU:-1}"
DEFAULT_MEM="${DEFAULT_MEM:-2048}"
JUMP_HOST_IP="${JUMP_HOST_IP:-192.168.56.100}"
NODE_COUNT="${NODE_COUNT:-5}"
NODE_IP_BASE="${NODE_IP_BASE:-192.168.56}"
NODE_IP_START="${NODE_IP_START:-10}"

echo "=== Bootstrapping ${NODE_NAME} ==="

sleep 5

cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
Domains=~.
EOF
systemctl restart systemd-resolved
systemctl enable systemd-resolved

echo "Waiting for network to be ready..."
sleep 5

echo "Updating package lists..."
for attempt in {1..3}; do
  if apt-get update > /dev/null 2>&1; then
    echo "Package lists updated successfully"
    break
  else
    echo "Attempt $attempt failed, retrying in 5 seconds..."
    sleep 5
  fi
done

echo "Installing essential packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  curl \
  wget \
  openssh-server \
  vim-tiny \
  git \
  net-tools \
  python3 \
  python3-pip \
  htop \
  sysstat

systemctl enable ssh
systemctl start ssh

cat >> /home/vagrant/.bashrc <<'EOF'

# Display node information
echo "=== Node Information ==="
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print \$1}')"
echo "CPU Cores: $(nproc)"
echo "Total RAM: $(free -h | awk '/^Mem:/ {print \$2}')"
echo "Uptime: $(uptime -p)"
echo "========================="
EOF

echo "# Cluster nodes" >> /etc/hosts
echo "${JUMP_HOST_IP} jump" >> /etc/hosts

for i in $(seq 0 $((NODE_COUNT-1))); do
    other_node_ip="${NODE_IP_BASE}.$((NODE_IP_START + i))"
    other_node_name="node$((i+1))"
    echo "${other_node_ip} ${other_node_name}" >> /etc/hosts
done

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 5/' /etc/ssh/sshd_config
systemctl restart ssh

mkdir -p /cluster
chown vagrant:vagrant /cluster

if [ "$IS_HIGH_NODE" = "true" ]; then
    echo "Creating high node marker..."
    echo "HIGH_NODE=true" > /etc/high-node.info
    echo "HIGH_NODE_CPU=${HIGH_NODE_CPU}" >> /etc/high-node.info
    echo "HIGH_NODE_MEM=${HIGH_NODE_MEM}" >> /etc/high-node.info
    echo "This node has elevated resources for special workloads" >> /etc/high-node.info
fi

echo "=== Basic setup for ${NODE_NAME} completed ==="

if [ "$IS_HIGH_NODE" = "true" ]; then
    echo "=== HIGH NODE CONFIGURATION ==="
    echo "This node is configured with elevated resources:"
    echo "- CPU Cores: ${HIGH_NODE_CPU}"
    echo "- Memory: ${HIGH_NODE_MEM}MB"
    echo "==============================="
else
    echo "=== REGULAR NODE ==="
    echo "This node has standard resources:"
    echo "- CPU Cores: ${DEFAULT_CPU}"
    echo "- Memory: ${DEFAULT_MEM}MB"
    echo "==============================="
fi

echo "System check:"
echo "  Hostname: $(hostname)"
echo "  IP Address: $(hostname -I | awk '{print $1}')"
echo "  SSH Status: $(systemctl is-active ssh)"
ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "  Network: OK" || echo "  Network: FAILED"