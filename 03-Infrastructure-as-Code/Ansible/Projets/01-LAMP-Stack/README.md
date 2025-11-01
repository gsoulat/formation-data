# Projet 01 : Stack LAMP Complète

## Objectif

Déployer une stack LAMP (Linux, Apache, MySQL, PHP) complète avec Ansible pour héberger une application web.

## Architecture

```
┌─────────────────────────────────────┐
│         Load Balancer (HAProxy)      │
│         192.168.1.10                 │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌──────▼──────┐
│  Web Server 1│  │  Web Server 2│
│  Apache+PHP  │  │  Apache+PHP  │
│ 192.168.1.11 │  │ 192.168.1.12 │
└──────┬───────┘  └──────┬───────┘
       │                 │
       └────────┬────────┘
                │
        ┌───────▼────────┐
        │  Database      │
        │  MySQL/MariaDB │
        │  192.168.1.20  │
        └────────────────┘
```

## Composants

### 1. Load Balancer (HAProxy)
- Distribution du trafic HTTP/HTTPS
- Health checks
- SSL termination

### 2. Web Servers (Apache + PHP)
- Apache 2.4+
- PHP 8.x avec modules (mysql, curl, gd, xml)
- Application web (WordPress ou custom)

### 3. Database (MySQL/MariaDB)
- MySQL 8.0 ou MariaDB 10.6+
- Base de données applicative
- Backup automatique

## Prérequis

- 4 serveurs Ubuntu 22.04 ou Rocky Linux 9
- Ansible installé sur la machine de contrôle
- Accès SSH avec clés aux serveurs
- Connexion Internet sur les serveurs

## Structure du Projet

```
01-LAMP-Stack/
├── README.md
├── ansible.cfg
├── inventory/
│   ├── production
│   └── staging
├── group_vars/
│   ├── all.yml
│   ├── webservers.yml
│   ├── database.yml
│   └── loadbalancer.yml
├── host_vars/
│   └── db01.yml
├── roles/
│   ├── common/
│   ├── apache/
│   ├── php/
│   ├── mysql/
│   ├── haproxy/
│   └── application/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   ├── database.yml
│   └── loadbalancer.yml
└── files/
    └── app/
```

## Tâches

### Phase 1 : Préparation (30 min)

1. **Créer l'inventaire**
   ```ini
   [loadbalancers]
   lb01 ansible_host=192.168.1.10

   [webservers]
   web01 ansible_host=192.168.1.11
   web02 ansible_host=192.168.1.12

   [database]
   db01 ansible_host=192.168.1.20

   [lamp:children]
   webservers
   database
   loadbalancers
   ```

2. **Définir les variables globales** (`group_vars/all.yml`)
   ```yaml
   # Utilisateur système
   ansible_user: ansible
   ansible_become: yes

   # Application
   app_name: myapp
   app_version: 1.0.0

   # Timezone
   server_timezone: Europe/Paris
   ```

### Phase 2 : Rôle Common (30 min)

Créer un rôle `common` qui :
- Met à jour le système
- Configure le timezone
- Installe les packages de base (vim, git, curl, htop)
- Configure les utilisateurs
- Configure SSH (désactiver root login)
- Configure le firewall de base

### Phase 3 : Rôle MySQL (1h)

Créer un rôle `mysql` qui :
- Installe MySQL/MariaDB
- Sécurise l'installation (mysql_secure_installation)
- Crée la base de données applicative
- Crée l'utilisateur applicatif avec droits
- Configure le bind-address pour connexions réseau
- Configure la sauvegarde automatique

**Variables** (`group_vars/database.yml`) :
```yaml
mysql_root_password: "{{ vault_mysql_root_password }}"
mysql_databases:
  - name: myapp_db
    encoding: utf8mb4
    collation: utf8mb4_unicode_ci

mysql_users:
  - name: myapp_user
    password: "{{ vault_mysql_app_password }}"
    priv: "myapp_db.*:ALL"
    host: "192.168.1.%"
```

### Phase 4 : Rôle Apache + PHP (1h)

Créer des rôles `apache` et `php` qui :

**Apache** :
- Installe Apache 2.4
- Configure les virtual hosts
- Active les modules nécessaires (rewrite, ssl, headers)
- Configure les logs

**PHP** :
- Installe PHP 8.x
- Installe les extensions (mysql, curl, gd, xml, mbstring, zip)
- Configure php.ini (memory_limit, upload_max_filesize, etc.)
- Configure PHP-FPM si utilisé

**Variables** (`group_vars/webservers.yml`) :
```yaml
apache_listen_port: 80
apache_listen_port_ssl: 443

php_version: "8.1"
php_memory_limit: "256M"
php_upload_max_filesize: "64M"
php_max_execution_time: 300
```

### Phase 5 : Rôle Application (1h)

Créer un rôle `application` qui :
- Déploie le code source (Git ou copie)
- Configure les permissions
- Crée le fichier de configuration (avec template)
- Configure les cron jobs si nécessaire

**Template** (`roles/application/templates/config.php.j2`) :
```php
<?php
define('DB_HOST', '{{ mysql_host }}');
define('DB_NAME', '{{ mysql_database }}');
define('DB_USER', '{{ mysql_user }}');
define('DB_PASSWORD', '{{ mysql_password }}');
?>
```

### Phase 6 : Rôle HAProxy (1h)

Créer un rôle `haproxy` qui :
- Installe HAProxy
- Configure le load balancing
- Active les health checks
- Configure les logs
- Active les stats

**Configuration** :
```haproxy
frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    option httpchk GET /health.php
    server web01 192.168.1.11:80 check
    server web02 192.168.1.12:80 check
```

### Phase 7 : Playbook Principal (30 min)

Créer `playbooks/site.yml` :
```yaml
---
- name: Configure all servers
  hosts: all
  roles:
    - common

- name: Configure database server
  hosts: database
  roles:
    - mysql

- name: Configure web servers
  hosts: webservers
  roles:
    - apache
    - php
    - application

- name: Configure load balancer
  hosts: loadbalancers
  roles:
    - haproxy
```

### Phase 8 : Tests et Validation (30 min)

1. **Tester la syntaxe**
   ```bash
   ansible-playbook playbooks/site.yml --syntax-check
   ```

2. **Dry-run**
   ```bash
   ansible-playbook playbooks/site.yml --check
   ```

3. **Déployer**
   ```bash
   ansible-playbook playbooks/site.yml
   ```

4. **Vérifier le déploiement**
   ```bash
   # Test load balancer
   curl http://192.168.1.10

   # Test direct web servers
   curl http://192.168.1.11
   curl http://192.168.1.12

   # Test database
   mysql -h 192.168.1.20 -u myapp_user -p myapp_db
   ```

5. **HAProxy Stats**
   - Accéder à http://192.168.1.10:8080/stats

## Livrables

- ✅ Stack LAMP complète fonctionnelle
- ✅ Load balancer avec health checks
- ✅ 2 web servers avec Apache + PHP
- ✅ Base de données MySQL configurée
- ✅ Application déployée et accessible
- ✅ Playbooks idempotents
- ✅ Variables externalisées
- ✅ Secrets avec Ansible Vault
- ✅ Documentation

## Extensions possibles

1. **SSL/TLS** :
   - Let's Encrypt avec certbot
   - SSL termination sur HAProxy

2. **Monitoring** :
   - Prometheus + Grafana
   - Alerting

3. **Backup** :
   - Backup automatique MySQL
   - Backup fichiers application

4. **CI/CD** :
   - Déploiement automatique avec GitLab CI/Jenkins
   - Rolling updates

5. **Sécurité** :
   - Fail2ban
   - ModSecurity (WAF)
   - Hardening système

## Critères d'évaluation

- ✅ Infrastructure déployée et fonctionnelle (40%)
- ✅ Idempotence des playbooks (15%)
- ✅ Utilisation correcte des rôles (15%)
- ✅ Gestion des variables et secrets (10%)
- ✅ Code propre et commenté (10%)
- ✅ Documentation (10%)

## Ressources

- [Apache Documentation](https://httpd.apache.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [HAProxy Documentation](https://www.haproxy.org/documentation.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
