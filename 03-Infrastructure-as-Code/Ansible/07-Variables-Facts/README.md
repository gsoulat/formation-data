# Variables et Facts Ansible

## Table des matières

1. [Introduction aux Variables](#introduction-aux-variables)
2. [Types de Variables](#types-de-variables)
3. [Précédence des Variables](#précédence-des-variables)
4. [Facts](#facts)
5. [Registered Variables](#registered-variables)
6. [Magic Variables](#magic-variables)
7. [group_vars et host_vars](#group_vars-et-host_vars)
8. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction aux Variables

Les **variables** permettent de rendre vos playbooks dynamiques et réutilisables.

### Qu'est-ce qu'une Variable ?

**Définition :**
- Valeur nommée réutilisable dans les playbooks
- Permet la paramétrisation
- Types : string, number, boolean, list, dictionary
- Référencées avec la syntaxe Jinja2 `{{ variable_name }}`

**Pourquoi utiliser des variables ?**
- **Réutilisabilité** : Même playbook pour différents environnements
- **Flexibilité** : Adapter le comportement sans modifier le code
- **Maintenabilité** : Centraliser les valeurs
- **Sécurité** : Séparer les secrets avec Ansible Vault

### Nommage des variables

```yaml
# ✅ BON : snake_case
http_port: 80
mysql_root_password: secret
app_version: 1.2.3

# ❌ MAUVAIS : camelCase
httpPort: 80
mysqlRootPassword: secret

# ❌ MAUVAIS : Noms réservés
hostvars: value
groups: value
ansible_facts: value
```

**Conventions :**
- Utiliser `snake_case`
- Noms descriptifs
- Préfixer les variables de rôle (ex: `nginx_port`)
- Éviter les noms réservés

---

## Types de Variables

### 1. Variables Scalaires

**String**
```yaml
server_name: "example.com"
app_version: "1.2.3"
description: 'Mon application'
```

**Number**
```yaml
http_port: 80
max_connections: 1000
timeout: 30.5
```

**Boolean**
```yaml
ssl_enabled: true
debug_mode: false
monitoring: yes
backup: no
```

### 2. Listes (Arrays)

```yaml
# Liste simple
packages:
  - nginx
  - curl
  - vim
  - git

# Liste inline
ports: [80, 443, 8080]

# Accès aux éléments
# {{ packages[0] }} → nginx
# {{ packages | length }} → 4
```

**Utilisation :**
```yaml
- name: Install packages
  apt:
    name: "{{ packages }}"
    state: present

- name: Install first package only
  apt:
    name: "{{ packages[0] }}"
    state: present
```

### 3. Dictionnaires (Objects)

```yaml
# Dictionnaire simple
user:
  name: john
  uid: 1000
  shell: /bin/bash
  groups:
    - sudo
    - docker

# Dictionnaire inline
db: {host: localhost, port: 3306, name: mydb}

# Accès aux valeurs
# {{ user.name }} → john
# {{ user['name'] }} → john
# {{ db.port }} → 3306
```

**Utilisation :**
```yaml
- name: Create user
  user:
    name: "{{ user.name }}"
    uid: "{{ user.uid }}"
    shell: "{{ user.shell }}"
    groups: "{{ user.groups | join(',') }}"
```

### 4. Dictionnaires imbriqués

```yaml
application:
  name: myapp
  version: 1.2.3
  config:
    database:
      host: db.example.com
      port: 3306
      name: myapp_db
      credentials:
        username: app_user
        password: "{{ vault_db_password }}"
    cache:
      type: redis
      host: cache.example.com
      port: 6379
  features:
    - authentication
    - caching
    - monitoring

# Accès :
# {{ application.name }} → myapp
# {{ application.config.database.host }} → db.example.com
# {{ application.features[0] }} → authentication
```

---

## Précédence des Variables

Ansible applique les variables selon un ordre de priorité (de la plus basse à la plus haute) :

```
1.  command line values (ex: -u user)
2.  role defaults (defaults/main.yml)
3.  inventory file or script group vars
4.  inventory group_vars/all
5.  playbook group_vars/all
6.  inventory group_vars/*
7.  playbook group_vars/*
8.  inventory file or script host vars
9.  inventory host_vars/*
10. playbook host_vars/*
11. host facts / cached set_facts
12. play vars
13. play vars_prompt
14. play vars_files
15. role vars (vars/main.yml)
16. block vars (only for tasks in block)
17. task vars (only for the task)
18. include_vars
19. set_facts / registered vars
20. role (and include_role) params
21. include params
22. extra vars (-e in CLI) ← PLUS HAUTE PRIORITÉ
```

### Exemple de précédence

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
    # Affiche : Port is 3000 (playbook vars gagne)

# Mais si extra vars :
# ansible-playbook site.yml -e "http_port=5000"
# Affiche : Port is 5000 (extra vars gagne sur tout)
```

### Ordre pratique à retenir

```
Defaults < Inventory < Playbook < Extra Vars
  ↓           ↓           ↓           ↓
 Faible                            Haute
priorité                        priorité
```

---

## Facts

Les **facts** sont des informations collectées automatiquement sur les managed nodes.

### Qu'est-ce qu'un Fact ?

**Définition :**
- Informations système collectées par Ansible
- Collectées au début de chaque play (sauf si `gather_facts: no`)
- Accessibles via `ansible_facts` ou directement
- Exemples : OS, IP, CPU, mémoire, disques, etc.

### Collecter les facts

```yaml
# Facts collectés par défaut
- name: Play with facts
  hosts: all
  gather_facts: yes  # Par défaut
  tasks:
    - name: Display facts
      debug:
        var: ansible_facts

# Désactiver la collecte (améliore perf)
- name: Fast play
  hosts: all
  gather_facts: no
  tasks:
    - name: Simple task
      ping:
```

### Facts couramment utilisés

```yaml
# Système d'exploitation
ansible_distribution          # Ubuntu, CentOS, Debian
ansible_distribution_version  # 20.04, 8, 11
ansible_os_family            # Debian, RedHat
ansible_kernel               # 5.4.0-42-generic

# Réseau
ansible_hostname             # web1
ansible_fqdn                # web1.example.com
ansible_default_ipv4.address # 192.168.1.10
ansible_all_ipv4_addresses  # Liste de toutes les IPs
ansible_interfaces          # Liste des interfaces

# Hardware
ansible_processor_cores      # 4
ansible_processor_vcpus     # 8
ansible_memtotal_mb         # 16384
ansible_devices             # Disques

# Python
ansible_python_version      # 3.8.10
```

### Utiliser les facts

```yaml
---
- name: Use facts
  hosts: all
  tasks:
    - name: Display OS info
      debug:
        msg: |
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Hostname: {{ ansible_hostname }}
          IP: {{ ansible_default_ipv4.address }}
          CPUs: {{ ansible_processor_vcpus }}
          Memory: {{ ansible_memtotal_mb }} MB

    - name: Install package based on OS
      apt:
        name: nginx
        state: present
      when: ansible_os_family == "Debian"

    - name: Install package on RedHat
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"
```

### Facts custom avec set_fact

```yaml
- name: Calculate custom facts
  set_fact:
    is_production: "{{ 'prod' in inventory_hostname }}"
    memory_gb: "{{ (ansible_memtotal_mb / 1024) | round(1) }}"
    needs_swap: "{{ ansible_memtotal_mb < 4096 }}"

- name: Use custom facts
  debug:
    msg: |
      Production: {{ is_production }}
      Memory: {{ memory_gb }} GB
      Needs swap: {{ needs_swap }}
```

### Facts locaux (local facts)

Créer des facts custom sur les managed nodes :

**Sur le managed node : /etc/ansible/facts.d/custom.fact**
```ini
[general]
app_version=1.2.3
environment=production
datacenter=eu-west-1
```

**Dans le playbook :**
```yaml
- name: Use local facts
  hosts: all
  tasks:
    - name: Display local facts
      debug:
        msg: |
          App version: {{ ansible_local.custom.general.app_version }}
          Environment: {{ ansible_local.custom.general.environment }}
          Datacenter: {{ ansible_local.custom.general.datacenter }}
```

### Filtrer les facts

```bash
# Collecter seulement certains facts
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_default_ipv4"

# Voir tous les facts
ansible all -m setup
```

### Cache des facts

```ini
# ansible.cfg
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400  # 24h
```

---

## Registered Variables

Les **registered variables** capturent le résultat d'une tâche.

### Utilisation de base

```yaml
- name: Check if file exists
  stat:
    path: /etc/app/config.yml
  register: config_file

- name: Display result
  debug:
    var: config_file

- name: Create config if doesn't exist
  template:
    src: config.yml.j2
    dest: /etc/app/config.yml
  when: not config_file.stat.exists
```

### Structure d'une variable registered

```yaml
- name: Run command
  command: uptime
  register: result

- name: Show result structure
  debug:
    var: result

# Résultat :
# result:
#   changed: true
#   cmd: [uptime]
#   rc: 0
#   stdout: "14:23:45 up 10 days, 2:15, 1 user, load average: 0.00, 0.01, 0.05"
#   stderr: ""
#   start: "2024-01-15 14:23:45"
#   end: "2024-01-15 14:23:45"
```

### Exemples courants

**1. Vérifier un service**
```yaml
- name: Check if nginx is running
  command: systemctl is-active nginx
  register: nginx_status
  changed_when: false
  failed_when: false

- name: Start nginx if not running
  service:
    name: nginx
    state: started
  when: nginx_status.rc != 0
```

**2. Capturer la sortie**
```yaml
- name: Get disk usage
  shell: df -h /var
  register: disk_usage
  changed_when: false

- name: Display disk usage
  debug:
    msg: "{{ disk_usage.stdout_lines }}"
```

**3. API call**
```yaml
- name: Call API
  uri:
    url: https://api.example.com/status
    method: GET
    return_content: yes
  register: api_response

- name: Parse JSON response
  debug:
    msg: "Status is {{ api_response.json.status }}"
```

**4. Boucle avec résultats**
```yaml
- name: Check multiple services
  command: systemctl is-active {{ item }}
  register: services_status
  changed_when: false
  failed_when: false
  loop:
    - nginx
    - mysql
    - redis

- name: Display services status
  debug:
    msg: "{{ item.item }} is {{ 'running' if item.rc == 0 else 'stopped' }}"
  loop: "{{ services_status.results }}"
```

---

## Magic Variables

Les **magic variables** sont des variables spéciales fournies par Ansible.

### hostvars

Accès aux variables d'autres hosts :

```yaml
- name: Use hostvars
  debug:
    msg: |
      My IP: {{ ansible_default_ipv4.address }}
      DB server IP: {{ hostvars['db1'].ansible_default_ipv4.address }}
      Web1 hostname: {{ hostvars['web1'].ansible_hostname }}
```

### groups

Liste des groupes et hosts :

```yaml
- name: Display groups
  debug:
    msg: |
      All hosts: {{ groups['all'] }}
      Web servers: {{ groups['webservers'] }}
      First web server: {{ groups['webservers'][0] }}

- name: Configure load balancer
  template:
    src: haproxy.cfg.j2
    dest: /etc/haproxy/haproxy.cfg
```

**Template haproxy.cfg.j2 :**
```jinja
backend webservers
{% for host in groups['webservers'] %}
    server {{ host }} {{ hostvars[host].ansible_default_ipv4.address }}:80 check
{% endfor %}
```

### group_names

Groupes dont fait partie le host actuel :

```yaml
- name: Check group membership
  debug:
    msg: "I am in groups: {{ group_names }}"

- name: Task only for production
  debug:
    msg: "This is production"
  when: "'production' in group_names"
```

### inventory_hostname

Nom du host actuel :

```yaml
- name: Display hostname
  debug:
    msg: "Current host is {{ inventory_hostname }}"

- name: Create host-specific file
  copy:
    content: "This is {{ inventory_hostname }}"
    dest: "/tmp/{{ inventory_hostname }}.txt"
```

### inventory_hostname_short

Version courte du hostname :

```yaml
# Si inventory_hostname = web1.example.com
- debug:
    msg: "{{ inventory_hostname_short }}"
# Affiche : web1
```

### play_hosts

Liste des hosts dans le play actuel :

```yaml
- name: Display play hosts
  debug:
    msg: "Hosts in this play: {{ play_hosts }}"
```

### ansible_play_batch

Hosts dans le batch actuel (avec serial) :

```yaml
- name: Rolling update
  hosts: webservers
  serial: 2
  tasks:
    - debug:
        msg: "Updating hosts: {{ ansible_play_batch }}"
```

---

## group_vars et host_vars

### Structure recommandée

```
project/
├── ansible.cfg
├── inventory/
│   ├── production/
│   │   ├── hosts.yml
│   │   ├── group_vars/
│   │   │   ├── all.yml
│   │   │   ├── webservers.yml
│   │   │   ├── databases.yml
│   │   │   └── databases/
│   │   │       └── vault.yml
│   │   └── host_vars/
│   │       ├── web1.yml
│   │       ├── web2.yml
│   │       └── db1.yml
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/
│           └── all.yml
└── playbooks/
    └── site.yml
```

### group_vars/all.yml

Variables communes à tous les hosts :

```yaml
---
# group_vars/all.yml

# Global settings
ansible_user: ubuntu
ansible_python_interpreter: /usr/bin/python3
ansible_ssh_private_key_file: ~/.ssh/ansible_key

# Common packages
common_packages:
  - vim
  - curl
  - htop
  - git

# NTP configuration
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org

# Monitoring
monitoring_enabled: true
monitoring_server: monitor.example.com

# Environment
environment: production
datacenter: eu-west-1
```

### group_vars/webservers.yml

Variables pour le groupe webservers :

```yaml
---
# group_vars/webservers.yml

# Nginx configuration
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_port: 80
nginx_ssl_port: 443

# Application
app_name: myapp
app_port: 8080
app_user: www-data

# Logging
log_level: info
log_path: /var/log/nginx
```

### group_vars/databases/vault.yml

Secrets chiffrés avec Ansible Vault :

```yaml
---
# group_vars/databases/vault.yml (chiffré)

vault_mysql_root_password: SuperSecretPassword123!
vault_mysql_replication_password: ReplicationSecret456
vault_backup_password: BackupPassword789
```

**Créer/éditer :**
```bash
# Créer un fichier chiffré
ansible-vault create group_vars/databases/vault.yml

# Éditer un fichier chiffré
ansible-vault edit group_vars/databases/vault.yml

# Chiffrer un fichier existant
ansible-vault encrypt group_vars/databases/vault.yml

# Déchiffrer
ansible-vault decrypt group_vars/databases/vault.yml
```

### group_vars/databases.yml

Variables non sensibles pour databases :

```yaml
---
# group_vars/databases.yml

# MySQL configuration
mysql_port: 3306
mysql_bind_address: 0.0.0.0
mysql_max_connections: 500
mysql_root_password: "{{ vault_mysql_root_password }}"

# Replication
mysql_replication_user: replicator
mysql_replication_password: "{{ vault_mysql_replication_password }}"

# Backup
backup_enabled: true
backup_schedule: "0 2 * * *"
backup_retention_days: 30
```

### host_vars/web1.yml

Variables spécifiques à web1 :

```yaml
---
# host_vars/web1.yml

# Server-specific settings
nginx_worker_processes: 4
server_role: frontend

# Monitoring
monitoring_tags:
  - primary-web
  - frontend
  - production

# Custom configuration
custom_vhosts:
  - server_name: app1.example.com
    port: 80
  - server_name: app2.example.com
    port: 8080
```

### Utiliser les variables

**playbook.yml**
```yaml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Display variables
      debug:
        msg: |
          Environment: {{ environment }}
          Nginx port: {{ nginx_port }}
          App: {{ app_name }}
          Server role: {{ server_role | default('standard') }}

    - name: Install common packages
      apt:
        name: "{{ common_packages }}"
        state: present

    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Reload nginx
```

**Exécution :**
```bash
# Normal
ansible-playbook playbooks/site.yml

# Avec vault password
ansible-playbook playbooks/site.yml --ask-vault-pass

# Avec vault password file
ansible-playbook playbooks/site.yml --vault-password-file ~/.vault_pass
```

---

## Bonnes pratiques

### 1. Organisation des variables

```
✅ BON : Séparer par contexte
group_vars/
├── all.yml              # Variables globales
├── webservers.yml       # Variables web
├── databases.yml        # Variables DB (non sensibles)
└── databases/
    └── vault.yml        # Secrets DB (chiffrés)

❌ MAUVAIS : Tout dans un fichier
group_vars/
└── all.yml              # 500 lignes de variables mélangées
```

### 2. Nommage des variables

```yaml
# ✅ BON : Préfixer les variables de rôle
nginx_port: 80
nginx_worker_processes: 4
mysql_port: 3306
mysql_max_connections: 500

# ❌ MAUVAIS : Noms génériques
port: 80
workers: 4
max_conn: 500
```

### 3. Valeurs par défaut

```yaml
# ✅ BON : Fournir des valeurs par défaut
- name: Use variable with default
  debug:
    msg: "Port is {{ http_port | default(80) }}"

# ✅ BON : Dans les rôles, utiliser defaults/
# roles/nginx/defaults/main.yml
nginx_port: 80
nginx_ssl_enabled: false
```

### 4. Documentation

```yaml
# group_vars/webservers.yml

# Nginx Configuration
# -------------------
# nginx_port: Port HTTP (default: 80)
# nginx_ssl_port: Port HTTPS (default: 443)
# nginx_worker_processes: Nombre de workers (default: auto)

nginx_port: 80
nginx_ssl_port: 443
nginx_worker_processes: auto
```

### 5. Secrets avec Vault

```yaml
# ✅ BON : Préfixer les secrets par vault_
vault_mysql_root_password: secret
vault_api_key: abc123

# Utiliser dans les variables
mysql_root_password: "{{ vault_mysql_root_password }}"
api_key: "{{ vault_api_key }}"

# ❌ MAUVAIS : Secrets en clair
mysql_root_password: MyPassword123
```

### 6. Éviter la duplication

```yaml
# ✅ BON : Définir une fois, référencer partout
# group_vars/all.yml
app_version: 1.2.3
app_name: myapp

# Dans les playbooks
image_name: "{{ app_name }}:{{ app_version }}"

# ❌ MAUVAIS : Dupliquer partout
# playbook1.yml
image_name: myapp:1.2.3
# playbook2.yml
image_name: myapp:1.2.3
```

---

## Exemples complets

### Configuration multi-environnement

```
inventory/
├── production/
│   ├── hosts.yml
│   └── group_vars/
│       ├── all.yml
│       └── webservers.yml
└── staging/
    ├── hosts.yml
    └── group_vars/
        ├── all.yml
        └── webservers.yml
```

**inventory/production/group_vars/all.yml**
```yaml
---
environment: production
dns_servers:
  - 8.8.8.8
  - 8.8.4.4
monitoring_enabled: true
backup_enabled: true
```

**inventory/staging/group_vars/all.yml**
```yaml
---
environment: staging
dns_servers:
  - 8.8.8.8
monitoring_enabled: true
backup_enabled: false
```

**Playbook unique pour tous les environnements :**
```yaml
---
- name: Configure application
  hosts: webservers
  tasks:
    - name: Display environment
      debug:
        msg: "Deploying to {{ environment }}"

    - name: Deploy with environment-specific settings
      template:
        src: app.conf.j2
        dest: /etc/app/config.yml
```

```bash
# Deploy en production
ansible-playbook -i inventory/production site.yml

# Deploy en staging
ansible-playbook -i inventory/staging site.yml
```

---

## Prochaines étapes

Maintenant que vous maîtrisez les variables et facts, passez au module suivant :

**[08-Templates-Jinja2](../08-Templates-Jinja2/README.md)**

Vous allez apprendre à :
- Syntaxe Jinja2
- Utiliser les filters
- Conditions et boucles dans les templates
- Macros
- Créer des templates de configuration

---

**"Variables are the DNA of your infrastructure. Organize them well, and everything else falls into place."**
