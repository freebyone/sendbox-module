# 🚀 Dynamic Infrastructure Lab

A powerful, flexible Vagrant-based infrastructure for creating dynamic multi-node clusters with automated SSH configuration and jump host management.

## ✨ Features

- **Dynamic Node Creation**: Configure any number of nodes with a single variable
- **Jump Host Architecture**: Centralized management through a dedicated jump host
- **Automated SSH Configuration**: Passwordless SSH access between all nodes
- **Ansible-Ready**: Pre-configured with Ansible and optimized for automation
- **Network Isolation**: Private internal network for secure communication
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **Customizable**: Easy to modify memory, CPU, and network settings

## 📋 Prerequisites

- [VirtualBox](https://www.virtualbox.org/) (7.0 or later)
- [Vagrant](https://www.vagrantup.com/) (2.3.0 or later)
- 8GB+ RAM recommended
- 20GB+ free disk space

## 🚀 Quick Start

1. **Clone and navigate to the project directory**
```
git clone https://github.com/freebyone/sendbox-module.git
cd sendbox-module
```
   
2. Start the infrastructure

```bash
vagrant up
 ```
3. Access the jump host

```bash
vagrant ssh jump
 ```
4. Connect to any node from the jump host

 ```bash
ssh node1
ssh node2
# etc.
 ```

⚙️ Configuration
Basic Configuration
Edit the Vagrantfile to customize your setup:

Configuration vars
 ```
NODE_COUNT = 5           # Number of cluster nodes
JUMP_HOST_IP = "192.168.56.100"
NODE_IP_BASE = "192.168.56"
NODE_IP_START = 10       # First node IP: 192.168.56.10
JUMP_HOST_PORT = 2210
NODE_PORT_START = 2201   # First node SSH port: 2201
 ```
Node Resources
Each node gets:

Memory: 2048MB

CPU: 1 core

Storage: Default VirtualBox disk

Jump host gets:

Memory: 1024MB

CPU: 1 core

🏗️ Architecture

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
     │  │  ║  • Manages cluster nodes     ║    │   │
     │  │  ║  • Ansible control node      ║    │   │
     │  │  ╚═══════════╦══════════════════╝    │   │
     │  │              ║                       │   │
     │  │  ╔═══════════╩══════════════════╗    │   │
     │  │  ║   Cluster Network (Private)  ║    │   │
     │  │  ║   192.168.56.0/24            ║    │   │
     │  │  ║                              ║    │   │
     │  │  ║  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐    ║    │   │
     │  │  ║  │N1│ │N2│ │N3│ │N4│ │N5│    ║    │   │
     │  │  ║  └──┘ └──┘ └──┘ └──┘ └──┘    ║    │   │
     │  │  ║                              ║    │   │
     │  │  ║  2GB RAM each                ║    │   │
     │  │  ║  192.168.56.10-N             ║    │   │
     │  │  ║  SSH: 2201-220N              ║    │   │
     │  │  ╚══════════════════════════════╝    │   │
     │  └──────────────────────────────────────┘   │
     └─────────────────────────────────────────────┘

📁 Project Structure
```
.
├── Vagrantfile              # Основной файл конфигурации
├── ansible/                 # Ansible плейбуки и инвентарь
│   ├── ansible.cfg          # Конфигурация Ansible (опционально)
│   ├── inventory            # Файл инвентаря (опционально)
│   └── playbooks/           # Ваши плейбуки
│       ├── common.yml       # Общий плейбук настройки
│       ├── web.yml          # Плейбук веб-сервера
│       └── db.yml           # Плейбук базы данных
├── README.md                # Эта документация
└── .gitignore               # Файл исключений Git
```
🔧 **Usage Examples
Managing the Infrastructure

# Start all machines
 ```
vagrant up
 ```
# Start specific machines
 ```
vagrant up jump node1 node2
 ```
# Check status
 ```
vagrant status
 ```
# SSH to jump host
 ```
vagrant ssh jump
 ```
 
# SSH to specific node (from your host)
 ```
vagrant ssh node1
 ```

# Suspend all machines
 ```
 vagrant suspend
 ```
# Resume all machines
 ```
vagrant resume
 ```
# Destroy all machines
 ```
vagrant destroy -f
 ```
# Provision specific machines
 ```
vagrant provision jump
 ```
**From the Jump Host

# Connect to the jump host
 ```
vagrant ssh jump
 ```
# Test SSH connectivity to all nodes
 ```
for i in {1..5}; do ssh -o ConnectTimeout=2 node$i "echo node$i: OK" 2>/dev/null || echo "node$i: FAILED"; done
 ```
# Run commands on multiple nodes
 ```
for i in {1..5}; do ssh node$i "hostname"; done
 ```
# Copy files to nodes
 ```
scp /path/to/file node1:/destination/
 ```
Network Information
Host	IP Address	SSH Port	Hostname
Jump Host	192.168.56.100	2210	jump
Node 1	192.168.56.10	2201	node1
Node 2	192.168.56.11	2202	node2
Node 3	192.168.56.12	2203	node3
Node 4	192.168.56.13	2204	node4
Node 5	192.168.56.14	2205	node5
Additional nodes follow the same pattern

🔐 SSH Configuration
The infrastructure automatically configures:

SSH Key Generation: RSA 4096-bit keys on jump host

Passwordless Access: Jump host can SSH to all nodes without passwords

SSH Config File: Pre-configured host aliases for easy access

Enhanced Security: Password authentication disabled on nodes

SSH Config Example (Auto-generated on jump host):
 ```
Host node1
    HostName 192.168.56.10
    User vagrant
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ConnectTimeout 10
```
🛠️ Customization
Adding More Nodes
Simply change NODE_COUNT = 5 to your desired number.

Changing Resource Allocation
Modify these sections in the Vagrantfile:

 ```
vb.memory = 2048  # Node memory in MB
vb.cpus = 1       # Node CPU cores
 ```
Using Your Own Ansible Configuration
Place your Ansible files in the ./ansible directory:

ansible.cfg - Ansible configuration

inventory - Host inventory

playbooks/ - Your playbooks

These will be automatically synced to /home/vagrant/ansible/ on the jump host.

🐛 Troubleshooting
Common Issues
Port Collisions

text
Fixed port collision for 22 => 2203. Now on port 2204.
This is normal - Vagrant automatically finds free ports.

SSH Connection Issues

 ```
# From jump host, test connectivity
ping 192.168.56.10

# Check SSH config
cat ~/.ssh/config

# Test with verbose output
ssh -vvv node1
Provisioning Errors
 ```
 ```
# Re-run provisioning
vagrant provision jump
vagrant provision node1
VirtualBox Network Issues
 ```
 ```
# Check VirtualBox network settings
VBoxManage list hostonlyifs
Debug Mode
Run Vagrant with debug output:
 ```
 ```
vagrant up --debug
 ```
🔄 Maintenance
Updating All Nodes
bash
# From jump host
```
for i in {1..5}; do ssh node$i "sudo apt update && sudo apt upgrade -y"; done
```
Checking System Status
```
# Check disk space on all nodes
for i in {1..5}; do ssh node$i "df -h /"; done
```
```
# Check memory usage
for i in {1..5}; do ssh node$i "free -h"; done
```
```
# Check running services
for i in {1..5}; do ssh node$i "systemctl list-units --type=service --state=running"; done
 ```
📚 Use Cases
Learning Environments: Perfect for learning Linux, networking, and DevOps

Development Clusters: Test multi-node applications

CI/CD Testing: Automated testing environments

Training Labs: Classroom and workshop environments

Proof of Concepts: Rapid infrastructure prototyping

🎯 Best Practices
Version Control: Keep your Vagrantfile and Ansible configurations in Git

Regular Snapshots: Use vagrant snapshot before major changes

Resource Planning: Adjust memory/CPU based on your host machine capabilities

Network Planning: Ensure IP ranges don't conflict with your local network

Security: Consider adding firewall rules for production-like environments

🤝 Contributing
Fork the repository

Create a feature branch

Make your changes

Test thoroughly

Submit a pull request
