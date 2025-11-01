# Installation et Configuration d'Ansible

## Table des matières

1. [Prérequis](#prérequis)
2. [Méthodes d'installation](#méthodes-dinstallation)
3. [Configuration ansible.cfg](#configuration-ansiblecfg)
4. [SSH Setup](#ssh-setup)
5. [Premier playbook - Ping](#premier-playbook---ping)
6. [Environnement de test](#environnement-de-test)
7. [Troubleshooting](#troubleshooting)

---

## Prérequis

### Control Node (Machine où Ansible est installé)

**Système d'exploitation supporté :**
- Linux (Ubuntu, Debian, RHEL, CentOS, Fedora)
- macOS
- Windows via WSL2 (Windows Subsystem for Linux)

**Requirements :**
```bash
# Python 3.8 ou supérieur
python3 --version

# pip (gestionnaire de packages Python)
pip3 --version

# SSH client
ssh -V
```

**Remarque importante :** Windows ne peut PAS être un control node directement. Utilisez WSL2 ou une VM Linux.

### Managed Nodes (Serveurs cibles)

**Requirements :**
- SSH accessible (Linux/Unix)
- WinRM accessible (Windows)
- Python 2.7 ou Python 3.5+ (pour la plupart des modules)
- Utilisateur avec privilèges sudo (pour tâches avec `become`)

**Vérification Python sur managed nodes :**
```bash
# Connexion SSH au managed node
ssh user@managed-node

# Vérifier Python
python3 --version
# ou
python --version
```

---

## Méthodes d'installation

### Méthode 1 : pip (Recommandé)

**Avantages :**
- Version la plus récente
- Contrôle total sur la version
- Fonctionne sur toutes les plateformes

**Installation :**
```bash
# Mettre à jour pip
python3 -m pip install --upgrade pip

# Installer Ansible
pip3 install ansible

# OU installer une version spécifique
pip3 install ansible==2.16.0

# Vérifier l'installation
ansible --version
```

**Installation dans un virtualenv (Recommandé pour isolation) :**
```bash
# Créer un virtualenv
python3 -m venv ansible-env

# Activer le virtualenv
source ansible-env/bin/activate  # Linux/macOS
# ou
ansible-env\Scripts\activate     # Windows

# Installer Ansible
pip install ansible

# Vérifier
ansible --version
```

**Sortie attendue :**
```
ansible [core 2.16.0]
  config file = None
  configured module search path = ['/home/user/.ansible/plugins/modules', ...]
  ansible python module location = /usr/local/lib/python3.10/site-packages/ansible
  ansible collection location = /home/user/.ansible/collections
  executable location = /usr/local/bin/ansible
  python version = 3.10.12
```

### Méthode 2 : Package Manager (Ubuntu/Debian)

**Avantages :**
- Installation simple
- Gestion des dépendances automatique

**Inconvénients :**
- Version souvent plus ancienne

**Installation :**
```bash
# Ajouter le PPA Ansible (pour version récente)
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Installer Ansible
sudo apt update
sudo apt install ansible

# Vérifier
ansible --version
```

### Méthode 3 : Package Manager (RHEL/CentOS)

```bash
# RHEL/CentOS 8+
sudo dnf install ansible

# RHEL/CentOS 7
sudo yum install epel-release
sudo yum install ansible

# Vérifier
ansible --version
```

### Méthode 4 : Package Manager (macOS)

```bash
# Homebrew
brew install ansible

# Vérifier
ansible --version
```

### Méthode 5 : Docker (Pour tests)

**Avantages :**
- Pas d'installation locale
- Environnement isolé
- Facile à nettoyer

**Utilisation :**
```bash
# Pull l'image
docker pull cytopia/ansible:latest

# Exécuter un playbook
docker run -it --rm \
  -v $(pwd):/ansible \
  -v ~/.ssh:/root/.ssh:ro \
  cytopia/ansible:latest \
  ansible-playbook playbook.yml

# Mode interactif
docker run -it --rm \
  -v $(pwd):/ansible \
  cytopia/ansible:latest \
  /bin/bash
```

### Comparaison des méthodes

| Méthode | Version | Facilité | Isolation | Recommandé pour |
|---------|---------|----------|-----------|-----------------|
| **pip** | Dernière | ⭐⭐⭐ | ⭐⭐⭐⭐ (virtualenv) | Production, Dev |
| **apt/yum** | Ancienne | ⭐⭐⭐⭐⭐ | ⭐ | Serveurs |
| **brew** | Récente | ⭐⭐⭐⭐⭐ | ⭐⭐ | macOS |
| **Docker** | Dernière | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Tests, CI/CD |

---

## Configuration ansible.cfg

Le fichier `ansible.cfg` configure le comportement d'Ansible.

### Ordre de lecture de la configuration

Ansible cherche `ansible.cfg` dans cet ordre :
1. `ANSIBLE_CONFIG` (variable d'environnement)
2. `./ansible.cfg` (répertoire courant)
3. `~/.ansible.cfg` (home directory)
4. `/etc/ansible/ansible.cfg` (configuration globale)

**Recommandation :** Placez `ansible.cfg` à la racine de votre projet.

### Configuration minimale

Créez `ansible.cfg` dans votre répertoire de projet :

```ini
# ansible.cfg
[defaults]
# Inventaire par défaut
inventory = ./inventory

# Désactiver la vérification des clés SSH (SEULEMENT pour dev/test)
host_key_checking = False

# Nombre de connexions parallèles
forks = 5

# Timeout SSH (secondes)
timeout = 10

# Utilisateur SSH par défaut
remote_user = ubuntu

# Chemin vers les rôles
roles_path = ./roles

# Désactiver gather_facts par défaut (améliore performance)
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400

[privilege_escalation]
# Utiliser sudo par défaut
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
# Utiliser pipelining pour améliorer les performances
pipelining = True
# SSH control persist pour réutiliser les connexions
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

### Configuration avancée

```ini
# ansible.cfg (production-ready)
[defaults]
inventory = ./inventory
host_key_checking = False
forks = 20
timeout = 30
remote_user = ansible
roles_path = ./roles:~/.ansible/roles:/usr/share/ansible/roles

# Logging
log_path = ./ansible.log
log_level = INFO

# Performance
gathering = smart
fact_caching = redis
fact_caching_connection = localhost:6379:0
fact_caching_timeout = 86400

# Retry files (désactivé en production)
retry_files_enabled = False

# Callback plugins pour meilleur output
stdout_callback = yaml
callbacks_enabled = profile_tasks, timer

# Collections path
collections_paths = ./collections:~/.ansible/collections

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=3600s -o PreferredAuthentications=publickey
transfer_method = smart
retries = 3

[diff]
# Toujours afficher les diffs
always = True
context = 3
```

### Variables d'environnement importantes

```bash
# Forcer la couleur dans les logs
export ANSIBLE_FORCE_COLOR=true

# Désactiver cow (output ASCII art)
export ANSIBLE_NOCOWS=1

# Spécifier un fichier de configuration
export ANSIBLE_CONFIG=/path/to/ansible.cfg

# Augmenter la verbosité par défaut
export ANSIBLE_VERBOSITY=1

# Chemin vers l'inventaire
export ANSIBLE_INVENTORY=/path/to/inventory

# Désactiver SSH host key checking
export ANSIBLE_HOST_KEY_CHECKING=False
```

**Ajouter dans ~/.bashrc ou ~/.zshrc :**
```bash
# Ansible configuration
export ANSIBLE_NOCOWS=1
export ANSIBLE_FORCE_COLOR=true
```

---

## SSH Setup

### 1. Générer une paire de clés SSH

```bash
# Générer une clé SSH (si vous n'en avez pas)
ssh-keygen -t ed25519 -C "ansible-automation" -f ~/.ssh/ansible_key

# OU avec RSA (plus compatible)
ssh-keygen -t rsa -b 4096 -C "ansible-automation" -f ~/.ssh/ansible_key

# Options :
# -t : type de clé (ed25519 recommandé, rsa pour compatibilité)
# -C : commentaire
# -f : fichier de destination
```

**Output :**
```
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase): [Appuyez sur Entrée]
Your identification has been saved in ~/.ssh/ansible_key
Your public key has been saved in ~/.ssh/ansible_key.pub
```

**Remarque :** Pour l'automatisation, ne mettez PAS de passphrase (ou utilisez ssh-agent).

### 2. Copier la clé publique sur les managed nodes

**Méthode 1 : ssh-copy-id (Recommandé)**
```bash
# Copier la clé sur le managed node
ssh-copy-id -i ~/.ssh/ansible_key.pub user@managed-node

# Exemple concret
ssh-copy-id -i ~/.ssh/ansible_key.pub ubuntu@192.168.1.10
```

**Méthode 2 : Manuellement**
```bash
# Afficher la clé publique
cat ~/.ssh/ansible_key.pub

# Se connecter au managed node
ssh user@managed-node

# Ajouter la clé au fichier authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "votre-clé-publique" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Méthode 3 : Via Ansible (si password SSH autorisé)**
```yaml
# setup-ssh.yml
---
- name: Setup SSH keys
  hosts: all
  gather_facts: no
  tasks:
    - name: Add SSH key to authorized_keys
      authorized_key:
        user: "{{ ansible_user }}"
        key: "{{ lookup('file', '~/.ssh/ansible_key.pub') }}"
        state: present

# Exécuter avec mot de passe
# ansible-playbook setup-ssh.yml -k
```

### 3. Configurer SSH client

Créez `~/.ssh/config` :

```
# ~/.ssh/config

# Configuration globale
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null

# Managed nodes
Host managed-*
    User ubuntu
    IdentityFile ~/.ssh/ansible_key
    ForwardAgent yes

# Exemple spécifique
Host managed-01
    HostName 192.168.1.10
    User ubuntu
    IdentityFile ~/.ssh/ansible_key

Host managed-02
    HostName 192.168.1.11
    User ubuntu
    IdentityFile ~/.ssh/ansible_key
```

### 4. Tester la connexion SSH

```bash
# Test connexion SSH
ssh -i ~/.ssh/ansible_key ubuntu@managed-node

# Test avec clé par défaut (si configuré dans ~/.ssh/config)
ssh managed-01

# Vérifier l'accès sudo
ssh managed-01 "sudo whoami"
# Doit afficher : root
```

### 5. Troubleshooting SSH

**Problème : Permission denied**
```bash
# Vérifier les permissions
ls -la ~/.ssh/
# Fichiers doivent être :
# - ~/.ssh : 700
# - ~/.ssh/ansible_key : 600
# - ~/.ssh/ansible_key.pub : 644

# Corriger si nécessaire
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ansible_key
chmod 644 ~/.ssh/ansible_key.pub
```

**Problème : Clé refusée**
```bash
# Connexion en mode debug
ssh -vvv -i ~/.ssh/ansible_key ubuntu@managed-node

# Vérifier authorized_keys sur le managed node
ssh managed-node
cat ~/.ssh/authorized_keys
ls -la ~/.ssh/authorized_keys  # Doit être 600
```

---

## Premier playbook - Ping

### 1. Créer un inventaire simple

Créez `inventory` :

```ini
# inventory (format INI)
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=ubuntu
web2 ansible_host=192.168.1.11 ansible_user=ubuntu

[databases]
db1 ansible_host=192.168.1.20 ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=~/.ssh/ansible_key
ansible_python_interpreter=/usr/bin/python3
```

**OU en YAML :**

```yaml
# inventory.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
        web2:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/ansible_key
    ansible_python_interpreter: /usr/bin/python3
```

### 2. Test avec ad-hoc command

```bash
# Ping tous les hosts
ansible all -m ping

# Ping un groupe spécifique
ansible webservers -m ping

# Ping un host spécifique
ansible web1 -m ping

# Avec inventaire spécifique
ansible all -i inventory -m ping
```

**Sortie attendue :**
```json
web1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
web2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
db1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 3. Créer le premier playbook

Créez `ping.yml` :

```yaml
---
# ping.yml - Premier playbook Ansible
- name: Test connectivity to all hosts
  hosts: all
  gather_facts: no
  tasks:
    - name: Ping test
      ping:

    - name: Display message
      debug:
        msg: "Host {{ inventory_hostname }} is reachable!"
```

**Exécution :**
```bash
# Exécuter le playbook
ansible-playbook ping.yml

# Avec verbosité pour plus de détails
ansible-playbook ping.yml -v
ansible-playbook ping.yml -vv
ansible-playbook ping.yml -vvv

# Sur un groupe spécifique
ansible-playbook ping.yml --limit webservers

# Check mode (dry-run)
ansible-playbook ping.yml --check
```

**Sortie attendue :**
```
PLAY [Test connectivity to all hosts] ******************************************

TASK [Ping test] ***************************************************************
ok: [web1]
ok: [web2]
ok: [db1]

TASK [Display message] *********************************************************
ok: [web1] => {
    "msg": "Host web1 is reachable!"
}
ok: [web2] => {
    "msg": "Host web2 is reachable!"
}
ok: [db1] => {
    "msg": "Host db1 is reachable!"
}

PLAY RECAP *********************************************************************
web1                       : ok=2    changed=0    unreachable=0    failed=0
web2                       : ok=2    changed=0    unreachable=0    failed=0
db1                        : ok=2    changed=0    unreachable=0    failed=0
```

### 4. Playbook avec gather_facts

```yaml
---
# system-info.yml - Collecter des informations système
- name: Gather system information
  hosts: all
  gather_facts: yes
  tasks:
    - name: Display OS information
      debug:
        msg: |
          Hostname: {{ ansible_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Architecture: {{ ansible_architecture }}
          Python: {{ ansible_python_version }}
          IP: {{ ansible_default_ipv4.address }}
          CPU Cores: {{ ansible_processor_vcpus }}
          Memory: {{ ansible_memtotal_mb }} MB
```

**Exécution :**
```bash
ansible-playbook system-info.yml
```

---

## Environnement de test

### Option 1 : Vagrant (VMs locales)

**1. Installer Vagrant**
```bash
# macOS
brew install vagrant virtualbox

# Ubuntu/Debian
sudo apt install vagrant virtualbox

# Vérifier
vagrant --version
```

**2. Créer le Vagrantfile**

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  # Configuration commune
  config.vm.box = "ubuntu/focal64"
  config.ssh.insert_key = false

  # Copier la clé SSH publique
  config.vm.provision "file", source: "~/.ssh/ansible_key.pub",
                              destination: "/tmp/ansible_key.pub"
  config.vm.provision "shell", inline: <<-SHELL
    cat /tmp/ansible_key.pub >> /home/vagrant/.ssh/authorized_keys
    apt-get update
    apt-get install -y python3 python3-pip
  SHELL

  # Web Server 1
  config.vm.define "web1" do |web1|
    web1.vm.hostname = "web1"
    web1.vm.network "private_network", ip: "192.168.56.10"
    web1.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end
  end

  # Web Server 2
  config.vm.define "web2" do |web2|
    web2.vm.hostname = "web2"
    web2.vm.network "private_network", ip: "192.168.56.11"
    web2.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end
  end

  # Database Server
  config.vm.define "db1" do |db1|
    db1.vm.hostname = "db1"
    db1.vm.network "private_network", ip: "192.168.56.20"
    db1.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end
end
```

**3. Démarrer les VMs**
```bash
# Démarrer toutes les VMs
vagrant up

# Démarrer une VM spécifique
vagrant up web1

# SSH dans une VM
vagrant ssh web1

# Statut des VMs
vagrant status

# Arrêter les VMs
vagrant halt

# Détruire les VMs
vagrant destroy -f
```

**4. Inventaire Vagrant**

```ini
# inventory-vagrant
[webservers]
web1 ansible_host=192.168.56.10
web2 ansible_host=192.168.56.11

[databases]
db1 ansible_host=192.168.56.20

[all:vars]
ansible_user=vagrant
ansible_ssh_private_key_file=~/.ssh/ansible_key
ansible_python_interpreter=/usr/bin/python3
```

**5. Tester**
```bash
ansible all -i inventory-vagrant -m ping
```

### Option 2 : Docker (Containers)

**1. Créer le Dockerfile**

```dockerfile
# Dockerfile.ansible-node
FROM ubuntu:22.04

# Installer Python et SSH
RUN apt-get update && \
    apt-get install -y \
        openssh-server \
        python3 \
        python3-pip \
        sudo && \
    rm -rf /var/lib/apt/lists/*

# Créer l'utilisateur ansible
RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configurer SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Copier la clé publique
RUN mkdir -p /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh
COPY ansible_key.pub /home/ansible/.ssh/authorized_keys
RUN chmod 600 /home/ansible/.ssh/authorized_keys && \
    chown -R ansible:ansible /home/ansible/.ssh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
```

**2. Créer docker-compose.yml**

```yaml
# docker-compose.yml
version: '3'
services:
  web1:
    build:
      context: .
      dockerfile: Dockerfile.ansible-node
    container_name: ansible-web1
    hostname: web1
    networks:
      ansible_net:
        ipv4_address: 172.20.0.10
    ports:
      - "2201:22"

  web2:
    build:
      context: .
      dockerfile: Dockerfile.ansible-node
    container_name: ansible-web2
    hostname: web2
    networks:
      ansible_net:
        ipv4_address: 172.20.0.11
    ports:
      - "2202:22"

  db1:
    build:
      context: .
      dockerfile: Dockerfile.ansible-node
    container_name: ansible-db1
    hostname: db1
    networks:
      ansible_net:
        ipv4_address: 172.20.0.20
    ports:
      - "2203:22"

networks:
  ansible_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

**3. Démarrer les containers**

```bash
# Copier la clé publique
cp ~/.ssh/ansible_key.pub .

# Build et démarrer
docker-compose up -d

# Vérifier
docker-compose ps

# Logs
docker-compose logs web1

# Arrêter
docker-compose down
```

**4. Inventaire Docker**

```ini
# inventory-docker
[webservers]
web1 ansible_host=localhost ansible_port=2201
web2 ansible_host=localhost ansible_port=2202

[databases]
db1 ansible_host=localhost ansible_port=2203

[all:vars]
ansible_user=ansible
ansible_ssh_private_key_file=~/.ssh/ansible_key
ansible_python_interpreter=/usr/bin/python3
```

**5. Tester**
```bash
ansible all -i inventory-docker -m ping
```

### Option 3 : Cloud (AWS EC2)

**Setup rapide avec Terraform + Ansible**

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Security Group
resource "aws_security_group" "ansible_sg" {
  name = "ansible-test-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04
  instance_type = "t3.micro"
  key_name      = "ansible-key"
  security_groups = [aws_security_group.ansible_sg.name]

  tags = {
    Name = "ansible-web-${count.index + 1}"
    Role = "webserver"
  }
}

# Output pour Ansible
output "web_ips" {
  value = aws_instance.web[*].public_ip
}
```

**Appliquer :**
```bash
terraform init
terraform apply
terraform output -json > inventory.json
```

---

## Troubleshooting

### Problème 1 : "Host key checking failed"

**Erreur :**
```
fatal: [web1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Host key verification failed.", "unreachable": true}
```

**Solution :**
```bash
# Option 1 : Désactiver dans ansible.cfg
[defaults]
host_key_checking = False

# Option 2 : Variable d'environnement
export ANSIBLE_HOST_KEY_CHECKING=False

# Option 3 : Ajouter les hosts à known_hosts
ssh-keyscan -H 192.168.1.10 >> ~/.ssh/known_hosts
```

### Problème 2 : "Permission denied (publickey)"

**Erreur :**
```
fatal: [web1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Permission denied (publickey).", "unreachable": true}
```

**Solution :**
```bash
# Vérifier la clé SSH
ssh -i ~/.ssh/ansible_key ubuntu@managed-node

# Vérifier ansible.cfg
[defaults]
private_key_file = ~/.ssh/ansible_key

# OU spécifier dans l'inventaire
ansible_ssh_private_key_file=~/.ssh/ansible_key

# Vérifier les permissions
chmod 600 ~/.ssh/ansible_key
```

### Problème 3 : "Python interpreter not found"

**Erreur :**
```
fatal: [web1]: FAILED! => {"changed": false, "msg": "/usr/bin/python: not found"}
```

**Solution :**
```bash
# Spécifier Python 3 dans l'inventaire
[all:vars]
ansible_python_interpreter=/usr/bin/python3

# OU installer Python 2.7 sur le managed node
ssh managed-node
sudo apt install python
```

### Problème 4 : "Sudo password required"

**Erreur :**
```
fatal: [web1]: FAILED! => {"msg": "Missing sudo password"}
```

**Solution :**
```bash
# Option 1 : Demander le mot de passe
ansible-playbook playbook.yml --ask-become-pass
# OU
ansible-playbook playbook.yml -K

# Option 2 : Configurer NOPASSWD dans sudoers
ssh managed-node
sudo visudo
# Ajouter :
ansible ALL=(ALL) NOPASSWD:ALL
```

### Problème 5 : Timeout de connexion

**Erreur :**
```
fatal: [web1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host 192.168.1.10 port 22: Operation timed out", "unreachable": true}
```

**Solution :**
```bash
# Vérifier connectivité
ping 192.168.1.10
telnet 192.168.1.10 22

# Augmenter le timeout dans ansible.cfg
[defaults]
timeout = 60

# Vérifier firewall
ssh managed-node
sudo ufw status
```

---

## Commandes utiles

```bash
# Versions et informations
ansible --version
ansible-config dump
ansible-config list

# Inventaire
ansible-inventory --list
ansible-inventory --graph
ansible-inventory --host web1

# Ad-hoc commands
ansible all -m ping
ansible all -m setup
ansible all -m shell -a "uptime"
ansible all -m apt -a "name=nginx state=present" --become

# Playbooks
ansible-playbook playbook.yml
ansible-playbook playbook.yml --check        # Dry-run
ansible-playbook playbook.yml --diff         # Show diffs
ansible-playbook playbook.yml -v             # Verbose
ansible-playbook playbook.yml --limit web1   # Specific host
ansible-playbook playbook.yml --tags deploy  # Specific tags

# Documentation
ansible-doc ping
ansible-doc apt
ansible-doc -l  # Liste tous les modules
```

---

## Prochaines étapes

Vous avez maintenant un environnement Ansible fonctionnel ! Passez au module suivant :

**[03-Playbooks-Basics](../03-Playbooks-Basics/README.md)**

Vous allez apprendre à :
- Écrire des playbooks YAML
- Utiliser tasks, plays et handlers
- Comprendre l'idempotence
- Utiliser check mode et tags
- Gérer les erreurs

---

## Checklist d'installation

- [ ] Python 3.8+ installé
- [ ] Ansible installé (`ansible --version`)
- [ ] SSH configuré avec clés
- [ ] Connexion SSH aux managed nodes réussie
- [ ] `ansible.cfg` créé
- [ ] Inventaire créé
- [ ] `ansible all -m ping` réussi
- [ ] Premier playbook exécuté avec succès
- [ ] Environnement de test configuré (Vagrant/Docker)

---

**"The best time to automate was yesterday. The second best time is now."**
