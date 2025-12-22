# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configuration for vagrantfile
NODE_COUNT = 5  # Number of nodes
JUMP_HOST_IP = "192.168.56.100"
NODE_IP_BASE = "192.168.56"
NODE_IP_START = 10  # First node IP
JUMP_HOST_PORT = 2210
# Явно задаем порты для избежания конфликтов
NODE_PORTS = {
  1 => 2201,
  2 => 2202, 
  3 => 2203,
  4 => 2204,
  5 => 2205
}

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
    jump_config.vm.network "forwarded_port", 
      guest: 22, 
      host: JUMP_HOST_PORT,
      host_ip: "127.0.0.1",
      id: "ssh"
    
    jump_config.vm.network "private_network", 
      ip: JUMP_HOST_IP, 
      virtualbox__intnet: "cluster-network"

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
    end
    
    # Bootstrap jump host using external script
    jump_config.vm.provision "bootstrap", type: "shell", path: "scripts/jump-host-setup.sh"
    
    # SSH setup using external script
    jump_config.vm.provision "ssh-setup", type: "shell", path: "scripts/jump-host-ssh-setup.sh"
    
    # POST-PROVISIONING for jump host using external script
    jump_config.vm.provision "dynamic-config", type: "shell", run: "always", 
      inline: <<-SHELL
        # Set environment variables for the script
        export NODE_COUNT=#{NODE_COUNT}
        export JUMP_HOST_IP='#{JUMP_HOST_IP}'
        export NODE_IP_BASE='#{NODE_IP_BASE}'
        export NODE_IP_START=#{NODE_IP_START}
        export HIGH_NODE_ENABLED=#{HIGH_NODE_ENABLED}
        export HIGH_NODE_INDEX=#{HIGH_NODE_INDEX}
        export HIGH_NODE_CPU=#{HIGH_NODE_CPU}
        export HIGH_NODE_MEM=#{HIGH_NODE_MEM}
        export DEFAULT_NODE_CPU=#{DEFAULT_NODE_CPU}
        export DEFAULT_NODE_MEM=#{DEFAULT_NODE_MEM}
        
        # Run the dynamic configuration script
        /vagrant/scripts/jump-host-dynamic-config.sh
      SHELL
  end

  # ==================== NODES ====================
  
  # Dynamic configuration for nodes
  (1..NODE_COUNT).each do |i|
    node_ip = "#{NODE_IP_BASE}.#{NODE_IP_START + i - 1}"
    node_port = NODE_PORTS[i]  # Используем явно заданный порт
    node_name = "node#{i}"
    
    config.vm.define node_name do |node_config|
      node_config.vm.hostname = node_name
      
      # Используем явный порт и отключаем auto_correct
      node_config.vm.network "forwarded_port", 
        guest: 22, 
        host: node_port,
        host_ip: "127.0.0.1",
        id: "ssh",
        auto_correct: false  # Отключаем автокоррекцию
      
      node_config.vm.network "private_network", 
        ip: node_ip,
        virtualbox__intnet: "cluster-network"
      
      node_config.vm.provider "virtualbox" do |vb|
        # Use a unique VM name to avoid conflicts
        vb.name = "cluster-#{node_name}"
        
        # Determine node configuration
        if HIGH_NODE_ENABLED && i == HIGH_NODE_INDEX
          # Node with high resources
          vb.memory = HIGH_NODE_MEM
          vb.cpus = HIGH_NODE_CPU
        else
          # Default node configuration
          vb.memory = DEFAULT_NODE_MEM
          vb.cpus = DEFAULT_NODE_CPU
        end
        
        # VM customizations for better stability
        vb.gui = false
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
        vb.customize ["modifyvm", :id, "--cableconnected2", "on"]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
      
      # Node bootstrap with retry logic using external script
      node_config.vm.provision "bootstrap", type: "shell", 
        inline: <<-SHELL
          # Set environment variables for the script
          export NODE_NAME='#{node_name}'
          export IS_HIGH_NODE='#{HIGH_NODE_ENABLED && i == HIGH_NODE_INDEX}'
          export HIGH_NODE_CPU=#{HIGH_NODE_CPU}
          export HIGH_NODE_MEM=#{HIGH_NODE_MEM}
          export DEFAULT_CPU=#{DEFAULT_NODE_CPU}
          export DEFAULT_MEM=#{DEFAULT_NODE_MEM}
          export JUMP_HOST_IP='#{JUMP_HOST_IP}'
          export NODE_COUNT=#{NODE_COUNT}
          export NODE_IP_BASE='#{NODE_IP_BASE}'
          export NODE_IP_START=#{NODE_IP_START}
          
          # Run the bootstrap script
          /vagrant/scripts/node-bootstrap.sh
        SHELL

      # Setup SSH access from jump host using external script
      node_config.vm.provision "jump-host-access", type: "shell",
        inline: <<-SHELL
          export NODE_NAME='#{node_name}'
          /vagrant/scripts/node-jump-host-access.sh
        SHELL
    end
  end
end