# Ansible Galaxy et Collections

## Table des matières

1. [Introduction à Ansible Galaxy](#introduction-à-ansible-galaxy)
2. [Rechercher et installer des rôles](#rechercher-et-installer-des-rôles)
3. [Utiliser requirements.yml](#utiliser-requirementsyml)
4. [Créer et publier un rôle](#créer-et-publier-un-rôle)
5. [Collections Ansible](#collections-ansible)
6. [Namespaces et versioning](#namespaces-et-versioning)
7. [Bonnes pratiques](#bonnes-pratiques)

---

## Introduction à Ansible Galaxy

**Ansible Galaxy** est le hub communautaire officiel pour partager et découvrir du contenu Ansible (rôles et collections).

### Qu'est-ce qu'Ansible Galaxy ?

**Définition :**
- Hub public : https://galaxy.ansible.com
- 20 000+ rôles disponibles
- Collections officielles et communautaires
- Gratuit et open-source
- Intégration GitHub/GitLab

**Contenus disponibles :**
- **Rôles** : Configuration réutilisable (nginx, mysql, docker, etc.)
- **Collections** : Packages de modules, plugins, rôles
- **Playbooks** : Exemples et templates

### Pourquoi utiliser Galaxy ?

**Avantages :**
- **Gain de temps** : Pas besoin de réinventer la roue
- **Qualité** : Rôles testés et maintenus
- **Communauté** : Apprentissage et partage
- **Standards** : Best practices

**Ne pas tout prendre de Galaxy :**
- Vérifier la qualité (nombre d'étoiles, downloads, dernière mise à jour)
- Lire le code avant d'utiliser
- Tester dans un environnement de dev
- Préférer les rôles officiels (geerlingguy, RedHat, etc.)

---

## Rechercher et installer des rôles

### Rechercher des rôles

**1. Sur le site web**
```
https://galaxy.ansible.com
→ Rechercher "nginx"
→ Trier par popularité, téléchargements, mise à jour
```

**2. En ligne de commande**
```bash
# Rechercher un rôle
ansible-galaxy search nginx

# Rechercher par auteur
ansible-galaxy search nginx --author geerlingguy

# Rechercher par plateforme
ansible-galaxy search mysql --platforms EL

# Rechercher par tag
ansible-galaxy search --galaxy-tags web
```

### Obtenir des informations sur un rôle

```bash
# Informations détaillées
ansible-galaxy info geerlingguy.nginx

# Affiche :
# - Description
# - Auteur
# - Plateformes supportées
# - Version
# - Tags
# - Dépendances
```

**Exemple de sortie :**
```yaml
Role: geerlingguy.nginx
    description: Nginx installation and configuration
    active: True
    commit: 0a1b2c3d4e5f
    commit_message: Fix issue #123
    company: Midwestern Mac
    created: 2014-04-03T17:57:00.000000Z
    download_count: 1234567
    forks_count: 567
    github_branch: master
    github_repo: ansible-role-nginx
    github_user: geerlingguy
    id: 123
    license: MIT
    min_ansible_version: 2.4
    modified: 2024-01-15T10:30:00.000000Z
    stargazers_count: 1234

    platforms:
        - name: EL
          versions:
            - 7
            - 8
        - name: Ubuntu
          versions:
            - focal
            - jammy
```

### Installer un rôle

```bash
# Installation de base
ansible-galaxy install geerlingguy.nginx

# Version spécifique
ansible-galaxy install geerlingguy.nginx,4.1.0

# Depuis une source alternative
ansible-galaxy install git+https://github.com/geerlingguy/ansible-role-nginx.git

# Dans un répertoire spécifique
ansible-galaxy install geerlingguy.nginx -p ./roles

# Forcer la réinstallation
ansible-galaxy install geerlingguy.nginx --force
```

**Où sont installés les rôles ?**
```bash
# Ordre de recherche :
1. ./roles/                    # Répertoire courant
2. ~/.ansible/roles/           # Home directory
3. /usr/share/ansible/roles/   # System-wide
4. /etc/ansible/roles/         # Legacy

# Configurable dans ansible.cfg
[defaults]
roles_path = ./roles:~/.ansible/roles
```

### Gérer les rôles installés

```bash
# Lister les rôles installés
ansible-galaxy list

# Lister avec chemin complet
ansible-galaxy list -p ./roles

# Supprimer un rôle
ansible-galaxy remove geerlingguy.nginx

# Supprimer depuis un chemin spécifique
ansible-galaxy remove geerlingguy.nginx -p ./roles
```

---

## Utiliser requirements.yml

Le fichier `requirements.yml` centralise les dépendances de votre projet.

### Structure de base

```yaml
---
# requirements.yml

# Rôles depuis Galaxy
roles:
  - name: geerlingguy.nginx
    version: 4.1.0

  - name: geerlingguy.docker
    version: latest

# Collections
collections:
  - name: community.general
    version: 5.0.0

  - name: ansible.posix
```

### Sources multiples

```yaml
---
roles:
  # Depuis Galaxy (par défaut)
  - name: geerlingguy.nginx
    version: 4.1.0

  # Depuis GitHub
  - src: https://github.com/geerlingguy/ansible-role-mysql.git
    name: mysql
    version: main

  # Depuis GitHub avec version tag
  - src: git+https://github.com/user/role.git
    name: custom_role
    version: v1.2.3

  # Depuis un repo Git privé avec SSH
  - src: git@github.com:company/private-role.git
    name: private_role
    version: develop

  # Depuis une URL tar.gz
  - src: https://example.com/roles/custom-role.tar.gz
    name: custom_role

  # Depuis un chemin local
  - src: /path/to/local/role
    name: local_role

collections:
  # Collection depuis Galaxy
  - name: community.general
    version: ">=5.0.0,<6.0.0"  # Range de versions

  - name: ansible.posix
    version: "*"  # Latest

  # Collection depuis Git
  - name: https://github.com/namespace/collection.git
    type: git
    version: main
```

### Installer depuis requirements.yml

```bash
# Installer tous les rôles et collections
ansible-galaxy install -r requirements.yml

# Installer seulement les rôles
ansible-galaxy role install -r requirements.yml

# Installer seulement les collections
ansible-galaxy collection install -r requirements.yml

# Forcer la réinstallation
ansible-galaxy install -r requirements.yml --force

# Forcer avec dépendances
ansible-galaxy install -r requirements.yml --force-with-deps

# Installer dans un chemin spécifique
ansible-galaxy install -r requirements.yml -p ./roles
```

### Exemple complet

```yaml
---
# requirements.yml

roles:
  # Infrastructure
  - name: geerlingguy.nginx
    version: 4.1.0

  - name: geerlingguy.mysql
    version: 4.0.0

  - name: geerlingguy.redis
    version: 1.7.0

  - name: geerlingguy.docker
    version: 6.0.0

  # Monitoring
  - src: https://github.com/cloudalchemy/ansible-prometheus.git
    name: prometheus
    version: 2.40.0

  # Custom roles
  - src: git@github.com:mycompany/ansible-role-app.git
    name: myapp
    version: v1.5.0

collections:
  # Core collections
  - name: ansible.posix
    version: 1.5.0

  - name: community.general
    version: 6.0.0

  # Cloud providers
  - name: amazon.aws
    version: 5.0.0

  - name: azure.azcollection
    version: 1.14.0

  - name: google.cloud
    version: 1.1.0

  # Containers
  - name: community.docker
    version: 3.4.0

  - name: kubernetes.core
    version: 2.4.0
```

### Versionning sémantique

```yaml
# Version exacte
version: 1.2.3

# Version minimale
version: ">=1.2.0"

# Range
version: ">=1.2.0,<2.0.0"

# Wildcard
version: 1.2.*

# Latest
version: "*"
```

---

## Créer et publier un rôle

### 1. Créer la structure du rôle

```bash
# Initialiser un rôle
ansible-galaxy init my-nginx-role

# OU avec namespace
ansible-galaxy init mycompany.nginx
```

**Structure créée :**
```
my-nginx-role/
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

### 2. Développer le rôle

**tasks/main.yml**
```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Reload nginx

- name: Start nginx
  service:
    name: nginx
    state: started
    enabled: yes
```

**defaults/main.yml**
```yaml
---
nginx_port: 80
nginx_user: www-data
nginx_worker_processes: auto
nginx_worker_connections: 1024
```

**handlers/main.yml**
```yaml
---
- name: Reload nginx
  service:
    name: nginx
    state: reloaded
```

### 3. Configurer meta/main.yml

```yaml
---
galaxy_info:
  # Informations de base
  role_name: nginx
  author: Your Name
  description: Install and configure Nginx web server
  company: Your Company
  license: MIT

  # Version minimale d'Ansible
  min_ansible_version: 2.9

  # Plateformes supportées
  platforms:
    - name: Ubuntu
      versions:
        - focal       # 20.04
        - jammy       # 22.04
    - name: Debian
      versions:
        - bullseye    # 11
        - bookworm    # 12

  # Tags pour la recherche
  galaxy_tags:
    - nginx
    - web
    - webserver
    - proxy
    - loadbalancer

# Dépendances
dependencies: []
  # - role: common
  #   vars:
  #     some_var: value
```

### 4. Écrire un bon README.md

```markdown
# Ansible Role: Nginx

Install and configure Nginx web server.

## Requirements

- Ansible 2.9 or higher
- Ubuntu 20.04+ or Debian 11+

## Role Variables

Available variables with default values (see `defaults/main.yml`):

| Variable | Default | Description |
|----------|---------|-------------|
| `nginx_port` | `80` | HTTP port |
| `nginx_user` | `www-data` | User running nginx |
| `nginx_worker_processes` | `auto` | Number of worker processes |
| `nginx_worker_connections` | `1024` | Max connections per worker |

## Dependencies

None.

## Example Playbook

```yaml
- hosts: webservers
  become: yes
  roles:
    - role: mycompany.nginx
      nginx_port: 8080
      nginx_worker_processes: 4
```

## Testing

```bash
molecule test
```

## License

MIT

## Author Information

This role was created by [Your Name](https://github.com/yourname).

## Contributing

Issues and pull requests are welcome!
```

### 5. Tester le rôle

**tests/test.yml**
```yaml
---
- hosts: localhost
  remote_user: root
  roles:
    - my-nginx-role
```

```bash
# Tester localement
cd my-nginx-role
ansible-playbook -i tests/inventory tests/test.yml
```

### 6. Créer un repository GitHub

```bash
# Initialiser Git
cd my-nginx-role
git init

# Créer .gitignore
cat > .gitignore <<EOF
*.retry
*.pyc
.molecule/
.cache/
EOF

# Commit initial
git add .
git commit -m "Initial commit"

# Créer repo sur GitHub puis :
git remote add origin https://github.com/yourname/ansible-role-nginx.git
git branch -M main
git push -u origin main
```

**Important : Nom du repository GitHub**
- Format : `ansible-role-NAME`
- Exemple : `ansible-role-nginx`
- Galaxy détecte automatiquement

### 7. Publier sur Galaxy

**A. Créer un compte Galaxy**
1. Aller sur https://galaxy.ansible.com
2. "Sign in" avec GitHub
3. Autoriser Ansible Galaxy

**B. Importer le rôle**
1. Aller dans "My Content" → "Add Content"
2. Sélectionner votre repository GitHub
3. Cliquer "Import"
4. Galaxy teste et publie automatiquement

**C. Configuration automatique avec GitHub Actions**

**.github/workflows/galaxy.yml**
```yaml
name: Release to Galaxy

on:
  push:
    tags:
      - '*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Release to Galaxy
        uses: artis3n/ansible-role-publish@v1
        with:
          api_key: ${{ secrets.GALAXY_API_KEY }}
```

### 8. Versionner le rôle

```bash
# Créer un tag Git
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Galaxy importe automatiquement la nouvelle version
```

### 9. Installer et utiliser votre rôle

```bash
# Installer
ansible-galaxy install yourname.nginx

# OU depuis GitHub directement
ansible-galaxy install git+https://github.com/yourname/ansible-role-nginx.git
```

**requirements.yml**
```yaml
---
roles:
  - name: yourname.nginx
    version: 1.0.0
```

---

## Collections Ansible

Les **collections** sont des packages qui regroupent modules, plugins, rôles et playbooks.

### Qu'est-ce qu'une Collection ?

**Différence Rôle vs Collection :**

| Rôle | Collection |
|------|------------|
| Tasks Ansible | Modules Python |
| Templates | Plugins |
| Handlers | Rôles |
| Variables | Playbooks |
| | Documentation |

**Collections populaires :**
- `ansible.builtin` : Modules de base
- `community.general` : Modules communautaires
- `amazon.aws` : Modules AWS
- `azure.azcollection` : Modules Azure
- `google.cloud` : Modules GCP
- `kubernetes.core` : Modules Kubernetes

### Installer des collections

```bash
# Depuis Galaxy
ansible-galaxy collection install community.general

# Version spécifique
ansible-galaxy collection install community.general:5.0.0

# Depuis requirements.yml
ansible-galaxy collection install -r requirements.yml

# Forcer la réinstallation
ansible-galaxy collection install community.general --force

# Dans un chemin spécifique
ansible-galaxy collection install community.general -p ./collections
```

### Lister les collections

```bash
# Lister toutes les collections installées
ansible-galaxy collection list

# Informations sur une collection
ansible-galaxy collection list community.general
```

**Sortie :**
```
# /home/user/.ansible/collections/ansible_collections
Collection        Version
----------------- -------
ansible.posix     1.5.0
community.general 6.0.0
```

### Utiliser une collection

**Méthode 1 : FQCN (Fully Qualified Collection Name)**
```yaml
- name: Use module with FQCN
  hosts: localhost
  tasks:
    - name: Start Docker container
      community.docker.docker_container:
        name: nginx
        image: nginx:latest
        state: started
```

**Méthode 2 : Import au niveau du play**
```yaml
- name: Import collection
  hosts: localhost
  collections:
    - community.docker

  tasks:
    - name: Start container
      docker_container:  # Pas besoin du FQCN
        name: nginx
        image: nginx:latest
```

**Méthode 3 : Import au niveau du task**
```yaml
- name: Use collection
  hosts: localhost
  tasks:
    - name: Import and use
      collections:
        - community.docker
      docker_container:
        name: nginx
        image: nginx:latest
```

### Créer une collection

**1. Initialiser la structure**
```bash
ansible-galaxy collection init mycompany.mycollection
```

**Structure créée :**
```
mycompany/mycollection/
├── galaxy.yml
├── plugins/
│   ├── modules/
│   ├── inventory/
│   ├── lookup/
│   └── filter/
├── roles/
├── playbooks/
├── docs/
└── README.md
```

**2. Configurer galaxy.yml**
```yaml
namespace: mycompany
name: mycollection
version: 1.0.0
readme: README.md

authors:
  - Your Name <your.email@example.com>

description: My awesome Ansible collection

license:
  - MIT

tags:
  - infrastructure
  - automation
  - cloud

dependencies:
  ansible.posix: ">=1.0.0"
  community.general: ">=4.0.0"

repository: https://github.com/mycompany/ansible-collection-mycollection
documentation: https://docs.example.com
homepage: https://example.com
issues: https://github.com/mycompany/ansible-collection-mycollection/issues
```

**3. Ajouter du contenu**

**plugins/modules/my_module.py**
```python
#!/usr/bin/python

from ansible.module_utils.basic import AnsibleModule

DOCUMENTATION = r'''
---
module: my_module
short_description: My custom module
description:
    - This module does something awesome
options:
    name:
        description: The name parameter
        required: true
        type: str
'''

def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True)
        )
    )

    result = {
        'changed': False,
        'name': module.params['name'],
        'message': f"Hello {module.params['name']}"
    }

    module.exit_json(**result)

if __name__ == '__main__':
    main()
```

**4. Build la collection**
```bash
cd mycompany/mycollection
ansible-galaxy collection build
```

**5. Installer localement**
```bash
ansible-galaxy collection install mycompany-mycollection-1.0.0.tar.gz
```

**6. Publier sur Galaxy**
```bash
ansible-galaxy collection publish mycompany-mycollection-1.0.0.tar.gz --api-key=YOUR_API_KEY
```

---

## Namespaces et versioning

### Namespaces

**Format :** `namespace.collection` ou `namespace.role`

**Exemples :**
- `community.general` → namespace: community, collection: general
- `geerlingguy.nginx` → namespace: geerlingguy, role: nginx
- `ansible.builtin` → namespace: ansible, collection: builtin

**Créer votre namespace :**
1. Sur Galaxy : My Content → Create Namespace
2. Nom unique (company, username, project)
3. Utiliser dans galaxy.yml ou meta/main.yml

### Versioning sémantique

**Format : MAJOR.MINOR.PATCH**
```
1.2.3
│ │ │
│ │ └─ Patch : Bug fixes
│ └─── Minor : New features (backwards compatible)
└───── Major : Breaking changes
```

**Exemples :**
- `1.0.0` → Première version stable
- `1.1.0` → Nouvelle fonctionnalité
- `1.1.1` → Bug fix
- `2.0.0` → Breaking change

**Dans requirements.yml :**
```yaml
collections:
  # Version exacte
  - name: community.general
    version: 5.0.0

  # Version minimale
  - name: ansible.posix
    version: ">=1.5.0"

  # Range
  - name: amazon.aws
    version: ">=4.0.0,<5.0.0"

  # Latest stable
  - name: azure.azcollection
    version: "*"
```

---

## Bonnes pratiques

### 1. Vérifier avant d'installer

```bash
# Informations sur le rôle
ansible-galaxy info geerlingguy.nginx

# Vérifier :
# - Nombre de téléchargements
# - Date de dernière mise à jour
# - Nombre d'étoiles GitHub
# - Issues ouvertes
# - Pull requests
```

### 2. Toujours versionner

```yaml
# ✅ BON : Version spécifique
- name: geerlingguy.nginx
  version: 4.1.0

# ❌ MAUVAIS : Pas de version
- name: geerlingguy.nginx
```

### 3. Documenter les rôles

```markdown
# README.md complet
- Description
- Requirements
- Variables
- Dependencies
- Examples
- License
- Author
```

### 4. Tester avant de publier

```bash
# Avec Molecule
molecule test

# Avec CI/CD
.github/workflows/ci.yml
```

### 5. Maintenir à jour

```bash
# Vérifier les mises à jour
ansible-galaxy list --outdated

# Mettre à jour
ansible-galaxy install -r requirements.yml --force
```

---

## Exemple complet

**requirements.yml**
```yaml
---
# Infrastructure roles
roles:
  - name: geerlingguy.nginx
    version: 4.1.0

  - name: geerlingguy.mysql
    version: 4.0.0

  - name: geerlingguy.docker
    version: 6.0.0

# Custom roles
  - src: git@github.com:mycompany/ansible-role-app.git
    name: myapp
    version: v2.1.0

# Collections
collections:
  - name: community.general
    version: ">=6.0.0,<7.0.0"

  - name: ansible.posix
    version: 1.5.0

  - name: amazon.aws
    version: 5.0.0
```

**Installation :**
```bash
# Installer tout
ansible-galaxy install -r requirements.yml

# Vérifier
ansible-galaxy list
```

**Utilisation dans playbook :**
```yaml
---
- name: Setup infrastructure
  hosts: all
  become: yes

  roles:
    # Depuis Galaxy
    - role: geerlingguy.docker

    # Custom role
    - role: myapp
      app_version: 2.1.0

  tasks:
    # Depuis collection
    - name: Start container
      community.docker.docker_container:
        name: nginx
        image: nginx:latest
```

---

## Prochaines étapes

Maintenant que vous maîtrisez Galaxy et les collections, passez au dernier module :

**[10-Best-Practices](../10-Best-Practices/README.md)**

Vous allez apprendre à :
- Structurer vos projets Ansible
- Tester avec Molecule et ansible-lint
- Intégrer Ansible dans CI/CD
- Gérer les secrets avec Ansible Vault
- Optimiser les performances
- Troubleshooting

---

**"Standing on the shoulders of giants: use Galaxy wisely, contribute generously."**
