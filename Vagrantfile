VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  
  if Vagrant::Util::Platform.windows?
    config.vm.synced_folder "shared/", "/cluster/shared", type: "virtualbox"
  else
    config.vm.synced_folder "shared/", "/cluster/shared"
  end
  
  config.vm.provision "shell", path: "scripts/base.sh"
  config.vm.provision "shell", path: "scripts/network.sh"
  config.vm.provision "shell", path: "scripts/docker.sh"
  config.vm.provision "shell", path: "scripts/firewall.sh"
  config.vm.provision "shell", path: "scripts/cluster.sh", run: "always"
  
  nodes = [
    { 
      name: "node1", 
      ip: "192.168.56.10",
      cpus: 2,
      memory: 2048
    },
    { 
      name: "node2", 
      ip: "192.168.56.11",
      cpus: 2,
      memory: 2048
    },
    { 
      name: "node3", 
      ip: "192.168.56.12",
      cpus: 2,
      memory: 2048
    }
  ]
  
  nodes.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.hostname = node[:name]
      
      node_config.vm.provider "virtualbox" do |vb|
        vb.name = node[:name]
        vb.cpus = node[:cpus]
        vb.memory = node[:memory]
        vb.linked_clone = true

        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      end
      
      node_config.vm.network "forwarded_port", guest: 22, host: "220#{node[:name][-1]}", auto_correct: true
      
      node_config.vm.network "private_network", ip: node[:ip], virtualbox__intnet: "cluster-network"
      
      node_config.vm.provision "shell", inline: <<-SHELL
        echo "Configuring node-specific settings for #{node[:name]}"

        echo "127.0.1.1 #{node[:name]}" | sudo tee -a /etc/hosts
      SHELL
    end
  end
  
  config.vm.provision "shell", path: "scripts/validation.sh", run: "always"
end