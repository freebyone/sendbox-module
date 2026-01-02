# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'config.rb'

Vagrant.configure("2") do |config|
  config.vm.box = ClusterConfig::VM_BOX
  config.vm.box_check_update = ClusterConfig::CHECK_UPDATES
  
  config.ssh.insert_key = ClusterConfig::SSH_INSERT_KEY
  config.ssh.forward_agent = ClusterConfig::SSH_FORWARD_AGENT
  config.ssh.keep_alive = ClusterConfig::SSH_KEEP_ALIVE
  
  config.vm.boot_timeout = ClusterConfig::BOOT_TIMEOUT

  # JUMP HOST configuration
  config.vm.define "jump" do |jump_config|
    jump_config.vm.hostname = "jump"
    jump_config.vm.network "forwarded_port", 
      guest: 22, 
      host: ClusterConfig::JUMP_HOST_PORT,
      host_ip: "127.0.0.1",
      id: "ssh"
    
    jump_config.vm.network "private_network", 
      ip: ClusterConfig::JUMP_HOST_IP, 
      virtualbox__intnet: ClusterConfig::NETWORK_NAME

    jump_config.vm.provider "virtualbox" do |vb|
      vb.name = "jump-host"
      vb.memory = ClusterConfig::JUMP_HOST_MEMORY
      vb.cpus = ClusterConfig::JUMP_HOST_CPUS
      vb.gui = ClusterConfig::GUI_ENABLED
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["modifyvm", :id, "--usb", "off"]
      vb.customize ["modifyvm", :id, "--usbehci", "off"]
    end
    
    jump_config.vm.provision "bootstrap", type: "shell", 
      path: "#{ClusterConfig::SCRIPTS_DIR}/jump-host-setup.sh"
    
    jump_config.vm.provision "ssh-setup", type: "shell", 
      path: "#{ClusterConfig::SCRIPTS_DIR}/jump-host-ssh-setup.sh"
    
    jump_config.vm.provision "dynamic-config", type: "shell", run: "always", 
      inline: <<-SHELL
        export NODE_COUNT=#{ClusterConfig::NODE_COUNT}
        export JUMP_HOST_IP='#{ClusterConfig::JUMP_HOST_IP}'
        export NODE_IP_BASE='#{ClusterConfig::NODE_IP_BASE}'
        export NODE_IP_START=#{ClusterConfig::NODE_IP_START}
        export HIGH_NODE_ENABLED=#{ClusterConfig::HIGH_NODE_ENABLED}
        export HIGH_NODE_INDEX=#{ClusterConfig::HIGH_NODE_INDEX}
        export HIGH_NODE_CPU=#{ClusterConfig::HIGH_NODE_CPU}
        export HIGH_NODE_MEM=#{ClusterConfig::HIGH_NODE_MEM}
        export DEFAULT_NODE_CPU=#{ClusterConfig::DEFAULT_NODE_CPU}
        export DEFAULT_NODE_MEM=#{ClusterConfig::DEFAULT_NODE_MEM}
        
        #{ClusterConfig.script_path('jump-host-dynamic-config.sh')}
      SHELL
  end

  # NODES configuration
  (1..ClusterConfig::NODE_COUNT).each do |i|
    config.vm.define ClusterConfig.node_name(i) do |node_config|
      node_config.vm.hostname = ClusterConfig.node_name(i)
      
      node_config.vm.network "forwarded_port", 
        guest: 22, 
        host: ClusterConfig.node_port(i),
        host_ip: "127.0.0.1",
        id: "ssh",
        auto_correct: false
      
      node_config.vm.network "private_network", 
        ip: ClusterConfig.node_ip(i),
        virtualbox__intnet: ClusterConfig::NETWORK_NAME
      
      node_config.vm.provider "virtualbox" do |vb|
        vb.name = "cluster-#{ClusterConfig.node_name(i)}"
        vb.memory = ClusterConfig.get_node_memory(i)
        vb.cpus = ClusterConfig.get_node_cpu(i)
        vb.gui = ClusterConfig::GUI_ENABLED
        
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
        vb.customize ["modifyvm", :id, "--cableconnected2", "on"]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
      
      node_config.vm.provision "bootstrap", type: "shell", 
        inline: <<-SHELL
          export NODE_NAME='#{ClusterConfig.node_name(i)}'
          export IS_HIGH_NODE='#{ClusterConfig.is_high_node?(i)}'
          export HIGH_NODE_CPU=#{ClusterConfig::HIGH_NODE_CPU}
          export HIGH_NODE_MEM=#{ClusterConfig::HIGH_NODE_MEM}
          export DEFAULT_CPU=#{ClusterConfig::DEFAULT_NODE_CPU}
          export DEFAULT_MEM=#{ClusterConfig::DEFAULT_NODE_MEM}
          export JUMP_HOST_IP='#{ClusterConfig::JUMP_HOST_IP}'
          export NODE_COUNT=#{ClusterConfig::NODE_COUNT}
          export NODE_IP_BASE='#{ClusterConfig::NODE_IP_BASE}'
          export NODE_IP_START=#{ClusterConfig::NODE_IP_START}
          
          #{ClusterConfig.script_path('node-bootstrap.sh')}
        SHELL

      node_config.vm.provision "jump-host-access", type: "shell",
        inline: <<-SHELL
          export NODE_NAME='#{ClusterConfig.node_name(i)}'
          #{ClusterConfig.script_path('node-jump-host-access.sh')}
        SHELL
    end
  end
end