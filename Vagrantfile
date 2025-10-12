# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false

  # Jump host
  config.vm.define "jump" do |jump_config|
    jump_config.vm.hostname = "jump"
    jump_config.vm.network "forwarded_port", guest: 22, host: 2210, auto_correct: true
    jump_config.vm.network "private_network", ip: "192.168.56.100", virtualbox__intnet: "cluster-network"
    
    jump_config.vm.provider "virtualbox" do |vb|
      vb.name = "jump-host"
      vb.memory = 1024
      vb.cpus = 1
      if Vagrant::Util::Platform.windows?
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      end
    end
    
    # Configuration jump
    jump_config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
      echo "=== Setting up Jump Host ==="
      
      # DNS
      echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
      echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
      
      # upgrade
      apt-get update
      apt-get upgrade -y
      
      apt-get install -y ansible sshpass git vim curl wget
      
      # hosts
      cat >> /etc/hosts <<EOF
# Cluster nodes
192.168.56.10 node1
192.168.56.11 node2
192.168.56.12 node3
EOF
      
      # Configure
      mkdir -p /ansible
      chown vagrant:vagrant /ansible
      
      echo "=== Jump Host setup completed ==="
    SHELL
    
    jump_config.vm.provision "file", source: "./ansible", destination: "/home/vagrant/"
    
    # ssh
    jump_config.vm.provision "ssh-setup", type: "shell", inline: <<-SHELL
      echo "=== Setting up SSH on Jump Host ==="
      
      if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
          ssh-keygen -t rsa -b 4096 -N "" -f /home/vagrant/.ssh/id_rsa -q
      fi
      
      chmod 700 /home/vagrant/.ssh
      chmod 600 /home/vagrant/.ssh/id_rsa
      chmod 644 /home/vagrant/.ssh/id_rsa.pub
      
      # Create SSH config
      cat > /home/vagrant/.ssh/config <<EOF
Host node1
    HostName node1
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    ConnectTimeout 5

Host node2
    HostName node2
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no

Host node3
    HostName node3
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
EOF
      
      chmod 600 /home/vagrant/.ssh/config
      chown -R vagrant:vagrant /home/vagrant/.ssh
      
      echo "=== SSH setup completed on Jump Host ==="
      echo "Public key for cluster nodes:"
      cat /home/vagrant/.ssh/id_rsa.pub
    SHELL
  end

  # Config
  nodes = [
    { name: "node1", ip: "192.168.56.10", port: 2201 },
    { name: "node2", ip: "192.168.56.11", port: 2202 },
    { name: "node3", ip: "192.168.56.12", port: 2203 }
  ]

  nodes.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.hostname = node[:name]
      
      node_config.vm.network "forwarded_port", 
        guest: 22, 
        host: node[:port], 
        auto_correct: true
      
      node_config.vm.network "private_network", 
        ip: node[:ip],
        virtualbox__intnet: "cluster-network"
      
      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.memory = 1024
        vb.cpus = 1
        
        if Vagrant::Util::Platform.windows?
          vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
          vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
        end
      end
      
      node_config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
        echo "=== Bootstrapping #{node[:name]} ==="
        apt-get update
        apt-get upgrade -y
        apt-get install -y curl wget vim git net-tools python3 python3-pip
        
        cat >> /etc/hosts <<EOF
# Cluster nodes
192.168.56.10 node1
192.168.56.11 node2
192.168.56.12 node3
192.168.56.100 jump
EOF
        
        mkdir -p /cluster
        chown vagrant:vagrant /cluster
        echo "=== Basic setup for #{node[:name]} completed ==="
      SHELL

      # Node configuration
      node_config.vm.provision "jump-host-access", type: "shell", inline: <<-SHELL
        echo "=== Setting up SSH access for Jump Host ==="
        
        mkdir -p /home/vagrant/.ssh
        chmod 700 /home/vagrant/.ssh
        
        until [ -f /vagrant/jump-host-key.pub ]; do
          echo "Waiting for jump host key..."
          sleep 5
        done
        
        cat /vagrant/jump-host-key.pub >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
        
        echo "=== Jump Host SSH access configured ==="
      SHELL
    end
  end
  
  config.vm.provision "share-jump-key", type: "shell", run: "once", inline: <<-SHELL
    echo "=== Sharing Jump Host SSH key ==="
    
    vagrant ssh jump -c "cat /home/vagrant/.ssh/id_rsa.pub" > /vagrant/jump-host-key.pub
    
    echo "=== Jump Host key shared ==="
  SHELL

  config.vm.provision "run-ansible", type: "shell", run: "once", inline: <<-SHELL
    echo "=== Running Ansible from Jump Host ==="
    
    sleep 30
    
    vagrant ssh jump -c "cd /home/vagrant/ansible && ansible-playbook playbook.yml"
    
    echo "=== Ansible deployment completed ==="
  SHELL
end