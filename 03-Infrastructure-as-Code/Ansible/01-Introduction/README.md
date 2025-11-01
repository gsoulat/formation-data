# Introduction à Ansible

## Table des matières

1. [Qu'est-ce qu'Ansible ?](#quest-ce-quansible)
2. [Historique et évolution](#historique-et-évolution)
3. [Architecture d'Ansible](#architecture-dansible)
4. [Concepts clés](#concepts-clés)
5. [Ansible vs autres outils](#ansible-vs-autres-outils)
6. [Cas d'usage](#cas-dusage)
7. [Écosystème Ansible](#écosystème-ansible)

---

## Qu'est-ce qu'Ansible ?

**Ansible** est un outil open-source d'automatisation IT qui permet de gérer la configuration, déployer des applications et orchestrer des tâches complexes sur des infrastructures distribuées.

### Caractéristiques principales

**Agentless (Sans agent)**
- Pas d'agent à installer sur les machines cibles
- Utilise SSH pour Linux/Unix et WinRM pour Windows
- Réduction de la complexité et de la maintenance
- Pas de daemon tournant en permanence

**Simple et lisible**
- Syntaxe YAML facile à lire et écrire
- Pas besoin d'être développeur
- Courbe d'apprentissage douce
- Documentation claire et complète

**Puissant et flexible**
- 3000+ modules intégrés (système, cloud, réseau, etc.)
- Support multi-plateforme (Linux, Windows, BSD, réseau)
- Extensible avec modules custom en Python
- Intégrations avec tous les clouds majeurs

**Idempotent**
- Exécution répétée = même résultat
- Sécurité : pas d'effet de bord
- Détection automatique de l'état actuel
- Application uniquement des changements nécessaires

---

## Historique et évolution

**2012** : Création par Michael DeHaan (ex-Puppet/Cobbler)

**2013** : Ansible Inc. fondée pour support commercial

**2015** : Rachat par Red Hat pour $150M

**2016** : Ansible 2.0 - Architecture modulaire, blocks

**2017** : Ansible Tower devient produit phare entreprise

**2019** : IBM rachète Red Hat (incluant Ansible)

**2020** : Collections et Ansible Content Collections

**2023** : Ansible 2.16+ - Amélioration performances et sécurité

### Timeline des versions

```
Ansible 1.x (2012-2015)
  ├─ Playbooks YAML
  ├─ Modules de base
  └─ Inventory statique

Ansible 2.x (2016-2020)
  ├─ Architecture modulaire
  ├─ Blocks (error handling)
  ├─ Stratégies d'exécution
  ├─ Ansible Vault amélioré
  └─ Dynamic inventory

Ansible 2.9+ (2020-present)
  ├─ Collections (namespace)
  ├─ Ansible Content Collections
  ├─ Amélioration performances
  ├─ Support Python 3.8+
  └─ Ansible Galaxy v3
```

---

## Architecture d'Ansible

### Vue d'ensemble

```
┌─────────────────────────────────────────────────┐
│          CONTROL NODE (Votre machine)           │
│                                                   │
│  ┌───────────────────────────────────────────┐  │
│  │         Ansible Engine                     │  │
│  │  ┌─────────────┐  ┌──────────────────┐   │  │
│  │  │ Playbooks   │  │  Inventory        │   │  │
│  │  └─────────────┘  └──────────────────┘   │  │
│  │  ┌─────────────┐  ┌──────────────────┐   │  │
│  │  │  Modules    │  │  Plugins          │   │  │
│  │  └─────────────┘  └──────────────────┘   │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────┘
                          │
                    SSH / WinRM
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
    ┌────────┐       ┌────────┐       ┌────────┐
    │ Node 1 │       │ Node 2 │       │ Node 3 │
    │ Linux  │       │ Linux  │       │Windows │
    │        │       │        │       │        │
    │ No     │       │ No     │       │ No     │
    │ Agent  │       │ Agent  │       │ Agent  │
    └────────┘       └────────┘       └────────┘
    MANAGED NODES (Serveurs cibles)
```

### Composants principaux

**Control Node (Nœud de contrôle)**
- Machine où Ansible est installé
- Exécute les playbooks
- Peut être votre laptop, un serveur CI/CD, etc.
- **Requirement** : Python 3.8+ (pas de support Windows comme control node)

**Managed Nodes (Nœuds gérés)**
- Serveurs cibles à configurer
- Pas d'agent Ansible nécessaire
- Nécessite Python 2.7+ ou Python 3.5+ (pour la plupart des modules)
- Accès SSH (Linux) ou WinRM (Windows)

**Inventory (Inventaire)**
- Liste des machines à gérer
- Format INI ou YAML
- Peut être statique (fichier) ou dynamique (script/plugin)
- Permet de grouper les machines

**Modules**
- Unités de code exécutées sur les managed nodes
- 3000+ modules fournis (apt, yum, copy, service, etc.)
- Custom modules possibles en Python
- Modules pour cloud, réseau, bases de données, etc.

**Playbooks**
- Fichiers YAML décrivant l'automatisation
- Composés de "plays" qui contiennent des "tasks"
- Déclaratifs : décrivent l'état souhaité
- Réutilisables et versionnables

**Plugins**
- Étendent les fonctionnalités d'Ansible
- Types : connection, lookup, filter, callback, etc.
- Exécutés sur le control node
- Personnalisent le comportement d'Ansible

---

## Concepts clés

### 1. Architecture Agentless

**Comment ça fonctionne ?**

```
1. Ansible lit le playbook
       ↓
2. Génère un script Python temporaire
       ↓
3. Copie le script via SSH sur le managed node
       ↓
4. Exécute le script Python sur le managed node
       ↓
5. Récupère le résultat
       ↓
6. Supprime le script temporaire
       ↓
7. Affiche le résultat
```

**Avantages :**
- Pas de daemon à maintenir
- Pas de problème de version d'agent
- Pas de port supplémentaire à ouvrir
- Sécurité : utilise SSH natif

**Inconvénients :**
- Nécessite Python sur les managed nodes
- Peut être plus lent que les solutions avec agent
- SSH doit être configuré correctement

### 2. Idempotence

L'idempotence garantit que l'exécution répétée d'une tâche produit le même résultat.

**Exemple : Installation de package**

```yaml
# Premier run : Apache n'est pas installé
- name: Ensure Apache is installed
  apt:
    name: apache2
    state: present
# Résultat : Apache est installé (changed=true)

# Deuxième run : Apache est déjà installé
- name: Ensure Apache is installed
  apt:
    name: apache2
    state: present
# Résultat : Rien à faire (changed=false, ok=true)
```

**Modules non-idempotents à éviter :**
```yaml
# ❌ MAUVAIS : command/shell ne sont pas idempotents par défaut
- name: Install package
  command: apt-get install apache2

# ✅ BON : Utiliser le module approprié
- name: Install package
  apt:
    name: apache2
    state: present
```

### 3. Déclaratif vs Impératif

**Impératif (Comment faire)**
```bash
# Script shell impératif
apt-get update
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2
```

**Déclaratif (Quel état)**
```yaml
# Ansible déclaratif
- name: Ensure Apache is running
  apt:
    name: apache2
    state: present

- name: Ensure Apache is started and enabled
  service:
    name: apache2
    state: started
    enabled: yes
```

Ansible gère automatiquement les détails (mise à jour cache, démarrage, etc.).

### 4. Push vs Pull

**Ansible = Push Model**
```
Control Node --push--> Managed Nodes
```

**Puppet/Chef = Pull Model**
```
Managed Nodes --pull--> Configuration Server
```

**Avantages du Push :**
- Contrôle total du moment d'exécution
- Pas de daemon à maintenir
- Idéal pour déploiements orchestrés

**Avantages du Pull :**
- Scalabilité pour milliers de nodes
- Auto-remédiation (check régulier)
- Pas besoin d'accès direct aux nodes

---

## Ansible vs autres outils

| Critère | Ansible | Puppet | Chef | SaltStack | Terraform |
|---------|---------|--------|------|-----------|-----------|
| **Architecture** | Agentless (SSH) | Agent-based | Agent-based | Agent-based | Agentless (API) |
| **Langage** | YAML | DSL propriétaire | Ruby | YAML/Python | HCL |
| **Courbe apprentissage** | ⭐⭐ Facile | ⭐⭐⭐⭐ Difficile | ⭐⭐⭐⭐ Difficile | ⭐⭐⭐ Moyen | ⭐⭐ Facile |
| **Idempotence** | Oui | Oui | Oui | Oui | Oui |
| **Push/Pull** | Push | Pull | Pull | Push & Pull | Push |
| **Cas d'usage principal** | Config Management | Config Management | Config Management | Config + Event-driven | Infrastructure Provisioning |
| **Windows support** | Oui (WinRM) | Oui | Limité | Oui | Non (API cloud) |
| **Courbe de perf** | Bon | Excellent | Excellent | Excellent | N/A |
| **Community** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### Comparaison détaillée

**Ansible**
```yaml
# Simple, lisible
- name: Install nginx
  apt:
    name: nginx
    state: present
```

**Puppet**
```puppet
# DSL propriétaire
package { 'nginx':
  ensure => installed,
}
```

**Chef**
```ruby
# Ruby
package 'nginx' do
  action :install
end
```

**SaltStack**
```yaml
# YAML
nginx:
  pkg.installed
```

### Quand utiliser quoi ?

**Choisissez Ansible pour :**
- Configuration management simple
- Déploiement d'applications
- Orchestration de workflows
- Environnements mixtes (cloud + on-premise)
- Équipe sans background développement

**Choisissez Puppet/Chef pour :**
- Infrastructure avec milliers de serveurs
- Besoin de pull model (auto-remédiation)
- Infrastructure hautement réglementée (compliance)
- Équipe avec compétences Ruby/DSL

**Choisissez SaltStack pour :**
- Event-driven automation
- Besoin de performance extrême
- Mix push/pull nécessaire

**Choisissez Terraform pour :**
- Provisioning infrastructure cloud (AWS, Azure, GCP)
- Infrastructure as Code
- Gestion du cycle de vie complet (create, update, destroy)

**Meilleure pratique : Combinez Terraform + Ansible**
```
1. Terraform → Créer l'infrastructure (VMs, réseau, cloud)
2. Ansible   → Configurer les systèmes (packages, apps, config)
```

---

## Cas d'usage

### 1. Configuration Management

**Problème :** Maintenir une configuration cohérente sur des centaines de serveurs.

**Solution Ansible :**
```yaml
---
- name: Configure all web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install standard packages
      apt:
        name:
          - vim
          - curl
          - htop
          - git
        state: present

    - name: Configure timezone
      timezone:
        name: Europe/Paris

    - name: Create admin user
      user:
        name: admin
        groups: sudo
        shell: /bin/bash
```

**Avantages :**
- Configuration centralisée
- Versionnable dans Git
- Auditable et reproductible

### 2. Application Deployment

**Problème :** Déployer une application sur plusieurs environnements (dev, staging, prod).

**Solution Ansible :**
```yaml
---
- name: Deploy web application
  hosts: "{{ environment }}"
  vars:
    app_version: "{{ version | default('latest') }}"
  tasks:
    - name: Pull latest code from Git
      git:
        repo: https://github.com/company/app.git
        dest: /var/www/app
        version: "{{ app_version }}"

    - name: Install dependencies
      pip:
        requirements: /var/www/app/requirements.txt
        virtualenv: /var/www/app/venv

    - name: Restart application
      systemd:
        name: myapp
        state: restarted
```

**Utilisation :**
```bash
# Deploy en dev
ansible-playbook deploy.yml -e "environment=dev"

# Deploy version spécifique en prod
ansible-playbook deploy.yml -e "environment=prod version=v2.1.0"
```

### 3. Infrastructure Provisioning

**Problème :** Créer et configurer des VMs dans le cloud.

**Solution Ansible :**
```yaml
---
- name: Provision AWS EC2 instances
  hosts: localhost
  tasks:
    - name: Create EC2 instances
      amazon.aws.ec2_instance:
        name: "web-server-{{ item }}"
        instance_type: t3.micro
        image_id: ami-0c55b159cbfafe1f0
        key_name: my-key
        vpc_subnet_id: subnet-12345
        security_group: sg-12345
        tags:
          Environment: production
          Role: webserver
      loop: "{{ range(1, 4) | list }}"
      register: ec2_instances

    - name: Wait for SSH to be available
      wait_for:
        host: "{{ item.public_ip }}"
        port: 22
        timeout: 300
      loop: "{{ ec2_instances.results }}"

- name: Configure newly created instances
  hosts: tag_Role_webserver
  become: yes
  tasks:
    - name: Install web server
      apt:
        name: nginx
        state: present
```

### 4. Orchestration complexe

**Problème :** Orchestrer un déploiement avec plusieurs étapes séquentielles.

**Solution Ansible :**
```yaml
---
- name: Rolling update of web servers
  hosts: webservers
  serial: 2  # Traite 2 serveurs à la fois
  tasks:
    - name: Remove from load balancer
      local_action:
        module: haproxy
        state: disabled
        host: "{{ inventory_hostname }}"

    - name: Update application
      git:
        repo: https://github.com/company/app.git
        dest: /var/www/app
        version: "{{ app_version }}"

    - name: Restart service
      systemd:
        name: myapp
        state: restarted

    - name: Wait for service to be healthy
      uri:
        url: "http://{{ inventory_hostname }}/health"
        status_code: 200
      retries: 5
      delay: 10

    - name: Add back to load balancer
      local_action:
        module: haproxy
        state: enabled
        host: "{{ inventory_hostname }}"
```

### 5. Security & Compliance

**Problème :** Appliquer des politiques de sécurité sur tous les serveurs.

**Solution Ansible :**
```yaml
---
- name: Harden security on all servers
  hosts: all
  become: yes
  tasks:
    - name: Ensure password policy is configured
      lineinfile:
        path: /etc/login.defs
        regexp: "^PASS_MAX_DAYS"
        line: "PASS_MAX_DAYS 90"

    - name: Disable root login via SSH
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^PermitRootLogin"
        line: "PermitRootLogin no"
      notify: Restart sshd

    - name: Install security updates
      apt:
        upgrade: safe
        update_cache: yes

    - name: Ensure fail2ban is installed
      apt:
        name: fail2ban
        state: present

  handlers:
    - name: Restart sshd
      service:
        name: sshd
        state: restarted
```

---

## Écosystème Ansible

```
┌─────────────────────────────────────────────────┐
│           Ansible Ecosystem                      │
├─────────────────────────────────────────────────┤
│                                                   │
│  Core                                            │
│  ├─ ansible-core (engine)                       │
│  ├─ ansible (core + collections)                │
│  └─ ansible-playbook (runner)                   │
│                                                   │
│  Outils                                          │
│  ├─ Ansible Tower (Enterprise Web UI)           │
│  ├─ AWX (Open-source Tower)                     │
│  ├─ Ansible Galaxy (partage rôles/collections)  │
│  ├─ ansible-lint (validation)                   │
│  ├─ Molecule (testing)                          │
│  └─ Ansible Vault (secrets)                     │
│                                                   │
│  Collections (namespaces)                        │
│  ├─ ansible.builtin (modules de base)           │
│  ├─ community.general                            │
│  ├─ amazon.aws                                   │
│  ├─ azure.azcollection                           │
│  ├─ google.cloud                                 │
│  └─ kubernetes.core                              │
│                                                   │
│  Intégrations                                    │
│  ├─ CI/CD (Jenkins, GitLab, GitHub Actions)     │
│  ├─ Monitoring (Prometheus, Grafana)            │
│  ├─ ITSM (ServiceNow, Jira)                     │
│  └─ Source Control (Git, GitHub, GitLab)        │
│                                                   │
│  Cloud Providers                                 │
│  ├─ AWS (EC2, S3, RDS, etc.)                    │
│  ├─ Azure (VMs, Storage, etc.)                  │
│  ├─ GCP (Compute Engine, etc.)                  │
│  ├─ VMware                                       │
│  └─ OpenStack                                    │
│                                                   │
│  Network Automation                              │
│  ├─ Cisco (IOS, NX-OS)                          │
│  ├─ Juniper (Junos)                             │
│  ├─ Arista (EOS)                                │
│  └─ F5 (BIG-IP)                                  │
└─────────────────────────────────────────────────┘
```

### Ansible vs Ansible Tower vs AWX

| Fonctionnalité | Ansible CLI | AWX | Ansible Tower |
|----------------|-------------|-----|---------------|
| **Interface** | CLI | Web UI | Web UI |
| **RBAC** | Non | Oui | Oui |
| **Scheduling** | Via cron | Oui | Oui |
| **API REST** | Non | Oui | Oui |
| **Job history** | Non | Oui | Oui |
| **Workflows** | Limité | Oui | Oui |
| **Support** | Community | Community | Red Hat |
| **Prix** | Gratuit | Gratuit | Payant |

**Recommendation :**
- **Ansible CLI** : Pour débuter, petites équipes, CI/CD
- **AWX** : Pour équipes moyennes, besoin Web UI, gratuit
- **Ansible Tower** : Entreprise, support Red Hat, compliance

---

## Concepts avancés

### 1. Ansible Collections

Les collections sont des packages qui regroupent modules, rôles, plugins.

**Structure d'une collection :**
```
namespace.collection/
├── docs/
├── galaxy.yml          # Métadonnées
├── plugins/
│   ├── modules/
│   ├── inventory/
│   └── filter/
├── roles/
└── playbooks/
```

**Installation :**
```bash
ansible-galaxy collection install community.general
```

**Utilisation :**
```yaml
- name: Use module from collection
  community.general.docker_container:
    name: myapp
    image: nginx
```

### 2. Ansible Modes

**Ad-hoc commands**
```bash
# Exécution ponctuelle sans playbook
ansible webservers -m ping
ansible webservers -m apt -a "name=nginx state=present" --become
```

**Playbook mode**
```bash
# Exécution déclarative via playbook
ansible-playbook site.yml
```

**Check mode (dry-run)**
```bash
# Voir ce qui serait changé sans appliquer
ansible-playbook site.yml --check
```

**Diff mode**
```bash
# Voir les différences de fichiers
ansible-playbook site.yml --diff
```

---

## Quand utiliser Ansible ?

### Utilisez Ansible pour :

- Configuration management de serveurs
- Déploiement d'applications
- Orchestration de workflows
- Provisioning cloud (avec Terraform)
- Automatisation réseau
- Gestion Windows (via WinRM)
- Security compliance
- Disaster recovery
- Continuous delivery

### N'utilisez PAS Ansible pour :

- Infrastructure Provisioning pure → Terraform
- Monitoring → Prometheus, Grafana, Datadog
- Log aggregation → ELK, Splunk
- Container orchestration → Kubernetes
- Latence ultra-faible → Scripts natifs
- Real-time event processing → SaltStack

---

## Architecture typique Terraform + Ansible

```
┌─────────────────────────────────────────────────┐
│              PHASE 1 : Terraform                 │
│  ┌───────────────────────────────────────────┐  │
│  │  Provisioning Infrastructure               │  │
│  │  ├─ VPC, Subnets, Security Groups         │  │
│  │  ├─ EC2 Instances                          │  │
│  │  ├─ Load Balancers                         │  │
│  │  ├─ S3 Buckets                             │  │
│  │  └─ RDS Databases                          │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────┘
                      │
                      │ terraform output -json > inventory.json
                      ▼
┌─────────────────────────────────────────────────┐
│              PHASE 2 : Ansible                   │
│  ┌───────────────────────────────────────────┐  │
│  │  Configuration Management                  │  │
│  │  ├─ Install packages (nginx, Docker)      │  │
│  │  ├─ Configure services                     │  │
│  │  ├─ Deploy applications                    │  │
│  │  ├─ Setup monitoring                       │  │
│  │  └─ Apply security policies               │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

**Workflow complet :**
1. Terraform crée l'infrastructure
2. Terraform output génère l'inventaire Ansible
3. Ansible configure les systèmes créés
4. Application déployée et opérationnelle

---

## Prochaines étapes

Maintenant que vous comprenez les bases d'Ansible, passez au module suivant :

**[02-Installation-Setup](../02-Installation-Setup/README.md)**

Vous allez apprendre à :
- Installer Ansible sur différentes plateformes
- Configurer ansible.cfg
- Setup SSH et clés d'authentification
- Exécuter votre premier ping
- Créer un environnement de test

---

## Ressources complémentaires

### Documentation officielle
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Getting Started](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

### Livres recommandés
- "Ansible for DevOps" - Jeff Geerling
- "Ansible: Up and Running" - Lorin Hochstein
- "Mastering Ansible" - James Freeman

### Cours vidéo
- [Ansible 101 by Jeff Geerling](https://www.youtube.com/watch?v=goclfp6a2IQ&list=PL2_OBreMn7FqZkvMYt6ATmgC0KAGGJNAN)
- [Red Hat Ansible Essentials](https://www.redhat.com/en/services/training/do007-ansible-essentials-simplicity-automation-technical-overview)

---

**"Automation is not about replacing people, it's about empowering them."**
