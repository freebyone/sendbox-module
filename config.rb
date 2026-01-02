
module ClusterConfig
  NODE_COUNT = 5
  JUMP_HOST_IP = "192.168.56.100"
  NODE_IP_BASE = "192.168.56"
  NODE_IP_START = 10
  
  JUMP_HOST_PORT = 2210
  
  NODE_PORTS = {
    1 => 2201,
    2 => 2202, 
    3 => 2203,
    4 => 2204,
    5 => 2205
  }
  
  HIGH_NODE_ENABLED = true
  HIGH_NODE_INDEX = 1
  HIGH_NODE_CPU = 3
  HIGH_NODE_MEM = 6144  # 6 GB
  
  DEFAULT_NODE_CPU = 1
  DEFAULT_NODE_MEM = 2048  # 2 GB
  
  VM_BOX = "ubuntu/jammy64"
  VM_BOX_VERSION = nil
  
  NETWORK_NAME = "cluster-network"
  
  GUI_ENABLED = false
  CHECK_UPDATES = false
  
  SSH_INSERT_KEY = false
  SSH_FORWARD_AGENT = true
  SSH_KEEP_ALIVE = true
  BOOT_TIMEOUT = 600
  
  JUMP_HOST_MEMORY = 1024
  JUMP_HOST_CPUS = 1
  
  SCRIPTS_DIR = "scripts"
  
  def self.node_ip(index)
    "#{NODE_IP_BASE}.#{NODE_IP_START + index - 1}"
  end
  
  def self.node_port(index)
    NODE_PORTS[index] || (2200 + index)
  end
  
  def self.node_name(index)
    "node#{index}"
  end
  
  def self.is_high_node?(index)
    HIGH_NODE_ENABLED && index == HIGH_NODE_INDEX
  end
  
  def self.get_node_cpu(index)
    is_high_node?(index) ? HIGH_NODE_CPU : DEFAULT_NODE_CPU
  end
  
  def self.get_node_memory(index)
    is_high_node?(index) ? HIGH_NODE_MEM : DEFAULT_NODE_MEM
  end
  
  def self.script_path(filename)
    "/vagrant/#{SCRIPTS_DIR}/#{filename}"
  end
end