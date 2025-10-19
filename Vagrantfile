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
    
    jump_config.vm.synced_folder "./ansible", "/home/vagrant/ansible", 
      type: "rsync",
      rsync__auto: true,
      rsync__exclude: [".git/", ".vagrant/", "*.retry", "*.tmp"]

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
      
      # Configure hosts file
      cat >> /etc/hosts <<EOF
# Cluster nodes
192.168.56.10 node1
192.168.56.11 node2
192.168.56.12 node3
EOF
      
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
      
      # Create SSH config with IP addresses
      cat > /home/vagrant/.ssh/config <<EOF
Host node1
    HostName 192.168.56.10
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10

Host node2
    HostName 192.168.56.11
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10

Host node3
    HostName 192.168.56.12
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
EOF
      
      chmod 600 /home/vagrant/.ssh/config
      chown -R vagrant:vagrant /home/vagrant/.ssh
      
      cp /home/vagrant/.ssh/id_rsa.pub /vagrant/jump-host-key.pub
      echo "Public key for nodes saved to shared folder"
      
      echo "=== SSH setup completed on Jump Host ==="
    SHELL

    jump_config.vm.provision "file", source: "./ansible", destination: "/home/vagrant/"
    
    jump_config.vm.provision "ansible-setup", type: "shell", inline: <<-SHELL
      echo "=== Setting up Ansible on Jump Host ==="
      
      if [ ! -f /home/vagrant/ansible/ansible.cfg ]; then
        cat > /home/vagrant/ansible/ansible.cfg <<EOF
[defaults]
host_key_checking = False
inventory = /home/vagrant/ansible/inventory
remote_user = vagrant
private_key_file = /home/vagrant/.ssh/id_rsa

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
pipelining = True
timeout = 30
EOF
      fi
      
      if [ ! -f /home/vagrant/ansible/inventory ]; then
        cat > /home/vagrant/ansible/inventory <<EOF
[cluster]
node1 ansible_host=192.168.56.10
node2 ansible_host=192.168.56.11
node3 ansible_host=192.168.56.12

[cluster:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=/home/vagrant/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
      fi
      
      chown -R vagrant:vagrant /home/vagrant/ansible
      echo "=== Ansible setup completed ==="
    SHELL
  end

  # Config for cluster nodes
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
      
      # Node bootstrap
      node_config.vm.provision "bootstrap", type: "shell", inline: <<-SHELL
        echo "=== Bootstrapping #{node[:name]} ==="
        
        # DNS configuration
        cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
Domains=~.
EOF
        systemctl restart systemd-resolved
        systemctl enable systemd-resolved
        
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q
        DEBIAN_FRONTEND=noninteractive apt-get install -y -q curl wget vim git net-tools python3 python3-pip openssh-server
        
        cat >> /etc/hosts <<EOF
# Cluster nodes
192.168.56.10 node1
192.168.56.11 node2
192.168.56.12 node3
192.168.56.100 jump
EOF
        
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl enable ssh
        systemctl restart ssh
        
        mkdir -p /cluster
        chown vagrant:vagrant /cluster
        echo "=== Basic setup for #{node[:name]} completed ==="
      SHELL

      node_config.vm.provision "jump-host-access", type: "shell", inline: <<-SHELL
        echo "=== Setting up SSH access for Jump Host on #{node[:name]} ==="
        
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
          echo "=== Jump Host SSH access configured on #{node[:name]} ==="
        else
          echo "ERROR: Jump host key not found after waiting 3 minutes"
          echo "Trying to continue anyway..."
        fi
      SHELL
    end
  end
end