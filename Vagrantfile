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
  config.vm.boot_timeout = 600  # 10 minutes instead of default 5

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

SSHCONFIG"
      }.join("\n")}
      
      chmod 600 /home/vagrant/.ssh/config
      chown vagrant:vagrant /home/vagrant/.ssh/config
      echo "Updated SSH config with #{NODE_COUNT} nodes"
      
      echo "=== Dynamic configuration completed ==="
      echo "Total nodes configured: #{NODE_COUNT}"
      #{if HIGH_NODE_ENABLED
        "echo 'High node configuration: Node#{HIGH_NODE_INDEX} with #{HIGH_NODE_CPU} CPUs and #{HIGH_NODE_MEM}MB RAM'"
      else
        "echo 'High node: DISABLED (all nodes have equal resources)'"
      end}
      echo "Node IP range: #{NODE_IP_BASE}.#{NODE_IP_START} - #{NODE_IP_BASE}.#{NODE_IP_START + NODE_COUNT - 1}"
      echo "SSH to nodes: ssh node1, ssh node2, ..., ssh node#{NODE_COUNT}"
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
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
        vb.customize ["modifyvm", :id, "--rtcuseutc", "on"]
        
        if Vagrant::Util::Platform.windows?
          vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
          vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
          # Disable audio for better performance
          vb.customize ["modifyvm", :id, "--audio", "none"]
        end
        
        # Add some debugging information
        puts "💡 VM #{node_name} will use port #{node_port} for SSH"
      end
      
      # Pre-boot shell to fix potential issues
      node_config.vm.provision "fix-boot-issues", type: "shell", run: "once", inline: <<-SHELL
        # This script runs before the VM boots
        echo "Preparing #{node_name} for boot..."
      SHELL
      
      # Node bootstrap
      node_config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
        echo "=== Bootstrapping #{node_name} ==="
        
        # First, make sure network is working
        echo "Checking network connectivity..."
        ping -c 2 8.8.8.8 || echo "Warning: Could not ping external network"
        
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
        sleep 5
        
        # Update apt with retry logic
        echo "Updating package lists..."
        for i in {1..5}; do
          apt-get update && break
          echo "Attempt $i failed, retrying in 10 seconds..."
          sleep 10
        done
        
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q curl wget vim git net-tools python3 python3-pip openssh-server
        
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
        systemctl enable ssh
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
      SHELL

      # Setup SSH access from jump host
      node_config.vm.provision "jump-host-access", type: "shell", inline: <<-SHELL
        echo "=== Setting up SSH access for Jump Host on #{node_name} ==="
        
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
          echo "=== Jump Host SSH access configured on #{node_name} ==="
        else
          echo "ERROR: Jump host key not found after waiting 3 minutes"
          echo "Trying to continue anyway..."
        fi
      SHELL
    end
  end
end