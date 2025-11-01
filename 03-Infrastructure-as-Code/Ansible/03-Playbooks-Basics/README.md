# Les Playbooks Ansible - Fondamentaux

## Table des matières

1. [Introduction aux Playbooks](#introduction-aux-playbooks)
2. [Syntaxe YAML](#syntaxe-yaml)
3. [Structure d'un Playbook](#structure-dun-playbook)
4. [Tasks et Plays](#tasks-et-plays)
5. [Handlers et Notifications](#handlers-et-notifications)
6. [Idempotence](#idempotence)
7. [Check Mode et Diff](#check-mode-et-diff)
8. [Tags](#tags)
9. [Gestion des erreurs](#gestion-des-erreurs)
10. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction aux Playbooks

Un **playbook** est un fichier YAML qui décrit l'état souhaité de votre infrastructure. C'est le cœur d'Ansible.

### Qu'est-ce qu'un Playbook ?

**Définition :**
- Fichier de configuration déclaratif en YAML
- Décrit "ce que vous voulez" pas "comment le faire"
- Composé de "plays" qui contiennent des "tasks"
- Réutilisable, versionnable (Git), auditable

**Philosophie :**
```
Infrastructure as Code (IaC)
  ↓
Playbook décrit l'état souhaité
  ↓
Ansible applique les changements nécessaires
  ↓
Idempotence : même résultat à chaque exécution
```

### Playbook vs Ad-hoc Commands

**Ad-hoc command :**
```bash
# Une seule tâche, usage ponctuel
ansible webservers -m apt -a "name=nginx state=present" --become
```

**Playbook :**
```yaml
# Multiples tâches, reproductible, versionnable
---
- name: Configure web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Start nginx
      service:
        name: nginx
        state: started
```

**Quand utiliser quoi ?**

| Ad-hoc | Playbook |
|--------|----------|
| Debug rapide | Configuration complète |
| Test ponctuel | Déploiement |
| Gather facts | Orchestration |
| Commande unique | Automatisation répétée |

---

## Syntaxe YAML

YAML (YAML Ain't Markup Language) est un format de sérialisation de données lisible par l'homme.

### Règles de base

**1. Indentation (IMPORTANT !)**
```yaml
# ✅ CORRECT : 2 espaces
- name: Install packages
  apt:
    name: nginx
    state: present

# ❌ INCORRECT : Tabulations ou 4 espaces
- name: Install packages
    apt:
        name: nginx
```

**Règle d'or :** Utilisez TOUJOURS 2 espaces, JAMAIS de tabulations.

**2. Listes (Arrays)**
```yaml
# Style 1 : Tirets
packages:
  - nginx
  - curl
  - vim

# Style 2 : Inline (moins lisible)
packages: [nginx, curl, vim]
```

**3. Dictionnaires (Objects)**
```yaml
# Style 1 : Multi-ligne (recommandé)
user:
  name: john
  age: 30
  admin: true

# Style 2 : Inline
user: {name: john, age: 30, admin: true}
```

**4. Chaînes de caractères**
```yaml
# Sans quotes (simple)
message: Hello World

# Avec quotes simples (littéral)
message: 'L''apostrophe doit être échappée'

# Avec quotes doubles (interprétation)
message: "Hello\nWorld"  # Avec newline

# Multi-ligne avec |
script: |
  #!/bin/bash
  echo "Line 1"
  echo "Line 2"

# Multi-ligne avec > (une seule ligne)
description: >
  This is a very long
  description that spans
  multiple lines
```

**5. Booléens**
```yaml
# Valeurs acceptées pour true
enabled: true
enabled: True
enabled: yes
enabled: on

# Valeurs acceptées pour false
enabled: false
enabled: False
enabled: no
enabled: off
```

**6. Variables et Jinja2**
```yaml
# Variables
message: "Hello {{ username }}"

# Avec quotes (obligatoire si commence par {{)
message: "{{ greeting }} World"

# Sans quotes (erreur !)
# message: {{ greeting }} World  # ❌
```

### Exemple complet YAML

```yaml
---
# Début du document
- name: Example playbook
  hosts: all
  vars:
    app_name: myapp
    app_version: 1.0.0
    packages:
      - nginx
      - curl
      - git
    config:
      port: 80
      workers: 4
  tasks:
    - name: Install packages
      apt:
        name: "{{ packages }}"
        state: present

    - name: Create config
      template:
        src: config.j2
        dest: "/etc/{{ app_name }}/config.yml"
        owner: root
        group: root
        mode: '0644'
```

---

## Structure d'un Playbook

### Anatomie d'un Playbook

```yaml
---
# play.yml
- name: First play                    # Nom du play
  hosts: webservers                   # Hosts cibles
  become: yes                         # Élévation privilèges (sudo)
  vars:                               # Variables
    http_port: 80
  tasks:                              # Liste des tâches
    - name: Install Apache
      apt:
        name: apache2
        state: present

    - name: Start Apache
      service:
        name: apache2
        state: started

- name: Second play                   # Deuxième play
  hosts: databases
  tasks:
    - name: Install MySQL
      apt:
        name: mysql-server
        state: present
```

### Composants d'un Play

**1. name (optionnel mais recommandé)**
```yaml
- name: Configure web servers  # Description lisible
```

**2. hosts (obligatoire)**
```yaml
# Un groupe
hosts: webservers

# Plusieurs groupes
hosts: webservers:databases

# Tous les hosts
hosts: all

# Pattern
hosts: web*.example.com

# Exclusion
hosts: webservers:!web1
```

**3. become (élévation privilèges)**
```yaml
# Au niveau du play
- name: Play with sudo
  hosts: all
  become: yes        # Exécuter en sudo
  become_user: root  # Utilisateur cible (défaut: root)

# Au niveau d'une task
- name: Install package
  apt:
    name: nginx
    state: present
  become: yes  # Juste cette tâche en sudo
```

**4. vars (variables)**
```yaml
- name: Play with variables
  hosts: all
  vars:
    http_port: 80
    max_clients: 200
    server_name: example.com
  tasks:
    - name: Use variable
      debug:
        msg: "Port is {{ http_port }}"
```

**5. tasks (tâches)**
```yaml
tasks:
  - name: First task
    module_name:
      param1: value1
      param2: value2

  - name: Second task
    another_module:
      param: value
```

---

## Tasks et Plays

### Définition d'une Task

Une **task** est l'unité de travail la plus petite dans Ansible.

```yaml
- name: Install nginx           # Nom descriptif
  apt:                          # Module
    name: nginx                 # Paramètre 1
    state: present              # Paramètre 2
    update_cache: yes           # Paramètre 3
```

**Composants d'une task :**
- `name` : Description (optionnel mais fortement recommandé)
- Module : Action à exécuter (`apt`, `service`, `copy`, etc.)
- Paramètres : Arguments du module

### Modules courants

**1. Gestion de packages**
```yaml
# APT (Debian/Ubuntu)
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

# YUM (RHEL/CentOS)
- name: Install httpd
  yum:
    name: httpd
    state: present

# DNF (Fedora)
- name: Install nginx
  dnf:
    name: nginx
    state: present

# Package (abstraction multi-OS)
- name: Install package
  package:
    name: nginx
    state: present
```

**2. Gestion de services**
```yaml
- name: Start and enable nginx
  service:
    name: nginx
    state: started    # started, stopped, restarted, reloaded
    enabled: yes      # Démarrage automatique
```

**3. Gestion de fichiers**
```yaml
# Copier un fichier
- name: Copy configuration
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'

# Créer un fichier/répertoire
- name: Create directory
  file:
    path: /var/www/html
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

# Télécharger un fichier
- name: Download file
  get_url:
    url: https://example.com/file.tar.gz
    dest: /tmp/file.tar.gz
    mode: '0755'
```

**4. Exécution de commandes**
```yaml
# Command (simple)
- name: Run command
  command: /usr/bin/uptime

# Shell (avec pipes, redirections)
- name: Run shell command
  shell: cat /etc/passwd | grep root > /tmp/root.txt

# Script
- name: Run script
  script: /path/to/script.sh
```

### Exemple de Playbook complet

```yaml
---
# webserver.yml
- name: Configure web server
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    server_name: example.com

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Create web root directory
      file:
        path: /var/www/{{ server_name }}
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: Copy index.html
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head><title>{{ server_name }}</title></head>
          <body><h1>Welcome to {{ server_name }}</h1></body>
          </html>
        dest: /var/www/{{ server_name }}/index.html
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Copy nginx configuration
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/sites-available/{{ server_name }}
        owner: root
        group: root
        mode: '0644'
      notify: Reload nginx

    - name: Enable site
      file:
        src: /etc/nginx/sites-available/{{ server_name }}
        dest: /etc/nginx/sites-enabled/{{ server_name }}
        state: link
      notify: Reload nginx

    - name: Start and enable nginx
      service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

---

## Handlers et Notifications

Les **handlers** sont des tâches spéciales qui s'exécutent SEULEMENT quand elles sont notifiées.

### Pourquoi utiliser les Handlers ?

**Problème sans handlers :**
```yaml
# Sans handlers : Nginx redémarre à chaque run, même sans changement
- name: Copy config
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf

- name: Restart nginx  # ❌ Redémarre TOUJOURS
  service:
    name: nginx
    state: restarted
```

**Solution avec handlers :**
```yaml
# Avec handlers : Nginx redémarre SEULEMENT si config change
- name: Copy config
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx  # Notification conditionnelle

handlers:
  - name: Restart nginx  # ✅ Redémarre SEULEMENT si notifié
    service:
      name: nginx
      state: restarted
```

### Fonctionnement des Handlers

**1. Définition**
```yaml
handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted

  - name: Reload nginx
    service:
      name: nginx
      state: reloaded

  - name: Restart php-fpm
    service:
      name: php-fpm
      state: restarted
```

**2. Notification**
```yaml
tasks:
  - name: Copy nginx config
    copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx  # Notifie le handler

  - name: Copy php config
    copy:
      src: php.ini
      dest: /etc/php/php.ini
    notify: Restart php-fpm
```

**3. Plusieurs notifications**
```yaml
- name: Update nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify:
    - Restart nginx
    - Send notification email
```

### Ordre d'exécution des Handlers

**Important :** Les handlers s'exécutent :
1. À la **fin du play** (pas immédiatement)
2. **Une seule fois**, même notifiés plusieurs fois
3. Dans l'**ordre de définition** dans la section `handlers`

**Exemple :**
```yaml
---
- name: Handler execution order
  hosts: localhost
  tasks:
    - name: Task 1
      debug:
        msg: "Task 1"
      notify: Handler A
      changed_when: true

    - name: Task 2
      debug:
        msg: "Task 2"
      notify: Handler B
      changed_when: true

    - name: Task 3
      debug:
        msg: "Task 3"
      notify: Handler A  # Handler A notifié 2 fois
      changed_when: true

  handlers:
    - name: Handler A
      debug:
        msg: "Handler A executed"  # S'exécute 1 seule fois

    - name: Handler B
      debug:
        msg: "Handler B executed"

# Ordre d'exécution :
# 1. Task 1
# 2. Task 2
# 3. Task 3
# 4. Handler A (une fois, malgré 2 notifications)
# 5. Handler B
```

### Forcer l'exécution immédiate

```yaml
tasks:
  - name: Copy config
    copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx

  - name: Flush handlers NOW
    meta: flush_handlers  # Exécute les handlers immédiatement

  - name: Test nginx
    uri:
      url: http://localhost
      status_code: 200
```

---

## Idempotence

L'**idempotence** garantit que l'exécution répétée d'un playbook produit le même résultat.

### Principe

```
État initial : Package non installé
  ↓
Run 1 : Installer le package (changed=true)
  ↓
État final : Package installé
  ↓
Run 2 : Package déjà installé (changed=false, ok=true)
  ↓
État final : Package installé (identique)
```

### Modules idempotents

**La plupart des modules Ansible sont idempotents :**

```yaml
# ✅ Idempotent
- name: Ensure nginx is installed
  apt:
    name: nginx
    state: present
# Run 1: installe nginx (changed)
# Run 2+: nginx déjà présent (ok, pas de changement)

# ✅ Idempotent
- name: Ensure directory exists
  file:
    path: /var/www/html
    state: directory
    owner: www-data
# Run 1: crée le répertoire (changed)
# Run 2+: répertoire existe déjà (ok)

# ✅ Idempotent
- name: Ensure service is running
  service:
    name: nginx
    state: started
# Run 1: démarre nginx (changed)
# Run 2+: nginx déjà démarré (ok)
```

### Modules NON idempotents

**Modules command/shell ne sont PAS idempotents par défaut :**

```yaml
# ❌ NON idempotent
- name: Install package
  command: apt-get install nginx
# S'exécute à chaque run, même si nginx installé

# ❌ NON idempotent
- name: Append to file
  shell: echo "text" >> /tmp/file.txt
# Ajoute "text" à chaque run
```

### Rendre command/shell idempotents

**Technique 1 : creates / removes**
```yaml
# ✅ Idempotent avec creates
- name: Download and extract
  command: tar -xzf /tmp/archive.tar.gz -C /opt/
  args:
    creates: /opt/extracted_folder
# Ne s'exécute que si /opt/extracted_folder n'existe pas

# ✅ Idempotent avec removes
- name: Remove old files
  command: rm -rf /tmp/old_data
  args:
    removes: /tmp/old_data
# Ne s'exécute que si /tmp/old_data existe
```

**Technique 2 : changed_when**
```yaml
- name: Check if service is running
  command: systemctl is-active nginx
  register: result
  changed_when: false  # Ne jamais marquer comme changed
  failed_when: result.rc not in [0, 3]

- name: Restart if not running
  service:
    name: nginx
    state: restarted
  when: result.rc != 0
```

**Technique 3 : Conditions**
```yaml
- name: Check if file exists
  stat:
    path: /etc/myapp/config.yml
  register: config_file

- name: Create config only if doesn't exist
  command: /usr/bin/generate-config.sh
  when: not config_file.stat.exists
```

### Tester l'idempotence

```bash
# Run 1 : Changements attendus
ansible-playbook site.yml
# PLAY RECAP: changed=10

# Run 2 : Aucun changement
ansible-playbook site.yml
# PLAY RECAP: changed=0  ✅ Idempotent !

# Si changed > 0 sur run 2 : NON idempotent ❌
```

---

## Check Mode et Diff

### Check Mode (Dry-run)

Le **check mode** simule l'exécution sans appliquer les changements.

```bash
# Dry-run : voir ce qui serait changé
ansible-playbook site.yml --check

# Alias
ansible-playbook site.yml -C
```

**Exemple :**
```yaml
# playbook.yml
- name: Install packages
  hosts: all
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
```

```bash
$ ansible-playbook playbook.yml --check

TASK [Install nginx] ***********
changed: [web1]  # Serait changé, mais pas appliqué

PLAY RECAP *********************
web1 : ok=1 changed=1  # Changed, mais rien n'a été fait
```

**Forcer une tâche en check mode :**
```yaml
# Toujours exécuter, même en check mode
- name: Get system info
  command: uptime
  check_mode: no

# Ne JAMAIS exécuter en check mode
- name: Dangerous operation
  command: rm -rf /tmp/*
  check_mode: yes
```

### Diff Mode

Le **diff mode** affiche les différences de fichiers avant/après.

```bash
# Afficher les diffs
ansible-playbook site.yml --diff

# Combiner check + diff
ansible-playbook site.yml --check --diff
```

**Exemple :**
```yaml
- name: Update config file
  copy:
    content: |
      server {
        listen 80;
        server_name example.com;
      }
    dest: /etc/nginx/sites-available/default
```

```bash
$ ansible-playbook playbook.yml --diff

TASK [Update config file] *******
--- before: /etc/nginx/sites-available/default
+++ after: /tmp/tmpXXXXXX
@@ -1,3 +1,4 @@
 server {
-  listen 8080;
+  listen 80;
   server_name example.com;
 }
changed: [web1]
```

---

## Tags

Les **tags** permettent d'exécuter seulement certaines parties d'un playbook.

### Définition des Tags

```yaml
---
- name: Full configuration
  hosts: webservers
  tasks:
    - name: Install packages
      apt:
        name:
          - nginx
          - curl
          - vim
      tags:
        - install
        - packages

    - name: Copy nginx config
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
      tags:
        - config
        - nginx

    - name: Start nginx
      service:
        name: nginx
        state: started
      tags:
        - service
        - nginx

    - name: Deploy application
      copy:
        src: app/
        dest: /var/www/app/
      tags:
        - deploy
        - app
```

### Utilisation des Tags

```bash
# Exécuter seulement les tasks avec tag "install"
ansible-playbook site.yml --tags install

# Exécuter plusieurs tags
ansible-playbook site.yml --tags "install,config"

# Exécuter tout SAUF certains tags
ansible-playbook site.yml --skip-tags deploy

# Lister tous les tags disponibles
ansible-playbook site.yml --list-tags

# Lister les tasks par tag
ansible-playbook site.yml --tags install --list-tasks
```

### Tags spéciaux

```yaml
# Tag "always" : S'exécute TOUJOURS
- name: Check prerequisites
  command: which python3
  tags: always

# Tag "never" : Ne s'exécute JAMAIS (sauf si explicitement appelé)
- name: Dangerous cleanup
  file:
    path: /var/data
    state: absent
  tags: never
```

```bash
# "always" s'exécute même avec --tags
ansible-playbook site.yml --tags deploy
# La task "Check prerequisites" s'exécute aussi

# "never" ne s'exécute que si explicitement appelé
ansible-playbook site.yml --tags never
```

### Tags au niveau du play

```yaml
---
- name: Install phase
  hosts: all
  tags: install
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present

- name: Configure phase
  hosts: all
  tags: config
  tasks:
    - name: Copy config
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
```

```bash
# Exécuter seulement le play "install"
ansible-playbook site.yml --tags install
```

---

## Gestion des erreurs

### Ignorer les erreurs

```yaml
# Ignorer les erreurs et continuer
- name: Command that might fail
  command: /usr/bin/might-fail
  ignore_errors: yes

# Continuer même si cette task échoue
- name: Try to stop service
  service:
    name: nginx
    state: stopped
  ignore_errors: yes
```

### any_errors_fatal

```yaml
# Arrêter TOUT le playbook si une erreur sur un host
- name: Critical play
  hosts: all
  any_errors_fatal: yes
  tasks:
    - name: Critical task
      command: /critical/operation
```

### failed_when

Personnaliser les conditions d'échec :

```yaml
# Échec si code retour != 0 et != 2
- name: Check service
  command: systemctl is-active nginx
  register: result
  failed_when: result.rc not in [0, 2]

# Échec si output contient "ERROR"
- name: Run script
  shell: /opt/script.sh
  register: result
  failed_when: "'ERROR' in result.stdout"

# Ne jamais échouer
- name: Always succeed
  command: /might/fail
  failed_when: false
```

### changed_when

Personnaliser les conditions de "changed" :

```yaml
# Jamais marquer comme changed
- name: Read-only check
  command: cat /etc/passwd
  register: result
  changed_when: false

# Changed si output contient "Updated"
- name: Update script
  shell: /opt/update.sh
  register: result
  changed_when: "'Updated' in result.stdout"

# Changed si code retour = 0
- name: Conditional change
  command: /usr/bin/update
  register: result
  changed_when: result.rc == 0
```

### Blocks pour gestion d'erreurs

```yaml
tasks:
  - name: Error handling with blocks
    block:
      - name: Try this first
        command: /might/fail

      - name: Then this
        command: /another/command

    rescue:
      - name: Run if block fails
        debug:
          msg: "Block failed, running rescue"

      - name: Cleanup
        file:
          path: /tmp/cleanup
          state: absent

    always:
      - name: Always run this
        debug:
          msg: "This runs whether block succeeded or failed"
```

**Exemple concret :**
```yaml
- name: Deploy application with rollback
  block:
    - name: Stop application
      service:
        name: myapp
        state: stopped

    - name: Deploy new version
      copy:
        src: app-v2.0.tar.gz
        dest: /opt/myapp/

    - name: Extract
      unarchive:
        src: /opt/myapp/app-v2.0.tar.gz
        dest: /opt/myapp/
        remote_src: yes

    - name: Start application
      service:
        name: myapp
        state: started

    - name: Health check
      uri:
        url: http://localhost:8080/health
        status_code: 200
      retries: 5
      delay: 10

  rescue:
    - name: Rollback - Restore backup
      copy:
        src: /opt/myapp/backup/
        dest: /opt/myapp/
        remote_src: yes

    - name: Restart application
      service:
        name: myapp
        state: restarted

    - name: Send alert
      debug:
        msg: "Deployment failed! Rolled back to previous version."

  always:
    - name: Cleanup temporary files
      file:
        path: /opt/myapp/app-v2.0.tar.gz
        state: absent
```

---

## Bonnes pratiques

### 1. Nommage

```yaml
# ✅ BON : Nom descriptif
- name: Install nginx web server on Ubuntu
  apt:
    name: nginx
    state: present

# ❌ MAUVAIS : Pas de nom
- apt:
    name: nginx
    state: present

# ❌ MAUVAIS : Nom vague
- name: Install package
  apt:
    name: nginx
```

### 2. Structure du playbook

```yaml
# ✅ BON : Structure claire et organisée
---
- name: Configure web servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200

  tasks:
    - name: Install packages
      apt:
        name:
          - nginx
          - curl
        state: present

    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Reload nginx

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

### 3. Idempotence

```yaml
# ✅ BON : Utiliser les modules appropriés
- name: Ensure line in file
  lineinfile:
    path: /etc/hosts
    line: "192.168.1.10 server1"

# ❌ MAUVAIS : Utiliser shell
- name: Add line to file
  shell: echo "192.168.1.10 server1" >> /etc/hosts
```

### 4. Variables

```yaml
# ✅ BON : Utiliser des variables
vars:
  app_port: 8080
  app_name: myapp

tasks:
  - name: Configure app
    template:
      src: config.j2
      dest: "/etc/{{ app_name }}/config.yml"

# ❌ MAUVAIS : Valeurs en dur
- name: Configure app
  template:
    src: config.j2
    dest: /etc/myapp/config.yml
```

### 5. Handlers

```yaml
# ✅ BON : Utiliser handlers
- name: Copy config
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf
  notify: Restart nginx

handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted

# ❌ MAUVAIS : Redémarrer systématiquement
- name: Copy config
  copy:
    src: nginx.conf
    dest: /etc/nginx/nginx.conf

- name: Restart nginx
  service:
    name: nginx
    state: restarted
```

### 6. Organisation

```
# Structure recommandée
playbooks/
├── site.yml              # Playbook principal
├── webservers.yml        # Playbook web servers
├── databases.yml         # Playbook databases
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   └── databases.yml
├── host_vars/
│   └── web1.yml
├── inventory/
│   ├── production
│   └── staging
├── roles/
│   ├── nginx/
│   └── mysql/
└── files/
    └── configs/
```

---

## Exemples complets

### Exemple 1 : Installation LAMP Stack

```yaml
---
# lamp-stack.yml
- name: Install LAMP stack
  hosts: webservers
  become: yes
  vars:
    mysql_root_password: "StrongPassword123!"
    php_version: "8.1"

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      tags: install

    - name: Install Apache
      apt:
        name: apache2
        state: present
      tags: install

    - name: Install MySQL
      apt:
        name:
          - mysql-server
          - python3-pymysql
        state: present
      tags: install

    - name: Install PHP
      apt:
        name:
          - "php{{ php_version }}"
          - "php{{ php_version }}-mysql"
          - "libapache2-mod-php{{ php_version }}"
        state: present
      tags: install

    - name: Start and enable Apache
      service:
        name: apache2
        state: started
        enabled: yes
      tags: service

    - name: Start and enable MySQL
      service:
        name: mysql
        state: started
        enabled: yes
      tags: service

    - name: Create info.php
      copy:
        content: |
          <?php
          phpinfo();
          ?>
        dest: /var/www/html/info.php
        owner: www-data
        group: www-data
        mode: '0644'
      tags: deploy

    - name: Remove default index.html
      file:
        path: /var/www/html/index.html
        state: absent
      tags: deploy
```

### Exemple 2 : Déploiement avec rollback

```yaml
---
# deploy-with-rollback.yml
- name: Deploy application with rollback capability
  hosts: appservers
  become: yes
  vars:
    app_name: myapp
    app_version: "2.0.0"
    deploy_dir: "/opt/{{ app_name }}"
    backup_dir: "{{ deploy_dir }}/backup"

  tasks:
    - name: Create backup of current version
      block:
        - name: Check if app directory exists
          stat:
            path: "{{ deploy_dir }}"
          register: app_dir

        - name: Backup current version
          synchronize:
            src: "{{ deploy_dir }}/"
            dest: "{{ backup_dir }}/"
            mode: push
          delegate_to: "{{ inventory_hostname }}"
          when: app_dir.stat.exists
      tags: backup

    - name: Deploy new version
      block:
        - name: Stop application
          service:
            name: "{{ app_name }}"
            state: stopped

        - name: Copy new version
          unarchive:
            src: "files/{{ app_name }}-{{ app_version }}.tar.gz"
            dest: "{{ deploy_dir }}"
            owner: appuser
            group: appuser

        - name: Update configuration
          template:
            src: config.j2
            dest: "{{ deploy_dir }}/config.yml"

        - name: Start application
          service:
            name: "{{ app_name }}"
            state: started

        - name: Wait for application to be healthy
          uri:
            url: "http://localhost:8080/health"
            status_code: 200
          retries: 10
          delay: 5

      rescue:
        - name: Deployment failed - Rolling back
          debug:
            msg: "Deployment failed! Rolling back to previous version."

        - name: Stop failed version
          service:
            name: "{{ app_name }}"
            state: stopped

        - name: Restore backup
          synchronize:
            src: "{{ backup_dir }}/"
            dest: "{{ deploy_dir }}/"
            mode: push
          delegate_to: "{{ inventory_hostname }}"

        - name: Start previous version
          service:
            name: "{{ app_name }}"
            state: started

        - name: Fail playbook
          fail:
            msg: "Deployment failed and was rolled back"

      tags: deploy
```

---

## Prochaines étapes

Maintenant que vous maîtrisez les playbooks, passez au module suivant :

**[04-Inventory](../04-Inventory/README.md)**

Vous allez apprendre à :
- Créer des inventaires statiques (INI et YAML)
- Utiliser des inventaires dynamiques
- Organiser les hosts en groupes
- Gérer les variables d'inventaire
- Utiliser les inventory plugins

---

**"A playbook is a recipe for your infrastructure. Make it clear, make it idempotent, make it reusable."**
