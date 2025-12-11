# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configuration for vagrantfile
NODE_COUNT = 5  # Number of nodes
JUMP_HOST_IP = "192.168.56.100"
NODE_IP_BASE = "192.168.56"
NODE_IP_START = 10  # First node IP
JUMP_HOST_PORT = 2210
NODE_PORT_START = 2201  # First node port

# ==================== HIGH NODE CONFIGURATION ====================
# Settings for high-performance node
HIGH_NODE_ENABLED = true
HIGH_NODE_INDEX = 1
HIGH_NODE_CPU = 3
HIGH_NODE_MEM = 6144  # 6GB in MB

# Default settings for regular nodes
DEFAULT_NODE_CPU = 1
DEFAULT_NODE_MEM = 2048  # 2GB in MB

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  
  # Configure SSH to be more reliable
  config.ssh.insert_key = false
  config.ssh.forward_agent = true
  config.ssh.keep_alive = true
  
  # Increase boot timeout for nodes
  config.vm.boot_timeout = 900  # 15 minutes instead of default 5

  # ==================== JUMP HOST ====================
  config.vm.define "jump" do |jump_config|
    jump_config.vm.hostname = "jump"
    jump_config.vm.network "forwarded_port", guest: 22, host: JUMP_HOST_PORT, auto_correct: true
    jump_config.vm.network "private_network", ip: JUMP_HOST_IP, virtualbox__intnet: "cluster-network"
    
    jump_config.vm.synced_folder "./ansible", "/home/vagrant/ansible", 
      type: "rsync",
      rsync__auto: true,
      rsync__exclude: [".git/", ".vagrant/", "*.retry", "*.tmp"]

    jump_config.vm.provider "virtualbox" do |vb|
      vb.name = "jump-host"
      vb.memory = 1024
      vb.cpus = 1
      # Add VM customization for better stability
      vb.gui = false
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["modifyvm", :id, "--usb", "off"]
      vb.customize ["modifyvm", :id, "--usbehci", "off"]
      if Vagrant::Util::Platform.windows?
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      end
    end
    
    # Bootstrap jump host
    jump_config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
      echo "=== Setting up Jump Host ==="
      
      # DNS configuration
      cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
Domains=~.
EOF
      systemctl restart systemd-resolved
      systemctl enable systemd-resolved
      
      # Update and install packages
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q
      DEBIAN_FRONTEND=noninteractive apt-get install -y -q ansible sshpass git vim curl wget
      
      echo "=== Jump Host setup completed ==="
    SHELL
    
    # SSH setup
    jump_config.vm.provision "ssh-setup", type: "shell", inline: <<-SHELL
      echo "=== Setting up SSH on Jump Host ==="
      
      # Create SSH directory
      mkdir -p /home/vagrant/.ssh
      chmod 700 /home/vagrant/.ssh
      
      # Generate SSH key if not exists
      if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
          ssh-keygen -t rsa -b 4096 -N "" -f /home/vagrant/.ssh/id_rsa -q
      fi
      
      chmod 600 /home/vagrant/.ssh/id_rsa
      chmod 644 /home/vagrant/.ssh/id_rsa.pub
      
      # Copy public key to shared folder
      cp /home/vagrant/.ssh/id_rsa.pub /vagrant/jump-host-key.pub
      echo "Public key for nodes saved to shared folder"
      
      chown -R vagrant:vagrant /home/vagrant/.ssh
      
      echo "=== SSH setup completed on Jump Host ==="
    SHELL

    jump_config.vm.provision "file", source: "./ansible", destination: "/home/vagrant/"
    
    # POST-PROVISIONING for jump host
    jump_config.vm.provision "dynamic-config", type: "shell", run: "always", inline: <<-SHELL
      echo "=== Updating dynamic configuration on Jump Host ==="
      
      # Update /etc/hosts in jump host
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
#{JUMP_HOST_IP} jump
EOF
      
      # Add nodes to hosts file
      #{NODE_COUNT.times.map { |i| 
        node_ip = "#{NODE_IP_BASE}.#{NODE_IP_START + i}"
        node_name = "node#{i+1}"
        "echo '#{node_ip} #{node_name}' >> /etc/hosts"
      }.join("\n")}
      
      echo "Updated /etc/hosts with #{NODE_COUNT} nodes"
      
      # Update SSH config
      cat > /home/vagrant/.ssh/config <<EOF
# SSH Configuration for cluster nodes
EOF
      
      #{NODE_COUNT.times.map { |i| 
        node_ip = "#{NODE_IP_BASE}.#{NODE_IP_START + i}"
        node_name = "node#{i+1}"
        "cat >> /home/vagrant/.ssh/config <<SSHCONFIG
Host #{node_name}
    HostName #{node_ip}
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 5

SSHCONFIG"
      }.join("\n")}
      
      chmod 600 /home/vagrant/.ssh/config
      chown vagrant:vagrant /home/vagrant/.ssh/config
      echo "Updated SSH config with #{NODE_COUNT} nodes"
      
      # ==================== CLUSTER STATUS CHECK SCRIPT ====================
      # Create a script to check cluster status
      cat > /home/vagrant/check-cluster.sh <<'CHECK_SCRIPT'
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== CLUSTER STATUS CHECK ===${NC}"
echo "Checking connectivity to all nodes..."
echo ""

# Function to check a single node
check_node() {
  local node_name=$1
  local timeout=2
  
  echo -e "${BLUE}Checking ${node_name}...${NC}"
  
  # Try to connect and get resource information
  ssh_output=$(ssh -o ConnectTimeout=$timeout $node_name "
    echo -n '  Status: '
    if [ -f /etc/high-node.info ]; then
      echo -e '${GREEN}HIGH NODE${NC}'
      echo '  Resources configured:'
      grep 'HIGH_NODE_CPU' /etc/high-node.info | sed 's/HIGH_NODE_CPU=/    CPU: /'
      grep 'HIGH_NODE_MEM' /etc/high-node.info | sed 's/HIGH_NODE_MEM=/    RAM: /' | sed 's/$/ MB/'
    else
      echo -e '${YELLOW}REGULAR NODE${NC}'
    fi
    
    echo -n '  Connection: '
    hostname -I | awk '{print \$1}'
    
    echo -n '  Actual CPU cores: '
    nproc
    
    echo -n '  Actual RAM: '
    free -m | awk '/^Mem:/ {printf \"%d MB\n\", \$2}'
    
    echo -n '  Load average: '
    uptime | awk -F'load average:' '{print \$2}' | xargs
    
    echo -n '  Disk usage: '
    df -h / | awk 'NR==2 {print \$5 \" of \" \$2}'
    
    echo -n '  Uptime: '
    uptime -p | sed 's/up //'
  " 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    echo -e "$ssh_output"
    echo -e "  ${GREEN}✓ OK${NC}"
    return 0
  else
    echo -e "  ${RED}✗ FAILED - Cannot connect${NC}"
    return 1
  fi
}

# Check all nodes
total_nodes=#{NODE_COUNT}
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

# Quick connectivity test (your original command)
echo ""
echo -e "${CYAN}Quick connectivity test:${NC}"
for i in {1..#{NODE_COUNT}}; do
  if ssh -o ConnectTimeout=2 node$i "echo -n 'node$i: '" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${RED}FAILED${NC}"
  fi
done
CHECK_SCRIPT
      
      chmod +x /home/vagrant/check-cluster.sh
      chown vagrant:vagrant /home/vagrant/check-cluster.sh
      
      # Create alias for easy access
      echo "alias cluster-status='/home/vagrant/check-cluster.sh'" >> /home/vagrant/.bashrc
      echo "alias cs='/home/vagrant/check-cluster.sh'" >> /home/vagrant/.bashrc
      
      echo "=== Dynamic configuration completed ==="
      echo "Total nodes configured: #{NODE_COUNT}"
      #{if HIGH_NODE_ENABLED
        "echo 'High node configuration: Node#{HIGH_NODE_INDEX} with #{HIGH_NODE_CPU} CPUs and #{HIGH_NODE_MEM}MB RAM'"
      else
        "echo 'High node: DISABLED (all nodes have equal resources)'"
      end}
      echo "Node IP range: #{NODE_IP_BASE}.#{NODE_IP_START} - #{NODE_IP_BASE}.#{NODE_IP_START + NODE_COUNT - 1}"
      echo ""
      echo -e "\033[1;36m=== IMPORTANT: CLUSTER MANAGEMENT COMMANDS ===\033[0m"
      echo "To check cluster status: vagrant ssh jump --command '/home/vagrant/check-cluster.sh'"
      echo "Or from jump host: ./check-cluster.sh"
      echo "Quick alias: 'cluster-status' or 'cs'"
      echo ""
      echo "SSH to nodes:"
      echo "  ssh node1, ssh node2, ..., ssh node#{NODE_COUNT}"
      echo ""
      echo "Your original command is also available:"
      echo "  for i in {1..#{NODE_COUNT}}; do ssh -o ConnectTimeout=2 node\$i \"echo node\$i: OK\" 2>/dev/null || echo \"node\$i: FAILED\"; done"
    SHELL
  end

  # ==================== NODES ====================
  
  # Dynamic configuration for nodes
  (1..NODE_COUNT).each do |i|
    node_ip = "#{NODE_IP_BASE}.#{NODE_IP_START + i - 1}"
    node_port = NODE_PORT_START + i - 1
    node_name = "node#{i}"
    
    config.vm.define node_name do |node_config|
      node_config.vm.hostname = node_name
      
      node_config.vm.network "forwarded_port", 
        guest: 22, 
        host: node_port, 
        auto_correct: true
      
      node_config.vm.network "private_network", 
        ip: node_ip,
        virtualbox__intnet: "cluster-network"
      
      # Track if we've already printed configuration for this node
      @printed_nodes ||= {}
      
      node_config.vm.provider "virtualbox" do |vb|
        # Use a unique VM name to avoid conflicts
        vb.name = "cluster-#{node_name}"
        
        # Determine node configuration
        if HIGH_NODE_ENABLED && i == HIGH_NODE_INDEX
          # Node with high resources
          vb.memory = HIGH_NODE_MEM
          vb.cpus = HIGH_NODE_CPU
          # Print configuration only once per node
          unless @printed_nodes[node_name]
            puts "🚀 Configuring #{node_name} as HIGH-PERFORMANCE NODE"
            puts "   CPU: #{HIGH_NODE_CPU} cores | RAM: #{HIGH_NODE_MEM}MB"
            @printed_nodes[node_name] = true
          end
        else
          # Default node configuration
          vb.memory = DEFAULT_NODE_MEM
          vb.cpus = DEFAULT_NODE_CPU
          # Print configuration only once per node
          unless @printed_nodes[node_name]
            puts "⚙️  Configuring #{node_name} as REGULAR NODE"
            puts "   CPU: #{DEFAULT_NODE_CPU} core | RAM: #{DEFAULT_NODE_MEM}MB"
            @printed_nodes[node_name] = true
          end
        end
        
        # VM customizations for better stability
        vb.gui = false
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
        vb.customize ["modifyvm", :id, "--cableconnected2", "on"]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
        vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
        vb.customize ["modifyvm", :id, "--vrde", "off"]
        
        if Vagrant::Util::Platform.windows?
          vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
          vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
        end
      end
      
      # Node bootstrap with retry logic
      node_config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
        echo "=== Bootstrapping #{node_name} ==="
        
        # First, wait a bit for system to settle
        sleep 10
        
        # DNS configuration
        cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
Domains=~.
EOF
        systemctl restart systemd-resolved
        systemctl enable systemd-resolved
        
        # Wait for network to be fully up
        echo "Waiting for network to be ready..."
        sleep 10
        
        # Update apt with retry logic
        echo "Updating package lists..."
        for attempt in {1..5}; do
          if apt-get update; then
            echo "Package lists updated successfully"
            break
          else
            echo "Attempt \$attempt failed, retrying in 10 seconds..."
            sleep 10
          fi
        done
        
        # Install minimal packages first
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q curl wget openssh-server
        
        # Start SSH early
        systemctl enable ssh
        systemctl start ssh
        
        # Then install other packages
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q vim git net-tools python3 python3-pip
        
        # Install monitoring utilities
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q htop neofetch sysstat
        
        # Add node information to bashrc
        cat >> /home/vagrant/.bashrc <<EOF
        
# Display node information
echo "=== Node Information ==="
echo "Hostname: \$(hostname)"
echo "IP Address: \$(hostname -I | awk '{print \$1}')"
echo "CPU Cores: \$(nproc)"
echo "Total RAM: \$(free -h | awk '/^Mem:/ {print \$2}')"
echo "Uptime: \$(uptime -p)"
echo "========================="
EOF
        
        # Add all nodes to hosts file
        echo "# Cluster nodes" >> /etc/hosts
        echo "#{JUMP_HOST_IP} jump" >> /etc/hosts
        #{NODE_COUNT.times.map { |j| 
          other_node_ip = "#{NODE_IP_BASE}.#{NODE_IP_START + j}"
          other_node_name = "node#{j+1}"
          "echo '#{other_node_ip} #{other_node_name}' >> /etc/hosts"
        }.join("\n")}
        
        # Configure SSH for key-based authentication only
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' /etc/ssh/sshd_config
        sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 5/' /etc/ssh/sshd_config
        systemctl restart ssh
        
        # Create shared directory
        mkdir -p /cluster
        chown vagrant:vagrant /cluster
        
        # Create high node marker if this is the high node
        #{if HIGH_NODE_ENABLED && i == HIGH_NODE_INDEX
          "echo 'Creating high node marker...'
           echo 'HIGH_NODE=true' > /etc/high-node.info
           echo 'HIGH_NODE_CPU=#{HIGH_NODE_CPU}' >> /etc/high-node.info
           echo 'HIGH_NODE_MEM=#{HIGH_NODE_MEM}' >> /etc/high-node.info
           echo 'This node has elevated resources for special workloads' >> /etc/high-node.info"
        end}
        
        echo "=== Basic setup for #{node_name} completed ==="
        
        # Display node configuration information
        #{if HIGH_NODE_ENABLED && i == HIGH_NODE_INDEX
          "echo '=== HIGH NODE CONFIGURATION ==='
           echo 'This node is configured with elevated resources:'
           echo '- CPU Cores: #{HIGH_NODE_CPU}'
           echo '- Memory: #{HIGH_NODE_MEM}MB'
           echo '==============================='"
        else
          "echo '=== REGULAR NODE ==='
           echo 'This node has standard resources:'
           echo '- CPU Cores: #{DEFAULT_NODE_CPU}'
           echo '- Memory: #{DEFAULT_NODE_MEM}MB'
           echo '==============================='"
        end}
        
        # Final system check
        echo "System check:"
        echo "  Hostname: $(hostname)"
        echo "  IP Address: $(hostname -I | awk '{print \$1}')"
        echo "  SSH Status: $(systemctl is-active ssh)"
        echo "  Network: $(ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo 'OK' || echo 'FAILED')"
      SHELL

      # Setup SSH access from jump host
      node_config.vm.provision "jump-host-access", type: "shell", inline: <<-SHELL
        echo "=== Setting up SSH access for Jump Host on #{node_name} ==="
        
        mkdir -p /home/vagrant/.ssh
        chmod 700 /home/vagrant/.ssh
        
        counter=0
        while [ ! -f /vagrant/jump-host-key.pub ] && [ \$counter -lt 180 ]; do
          echo "Waiting for jump host key... (\$counter/180 seconds)"
          sleep 10
          counter=\$((counter + 10))
        done
        
        if [ -f /vagrant/jump-host-key.pub ]; then
          cat /vagrant/jump-host-key.pub >> /home/vagrant/.ssh/authorized_keys
          chmod 600 /home/vagrant/.ssh/authorized_keys
          chown -R vagrant:vagrant /home/vagrant/.ssh
          echo "=== Jump Host SSH access configured on #{node_name} ==="
        else
          echo "ERROR: Jump host key not found after waiting 3 minutes"
          echo "Trying to continue anyway..."
        fi
      SHELL
    end
  end
end