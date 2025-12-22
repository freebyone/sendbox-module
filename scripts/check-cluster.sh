#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

NODE_COUNT=5
HIGH_NODE_ENABLED=true
HIGH_NODE_INDEX=1
HIGH_NODE_CPU=3
HIGH_NODE_MEM=6144
DEFAULT_NODE_CPU=1
DEFAULT_NODE_MEM=2048
NODE_IP_BASE="192.168.56"
NODE_IP_START=10

# Function to display node configuration
show_node_config() {
  echo -e "${CYAN}=== NODE CONFIGURATION ===${NC}"
  echo "Node configuration summary:"
  echo ""
  
  total_nodes=$NODE_COUNT
  
  for i in $(seq 1 $total_nodes); do
    if [ "$HIGH_NODE_ENABLED" = "true" ] && [ $i -eq $HIGH_NODE_INDEX ]; then
      echo -e "🚀 ${YELLOW}node${i}${NC} as ${GREEN}HIGH-PERFORMANCE NODE${NC}"
      echo "   CPU: ${HIGH_NODE_CPU} cores | RAM: ${HIGH_NODE_MEM}MB"
    else
      echo -e "⚙️  ${YELLOW}node${i}${NC} as ${BLUE}REGULAR NODE${NC}"
      echo "   CPU: ${DEFAULT_NODE_CPU} core | RAM: ${DEFAULT_NODE_MEM}MB"
    fi
  done
  
  echo ""
  echo "IP range: ${NODE_IP_BASE}.${NODE_IP_START} - ${NODE_IP_BASE}.$((NODE_IP_START + NODE_COUNT - 1))"
  echo "=========================================="
  echo ""
}

if [ "$1" = "--show-config" ] || [ "$1" = "-c" ]; then
  show_node_config
  exit 0
fi

echo -e "${CYAN}=== CLUSTER STATUS CHECK ===${NC}"
echo "Checking connectivity to all nodes..."
echo ""

check_node() {
  local node_name=$1
  local timeout=2
  
  echo -e "${BLUE}Checking ${node_name}...${NC}"
  
  ssh_output=$(ssh -o ConnectTimeout=$timeout $node_name 2>/dev/null <<'EOF'
    # Проверяем тип узла
    if [ -f /etc/high-node.info ]; then
      echo "  Type: HIGH NODE"
      echo "  Configured resources:"
      grep 'HIGH_NODE_CPU' /etc/high-node.info | sed 's/HIGH_NODE_CPU=/    CPU: /'
      grep 'HIGH_NODE_MEM' /etc/high-node.info | sed 's/HIGH_NODE_MEM=/    RAM: /' | sed 's/$/ MB/'
    else
      echo "  Type: REGULAR NODE"
    fi
    
    # Собираем информацию о системе
    echo -n "  IP Address: "
    hostname -I | awk '{print $1}'
    
    echo -n "  CPU cores: "
    nproc
    
    echo -n "  Total RAM: "
    free -m | awk '/^Mem:/ {printf "%d MB\n", $2}'
    
    echo -n "  Load average: "
    uptime | awk -F'load average:' '{print $2}' | xargs
    
    echo -n "  Disk usage: "
    df -h / | awk 'NR==2 {print $5 " of " $2}'
    
    echo -n "  Uptime: "
    uptime -p | sed 's/up //'
EOF
  )
  
  if [ $? -eq 0 ]; then
    echo "$ssh_output" | sed \
      -e "s/Type: HIGH NODE/Type: ${GREEN}HIGH NODE${NC}/" \
      -e "s/Type: REGULAR NODE/Type: ${BLUE}REGULAR NODE${NC}/"
    echo -e "  ${GREEN}✓ OK${NC}"
    return 0
  else
    echo -e "  ${RED}✗ FAILED - Cannot connect${NC}"
    return 1
  fi
}

# Check all nodes
total_nodes=$NODE_COUNT
online_nodes=0

for i in $(seq 1 $total_nodes); do
  echo "----------------------------------------"
  if check_node "node$i"; then
    ((online_nodes++))
  fi
  echo ""
done

echo "========================================"
echo -e "${CYAN}SUMMARY:${NC}"
echo -e "  Total nodes configured: ${total_nodes}"
echo -e "  Online nodes: ${GREEN}${online_nodes}${NC}"
echo -e "  Offline nodes: ${RED}$((total_nodes - online_nodes))${NC}"

if [ $online_nodes -eq $total_nodes ]; then
  echo -e "${GREEN}✅ All nodes are online and responding!${NC}"
  echo ""
  echo "You can SSH to any node using:"
  echo "  ssh node1"
  echo "  ssh node2"
  echo "  ..."
  echo "  ssh node$total_nodes"
else
  echo -e "${YELLOW}⚠ Some nodes are offline or not responding.${NC}"
  echo ""
  echo "Troubleshooting tips:"
  echo "  1. Check if VMs are running: vagrant status"
  echo "  2. Start offline nodes: vagrant up nodeX"
  echo "  3. Check network connectivity"
fi

echo ""
echo -e "${CYAN}Quick connectivity test:${NC}"
for i in {1..$NODE_COUNT}; do
  if ssh -o ConnectTimeout=2 node$i "echo -n 'node$i: '" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}FAILED${NC}"
  fi
done

if [ $online_nodes -eq 0 ]; then
  echo ""
  show_node_config
fi