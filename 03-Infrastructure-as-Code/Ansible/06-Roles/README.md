# Les Rôles Ansible

## Table des matières

1. [Introduction aux Rôles](#introduction-aux-rôles)
2. [Structure d'un Rôle](#structure-dun-rôle)
3. [Créer un Rôle](#créer-un-rôle)
4. [Utiliser un Rôle](#utiliser-un-rôle)
5. [Dépendances de Rôles](#dépendances-de-rôles)
6. [Ansible Galaxy](#ansible-galaxy)
7. [Collections](#collections)
8. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction aux Rôles

Les **rôles** sont une façon d'organiser les playbooks de manière modulaire et réutilisable.

### Qu'est-ce qu'un Rôle ?

**Définition :**
- Structure organisée de tasks, variables, templates, etc.
- Réutilisable dans plusieurs playbooks
- Partage facilité via Ansible Galaxy
- Permet la modularité et la séparation des responsabilités

**Avantages :**
- **Réutilisabilité** : Un rôle = une fonction (nginx, mysql, etc.)
- **Organisation** : Structure claire et standardisée
- **Collaboration** : Partage facile entre équipes
- **Testabilité** : Tester un rôle indépendamment
- **Maintenance** : Mise à jour centralisée

### Playbook vs Rôle

**Playbook monolithique :**
```yaml
# webserver.yml (tout dans un fichier)
---
- name: Configure web server
  hosts: webservers
  vars:
    http_port: 80
  tasks:
    - name: Install nginx
      apt:
        name: nginx
    - name: Copy config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
    # ... 50+ tasks
```

**Avec rôles :**
```yaml
# site.yml (clair et concis)
---
- name: Configure web server
  hosts: webservers
  roles:
    - nginx
    - ssl
    - firewall
```

---

## Structure d'un Rôle

### Arborescence complète

```
roles/
└── nginx/
    ├── README.md           # Documentation du rôle
    ├── defaults/
    │   └── main.yml        # Variables par défaut (faible priorité)
    ├── files/
    │   └── index.html      # Fichiers statiques
    ├── handlers/
    │   └── main.yml        # Handlers
    ├── meta/
    │   └── main.yml        # Métadonnées et dépendances
    ├── tasks/
    │   └── main.yml        # Tâches principales
    ├── templates/
    │   └── nginx.conf.j2   # Templates Jinja2
    ├── tests/
    │   ├── inventory       # Inventaire de test
    │   └── test.yml        # Playbook de test
    └── vars/
        └── main.yml        # Variables du rôle (haute priorité)
```

### Description des répertoires

**tasks/**
- Contient les tâches du rôle
- `main.yml` est le point d'entrée
- Peut inclure d'autres fichiers

**defaults/**
- Variables par défaut (basse priorité)
- Peuvent être écrasées facilement
- Pour les valeurs "raisonnables par défaut"

**vars/**
- Variables du rôle (haute priorité)
- Difficilement écrasables
- Pour les valeurs "fixes" du rôle

**files/**
- Fichiers statiques à copier tel quel
- Utilisés par le module `copy`

**templates/**
- Templates Jinja2
- Utilisés par le module `template`

**handlers/**
- Handlers du rôle
- Notifiés par les tasks

**meta/**
- Métadonnées du rôle
- Dépendances vers d'autres rôles
- Informations Galaxy

**tests/**
- Playbook et inventaire de test
- Pour valider le rôle

---

## Créer un Rôle

### Méthode 1 : ansible-galaxy init

```bash
# Créer la structure d'un rôle
ansible-galaxy init nginx

# Créer dans un répertoire spécifique
ansible-galaxy init roles/nginx

# Structure créée :
nginx/
├── README.md
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
```

### Méthode 2 : Créer manuellement

```bash
# Créer la structure
mkdir -p roles/nginx/{tasks,handlers,templates,files,vars,defaults,meta}
touch roles/nginx/{tasks,handlers,vars,defaults,meta}/main.yml
```

### Exemple de rôle complet : nginx

**roles/nginx/tasks/main.yml**
```yaml
---
# Installation et configuration de nginx
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes
  tags: install

- name: Create web root directory
  file:
    path: "{{ nginx_web_root }}"
    state: directory
    owner: "{{ nginx_user }}"
    group: "{{ nginx_group }}"
    mode: '0755'
  tags: config

- name: Copy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'
  notify: Reload nginx
  tags: config

- name: Copy site configuration
  template:
    src: site.conf.j2
    dest: "/etc/nginx/sites-available/{{ nginx_server_name }}"
    owner: root
    group: root
    mode: '0644'
  notify: Reload nginx
  tags: config

- name: Enable site
  file:
    src: "/etc/nginx/sites-available/{{ nginx_server_name }}"
    dest: "/etc/nginx/sites-enabled/{{ nginx_server_name }}"
    state: link
  notify: Reload nginx
  tags: config

- name: Start and enable nginx
  service:
    name: nginx
    state: started
    enabled: yes
  tags: service
```

**roles/nginx/handlers/main.yml**
```yaml
---
- name: Reload nginx
  service:
    name: nginx
    state: reloaded

- name: Restart nginx
  service:
    name: nginx
    state: restarted
```

**roles/nginx/defaults/main.yml**
```yaml
---
# Variables par défaut pour nginx
nginx_user: www-data
nginx_group: www-data
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_server_name: example.com
nginx_web_root: /var/www/html
nginx_port: 80
nginx_ssl_port: 443
```

**roles/nginx/vars/main.yml**
```yaml
---
# Variables fixes du rôle
nginx_config_path: /etc/nginx
nginx_log_path: /var/log/nginx
```

**roles/nginx/templates/nginx.conf.j2**
```jinja
user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log {{ nginx_log_path }}/access.log;
    error_log {{ nginx_log_path }}/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

**roles/nginx/templates/site.conf.j2**
```jinja
server {
    listen {{ nginx_port }};
    server_name {{ nginx_server_name }};

    root {{ nginx_web_root }};
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log {{ nginx_log_path }}/{{ nginx_server_name }}.access.log;
    error_log {{ nginx_log_path }}/{{ nginx_server_name }}.error.log;
}
```

**roles/nginx/meta/main.yml**
```yaml
---
galaxy_info:
  author: Your Name
  description: Nginx web server role
  company: Your Company
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
    - name: Debian
      versions:
        - bullseye
  galaxy_tags:
    - nginx
    - webserver
    - web

dependencies: []
```

**roles/nginx/README.md**
```markdown
# Nginx Role

Ce rôle installe et configure Nginx.

## Requirements

- Ubuntu 20.04+ ou Debian 11+
- Ansible 2.9+

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_server_name` | `example.com` | Nom du serveur |
| `nginx_port` | `80` | Port HTTP |
| `nginx_web_root` | `/var/www/html` | Racine web |

## Example Playbook

```yaml
- hosts: webservers
  roles:
    - role: nginx
      nginx_server_name: mysite.com
      nginx_port: 8080
```

## License

MIT

## Author

Your Name
```

---

## Utiliser un Rôle

### Dans un playbook

```yaml
# site.yml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  roles:
    - nginx

# Avec variables
- name: Configure with custom vars
  hosts: webservers
  become: yes
  roles:
    - role: nginx
      nginx_server_name: mysite.com
      nginx_port: 8080
```

### Syntaxe avancée

```yaml
---
- name: Configure servers
  hosts: all
  become: yes

  roles:
    # Syntaxe simple
    - common

    # Avec variables
    - role: nginx
      vars:
        nginx_server_name: example.com
        nginx_port: 80

    # Avec tags
    - role: mysql
      tags: database

    # Conditionnel
    - role: redis
      when: ansible_os_family == "Debian"

    # Pre/post tasks avec rôles
  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

  post_tasks:
    - name: Verify services
      service:
        name: nginx
        state: started
```

### Import vs Include

**import_role (Statique)**
```yaml
tasks:
  - name: Import nginx role
    import_role:
      name: nginx
    vars:
      nginx_port: 8080
    tags: web
```

**include_role (Dynamique)**
```yaml
tasks:
  - name: Include nginx role
    include_role:
      name: nginx
    vars:
      nginx_port: 8080
    when: install_nginx | bool
```

**Différences :**
| Critère | import_role | include_role |
|---------|-------------|--------------|
| Quand | À la lecture du playbook | À l'exécution |
| Tags | Hérités | Non hérités |
| When | Appliqué à toutes les tasks | Appliqué au include |
| Performance | Plus rapide | Plus flexible |

---

## Dépendances de Rôles

### Définir des dépendances

**roles/webapp/meta/main.yml**
```yaml
---
dependencies:
  # Dépendance simple
  - role: nginx

  # Avec variables
  - role: mysql
    vars:
      mysql_root_password: "{{ vault_mysql_password }}"

  # Conditionnel
  - role: redis
    when: use_cache | bool

  # Depuis Galaxy
  - role: geerlingguy.docker
    version: 4.1.0
```

### Ordre d'exécution

```yaml
# site.yml
- hosts: webservers
  roles:
    - common
    - webapp  # webapp dépend de nginx et mysql
```

**Ordre d'exécution :**
```
1. common (tasks)
2. nginx (tasks) - dépendance de webapp
3. mysql (tasks) - dépendance de webapp
4. webapp (tasks)
```

### Éviter les doublons

```yaml
# Les dépendances ne sont exécutées qu'une fois
- hosts: all
  roles:
    - app1  # dépend de common
    - app2  # dépend de common
    - app3  # dépend de common
# common s'exécute 1 seule fois
```

**Forcer la réexécution :**
```yaml
dependencies:
  - role: common
    allow_duplicates: yes
```

---

## Ansible Galaxy

### Qu'est-ce qu'Ansible Galaxy ?

**Ansible Galaxy** est le hub communautaire pour partager et télécharger des rôles.

- Hub : https://galaxy.ansible.com
- 20 000+ rôles disponibles
- Gratuit et open-source

### Rechercher des rôles

```bash
# Sur le site web
https://galaxy.ansible.com

# En ligne de commande
ansible-galaxy search nginx
ansible-galaxy search docker --author geerlingguy

# Informations sur un rôle
ansible-galaxy info geerlingguy.nginx
```

### Installer des rôles

```bash
# Installer un rôle
ansible-galaxy install geerlingguy.nginx

# Version spécifique
ansible-galaxy install geerlingguy.nginx,4.1.0

# Dans un répertoire spécifique
ansible-galaxy install geerlingguy.nginx -p ./roles

# Depuis requirements.yml
ansible-galaxy install -r requirements.yml
```

### requirements.yml

**requirements.yml**
```yaml
---
# Depuis Galaxy
- name: geerlingguy.nginx
  version: 4.1.0

- name: geerlingguy.docker

# Depuis Git
- src: https://github.com/user/ansible-role-custom.git
  name: custom
  version: main

- src: git+https://github.com/user/role.git
  name: myrole
  version: v1.2.3

# Depuis URL tar.gz
- src: https://example.com/roles/myrole.tar.gz
  name: myrole

# Collections
collections:
  - name: community.general
    version: 5.0.0

  - name: ansible.posix
```

**Installation :**
```bash
# Installer tous les rôles
ansible-galaxy install -r requirements.yml

# Forcer la réinstallation
ansible-galaxy install -r requirements.yml --force

# Upgrade
ansible-galaxy install -r requirements.yml --force-with-deps
```

### Publier un rôle sur Galaxy

**1. Créer un compte GitHub et Galaxy**
- Créer compte sur https://galaxy.ansible.com
- Lier votre compte GitHub

**2. Préparer le rôle**
```bash
# Structure du repo GitHub
ansible-role-nginx/
├── README.md
├── meta/
│   └── main.yml
├── defaults/
│   └── main.yml
├── tasks/
│   └── main.yml
├── handlers/
│   └── main.yml
└── templates/
    └── nginx.conf.j2
```

**3. Configurer meta/main.yml**
```yaml
---
galaxy_info:
  role_name: nginx
  author: yourname
  description: Nginx web server
  company: Your Company
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
  galaxy_tags:
    - nginx
    - web
    - webserver
```

**4. Pousser sur GitHub**
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourname/ansible-role-nginx.git
git push -u origin main
```

**5. Importer sur Galaxy**
- Aller sur https://galaxy.ansible.com/my-content/namespaces
- Importer le repository
- Galaxy teste et publie automatiquement

### Gérer les rôles installés

```bash
# Lister les rôles installés
ansible-galaxy list

# Supprimer un rôle
ansible-galaxy remove geerlingguy.nginx

# Mettre à jour un rôle
ansible-galaxy install geerlingguy.nginx --force
```

---

## Collections

Les **collections** sont des packages qui regroupent rôles, modules, plugins.

### Structure d'une collection

```
mycollection/
├── galaxy.yml              # Métadonnées
├── plugins/
│   ├── modules/
│   │   └── my_module.py
│   ├── inventory/
│   └── filter/
├── roles/
│   ├── role1/
│   └── role2/
├── playbooks/
│   └── example.yml
└── docs/
    └── README.md
```

### Installer une collection

```bash
# Depuis Galaxy
ansible-galaxy collection install community.general

# Version spécifique
ansible-galaxy collection install community.general:5.0.0

# Depuis requirements.yml
ansible-galaxy collection install -r requirements.yml

# Liste des collections installées
ansible-galaxy collection list
```

### Utiliser une collection

```yaml
---
# Importer toute la collection
- hosts: all
  collections:
    - community.general

  tasks:
    - name: Use module from collection
      docker_container:  # Pas besoin du FQCN
        name: nginx
        image: nginx

# Utiliser le FQCN (Fully Qualified Collection Name)
- hosts: all
  tasks:
    - name: Use module with FQCN
      community.general.docker_container:
        name: nginx
        image: nginx
```

### Créer une collection

```bash
# Créer la structure
ansible-galaxy collection init mycompany.mycollection

# Structure créée
mycompany/mycollection/
├── galaxy.yml
├── plugins/
│   └── README.md
├── roles/
└── README.md
```

**galaxy.yml**
```yaml
namespace: mycompany
name: mycollection
version: 1.0.0
readme: README.md
authors:
  - Your Name <your.email@example.com>
description: My awesome collection
license:
  - MIT
tags:
  - infrastructure
  - automation
dependencies: {}
repository: https://github.com/mycompany/mycollection
```

### Publier une collection

```bash
# Build la collection
ansible-galaxy collection build

# Publier sur Galaxy
ansible-galaxy collection publish mycompany-mycollection-1.0.0.tar.gz --api-key=xxx
```

---

## Bonnes pratiques

### 1. Un rôle = Une responsabilité

```
✅ BON :
roles/
├── nginx/      # Juste nginx
├── mysql/      # Juste mysql
├── redis/      # Juste redis
└── webapp/     # Application (utilise nginx, mysql, redis)

❌ MAUVAIS :
roles/
└── everything/  # Fait tout
```

### 2. Utiliser defaults/ pour les variables

```yaml
# ✅ BON : defaults/main.yml
nginx_port: 80
nginx_worker_processes: auto

# Facilement écrasable dans le playbook
- role: nginx
  nginx_port: 8080
```

### 3. Documenter avec README.md

```markdown
# Mon Rôle

## Description
Ce rôle installe et configure...

## Variables
| Var | Default | Description |
|-----|---------|-------------|
| `app_port` | `8080` | Port de l'application |

## Example
```yaml
- role: monrole
  app_port: 9090
```

## License
MIT
```

### 4. Tester les rôles avec Molecule

```bash
# Installer Molecule
pip install molecule molecule-docker

# Initialiser
cd roles/nginx
molecule init scenario

# Tester
molecule test
```

### 5. Versionner les rôles

```yaml
# requirements.yml
- name: geerlingguy.nginx
  version: 4.1.0  # Toujours spécifier la version
```

### 6. Structure de projet recommandée

```
project/
├── ansible.cfg
├── inventory/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── databases.yml
├── roles/
│   ├── common/
│   ├── nginx/
│   └── mysql/
├── requirements.yml
└── README.md
```

---

## Exemple complet : Application 3-tiers

**requirements.yml**
```yaml
---
roles:
  - name: geerlingguy.nginx
    version: 4.1.0
  - name: geerlingguy.mysql
    version: 4.0.0
  - name: geerlingguy.redis
    version: 1.7.0

collections:
  - name: community.general
    version: 5.0.0
```

**site.yml**
```yaml
---
- name: Configure load balancers
  hosts: loadbalancers
  become: yes
  roles:
    - role: geerlingguy.nginx
      nginx_vhosts:
        - listen: 80
          server_name: example.com
          extra_parameters: |
            location / {
              proxy_pass http://backend;
            }

- name: Configure application servers
  hosts: appservers
  become: yes
  roles:
    - common
    - webapp
    - role: geerlingguy.redis
      when: use_cache | bool

- name: Configure database servers
  hosts: databases
  become: yes
  roles:
    - common
    - role: geerlingguy.mysql
      mysql_root_password: "{{ vault_mysql_root_password }}"
      mysql_databases:
        - name: myapp
      mysql_users:
        - name: myapp
          password: "{{ vault_myapp_db_password }}"
          priv: "myapp.*:ALL"
```

---

## Prochaines étapes

Maintenant que vous maîtrisez les rôles, passez au module suivant :

**[07-Variables-Facts](../07-Variables-Facts/README.md)**

Vous allez apprendre à :
- Utiliser différents types de variables
- Comprendre la précédence des variables
- Collecter et utiliser les facts
- Registered variables
- group_vars et host_vars

---

**"Roles are the building blocks of infrastructure automation. Build them well, and they'll serve you forever."**
