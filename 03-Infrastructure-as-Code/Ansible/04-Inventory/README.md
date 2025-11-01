# Gestion de l'Inventaire Ansible

## Table des matières

1. [Introduction aux Inventaires](#introduction-aux-inventaires)
2. [Inventaire Statique - Format INI](#inventaire-statique---format-ini)
3. [Inventaire Statique - Format YAML](#inventaire-statique---format-yaml)
4. [Groupes et Patterns](#groupes-et-patterns)
5. [Variables d'Inventaire](#variables-dinventaire)
6. [Inventaire Dynamique](#inventaire-dynamique)
7. [Inventory Plugins](#inventory-plugins)
8. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction aux Inventaires

L'**inventaire** (inventory) est la liste des machines (hosts) que Ansible va gérer.

### Qu'est-ce qu'un Inventaire ?

**Définition :**
- Liste des serveurs cibles (managed nodes)
- Peut être statique (fichier) ou dynamique (script/plugin)
- Permet de grouper les serveurs par fonction
- Contient les variables associées aux hosts

**Formats supportés :**
- INI (format simple, legacy)
- YAML (format moderne, recommandé)
- Scripts dynamiques (Python, Bash, etc.)
- Plugins (AWS, Azure, GCP, etc.)

### Localisation de l'inventaire

Ansible cherche l'inventaire dans cet ordre :
1. Option `-i` en ligne de commande
2. Variable d'environnement `ANSIBLE_INVENTORY`
3. Configuration dans `ansible.cfg`
4. Défaut : `/etc/ansible/hosts`

```bash
# Spécifier un inventaire
ansible all -i inventory.yml -m ping

# Variable d'environnement
export ANSIBLE_INVENTORY=/path/to/inventory
ansible all -m ping

# ansible.cfg
[defaults]
inventory = ./inventory
```

---

## Inventaire Statique - Format INI

Le format INI est simple et lisible, idéal pour débuter.

### Structure de base

```ini
# inventory (INI)

# Host simple
server1.example.com

# Host avec alias
web1 ansible_host=192.168.1.10

# Groupe de hosts
[webservers]
web1.example.com
web2.example.com
web3.example.com

[databases]
db1.example.com
db2.example.com

# Variables de groupe
[webservers:vars]
http_port=80
max_clients=200

[databases:vars]
mysql_port=3306
```

### Hosts avec variables

```ini
# inventory

[webservers]
web1 ansible_host=192.168.1.10 ansible_user=ubuntu ansible_port=22
web2 ansible_host=192.168.1.11 ansible_user=ubuntu ansible_port=2222
web3 ansible_host=192.168.1.12 ansible_user=centos

[databases]
db1 ansible_host=192.168.1.20 ansible_user=ubuntu
db2 ansible_host=192.168.1.21 ansible_user=ubuntu

# Variables communes à tous les hosts
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/ansible_key
```

### Patterns de hosts

```ini
# Utiliser des ranges
[webservers]
web[01:10].example.com        # web01 à web10
web[a:f].example.com          # weba à webf

# Avec IPs
[databases]
db-[01:03] ansible_host=192.168.1.[20:22]
# db-01 → 192.168.1.20
# db-02 → 192.168.1.21
# db-03 → 192.168.1.22
```

### Groupes de groupes

```ini
# inventory

[webservers]
web1
web2

[databases]
db1
db2

[loadbalancers]
lb1

# Groupe de groupes avec :children
[production:children]
webservers
databases
loadbalancers

# Variables pour le groupe production
[production:vars]
environment=prod
monitoring_enabled=true
```

### Exemple complet INI

```ini
# inventory/production

# Web Servers
[webservers]
web1 ansible_host=10.0.1.10 ansible_user=ubuntu
web2 ansible_host=10.0.1.11 ansible_user=ubuntu
web3 ansible_host=10.0.1.12 ansible_user=ubuntu

# Application Servers
[appservers]
app1 ansible_host=10.0.2.10 ansible_user=centos
app2 ansible_host=10.0.2.11 ansible_user=centos

# Database Servers
[databases]
db1 ansible_host=10.0.3.10 ansible_user=ubuntu db_role=master
db2 ansible_host=10.0.3.11 ansible_user=ubuntu db_role=slave

# Load Balancers
[loadbalancers]
lb1 ansible_host=10.0.4.10 ansible_user=ubuntu

# Cache Servers
[cache]
redis1 ansible_host=10.0.5.10 ansible_user=ubuntu
redis2 ansible_host=10.0.5.11 ansible_user=ubuntu

# Group of groups - Production
[production:children]
webservers
appservers
databases
loadbalancers
cache

# Group of groups - Frontend
[frontend:children]
webservers
loadbalancers

# Group of groups - Backend
[backend:children]
appservers
databases
cache

# Variables for webservers
[webservers:vars]
http_port=80
https_port=443
nginx_version=1.21

# Variables for databases
[databases:vars]
mysql_port=3306
mysql_root_password=vault_encrypted_password

# Variables for all production
[production:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/prod_key
ntp_server=ntp.example.com
dns_servers=["8.8.8.8", "8.8.4.4"]
environment=production
```

---

## Inventaire Statique - Format YAML

Le format YAML est plus structuré et moderne, recommandé pour les inventaires complexes.

### Structure de base

```yaml
# inventory.yml

all:
  hosts:
    server1.example.com:

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
```

### Groupes avec variables

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
      vars:
        http_port: 80
        nginx_version: "1.21"

    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
          db_role: master
        db2:
          ansible_host: 192.168.1.21
          db_role: slave
      vars:
        mysql_port: 3306

  vars:
    ansible_user: ubuntu
    ansible_python_interpreter: /usr/bin/python3
```

### Groupes de groupes

```yaml
# inventory.yml

all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 10.0.1.10
        web2:
          ansible_host: 10.0.1.11

    databases:
      hosts:
        db1:
          ansible_host: 10.0.2.10
        db2:
          ansible_host: 10.0.2.11

    # Groupe de groupes
    production:
      children:
        webservers:
        databases:
      vars:
        environment: prod
        monitoring: true
```

### Exemple complet YAML

```yaml
# inventory/production.yml

all:
  children:
    # Web Servers
    webservers:
      hosts:
        web1:
          ansible_host: 10.0.1.10
          ansible_user: ubuntu
          nginx_worker_processes: 4
        web2:
          ansible_host: 10.0.1.11
          ansible_user: ubuntu
          nginx_worker_processes: 8
        web3:
          ansible_host: 10.0.1.12
          ansible_user: ubuntu
          nginx_worker_processes: 4
      vars:
        http_port: 80
        https_port: 443
        ssl_certificate: /etc/ssl/certs/example.crt
        ssl_key: /etc/ssl/private/example.key

    # Application Servers
    appservers:
      hosts:
        app1:
          ansible_host: 10.0.2.10
          ansible_user: centos
          app_memory: 4096
        app2:
          ansible_host: 10.0.2.11
          ansible_user: centos
          app_memory: 8192
      vars:
        app_port: 8080
        java_version: "11"

    # Database Servers
    databases:
      hosts:
        db1:
          ansible_host: 10.0.3.10
          ansible_user: ubuntu
          db_role: master
          replication_id: 1
        db2:
          ansible_host: 10.0.3.11
          ansible_user: ubuntu
          db_role: slave
          replication_id: 2
          master_host: db1
      vars:
        mysql_port: 3306
        mysql_max_connections: 500
        mysql_innodb_buffer_pool_size: "4G"

    # Load Balancers
    loadbalancers:
      hosts:
        lb1:
          ansible_host: 10.0.4.10
          ansible_user: ubuntu
      vars:
        backend_servers:
          - web1
          - web2
          - web3

    # Cache Servers
    cache:
      hosts:
        redis1:
          ansible_host: 10.0.5.10
          ansible_user: ubuntu
          redis_role: master
        redis2:
          ansible_host: 10.0.5.11
          ansible_user: ubuntu
          redis_role: slave
          redis_master: redis1
      vars:
        redis_port: 6379
        redis_maxmemory: "2gb"

    # Group of groups
    production:
      children:
        webservers:
        appservers:
        databases:
        loadbalancers:
        cache:
      vars:
        environment: production
        ansible_python_interpreter: /usr/bin/python3
        ansible_ssh_private_key_file: ~/.ssh/prod_key
        ntp_server: ntp.example.com
        monitoring_enabled: true
        backup_enabled: true

    frontend:
      children:
        webservers:
        loadbalancers:

    backend:
      children:
        appservers:
        databases:
        cache:
```

---

## Groupes et Patterns

### Patterns de sélection

```bash
# Tous les hosts
ansible all -m ping

# Un groupe
ansible webservers -m ping

# Plusieurs groupes (OR)
ansible webservers:databases -m ping

# Intersection (AND)
ansible webservers:&production -m ping

# Exclusion (NOT)
ansible webservers:!web1 -m ping

# Combinaisons
ansible webservers:databases:!web1 -m ping

# Wildcard
ansible web* -m ping
ansible *.example.com -m ping

# Regex
ansible ~web[0-9]+ -m ping
```

### Patterns avancés

```bash
# Hosts dans webservers ET production
ansible 'webservers:&production' -m ping

# Hosts dans webservers MAIS PAS web1
ansible 'webservers:!web1' -m ping

# Premier host du groupe
ansible webservers[0] -m ping

# Range de hosts
ansible webservers[0:2] -m ping  # web1, web2, web3

# Hosts pairs
ansible webservers[0::2] -m ping  # web1, web3, web5...

# Tous sauf production
ansible 'all:!production' -m ping
```

### Groupes implicites

Ansible crée automatiquement ces groupes :

```yaml
# all : Tous les hosts
ansible all -m ping

# ungrouped : Hosts sans groupe
ansible ungrouped -m ping
```

---

## Variables d'Inventaire

### Variables de connexion

```yaml
# ansible_connection
ansible_connection: ssh         # ssh, winrm, local, docker, etc.

# SSH
ansible_host: 192.168.1.10     # IP ou hostname réel
ansible_port: 22                # Port SSH
ansible_user: ubuntu            # Utilisateur SSH
ansible_ssh_private_key_file: ~/.ssh/key
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

# Privilèges
ansible_become: true            # Utiliser sudo
ansible_become_method: sudo     # sudo, su, pbrun, etc.
ansible_become_user: root       # Utilisateur cible
ansible_become_password: secret

# Python
ansible_python_interpreter: /usr/bin/python3
```

### Variables personnalisées

```yaml
# inventory.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 10.0.1.10
          # Variables custom
          server_role: frontend
          max_memory: 4096
          ssl_enabled: true
          backup_schedule: "0 2 * * *"
      vars:
        http_port: 80
        app_name: myapp
        environment: production
```

**Utilisation dans un playbook :**

```yaml
---
- name: Configure web server
  hosts: webservers
  tasks:
    - name: Display server info
      debug:
        msg: |
          Server: {{ inventory_hostname }}
          Role: {{ server_role }}
          Memory: {{ max_memory }}
          App: {{ app_name }}
          Port: {{ http_port }}
```

### Précédence des variables

De la plus basse à la plus haute priorité :

```
1. group_vars/all
2. group_vars/group_name
3. host_vars/hostname
4. Inventory (group vars)
5. Inventory (host vars)
6. Playbook (vars)
7. Playbook (vars_files)
8. Play (vars)
9. Task (vars)
10. Extra vars (-e)
```

**Exemple :**

```yaml
# group_vars/all.yml
http_port: 80

# group_vars/webservers.yml
http_port: 8080

# host_vars/web1.yml
http_port: 9090

# playbook.yml
- hosts: web1
  vars:
    http_port: 3000
  tasks:
    - debug:
        msg: "Port is {{ http_port }}"
# Affiche: Port is 3000 (playbook vars gagne)
```

```bash
# Extra vars gagne sur tout
ansible-playbook site.yml -e "http_port=5000"
# Affiche: Port is 5000
```

---

## Inventaire Dynamique

Les inventaires dynamiques génèrent la liste des hosts à la volée, idéal pour le cloud.

### Script d'inventaire dynamique

**Format de sortie attendu :**

```json
{
  "_meta": {
    "hostvars": {
      "host1": {
        "ansible_host": "10.0.1.10",
        "ansible_user": "ubuntu"
      },
      "host2": {
        "ansible_host": "10.0.1.11",
        "ansible_user": "ubuntu"
      }
    }
  },
  "webservers": {
    "hosts": ["host1", "host2"],
    "vars": {
      "http_port": 80
    }
  },
  "databases": {
    "hosts": ["host3"],
    "vars": {
      "mysql_port": 3306
    }
  }
}
```

### Exemple de script Python

```python
#!/usr/bin/env python3
# dynamic_inventory.py

import json
import sys

def get_inventory():
    inventory = {
        "_meta": {
            "hostvars": {
                "web1": {
                    "ansible_host": "10.0.1.10",
                    "ansible_user": "ubuntu"
                },
                "web2": {
                    "ansible_host": "10.0.1.11",
                    "ansible_user": "ubuntu"
                },
                "db1": {
                    "ansible_host": "10.0.2.10",
                    "ansible_user": "ubuntu"
                }
            }
        },
        "webservers": {
            "hosts": ["web1", "web2"],
            "vars": {
                "http_port": 80
            }
        },
        "databases": {
            "hosts": ["db1"],
            "vars": {
                "mysql_port": 3306
            }
        }
    }
    return inventory

def get_host(hostname):
    # Retourner les variables d'un host spécifique
    inventory = get_inventory()
    return inventory["_meta"]["hostvars"].get(hostname, {})

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        print(json.dumps(get_inventory(), indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        print(json.dumps(get_host(sys.argv[2]), indent=2))
    else:
        print("Usage: {} --list or {} --host <hostname>".format(sys.argv[0], sys.argv[0]))
        sys.exit(1)
```

**Utilisation :**

```bash
# Rendre exécutable
chmod +x dynamic_inventory.py

# Tester
./dynamic_inventory.py --list
./dynamic_inventory.py --host web1

# Utiliser avec Ansible
ansible all -i dynamic_inventory.py -m ping
ansible-playbook site.yml -i dynamic_inventory.py
```

### Inventaire dynamique AWS EC2

```python
#!/usr/bin/env python3
# aws_ec2_inventory.py

import json
import boto3

def get_ec2_inventory():
    ec2 = boto3.client('ec2', region_name='eu-west-1')

    response = ec2.describe_instances(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )

    inventory = {
        "_meta": {
            "hostvars": {}
        }
    }

    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            public_ip = instance.get('PublicIpAddress', '')
            private_ip = instance.get('PrivateIpAddress', '')

            # Tags
            tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
            name = tags.get('Name', instance_id)
            role = tags.get('Role', 'ungrouped')

            # Hostvars
            inventory["_meta"]["hostvars"][name] = {
                "ansible_host": public_ip or private_ip,
                "ansible_user": "ubuntu",
                "instance_id": instance_id,
                "instance_type": instance['InstanceType'],
                "private_ip": private_ip,
                "public_ip": public_ip,
                "tags": tags
            }

            # Groupes par rôle
            if role not in inventory:
                inventory[role] = {"hosts": []}
            inventory[role]["hosts"].append(name)

    return inventory

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 2 and sys.argv[1] == "--list":
        print(json.dumps(get_ec2_inventory(), indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == "--host":
        # Retourner hostvars pour un host
        inventory = get_ec2_inventory()
        print(json.dumps(inventory["_meta"]["hostvars"].get(sys.argv[2], {}), indent=2))
```

**Prérequis :**

```bash
# Installer boto3
pip install boto3

# Configurer AWS credentials
aws configure
# ou
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_DEFAULT_REGION=eu-west-1

# Utiliser
ansible all -i aws_ec2_inventory.py -m ping
```

---

## Inventory Plugins

Les inventory plugins sont la méthode moderne pour les inventaires dynamiques.

### Plugin AWS EC2

**1. Configuration**

```yaml
# inventory/aws_ec2.yml
plugin: amazon.aws.aws_ec2

regions:
  - eu-west-1
  - us-east-1

filters:
  instance-state-name: running
  tag:Environment: production

keyed_groups:
  # Grouper par tag Role
  - key: tags.Role
    prefix: role
  # Grouper par type d'instance
  - key: instance_type
    prefix: type
  # Grouper par zone
  - key: placement.availability_zone
    prefix: az

hostnames:
  - tag:Name
  - dns-name
  - private-ip-address

compose:
  ansible_host: public_ip_address
  ansible_user: "'ubuntu'"
```

**2. Utilisation**

```bash
# Lister l'inventaire
ansible-inventory -i inventory/aws_ec2.yml --list

# Graph
ansible-inventory -i inventory/aws_ec2.yml --graph

# Ping
ansible all -i inventory/aws_ec2.yml -m ping

# Playbook
ansible-playbook site.yml -i inventory/aws_ec2.yml
```

### Plugin Azure

```yaml
# inventory/azure_rm.yml
plugin: azure.azcollection.azure_rm

auth_source: auto

include_vm_resource_groups:
  - my-resource-group

keyed_groups:
  - key: tags.Role
    prefix: role
  - key: location
    prefix: loc

conditional_groups:
  webservers: "'web' in tags.Role"
  databases: "'db' in tags.Role"

compose:
  ansible_host: public_ipv4_addresses[0]
  ansible_user: "'azureuser'"
```

### Plugin GCP

```yaml
# inventory/gcp_compute.yml
plugin: google.cloud.gcp_compute

projects:
  - my-gcp-project

filters:
  - status = RUNNING

keyed_groups:
  - key: labels.role
    prefix: role
  - key: zone
    prefix: zone

compose:
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
  ansible_user: "'ubuntu'"
```

### Multiples inventaires

Utilisez un répertoire contenant plusieurs inventaires :

```
inventory/
├── 01-static.yml          # Inventaire statique
├── 02-aws_ec2.yml         # Dynamic AWS
├── 03-azure_rm.yml        # Dynamic Azure
└── group_vars/
    ├── all.yml
    └── webservers.yml
```

```bash
# Ansible fusionne tous les inventaires
ansible all -i inventory/ -m ping

# Liste tous les hosts
ansible-inventory -i inventory/ --list
```

---

## Bonnes pratiques

### 1. Structure d'inventaire

```
# Structure recommandée
inventory/
├── production/
│   ├── hosts.yml
│   ├── group_vars/
│   │   ├── all.yml
│   │   ├── webservers.yml
│   │   └── databases.yml
│   └── host_vars/
│       ├── web1.yml
│       └── db1.yml
├── staging/
│   ├── hosts.yml
│   └── group_vars/
│       └── all.yml
└── development/
    ├── hosts.yml
    └── group_vars/
        └── all.yml
```

### 2. Nommage des hosts

```yaml
# ✅ BON : Noms descriptifs
web-prod-01:
  ansible_host: 10.0.1.10
db-prod-master:
  ansible_host: 10.0.2.10

# ❌ MAUVAIS : Noms vagues
server1:
  ansible_host: 10.0.1.10
host2:
  ansible_host: 10.0.2.10
```

### 3. Groupes logiques

```yaml
# Organisation logique par fonction ET environnement
all:
  children:
    production:
      children:
        prod_web:
          hosts:
            web-prod-01:
        prod_db:
          hosts:
            db-prod-01:

    staging:
      children:
        staging_web:
          hosts:
            web-staging-01:
        staging_db:
          hosts:
            db-staging-01:
```

### 4. Variables sensibles

```yaml
# ❌ MAUVAIS : Secrets en clair
databases:
  vars:
    mysql_root_password: SuperSecret123

# ✅ BON : Utiliser Ansible Vault
databases:
  vars:
    mysql_root_password: "{{ vault_mysql_root_password }}"
```

```bash
# Créer un fichier chiffré
ansible-vault create group_vars/databases/vault.yml

# Éditer
ansible-vault edit group_vars/databases/vault.yml

# Contenu :
vault_mysql_root_password: SuperSecret123

# Exécuter
ansible-playbook site.yml --ask-vault-pass
```

### 5. Documentation

```yaml
# hosts.yml
# Description: Production inventory for myapp
# Maintainer: ops-team@example.com
# Last updated: 2024-01-15

all:
  children:
    webservers:
      # Nginx web servers serving static content
      hosts:
        web1:
          ansible_host: 10.0.1.10
```

---

## Commandes utiles

```bash
# Afficher l'inventaire
ansible-inventory --list
ansible-inventory --list -i inventory/production.yml

# Format YAML
ansible-inventory --list -y

# Graph
ansible-inventory --graph

# Variables d'un host
ansible-inventory --host web1

# Tous les hosts d'un groupe
ansible webservers --list-hosts

# Vérifier patterns
ansible 'webservers:&production' --list-hosts

# Debug
ansible all -i inventory.yml -m debug -a "var=hostvars"
```

---

## Prochaines étapes

Maintenant que vous maîtrisez les inventaires, passez au module suivant :

**[05-Modules](../05-Modules/README.md)**

Vous allez apprendre à :
- Utiliser les modules système (apt, yum, service, user)
- Gérer les fichiers (copy, template, file)
- Modules cloud (AWS, Azure, GCP)
- Différence entre command/shell et modules
- Modules Docker et Kubernetes

---

**"A well-organized inventory is the foundation of infrastructure automation."**
