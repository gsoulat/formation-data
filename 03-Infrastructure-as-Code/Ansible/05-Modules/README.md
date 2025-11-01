# Les Modules Ansible

## Table des matières

1. [Introduction aux Modules](#introduction-aux-modules)
2. [Modules Système](#modules-système)
3. [Modules Fichiers](#modules-fichiers)
4. [Modules Cloud](#modules-cloud)
5. [Modules Réseau](#modules-réseau)
6. [Command vs Modules](#command-vs-modules)
7. [Modules Docker et Kubernetes](#modules-docker-et-kubernetes)
8. [Créer un module custom](#créer-un-module-custom)

---

## Introduction aux Modules

Les **modules** sont les unités de travail d'Ansible. Ce sont des scripts qui exécutent des tâches spécifiques sur les managed nodes.

### Qu'est-ce qu'un Module ?

**Définition :**
- Code Python exécuté sur les managed nodes
- Idempotent (dans la plupart des cas)
- Retourne du JSON avec status (changed, failed, ok)
- 3000+ modules fournis par Ansible

**Comment ça fonctionne :**
```
1. Control node prépare le module
2. Module transféré via SSH sur managed node
3. Module exécuté en Python
4. Résultat retourné en JSON
5. Module supprimé du managed node
```

### Catégories de modules

```
Modules Ansible (3000+)
├── System (apt, yum, user, service, etc.)
├── Files (copy, template, file, lineinfile, etc.)
├── Cloud (aws_*, azure_*, gcp_*, etc.)
├── Network (command, shell, uri, get_url, etc.)
├── Database (mysql_*, postgresql_*, mongodb_*, etc.)
├── Containers (docker_*, kubernetes.core.*, etc.)
├── Windows (win_*, etc.)
├── Monitoring (datadog, prometheus, etc.)
└── Notification (slack, email, etc.)
```

### Documentation des modules

```bash
# Liste tous les modules
ansible-doc -l

# Documentation d'un module
ansible-doc apt
ansible-doc copy
ansible-doc service

# Exemples
ansible-doc -s apt

# Plugins
ansible-doc -t lookup file
```

---

## Modules Système

Les modules système gèrent packages, services, utilisateurs, groupes, etc.

### Package Management

#### apt (Debian/Ubuntu)

```yaml
# Installer un package
- name: Install nginx
  apt:
    name: nginx
    state: present        # present, absent, latest
    update_cache: yes     # apt update
    cache_valid_time: 3600  # Cache valide 1h

# Installer plusieurs packages
- name: Install multiple packages
  apt:
    name:
      - nginx
      - curl
      - vim
      - git
    state: present
    update_cache: yes

# Version spécifique
- name: Install specific version
  apt:
    name: nginx=1.18.0-0ubuntu1
    state: present

# Upgrade tous les packages
- name: Upgrade all packages
  apt:
    upgrade: dist
    update_cache: yes

# Supprimer un package
- name: Remove package
  apt:
    name: apache2
    state: absent
    purge: yes  # Supprimer aussi les configs
```

#### yum / dnf (RHEL/CentOS/Fedora)

```yaml
# YUM (RHEL 7 et antérieur)
- name: Install httpd
  yum:
    name: httpd
    state: present

# DNF (RHEL 8+, Fedora)
- name: Install nginx
  dnf:
    name: nginx
    state: latest

# Installer depuis un repo spécifique
- name: Install from repo
  yum:
    name: docker-ce
    enablerepo: docker-ce-stable
    state: present

# Groupe de packages
- name: Install development tools
  yum:
    name: "@Development tools"
    state: present
```

#### package (Abstraction multi-OS)

```yaml
# Fonctionne sur Debian, RHEL, etc.
- name: Install package (multi-OS)
  package:
    name: nginx
    state: present
```

### Service Management

```yaml
# Démarrer et activer un service
- name: Start and enable nginx
  service:
    name: nginx
    state: started    # started, stopped, restarted, reloaded
    enabled: yes      # Auto-start au boot

# Redémarrer un service
- name: Restart nginx
  service:
    name: nginx
    state: restarted

# Vérifier qu'un service est arrêté
- name: Ensure apache is stopped
  service:
    name: apache2
    state: stopped
    enabled: no

# Systemd (alternative moderne)
- name: Manage service with systemd
  systemd:
    name: nginx
    state: started
    enabled: yes
    daemon_reload: yes  # Recharger systemd
```

### User Management

```yaml
# Créer un utilisateur
- name: Create user
  user:
    name: john
    comment: "John Doe"
    uid: 1040
    group: users
    groups: sudo,docker  # Groupes supplémentaires
    shell: /bin/bash
    home: /home/john
    create_home: yes
    state: present

# Créer avec clé SSH
- name: Create user with SSH key
  user:
    name: ansible
    groups: sudo
    shell: /bin/bash
    generate_ssh_key: yes
    ssh_key_bits: 4096
    ssh_key_file: .ssh/id_rsa

# Supprimer un utilisateur
- name: Remove user
  user:
    name: olduser
    state: absent
    remove: yes  # Supprimer le home directory
```

### Group Management

```yaml
# Créer un groupe
- name: Create group
  group:
    name: developers
    gid: 2000
    state: present

# Supprimer un groupe
- name: Remove group
  group:
    name: oldgroup
    state: absent
```

### Cron Jobs

```yaml
# Ajouter un cron job
- name: Add cron job
  cron:
    name: "Backup database"
    minute: "0"
    hour: "2"
    job: "/usr/local/bin/backup.sh"
    user: root

# Backup quotidien à 2h
- name: Daily backup
  cron:
    name: "Daily backup"
    special_time: daily
    job: "/opt/backup.sh"

# Supprimer un cron job
- name: Remove cron job
  cron:
    name: "Backup database"
    state: absent
```

---

## Modules Fichiers

### copy - Copier des fichiers

```yaml
# Copier un fichier
- name: Copy configuration file
  copy:
    src: nginx.conf           # Sur control node
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    backup: yes               # Backup avant écrasement

# Copier avec contenu inline
- name: Create file with content
  copy:
    content: |
      server {
        listen 80;
        server_name example.com;
      }
    dest: /etc/nginx/sites-available/example.com
    owner: www-data
    mode: '0644'

# Copier un répertoire
- name: Copy directory
  copy:
    src: /local/configs/
    dest: /etc/myapp/
    owner: root
    group: root
    mode: '0755'
```

### template - Templates Jinja2

```yaml
# Utiliser un template Jinja2
- name: Deploy template
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'  # Valider avant d'appliquer
  notify: Reload nginx
```

**Template nginx.conf.j2 :**
```jinja
server {
    listen {{ http_port }};
    server_name {{ server_name }};

    location / {
        proxy_pass http://{{ backend_host }}:{{ backend_port }};
    }
}
```

### file - Gérer fichiers et répertoires

```yaml
# Créer un répertoire
- name: Create directory
  file:
    path: /var/www/html
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

# Créer un fichier vide
- name: Create empty file
  file:
    path: /var/log/app.log
    state: touch
    owner: appuser
    mode: '0644'

# Créer un lien symbolique
- name: Create symlink
  file:
    src: /etc/nginx/sites-available/example.com
    dest: /etc/nginx/sites-enabled/example.com
    state: link

# Supprimer un fichier/répertoire
- name: Remove file
  file:
    path: /tmp/oldfile
    state: absent

# Changer permissions
- name: Set permissions
  file:
    path: /var/www
    owner: www-data
    group: www-data
    mode: '0755'
    recurse: yes  # Récursif
```

### lineinfile - Modifier une ligne dans un fichier

```yaml
# Ajouter/modifier une ligne
- name: Add line to file
  lineinfile:
    path: /etc/hosts
    line: "192.168.1.10 server1.example.com"
    state: present

# Modifier une ligne avec regex
- name: Change SSH port
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?Port'
    line: 'Port 2222'
    state: present
  notify: Restart sshd

# Supprimer une ligne
- name: Remove line
  lineinfile:
    path: /etc/hosts
    regexp: '^192.168.1.10'
    state: absent
```

### blockinfile - Insérer un bloc de texte

```yaml
# Insérer un bloc
- name: Add config block
  blockinfile:
    path: /etc/hosts
    block: |
      192.168.1.10 server1
      192.168.1.11 server2
      192.168.1.12 server3
    marker: "# {mark} ANSIBLE MANAGED BLOCK"
    state: present
```

### fetch - Récupérer des fichiers

```yaml
# Récupérer un fichier du managed node
- name: Fetch log file
  fetch:
    src: /var/log/app.log
    dest: /tmp/logs/
    flat: yes  # Sans structure de répertoires
```

### synchronize - Synchroniser avec rsync

```yaml
# Synchroniser des fichiers
- name: Sync files
  synchronize:
    src: /local/files/
    dest: /remote/files/
    delete: yes  # Supprimer fichiers non présents dans src
    recursive: yes

# Sync depuis managed node vers control node
- name: Pull files from remote
  synchronize:
    src: /remote/backup/
    dest: /local/backup/
    mode: pull
```

---

## Modules Cloud

### AWS EC2

```yaml
# Créer une instance EC2
- name: Launch EC2 instance
  amazon.aws.ec2_instance:
    name: "web-server-01"
    instance_type: t3.micro
    image_id: ami-0c55b159cbfafe1f0
    key_name: my-key
    vpc_subnet_id: subnet-12345
    security_group: sg-12345
    tags:
      Environment: production
      Role: webserver
    wait: yes
    state: running

# Arrêter une instance
- name: Stop EC2 instance
  amazon.aws.ec2_instance:
    instance_ids:
      - i-1234567890abcdef0
    state: stopped

# Créer un Security Group
- name: Create security group
  amazon.aws.ec2_security_group:
    name: web-sg
    description: Security group for web servers
    vpc_id: vpc-12345
    rules:
      - proto: tcp
        from_port: 80
        to_port: 80
        cidr_ip: 0.0.0.0/0
      - proto: tcp
        from_port: 443
        to_port: 443
        cidr_ip: 0.0.0.0/0
      - proto: tcp
        from_port: 22
        to_port: 22
        cidr_ip: 10.0.0.0/8

# S3 bucket
- name: Create S3 bucket
  amazon.aws.s3_bucket:
    name: my-app-bucket
    state: present
    region: eu-west-1
    encryption: AES256
```

### Azure

```yaml
# Créer une VM Azure
- name: Create Azure VM
  azure.azcollection.azure_rm_virtualmachine:
    resource_group: myResourceGroup
    name: myVM
    vm_size: Standard_B2s
    admin_username: azureuser
    ssh_password_enabled: false
    ssh_public_keys:
      - path: /home/azureuser/.ssh/authorized_keys
        key_data: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
    image:
      offer: UbuntuServer
      publisher: Canonical
      sku: '20.04-LTS'
      version: latest
    tags:
      environment: production

# Créer un Storage Account
- name: Create storage account
  azure.azcollection.azure_rm_storageaccount:
    resource_group: myResourceGroup
    name: mystorageaccount
    account_type: Standard_LRS
    location: westeurope
```

### GCP

```yaml
# Créer une instance GCP
- name: Create GCP instance
  google.cloud.gcp_compute_instance:
    name: web-server-01
    machine_type: n1-standard-1
    zone: europe-west1-b
    project: my-project
    disks:
      - auto_delete: true
        boot: true
        initialize_params:
          source_image: projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts
    network_interfaces:
      - network: null
        access_configs:
          - name: External NAT
            type: ONE_TO_ONE_NAT
    tags:
      items:
        - http-server
        - https-server
    state: present
```

---

## Modules Réseau

### uri - HTTP requests

```yaml
# GET request
- name: Check website
  uri:
    url: https://example.com
    method: GET
    return_content: yes
  register: result

# POST request
- name: API call
  uri:
    url: https://api.example.com/endpoint
    method: POST
    body_format: json
    body:
      key: value
    headers:
      Authorization: "Bearer {{ api_token }}"
    status_code: [200, 201]
  register: api_response

# Health check avec retry
- name: Wait for application
  uri:
    url: http://localhost:8080/health
    status_code: 200
  retries: 10
  delay: 5
  register: result
  until: result.status == 200
```

### get_url - Télécharger des fichiers

```yaml
# Télécharger un fichier
- name: Download file
  get_url:
    url: https://example.com/file.tar.gz
    dest: /tmp/file.tar.gz
    mode: '0644'
    checksum: sha256:abc123...  # Vérifier checksum

# Avec authentification
- name: Download with auth
  get_url:
    url: https://secure.example.com/file.zip
    dest: /tmp/file.zip
    url_username: user
    url_password: pass
```

### git - Gérer repositories Git

```yaml
# Clone un repo
- name: Clone repository
  git:
    repo: https://github.com/user/repo.git
    dest: /opt/app
    version: main
    force: yes

# Avec clé SSH
- name: Clone private repo
  git:
    repo: git@github.com:user/private-repo.git
    dest: /opt/private-app
    version: v2.1.0
    key_file: /home/user/.ssh/id_rsa
    accept_hostkey: yes
```

---

## Command vs Modules

### Pourquoi éviter command/shell ?

```yaml
# ❌ MAUVAIS : Utiliser command/shell
- name: Install package
  command: apt-get install nginx

# ✅ BON : Utiliser le module approprié
- name: Install package
  apt:
    name: nginx
    state: present
```

**Raisons d'éviter command/shell :**
1. **Non idempotent** par défaut
2. **Pas de validation** des paramètres
3. **Pas de reporting** détaillé
4. **Pas multi-plateforme**
5. **Moins sécurisé** (injection commande)

### Quand utiliser command/shell ?

**Utilisez command/shell SEULEMENT si :**
- Aucun module ne fait le job
- Commande très spécifique
- Script custom à exécuter

### command vs shell vs raw

```yaml
# command : Pas de shell, pas de pipes/redirections
- name: Simple command
  command: /usr/bin/uptime
  args:
    creates: /tmp/marker  # Idempotence

# shell : Avec shell, pipes/redirections OK
- name: Shell command
  shell: cat /etc/passwd | grep root > /tmp/root.txt

# raw : Pas de Python nécessaire (bootstrap)
- name: Raw command (no Python)
  raw: apt-get install -y python3
```

### Rendre command/shell idempotents

```yaml
# Technique 1 : creates / removes
- name: Extract archive
  command: tar -xzf /tmp/app.tar.gz -C /opt/
  args:
    creates: /opt/app/  # N'exécute que si n'existe pas

# Technique 2 : changed_when
- name: Check status
  command: systemctl is-active nginx
  register: result
  changed_when: false  # Jamais "changed"
  failed_when: result.rc not in [0, 3]

# Technique 3 : when condition
- name: Check if file exists
  stat:
    path: /etc/app/config.yml
  register: config

- name: Initialize only if not exists
  command: /opt/app/init.sh
  when: not config.stat.exists
```

---

## Modules Docker et Kubernetes

### Docker

```yaml
# Installer Docker
- name: Install Docker
  apt:
    name:
      - docker.io
      - python3-docker
    state: present

# Lancer un container
- name: Run nginx container
  docker_container:
    name: nginx
    image: nginx:latest
    state: started
    ports:
      - "80:80"
    volumes:
      - /var/www:/usr/share/nginx/html:ro
    env:
      NGINX_HOST: example.com
    restart_policy: always

# Build une image
- name: Build Docker image
  docker_image:
    name: myapp
    build:
      path: /path/to/dockerfile
      pull: yes
    source: build
    state: present

# Docker Compose
- name: Run docker-compose
  docker_compose:
    project_src: /path/to/docker-compose
    state: present
```

### Kubernetes

```yaml
# Créer un namespace
- name: Create namespace
  kubernetes.core.k8s:
    name: myapp
    api_version: v1
    kind: Namespace
    state: present

# Déployer un pod
- name: Deploy pod
  kubernetes.core.k8s:
    state: present
    definition:
      apiVersion: v1
      kind: Pod
      metadata:
        name: nginx
        namespace: myapp
      spec:
        containers:
          - name: nginx
            image: nginx:latest
            ports:
              - containerPort: 80

# Depuis un fichier YAML
- name: Apply manifest
  kubernetes.core.k8s:
    state: present
    src: /path/to/deployment.yaml

# Obtenir des infos
- name: Get pods
  kubernetes.core.k8s_info:
    kind: Pod
    namespace: myapp
  register: pod_list
```

---

## Créer un module custom

### Module Python simple

```python
#!/usr/bin/python
# library/my_module.py

from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            state=dict(type='str', default='present', choices=['present', 'absent'])
        ),
        supports_check_mode=True
    )

    name = module.params['name']
    state = module.params['state']

    # Logique du module
    changed = False
    result = {'name': name, 'state': state}

    if state == 'present':
        # Faire quelque chose
        changed = True
        result['message'] = f"{name} is present"
    else:
        # Faire autre chose
        changed = True
        result['message'] = f"{name} is absent"

    module.exit_json(changed=changed, **result)

if __name__ == '__main__':
    main()
```

### Utilisation du module custom

```yaml
# playbook.yml
- name: Use custom module
  hosts: localhost
  tasks:
    - name: Call my module
      my_module:
        name: test
        state: present
```

---

## Exemples complets

### Configuration complète serveur web

```yaml
---
- name: Configure web server
  hosts: webservers
  become: yes
  vars:
    packages:
      - nginx
      - certbot
      - python3-certbot-nginx
    server_name: example.com

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install packages
      apt:
        name: "{{ packages }}"
        state: present

    - name: Create web root
      file:
        path: "/var/www/{{ server_name }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: Deploy website
      copy:
        src: website/
        dest: "/var/www/{{ server_name }}/"
        owner: www-data
        group: www-data

    - name: Configure nginx
      template:
        src: nginx-site.conf.j2
        dest: "/etc/nginx/sites-available/{{ server_name }}"
        validate: 'nginx -t -c /etc/nginx/nginx.conf'
      notify: Reload nginx

    - name: Enable site
      file:
        src: "/etc/nginx/sites-available/{{ server_name }}"
        dest: "/etc/nginx/sites-enabled/{{ server_name }}"
        state: link
      notify: Reload nginx

    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Obtain SSL certificate
      command: >
        certbot --nginx -d {{ server_name }}
        --non-interactive --agree-tos
        --email admin@{{ server_name }}
      args:
        creates: /etc/letsencrypt/live/{{ server_name }}/fullchain.pem

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

---

## Prochaines étapes

Maintenant que vous maîtrisez les modules, passez au module suivant :

**[06-Roles](../06-Roles/README.md)**

Vous allez apprendre à :
- Créer des rôles réutilisables
- Structurer un rôle
- Gérer les dépendances
- Utiliser Ansible Galaxy
- Travailler avec les collections

---

**"Use the right tool for the job. Always prefer modules over command/shell."**
