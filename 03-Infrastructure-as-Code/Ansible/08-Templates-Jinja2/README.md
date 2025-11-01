# Templates avec Jinja2

## Table des matières

1. [Introduction à Jinja2](#introduction-à-jinja2)
2. [Syntaxe de base](#syntaxe-de-base)
3. [Variables et Expressions](#variables-et-expressions)
4. [Conditions](#conditions)
5. [Boucles](#boucles)
6. [Filters](#filters)
7. [Macros](#macros)
8. [Templates de configuration](#templates-de-configuration)

---

## Introduction à Jinja2

**Jinja2** est un moteur de templates Python utilisé par Ansible pour générer dynamiquement des fichiers de configuration.

### Qu'est-ce qu'un Template ?

**Définition :**
- Fichier avec des variables et de la logique
- Extension `.j2` par convention
- Généré dynamiquement par Ansible
- Utilisé avec le module `template`

**Pourquoi utiliser des templates ?**
- **Configuration dynamique** : Adapter aux environnements
- **Réutilisabilité** : Un template pour plusieurs hosts
- **Maintenabilité** : Une seule source de vérité
- **Lisibilité** : Séparer logique et configuration

### Template vs Copie

```yaml
# ❌ MAUVAIS : Copier des fichiers statiques différents
- name: Copy nginx config for web1
  copy:
    src: nginx-web1.conf
    dest: /etc/nginx/nginx.conf

- name: Copy nginx config for web2
  copy:
    src: nginx-web2.conf
    dest: /etc/nginx/nginx.conf

# ✅ BON : Un template dynamique
- name: Deploy nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
  notify: Reload nginx
```

---

## Syntaxe de base

### Délimiteurs Jinja2

```jinja
{# Commentaire (non affiché dans le résultat) #}

{{ variable }}           {# Variable : affiche la valeur #}

{% instruction %}        {# Instruction : logique, boucles, conditions #}

{{ variable | filter }}  {# Filter : transforme la valeur #}
```

### Exemple simple

**Template : `greeting.j2`**
```jinja
Hello {{ name }}!
Your IP address is {{ ansible_default_ipv4.address }}
Today is {{ ansible_date_time.date }}
```

**Playbook :**
```yaml
- name: Generate greeting
  template:
    src: greeting.j2
    dest: /tmp/greeting.txt
  vars:
    name: John
```

**Résultat : `/tmp/greeting.txt`**
```
Hello John!
Your IP address is 192.168.1.10
Today is 2024-01-15
```

---

## Variables et Expressions

### Variables simples

```jinja
{# String #}
Server name: {{ server_name }}

{# Number #}
Port: {{ http_port }}

{# Boolean #}
SSL Enabled: {{ ssl_enabled }}

{# Liste #}
First package: {{ packages[0] }}
Last package: {{ packages[-1] }}

{# Dictionnaire #}
Database host: {{ database.host }}
Database port: {{ database.port }}
```

### Expressions

```jinja
{# Opérations mathématiques #}
Total memory: {{ ansible_memtotal_mb * 1024 }} KB
Half of cores: {{ ansible_processor_vcpus / 2 }}

{# Concaténation #}
Full URL: http://{{ server_name }}:{{ port }}/{{ path }}

{# Comparaison #}
Is production: {{ environment == 'production' }}
Has enough memory: {{ ansible_memtotal_mb > 4096 }}
```

### Valeurs par défaut

```jinja
{# Valeur par défaut si variable non définie #}
Port: {{ http_port | default(80) }}

{# Valeur par défaut si variable vide #}
Name: {{ server_name | default('localhost', true) }}

{# Valeur par défaut avec variable #}
Backend: {{ backend_host | default(ansible_default_ipv4.address) }}
```

### Échappement

```jinja
{# Afficher littéralement {{ }} #}
{% raw %}
  This will show: {{ variable }}
{% endraw %}

{# Résultat : This will show: {{ variable }} #}
```

---

## Conditions

### if / elif / else

```jinja
{% if ansible_os_family == "Debian" %}
Package manager: apt
{% elif ansible_os_family == "RedHat" %}
Package manager: yum
{% else %}
Package manager: unknown
{% endif %}
```

### Opérateurs de comparaison

```jinja
{% if ansible_memtotal_mb > 8192 %}
Large server (> 8 GB)
{% elif ansible_memtotal_mb > 4096 %}
Medium server (> 4 GB)
{% else %}
Small server (<= 4 GB)
{% endif %}

{# Opérateurs disponibles: ==, !=, <, >, <=, >=, in, not in #}

{% if 'production' in group_names %}
Production environment
{% endif %}

{% if ssl_enabled is defined and ssl_enabled %}
SSL is enabled
{% endif %}
```

### Opérateurs logiques

```jinja
{% if ssl_enabled and port == 443 %}
HTTPS configuration
{% endif %}

{% if environment == 'production' or environment == 'staging' %}
Non-development environment
{% endif %}

{% if not debug_mode %}
Logging disabled
{% endif %}
```

### Tests Jinja2

```jinja
{% if my_variable is defined %}
Variable is defined
{% endif %}

{% if my_variable is undefined %}
Variable is not defined
{% endif %}

{% if my_list is iterable %}
This is a list
{% endif %}

{% if my_value is number %}
This is a number
{% endif %}

{% if my_string is string %}
This is a string
{% endif %}

{% if result is success %}
Task succeeded
{% endif %}

{% if result is failed %}
Task failed
{% endif %}
```

---

## Boucles

### for loop - Liste

```jinja
{# Liste simple #}
{% for package in packages %}
  - {{ package }}
{% endfor %}

{# Avec index #}
{% for package in packages %}
{{ loop.index }}. {{ package }}
{% endfor %}

{# Résultat :
1. nginx
2. curl
3. vim
#}
```

### for loop - Dictionnaire

```jinja
{% for key, value in database.items() %}
{{ key }}: {{ value }}
{% endfor %}

{# Résultat :
host: localhost
port: 3306
name: mydb
#}
```

### Variables de boucle

```jinja
{% for item in items %}
Index: {{ loop.index }}      {# 1, 2, 3, ... #}
Index0: {{ loop.index0 }}    {# 0, 1, 2, ... #}
First: {{ loop.first }}      {# True si premier #}
Last: {{ loop.last }}        {# True si dernier #}
Length: {{ loop.length }}    {# Nombre total #}
{% endfor %}
```

### Exemple pratique : Hosts file

**Template : `hosts.j2`**
```jinja
# Generated by Ansible

127.0.0.1   localhost

# Application servers
{% for host in groups['appservers'] %}
{{ hostvars[host].ansible_default_ipv4.address }}   {{ host }}
{% endfor %}

# Database servers
{% for host in groups['databases'] %}
{{ hostvars[host].ansible_default_ipv4.address }}   {{ host }}
{% endfor %}
```

**Résultat : `/etc/hosts`**
```
# Generated by Ansible

127.0.0.1   localhost

# Application servers
10.0.1.10   app1
10.0.1.11   app2

# Database servers
10.0.2.10   db1
10.0.2.11   db2
```

### Boucle conditionnelle

```jinja
{% for host in groups['webservers'] %}
  {% if hostvars[host].ssl_enabled %}
server {{ host }}:443 ssl
  {% else %}
server {{ host }}:80
  {% endif %}
{% endfor %}
```

### else dans une boucle

```jinja
{% for user in users %}
  - {{ user }}
{% else %}
  No users defined
{% endfor %}
```

---

## Filters

Les **filters** transforment les valeurs des variables.

### Filters de chaînes

```jinja
{# upper / lower #}
{{ "hello" | upper }}           → HELLO
{{ "WORLD" | lower }}           → world

{# capitalize / title #}
{{ "hello world" | capitalize }} → Hello world
{{ "hello world" | title }}     → Hello World

{# replace #}
{{ "hello world" | replace("world", "ansible") }} → hello ansible

{# trim #}
{{ "  spaces  " | trim }}       → spaces

{# default #}
{{ undefined_var | default("default value") }}
```

### Filters de listes

```jinja
{# length #}
{{ packages | length }}         → 3

{# first / last #}
{{ packages | first }}          → nginx
{{ packages | last }}           → vim

{# join #}
{{ packages | join(', ') }}     → nginx, curl, vim

{# unique #}
{{ [1, 2, 2, 3] | unique }}     → [1, 2, 3]

{# sort #}
{{ packages | sort }}           → [curl, nginx, vim]
{{ packages | sort(reverse=True) }} → [vim, nginx, curl]
```

### Filters de dictionnaires

```jinja
{# dict2items #}
{% for item in database | dict2items %}
{{ item.key }}: {{ item.value }}
{% endfor %}

{# items2dict (inverse) #}
{{ [{'key': 'host', 'value': 'localhost'}] | items2dict }}

{# combine (merge) #}
{{ default_config | combine(custom_config) }}
```

### Filters mathématiques

```jinja
{# int / float #}
{{ "42" | int }}                → 42
{{ "3.14" | float }}            → 3.14

{# round #}
{{ 3.14159 | round(2) }}        → 3.14

{# abs #}
{{ -42 | abs }}                 → 42

{# min / max #}
{{ [1, 5, 3] | min }}           → 1
{{ [1, 5, 3] | max }}           → 5

{# sum #}
{{ [1, 2, 3] | sum }}           → 6
```

### Filters de fichiers

```jinja
{# basename #}
{{ "/path/to/file.txt" | basename }}        → file.txt

{# dirname #}
{{ "/path/to/file.txt" | dirname }}         → /path/to

{# expanduser #}
{{ "~/config" | expanduser }}               → /home/user/config
```

### Filters de format

```jinja
{# to_json / to_yaml #}
{{ my_dict | to_json }}
{{ my_dict | to_yaml }}

{# to_nice_json / to_nice_yaml (indented) #}
{{ my_dict | to_nice_json }}
{{ my_dict | to_nice_yaml }}

{# from_json / from_yaml #}
{{ json_string | from_json }}
{{ yaml_string | from_yaml }}
```

### Filters réseau

```jinja
{# ipaddr #}
{{ "192.168.1.0/24" | ipaddr }}             → 192.168.1.0/24
{{ "192.168.1.0/24" | ipaddr('address') }}  → 192.168.1.0
{{ "192.168.1.0/24" | ipaddr('netmask') }}  → 255.255.255.0

{# ipv4 / ipv6 #}
{{ ip_address | ipv4 }}
{{ ip_address | ipv6 }}
```

### Filters de hash/crypto

```jinja
{# hash #}
{{ "password" | hash('sha256') }}
{{ "password" | hash('md5') }}

{# password_hash #}
{{ password | password_hash('sha512') }}

{# b64encode / b64decode #}
{{ "hello" | b64encode }}       → aGVsbG8=
{{ "aGVsbG8=" | b64decode }}    → hello
```

### Filters personnalisés

```jinja
{# regex_search #}
{{ "version 1.2.3" | regex_search('[0-9.]+') }} → 1.2.3

{# regex_replace #}
{{ "Port: 8080" | regex_replace('Port: ([0-9]+)', 'Listen on \\1') }}
→ Listen on 8080

{# ternary (if-else inline) #}
{{ (ansible_memtotal_mb > 4096) | ternary('large', 'small') }}
```

---

## Macros

Les **macros** sont des fonctions réutilisables dans les templates.

### Définir une macro

```jinja
{% macro render_server(name, ip, port) %}
server {
    server_name {{ name }};
    listen {{ ip }}:{{ port }};
}
{% endmacro %}

{# Utiliser la macro #}
{{ render_server('example.com', '192.168.1.10', 80) }}
```

### Macro avec valeurs par défaut

```jinja
{% macro user_info(name, age=18, country='Unknown') %}
Name: {{ name }}
Age: {{ age }}
Country: {{ country }}
{% endmacro %}

{{ user_info('John') }}
{{ user_info('Jane', 25) }}
{{ user_info('Bob', 30, 'USA') }}
```

### Macro avec boucle

```jinja
{% macro render_backend_servers(servers) %}
backend app {
{% for server in servers %}
    server {{ server.name }} {{ server.ip }}:{{ server.port }};
{% endfor %}
}
{% endmacro %}

{{ render_backend_servers([
    {'name': 'app1', 'ip': '10.0.1.10', 'port': 8080},
    {'name': 'app2', 'ip': '10.0.1.11', 'port': 8080}
]) }}
```

### Import de macros

**macros/common.j2**
```jinja
{% macro nginx_server(domain, port=80) %}
server {
    listen {{ port }};
    server_name {{ domain }};
}
{% endmacro %}
```

**Template principal**
```jinja
{% from 'macros/common.j2' import nginx_server %}

{{ nginx_server('example.com') }}
{{ nginx_server('test.com', 8080) }}
```

---

## Templates de configuration

### Nginx configuration

**nginx.conf.j2**
```jinja
# Generated by Ansible - DO NOT EDIT MANUALLY

user {{ nginx_user }};
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections }};
    use epoll;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log {{ nginx_log_path }}/access.log;
    error_log {{ nginx_log_path }}/error.log;

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";
    gzip_types text/plain text/css application/json;

    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### HAProxy configuration

**haproxy.cfg.j2**
```jinja
# Generated by Ansible

global
    log /dev/log local0
    maxconn {{ haproxy_max_connections }}
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# Frontend
frontend http-in
    bind *:{{ haproxy_frontend_port }}
{% if ssl_enabled %}
    bind *:443 ssl crt /etc/ssl/certs/{{ server_name }}.pem
    redirect scheme https if !{ ssl_fc }
{% endif %}
    default_backend servers

# Backend
backend servers
    balance roundrobin
{% for host in groups['webservers'] %}
    server {{ host }} {{ hostvars[host].ansible_default_ipv4.address }}:{{ backend_port }} check
{% endfor %}

# Stats
listen stats
    bind *:{{ stats_port }}
    stats enable
    stats uri /stats
    stats refresh 30s
{% if stats_auth_enabled %}
    stats auth {{ stats_username }}:{{ stats_password }}
{% endif %}
```

### MySQL configuration

**my.cnf.j2**
```jinja
# Generated by Ansible

[mysqld]
# Basic Settings
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = {{ mysql_port }}
basedir = /usr
datadir = {{ mysql_datadir }}
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql

# Networking
bind-address = {{ mysql_bind_address }}
max_connections = {{ mysql_max_connections }}

# Memory Settings
{% if ansible_memtotal_mb > 8192 %}
innodb_buffer_pool_size = {{ (ansible_memtotal_mb * 0.6) | int }}M
{% else %}
innodb_buffer_pool_size = {{ (ansible_memtotal_mb * 0.4) | int }}M
{% endif %}

key_buffer_size = {{ mysql_key_buffer_size }}
max_allowed_packet = {{ mysql_max_allowed_packet }}

# Logging
log_error = {{ mysql_log_error }}
{% if mysql_slow_query_log %}
slow_query_log = 1
slow_query_log_file = {{ mysql_slow_query_log_file }}
long_query_time = {{ mysql_long_query_time }}
{% endif %}

# Replication
{% if mysql_replication_role == 'master' %}
server-id = {{ mysql_server_id }}
log_bin = {{ mysql_log_bin }}
binlog_format = {{ mysql_binlog_format }}
expire_logs_days = {{ mysql_expire_logs_days }}
max_binlog_size = {{ mysql_max_binlog_size }}
{% elif mysql_replication_role == 'slave' %}
server-id = {{ mysql_server_id }}
relay-log = {{ mysql_relay_log }}
read_only = 1
{% endif %}

[client]
port = {{ mysql_port }}
socket = /var/run/mysqld/mysqld.sock
```

### Application configuration

**app-config.yml.j2**
```jinja
# {{ ansible_managed }}

application:
  name: {{ app_name }}
  version: {{ app_version }}
  environment: {{ environment }}

server:
  host: {{ ansible_default_ipv4.address }}
  port: {{ app_port }}
  workers: {{ app_workers | default(ansible_processor_vcpus) }}

database:
  host: {{ db_host }}
  port: {{ db_port }}
  name: {{ db_name }}
  username: {{ db_username }}
  password: {{ db_password }}
  pool_size: {{ db_pool_size }}

cache:
{% if use_redis %}
  type: redis
  host: {{ redis_host }}
  port: {{ redis_port }}
  db: {{ redis_db }}
{% else %}
  type: memory
{% endif %}

logging:
  level: {{ log_level }}
  file: {{ log_file }}
  max_size: {{ log_max_size }}
  backup_count: {{ log_backup_count }}

features:
{% for feature in enabled_features %}
  - {{ feature }}
{% endfor %}

monitoring:
  enabled: {{ monitoring_enabled }}
{% if monitoring_enabled %}
  endpoint: {{ monitoring_endpoint }}
  interval: {{ monitoring_interval }}
{% endif %}
```

### Systemd service file

**myapp.service.j2**
```jinja
# {{ ansible_managed }}

[Unit]
Description={{ app_name }} Service
After=network.target
{% if app_requires_database %}
Requires=mysql.service
After=mysql.service
{% endif %}

[Service]
Type=simple
User={{ app_user }}
Group={{ app_group }}
WorkingDirectory={{ app_directory }}
ExecStart={{ app_binary }} --config {{ app_config }}
Restart={{ app_restart_policy }}
RestartSec={{ app_restart_delay }}

# Environment
Environment="APP_ENV={{ environment }}"
Environment="APP_PORT={{ app_port }}"
{% for key, value in app_environment.items() %}
Environment="{{ key }}={{ value }}"
{% endfor %}

# Limits
LimitNOFILE={{ app_max_open_files }}
{% if app_memory_limit %}
MemoryLimit={{ app_memory_limit }}
{% endif %}

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier={{ app_name }}

[Install]
WantedBy=multi-user.target
```

---

## Bonnes pratiques

### 1. Commentaires et documentation

```jinja
{#
  Nginx Configuration Template
  Maintainer: ops-team@example.com
  Last updated: 2024-01-15
#}

# {{ ansible_managed }}
# This file is managed by Ansible
# Manual changes will be overwritten
```

### 2. Validation

```yaml
- name: Deploy configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: 'nginx -t -c %s'  # Valider avant d'appliquer
  notify: Reload nginx
```

### 3. Indentation propre

```jinja
{# ✅ BON : Contrôler l'indentation #}
{% for item in items -%}
{{ item }}
{% endfor -%}

{# - supprime les espaces/newlines #}
{#- à gauche, -} à droite #}
```

### 4. Variables avec défaut

```jinja
{# ✅ BON : Toujours fournir des defaults #}
Port: {{ http_port | default(80) }}

{# ❌ MAUVAIS : Peut échouer si non défini #}
Port: {{ http_port }}
```

### 5. Séparer logique et présentation

```jinja
{# ✅ BON : Définir les variables en haut #}
{% set workers = ansible_processor_vcpus * 2 %}
{% set max_connections = workers * 1024 %}

worker_processes {{ workers }};
events {
    worker_connections {{ max_connections }};
}
```

---

## Exemples complets

### Playbook avec template

```yaml
---
- name: Configure web server
  hosts: webservers
  become: yes
  vars:
    nginx_user: www-data
    nginx_worker_processes: auto
    nginx_worker_connections: 1024
    server_name: example.com
    backend_servers:
      - { name: app1, ip: 10.0.1.10, port: 8080 }
      - { name: app2, ip: 10.0.1.11, port: 8080 }

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Deploy nginx configuration
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
        backup: yes
        validate: 'nginx -t -c %s'
      notify: Reload nginx

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

---

## Prochaines étapes

Maintenant que vous maîtrisez les templates Jinja2, passez au module suivant :

**[09-Ansible-Galaxy](../09-Ansible-Galaxy/README.md)**

Vous allez apprendre à :
- Utiliser des rôles Ansible Galaxy
- Créer et publier vos propres rôles
- Travailler avec les collections
- Gérer les dépendances avec requirements.yml
- Namespaces et versioning

---

**"Templates are where static configuration meets dynamic infrastructure."**
