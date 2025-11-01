# Projet 03 : Application Multi-Tier avec Haute Disponibilité

## Objectif

Déployer une application web 3-tiers complète (Frontend + Backend API + Database) avec haute disponibilité, réplication de base de données, load balancing, monitoring complet et pipeline CI/CD.

## Architecture

```
                    ┌─────────────────────────────────┐
                    │   Internet / Users              │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │   HAProxy + Keepalived (VIP)    │
                    │   192.168.1.100 (VIP)           │
                    │   192.168.1.10, 192.168.1.11    │
                    │   (Active/Passive HA)           │
                    └──────────────┬──────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
     ┌────────▼────────┐  ┌────────▼────────┐  ┌───────▼────────┐
     │  Frontend 1     │  │  Frontend 2     │  │  Frontend 3    │
     │  Nginx + React  │  │  Nginx + React  │  │  Nginx + React │
     │  192.168.1.21   │  │  192.168.1.22   │  │  192.168.1.23  │
     └────────┬────────┘  └────────┬────────┘  └───────┬────────┘
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
     ┌────────▼────────┐  ┌────────▼────────┐  ┌───────▼────────┐
     │  Backend 1      │  │  Backend 2      │  │  Backend 3     │
     │  Node.js API    │  │  Node.js API    │  │  Node.js API   │
     │  192.168.1.31   │  │  192.168.1.32   │  │  192.168.1.33  │
     └────────┬────────┘  └────────┬────────┘  └───────┬────────┘
              │                    │                    │
              └────────────────────┼────────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
     ┌────────▼────────┐  ┌────────▼────────────┐
     │  MySQL Master   │  │  MySQL Slave        │
     │  192.168.1.40   │──┤  192.168.1.41       │
     │  (Read/Write)   │  │  (Read Only)        │
     └─────────────────┘  └─────────────────────┘

Monitoring & Logging:
┌────────────────────────────────────────────────┐
│  Prometheus + Grafana + Alertmanager           │
│  192.168.1.50                                  │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  ELK Stack (Elasticsearch + Logstash + Kibana) │
│  192.168.1.60                                  │
└────────────────────────────────────────────────┘
```

## Stack Technique

### Frontend
- **Framework** : React 18.x avec Vite
- **Web Server** : Nginx
- **Features** : SPA, API consumption, responsive design

### Backend
- **Framework** : Node.js 20.x avec Express
- **Features** : REST API, JWT authentication, validation
- **ORM** : Sequelize ou Prisma
- **Cache** : Redis (optionnel)

### Database
- **SGBD** : MySQL 8.0 avec réplication Master-Slave
- **HA** : Réplication asynchrone
- **Backup** : Automatisé avec scripts

### Load Balancing
- **HAProxy** : Load balancer principal
- **Keepalived** : Gestion du VIP (Virtual IP)
- **Strategy** : Round-robin avec health checks

### Monitoring
- **Prometheus** : Collecte de métriques
- **Grafana** : Dashboards et visualisations
- **Alertmanager** : Gestion des alertes
- **Node Exporter** : Métriques système

### Logging
- **Elasticsearch** : Stockage des logs
- **Logstash** : Traitement des logs
- **Kibana** : Visualisation et recherche
- **Filebeat** : Collecte des logs

## Prérequis

- 12 serveurs Ubuntu 22.04 :
  - 2x HAProxy (2 CPU, 2 GB RAM)
  - 3x Frontend (2 CPU, 4 GB RAM)
  - 3x Backend (2 CPU, 4 GB RAM)
  - 2x Database (4 CPU, 8 GB RAM)
  - 1x Monitoring (4 CPU, 8 GB RAM)
  - 1x Logging (4 CPU, 8 GB RAM)
- Ansible 2.12+ installé
- Git, GitLab CI ou GitHub Actions pour CI/CD
- Connaissances : Web development, DevOps, HA concepts

## Structure du Projet

```
03-Multi-Tier-App/
├── README.md
├── ansible.cfg
├── inventory/
│   ├── production
│   ├── staging
│   └── group_vars/
│       ├── all.yml
│       ├── loadbalancers.yml
│       ├── frontend.yml
│       ├── backend.yml
│       ├── database.yml
│       ├── monitoring.yml
│       └── logging.yml
├── roles/
│   ├── common/
│   ├── haproxy/
│   ├── keepalived/
│   ├── nginx/
│   ├── nodejs/
│   ├── mysql-master/
│   ├── mysql-slave/
│   ├── frontend-app/
│   ├── backend-app/
│   ├── prometheus/
│   ├── grafana/
│   ├── elasticsearch/
│   ├── logstash/
│   ├── kibana/
│   └── filebeat/
├── playbooks/
│   ├── site.yml
│   ├── loadbalancers.yml
│   ├── frontend.yml
│   ├── backend.yml
│   ├── database.yml
│   ├── monitoring.yml
│   ├── logging.yml
│   ├── deploy-app.yml
│   └── rolling-update.yml
├── application/
│   ├── frontend/
│   │   ├── src/
│   │   ├── package.json
│   │   └── vite.config.js
│   └── backend/
│       ├── src/
│       ├── package.json
│       └── config/
├── ci-cd/
│   ├── .gitlab-ci.yml
│   └── Jenkinsfile
└── scripts/
    ├── backup-db.sh
    └── health-check.sh
```

## Tâches

### Phase 1 : Inventaire et Variables (1h)

#### Inventaire Production

**`inventory/production`** :
```ini
[loadbalancers]
lb01 ansible_host=192.168.1.10 keepalived_priority=100 keepalived_state=MASTER
lb02 ansible_host=192.168.1.11 keepalived_priority=90 keepalived_state=BACKUP

[frontend]
front01 ansible_host=192.168.1.21
front02 ansible_host=192.168.1.22
front03 ansible_host=192.168.1.23

[backend]
back01 ansible_host=192.168.1.31
back02 ansible_host=192.168.1.32
back03 ansible_host=192.168.1.33

[database_master]
db-master ansible_host=192.168.1.40

[database_slave]
db-slave ansible_host=192.168.1.41

[database:children]
database_master
database_slave

[monitoring]
monitoring ansible_host=192.168.1.50

[logging]
logging ansible_host=192.168.1.60

[app:children]
frontend
backend

[all:children]
loadbalancers
app
database
monitoring
logging
```

#### Variables Globales

**`inventory/group_vars/all.yml`** :
```yaml
---
# Configuration générale
ansible_user: ansible
ansible_become: yes

# Application
app_name: ecommerce
app_version: "{{ lookup('env', 'CI_COMMIT_TAG') | default('1.0.0', true) }}"
environment: production

# Network
virtual_ip: 192.168.1.100
virtual_ip_netmask: 24

# Timezone
server_timezone: Europe/Paris

# Secrets (utiliser Ansible Vault)
mysql_root_password: "{{ vault_mysql_root_password }}"
mysql_replication_password: "{{ vault_mysql_replication_password }}"
jwt_secret: "{{ vault_jwt_secret }}"
```

**`inventory/group_vars/database.yml`** :
```yaml
---
# MySQL Configuration
mysql_version: "8.0"
mysql_port: 3306

mysql_databases:
  - name: "{{ app_name }}_db"
    encoding: utf8mb4
    collation: utf8mb4_unicode_ci

mysql_users:
  - name: "{{ app_name }}_user"
    password: "{{ vault_mysql_app_password }}"
    priv: "{{ app_name }}_db.*:ALL"
    host: "192.168.1.%"

# Replication
mysql_server_id_master: 1
mysql_server_id_slave: 2
mysql_replication_user: replication
mysql_replication_password: "{{ vault_mysql_replication_password }}"

# Backup
mysql_backup_enabled: true
mysql_backup_retention_days: 7
```

**`inventory/group_vars/backend.yml`** :
```yaml
---
# Node.js Configuration
nodejs_version: "20.x"

# Application
backend_port: 3000
backend_repo: "https://gitlab.com/mycompany/ecommerce-backend.git"
backend_branch: "{{ lookup('env', 'CI_COMMIT_BRANCH') | default('main', true) }}"
backend_dir: "/opt/{{ app_name }}/backend"

# PM2 Configuration
pm2_instances: 4
pm2_max_memory: "512M"

# Environment variables
backend_env:
  NODE_ENV: production
  PORT: "{{ backend_port }}"
  DB_HOST: "192.168.1.40"
  DB_SLAVE_HOST: "192.168.1.41"
  DB_PORT: "{{ mysql_port }}"
  DB_NAME: "{{ app_name }}_db"
  DB_USER: "{{ app_name }}_user"
  DB_PASSWORD: "{{ vault_mysql_app_password }}"
  JWT_SECRET: "{{ jwt_secret }}"
  LOG_LEVEL: info
```

### Phase 2 : Rôle HAProxy avec Keepalived (1h 30min)

**`roles/haproxy/tasks/main.yml`** :
```yaml
---
- name: Install HAProxy
  apt:
    name: haproxy
    state: present
    update_cache: yes

- name: Configure HAProxy
  template:
    src: haproxy.cfg.j2
    dest: /etc/haproxy/haproxy.cfg
    validate: 'haproxy -c -f %s'
  notify: restart haproxy

- name: Enable HAProxy
  systemd:
    name: haproxy
    enabled: yes
    state: started

- name: Allow ports in firewall
  ufw:
    rule: allow
    port: "{{ item }}"
    proto: tcp
  loop:
    - "80"
    - "443"
    - "8404"  # Stats
```

**`roles/haproxy/templates/haproxy.cfg.j2`** :
```jinja
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
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
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Stats
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE

# Frontend HTTP
frontend http_front
    bind {{ virtual_ip }}:80
    mode http

    # ACL for API
    acl is_api path_beg /api

    # Route to backends
    use_backend backend_servers if is_api
    default_backend frontend_servers

# Backend Frontend
backend frontend_servers
    mode http
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
{% for host in groups['frontend'] %}
    server {{ host }} {{ hostvars[host]['ansible_host'] }}:80 check inter 2000 rise 2 fall 3
{% endfor %}

# Backend API
backend backend_servers
    mode http
    balance roundrobin
    option httpchk GET /api/health
    http-check expect status 200
{% for host in groups['backend'] %}
    server {{ host }} {{ hostvars[host]['ansible_host'] }}:{{ backend_port }} check inter 2000 rise 2 fall 3
{% endfor %}
```

**`roles/keepalived/tasks/main.yml`** :
```yaml
---
- name: Install Keepalived
  apt:
    name: keepalived
    state: present

- name: Configure Keepalived
  template:
    src: keepalived.conf.j2
    dest: /etc/keepalived/keepalived.conf
  notify: restart keepalived

- name: Enable IP forwarding
  sysctl:
    name: net.ipv4.ip_forward
    value: '1'
    state: present
    reload: yes

- name: Enable Keepalived
  systemd:
    name: keepalived
    enabled: yes
    state: started
```

**`roles/keepalived/templates/keepalived.conf.j2`** :
```jinja
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
}

vrrp_instance VI_1 {
    state {{ keepalived_state }}
    interface {{ ansible_default_ipv4.interface }}
    virtual_router_id 51
    priority {{ keepalived_priority }}
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass {{ vault_keepalived_password }}
    }

    virtual_ipaddress {
        {{ virtual_ip }}/{{ virtual_ip_netmask }}
    }

    track_script {
        chk_haproxy
    }
}
```

### Phase 3 : Rôle MySQL Master-Slave (2h)

**`roles/mysql-master/tasks/main.yml`** :
```yaml
---
- name: Install MySQL Server
  apt:
    name:
      - mysql-server
      - python3-pymysql
    state: present
    update_cache: yes

- name: Configure MySQL for replication
  template:
    src: my.cnf.j2
    dest: /etc/mysql/mysql.conf.d/replication.cnf
  notify: restart mysql

- name: Ensure MySQL is started
  systemd:
    name: mysql
    state: started
    enabled: yes

- name: Set MySQL root password
  mysql_user:
    name: root
    password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
    check_implicit_admin: yes

- name: Create application database
  mysql_db:
    name: "{{ item.name }}"
    encoding: "{{ item.encoding }}"
    collation: "{{ item.collation }}"
    login_user: root
    login_password: "{{ mysql_root_password }}"
    state: present
  loop: "{{ mysql_databases }}"

- name: Create application users
  mysql_user:
    name: "{{ item.name }}"
    password: "{{ item.password }}"
    priv: "{{ item.priv }}"
    host: "{{ item.host }}"
    login_user: root
    login_password: "{{ mysql_root_password }}"
    state: present
  loop: "{{ mysql_users }}"

- name: Create replication user
  mysql_user:
    name: "{{ mysql_replication_user }}"
    password: "{{ mysql_replication_password }}"
    priv: "*.*:REPLICATION SLAVE"
    host: "%"
    login_user: root
    login_password: "{{ mysql_root_password }}"
    state: present

- name: Get master status
  mysql_replication:
    mode: getprimary
    login_user: root
    login_password: "{{ mysql_root_password }}"
  register: master_status
  when: inventory_hostname in groups['database_master']

- name: Save master status
  set_fact:
    master_log_file: "{{ master_status.File }}"
    master_log_pos: "{{ master_status.Position }}"
  when: inventory_hostname in groups['database_master']
```

**`roles/mysql-master/templates/my.cnf.j2`** :
```jinja
[mysqld]
server-id = {{ mysql_server_id_master }}
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = {{ app_name }}_db
bind-address = 0.0.0.0

# Performance
max_connections = 500
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
```

**`roles/mysql-slave/tasks/main.yml`** :
```yaml
---
- name: Install MySQL Server
  apt:
    name:
      - mysql-server
      - python3-pymysql
    state: present

- name: Configure MySQL slave
  template:
    src: my.cnf.j2
    dest: /etc/mysql/mysql.conf.d/replication.cnf
  notify: restart mysql

- name: Start MySQL
  systemd:
    name: mysql
    state: started
    enabled: yes

- name: Set MySQL root password
  mysql_user:
    name: root
    password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
    check_implicit_admin: yes

- name: Stop slave
  mysql_replication:
    mode: stopreplica
    login_user: root
    login_password: "{{ mysql_root_password }}"
  ignore_errors: yes

- name: Configure slave replication
  mysql_replication:
    mode: changeprimary
    primary_host: "{{ hostvars[groups['database_master'][0]]['ansible_host'] }}"
    primary_user: "{{ mysql_replication_user }}"
    primary_password: "{{ mysql_replication_password }}"
    primary_log_file: "{{ hostvars[groups['database_master'][0]]['master_log_file'] }}"
    primary_log_pos: "{{ hostvars[groups['database_master'][0]]['master_log_pos'] }}"
    login_user: root
    login_password: "{{ mysql_root_password }}"

- name: Start slave
  mysql_replication:
    mode: startreplica
    login_user: root
    login_password: "{{ mysql_root_password }}"
```

### Phase 4 : Backend Node.js (1h 30min)

**`roles/backend-app/tasks/main.yml`** :
```yaml
---
- name: Install Node.js repository
  shell: curl -fsSL https://deb.nodesource.com/setup_{{ nodejs_version }} | bash -

- name: Install Node.js and npm
  apt:
    name:
      - nodejs
      - git
    state: present
    update_cache: yes

- name: Install PM2 globally
  npm:
    name: pm2
    global: yes
    state: present

- name: Create application directory
  file:
    path: "{{ backend_dir }}"
    state: directory
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0755'

- name: Clone backend repository
  git:
    repo: "{{ backend_repo }}"
    dest: "{{ backend_dir }}"
    version: "{{ backend_branch }}"
    force: yes
  become_user: "{{ ansible_user }}"

- name: Install npm dependencies
  npm:
    path: "{{ backend_dir }}"
    production: yes
  become_user: "{{ ansible_user }}"

- name: Create .env file
  template:
    src: env.j2
    dest: "{{ backend_dir }}/.env"
    owner: "{{ ansible_user }}"
    mode: '0600'

- name: Configure PM2 ecosystem
  template:
    src: ecosystem.config.js.j2
    dest: "{{ backend_dir }}/ecosystem.config.js"
    owner: "{{ ansible_user }}"

- name: Start application with PM2
  shell: |
    pm2 delete {{ app_name }}-api || true
    pm2 start ecosystem.config.js
    pm2 save
  args:
    chdir: "{{ backend_dir }}"
  become_user: "{{ ansible_user }}"

- name: Setup PM2 startup
  shell: |
    env PATH=$PATH:/usr/bin pm2 startup systemd -u {{ ansible_user }} --hp /home/{{ ansible_user }}
  args:
    creates: /etc/systemd/system/pm2-{{ ansible_user }}.service
```

**`roles/backend-app/templates/ecosystem.config.js.j2`** :
```javascript
module.exports = {
  apps: [{
    name: '{{ app_name }}-api',
    script: './src/server.js',
    instances: {{ pm2_instances }},
    exec_mode: 'cluster',
    max_memory_restart: '{{ pm2_max_memory }}',
    env: {
{% for key, value in backend_env.items() %}
      {{ key }}: '{{ value }}',
{% endfor %}
    },
    error_file: '/var/log/{{ app_name }}/api-error.log',
    out_file: '/var/log/{{ app_name }}/api-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
  }]
};
```

### Phase 5 : Frontend React (1h)

**`roles/frontend-app/tasks/main.yml`** :
```yaml
---
- name: Install Nginx
  apt:
    name: nginx
    state: present

- name: Create application directory
  file:
    path: "/var/www/{{ app_name }}"
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

- name: Clone frontend repository
  git:
    repo: "{{ frontend_repo }}"
    dest: "/tmp/{{ app_name }}-frontend"
    version: "{{ frontend_branch }}"
    force: yes

- name: Install dependencies and build
  shell: |
    cd /tmp/{{ app_name }}-frontend
    npm install
    npm run build
    cp -r dist/* /var/www/{{ app_name }}/
  args:
    creates: "/var/www/{{ app_name }}/index.html"

- name: Configure Nginx site
  template:
    src: nginx-site.conf.j2
    dest: "/etc/nginx/sites-available/{{ app_name }}"
  notify: restart nginx

- name: Enable Nginx site
  file:
    src: "/etc/nginx/sites-available/{{ app_name }}"
    dest: "/etc/nginx/sites-enabled/{{ app_name }}"
    state: link
  notify: restart nginx

- name: Remove default Nginx site
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: restart nginx

- name: Start Nginx
  systemd:
    name: nginx
    state: started
    enabled: yes
```

**`roles/frontend-app/templates/nginx-site.conf.j2`** :
```nginx
server {
    listen 80;
    server_name _;
    root /var/www/{{ app_name }};
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 1000;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### Phase 6 : Monitoring (1h)

**`roles/prometheus/tasks/main.yml`** :
```yaml
---
- name: Create Prometheus user
  user:
    name: prometheus
    system: yes
    shell: /bin/false

- name: Download and install Prometheus
  unarchive:
    src: "https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz"
    dest: /tmp
    remote_src: yes

- name: Copy Prometheus binaries
  copy:
    src: "/tmp/prometheus-2.45.0.linux-amd64/{{ item }}"
    dest: /usr/local/bin/
    remote_src: yes
    mode: '0755'
    owner: prometheus
  loop:
    - prometheus
    - promtool

- name: Create Prometheus directories
  file:
    path: "{{ item }}"
    state: directory
    owner: prometheus
    group: prometheus
    mode: '0755'
  loop:
    - /etc/prometheus
    - /var/lib/prometheus

- name: Configure Prometheus
  template:
    src: prometheus.yml.j2
    dest: /etc/prometheus/prometheus.yml
    owner: prometheus
  notify: restart prometheus

- name: Create Prometheus systemd service
  template:
    src: prometheus.service.j2
    dest: /etc/systemd/system/prometheus.service
  notify:
    - reload systemd
    - restart prometheus

- name: Start Prometheus
  systemd:
    name: prometheus
    state: started
    enabled: yes
```

**`roles/prometheus/templates/prometheus.yml.j2`** :
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets:
{% for host in groups['all'] %}
        - '{{ hostvars[host]['ansible_host'] }}:9100'
{% endfor %}

  - job_name: 'backend-api'
    metrics_path: '/metrics'
    static_configs:
      - targets:
{% for host in groups['backend'] %}
        - '{{ hostvars[host]['ansible_host'] }}:{{ backend_port }}'
{% endfor %}

  - job_name: 'mysql'
    static_configs:
      - targets:
{% for host in groups['database'] %}
        - '{{ hostvars[host]['ansible_host'] }}:9104'
{% endfor %}
```

### Phase 7 : CI/CD Pipeline (30min)

**`.gitlab-ci.yml`** :
```yaml
stages:
  - build
  - test
  - deploy

variables:
  ANSIBLE_FORCE_COLOR: "true"

build_frontend:
  stage: build
  image: node:20
  script:
    - cd application/frontend
    - npm install
    - npm run build
  artifacts:
    paths:
      - application/frontend/dist
    expire_in: 1 hour

build_backend:
  stage: build
  image: node:20
  script:
    - cd application/backend
    - npm install
  artifacts:
    paths:
      - application/backend/node_modules
    expire_in: 1 hour

test_backend:
  stage: test
  image: node:20
  dependencies:
    - build_backend
  script:
    - cd application/backend
    - npm run test
    - npm run lint

deploy_staging:
  stage: deploy
  image: willhallonline/ansible:latest
  before_script:
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
  script:
    - ansible-playbook -i inventory/staging playbooks/deploy-app.yml
  only:
    - develop
  environment:
    name: staging

deploy_production:
  stage: deploy
  image: willhallonline/ansible:latest
  before_script:
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
  script:
    - ansible-playbook -i inventory/production playbooks/rolling-update.yml
  only:
    - tags
  environment:
    name: production
  when: manual
```

**`playbooks/rolling-update.yml`** :
```yaml
---
- name: Rolling update backend
  hosts: backend
  serial: 1
  become: yes
  tasks:
    - name: Pull latest code
      git:
        repo: "{{ backend_repo }}"
        dest: "{{ backend_dir }}"
        version: "{{ backend_branch }}"
        force: yes

    - name: Install dependencies
      npm:
        path: "{{ backend_dir }}"
        production: yes

    - name: Reload PM2
      shell: pm2 reload {{ app_name }}-api
      become_user: "{{ ansible_user }}"

    - name: Wait for health check
      uri:
        url: "http://localhost:{{ backend_port }}/api/health"
        status_code: 200
      retries: 5
      delay: 3

- name: Update frontend
  hosts: frontend
  serial: 1
  become: yes
  tasks:
    - name: Build and deploy frontend
      include_role:
        name: frontend-app

    - name: Reload Nginx
      systemd:
        name: nginx
        state: reloaded
```

## Livrables

- ✅ Architecture multi-tier complète déployée
- ✅ HAProxy + Keepalived en haute disponibilité
- ✅ 3 serveurs frontend (React + Nginx)
- ✅ 3 serveurs backend (Node.js + PM2)
- ✅ MySQL Master-Slave réplication
- ✅ Monitoring complet (Prometheus + Grafana)
- ✅ Logging centralisé (ELK Stack)
- ✅ Pipeline CI/CD fonctionnel
- ✅ Rolling updates sans downtime
- ✅ Documentation complète

## Tests de Validation

### 1. Test de Load Balancing
```bash
# Test HAProxy
for i in {1..10}; do
  curl -s http://192.168.1.100 | grep "server"
done

# Doit montrer une distribution entre les serveurs
```

### 2. Test de Haute Disponibilité
```bash
# Arrêter le master HAProxy
ssh lb01 "sudo systemctl stop haproxy"

# Le VIP doit basculer sur lb02
ping 192.168.1.100

# L'application doit rester accessible
curl http://192.168.1.100
```

### 3. Test de Réplication MySQL
```bash
# Sur le master
mysql -h 192.168.1.40 -u root -p -e "INSERT INTO test VALUES (1, 'test');"

# Sur le slave
mysql -h 192.168.1.41 -u root -p -e "SELECT * FROM test;"
# Doit afficher la même donnée
```

### 4. Test de Rolling Update
```bash
# Déployer une nouvelle version
ansible-playbook -i inventory/production playbooks/rolling-update.yml

# Vérifier qu'il n'y a pas d'interruption de service
while true; do curl -s http://192.168.1.100/api/health || echo "FAIL"; sleep 1; done
```

## Critères d'évaluation

- ✅ Architecture complète déployée et fonctionnelle (25%)
- ✅ Haute disponibilité opérationnelle (20%)
- ✅ Réplication de base de données (15%)
- ✅ Monitoring et logging configurés (15%)
- ✅ CI/CD pipeline fonctionnel (10%)
- ✅ Rolling updates sans downtime (10%)
- ✅ Documentation et tests (5%)

## Ressources

- [HAProxy Documentation](https://www.haproxy.org/documentation.html)
- [Keepalived User Guide](https://keepalived.readthedocs.io/)
- [MySQL Replication](https://dev.mysql.com/doc/refman/8.0/en/replication.html)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)

---

**Durée estimée** : 6 heures

**Niveau** : Expert
