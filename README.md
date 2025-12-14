## 🚀 Dynamic Infrastructure Lab
A powerful, flexible Vagrant-based infrastructure for creating dynamic multi-node clusters with automated SSH configuration, jump host management, and support for heterogeneous node resources (including high-performance nodes).
## ✨ Features

* Dynamic Node Creation: Easily configure any number of nodes via a single variable.
* Heterogeneous Resources: Designate one node as a high-performance node with elevated CPU and RAM for demanding workloads.
* Jump Host Architecture: Centralized management through a dedicated jump host for secure access and automation.
* Automated SSH Setup: Passwordless SSH access from the jump host to all nodes, with auto-generated configs.
* Ansible-Ready: Pre-configured with Ansible on the jump host, synced from your local ./ansible directory.
* Network Isolation: Private internal network (192.168.56.0/24) for secure inter-node communication.
* Cluster Monitoring: Built-in check-cluster.sh script on the jump host for status checks, resource verification, and troubleshooting.
* Enhanced Stability: Increased boot timeouts, retry logic in provisioning, and optimized VM settings for reliability.
* Cross-Platform Compatibility: Tested on Windows, Linux, and macOS with VirtualBox.
* Customizable: Adjust node counts, IPs, ports, resources, and enable/disable high-node features.

## 📋 Prerequisites

VirtualBox (version 7.0 or later recommended for stability).
Vagrant (version 2.3.0 or later).
Host machine with at least 16GB RAM (for 5+ nodes with high-node enabled) and 20GB+ free disk space.
Git for cloning the repository.

## 🚀 Quick Start

Clone the Repository
```
git clone https://github.com/freebyone/sendbox-module.git

cd sendbox-module
```

Start the Infrastructuretextvagrant upThis will create the jump host and all nodes (default: 5 nodes, with node1 as high-performance).

Access the Jump Host
```
vagrant ssh jump
```
Check Cluster Status (from jump host)text
```
./check-cluster.shOr use aliases: cluster-status or cs.
```
Connect to Nodes (from jump host)textssh node1  # High-performance node
```
ssh node2  # Regular node
```

## ⚙️ Configuration
Edit the Vagrantfile to customize your setup. Key variables are at the top:
Basic Settings
```
NODE_COUNT = 5 – Total number of cluster nodes.
JUMP_HOST_IP = "192.168.56.100" – IP for the jump host.
NODE_IP_BASE = "192.168.56" – Base IP prefix for nodes.
NODE_IP_START = 10 – Starting IP suffix for nodes (e.g., node1: 192.168.56.10).
JUMP_HOST_PORT = 2210 – Host port forwarded to jump host SSH.
NODE_PORT_START = 2201 – Starting host port for node SSH forwarding.
```

High-Performance Node (Optional)
```
HIGH_NODE_ENABLED = true – Enable/disable the high-performance node.
HIGH_NODE_INDEX = 1 – Which node gets elevated resources (e.g., 1 for node1).
HIGH_NODE_CPU = 3 – CPUs for the high node.
HIGH_NODE_MEM = 6144 – RAM for the high node (in MB, e.g., 6GB).
```

Default Node Resources
```
DEFAULT_NODE_CPU = 1 – CPUs per regular node.
DEFAULT_NODE_MEM = 2048 – RAM per regular node (in MB, e.g., 2GB).
```

Jump Host Resources

Fixed: 1 CPU, 1024MB RAM.

After changes, run vagrant up or vagrant reload to apply.

## 🏗️ Architecture
The setup uses a jump host as a gateway for managing nodes in a private network. Node1 (by default) is configured as a high-performance node for heavy workloads.
```
     ┌─────────────────────────────────────────────┐
     │         Your Local Machine                  │
     │  ┌──────────────────────────────────────┐   │
     │  │      VirtualBox Environment          │   │
     │  │                                      │   │ 
     │  │  ╔══════════════════════════════╗    │   │
     │  │  ║     Jump Host (Gateway)      ║    │   │
     │  │  ║                              ║    │   │
     │  │  ║  jump (192.168.56.100)       ║    │   │
     │  │  ║  • 1GB RAM, 1 CPU            ║    │   │
     │  │  ║  • SSH Port: 2210            ║    │   │
     │  │  ║  • Ansible & SSH Management  ║    │   │
     │  │  ║  • check-cluster.sh Script   ║    │   │
     │  │  ╚═══════════╦══════════════════╝    │   │
     │  │              ║                       │   │
     │  │  ╔═══════════╩══════════════════╗    │   │
     │  │  ║   Cluster Network (Private)  ║    │   │
     │  │  ║   192.168.56.0/24            ║    │   │
     │  │  ║                              ║    │   │
     │  │  ║  ┌────┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  ║    │   │
     │  │  ║  │N1  │ │N2│ │N3│ │N4│ │N5│  ║    │   │
     │  │  ║  └────┘ └──┘ └──┘ └──┘ └──┘  ║    │   │
     │  │  ║  (High-Perf: 6GB/3CPU)       ║    │   │
     │  │  ║  Others: 2GB/1CPU each       ║    │   │
     │  │  ║  IPs: 192.168.56.10-14       ║    │   │
     │  │  ║  SSH Ports: 2201-2205        ║    │   │
     │  │  ╚══════════════════════════════╝    │   │
     │  └──────────────────────────────────────┘   │
     └─────────────────────────────────────────────┘
```

## 📁 Project Structure
```
.
├── Vagrantfile              # Main configuration file
├── ansible/                 # Ansible playbooks and inventory (synced to jump host)
│   ├── ansible.cfg          # Ansible config (optional)
│   ├── inventory            # Host inventory (optional)
│   └── playbooks/           # Your playbooks
│       ├── common.yml       # Common setup playbook
│       ├── web.yml          # Web server playbook
│       └── db.yml           # Database playbook
├── README.md                # This documentation
└── .gitignore               # Git ignore file
```

## 🔧 Usage Examples

Managing the Infrastructure (from Host)

*Start all machines: vagrant up
*Start specific machines: vagrant up jump node1 node2
*Check status: vagrant status
*SSH to jump host: vagrant ssh jump
*SSH to a node (direct from host): vagrant ssh node1
*Suspend all: vagrant suspend
*Resume all: vagrant resume
*Destroy all: vagrant destroy -f
*Re-provision: vagrant provision jump or vagrant provision node1

From the Jump Host

Check cluster status: ./check-cluster.sh (or cs / cluster-status)
Quick connectivity test: for i in {1..5}; do ssh -o ConnectTimeout=2 node$i "echo node$i: OK" 2>/dev/null || echo "node$i: FAILED"; done
Run command on all nodes: for i in {1..5}; do ssh node$i "hostname"; done
Copy files: scp /path/to/file node1:/destination/

## 🌐 Network Information
```
Host,IP Address,SSH Port,Hostname,CPU,RAM,Type
Jump Host,192.168.56.100,2210,jump,1,1GB,Gateway
Node 1,192.168.56.10,2201,node1,3,6GB,High-Performance
Node 2,192.168.56.11,2202,node2,1,2GB,Regular
Node 3,192.168.56.12,2203,node3,1,2GB,Regular
Node 4,192.168.56.13,2204,node4,1,2GB,Regular
Node 5,192.168.56.14,2205,node5,1,2GB,Regular
```

## 🔐 SSH Configuration

Key Generation: 4096-bit RSA keys auto-generated on jump host.
Passwordless Access: Jump host can SSH to nodes without passwords.
Auto-Generated Config: ~/.ssh/config on jump host with aliases (e.g., ssh node1).
Security Enhancements: Password auth disabled on nodes; keep-alive settings for stability.

Example SSH Config Snippet:

```
 node1
    HostName 192.168.56.10
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
    ServerAliveInterval 60
    ServerAliveCountMax 5
```
## 🔄 Maintenance

Update All Nodes (from jump host): ```for i in {1..5}; do ssh node$i "sudo apt update && sudo apt upgrade -y"; done```

Check Disk Space: ```for i in {1..5}; do ssh node$i "df -h /"; done```

Check Memory: ```for i in {1..5}; do ssh node$i "free -h"; done```

Check Services: ```for i in {1..5}; do ssh node$i "systemctl list-units --type=service --state=running"; done```

Node Info: SSH to a node;  .bashrc displays hostname, IP, CPU, RAM, uptime.

## 📚 Use Cases

Learning & Training: Ideal for DevOps, Linux, and networking labs.
Development Clusters: Test distributed apps on heterogeneous hardware.
CI/CD Testing: Spin up environments for automated tests.
Proof of Concepts: Quick prototyping for multi-node systems.
Workshops: Scalable setups for classrooms or demos.

## 🎯 Best Practices

Version Control: Commit Vagrantfile and Ansible changes to Git.
Snapshots: Use vagrant snapshot save before experiments.
Resource Monitoring: Use check-cluster.sh regularly; adjust resources based on host capacity.
Network Security: Add UFW/firewall rules in Ansible playbooks.
Backups: Snapshot VMs or rsync important data.

## 🤝 Contributing

Fork the repository.
Create a feature branch (git checkout -b feature/new-thing).
Make and test changes.
Commit and push.
Submit a pull request.
