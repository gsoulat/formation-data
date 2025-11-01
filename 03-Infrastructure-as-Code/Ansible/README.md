# Formation Ansible - Configuration Management

Bienvenue dans le cours complet sur Ansible, l'outil de gestion de configuration et d'automatisation IT le plus populaire.

## Vue d'ensemble

**Ansible** est un outil open-source d'automatisation IT qui permet de :
- Configurer des systèmes (Configuration Management)
- Déployer des applications (Application Deployment)
- Orchestrer des workflows complexes (Orchestration)
- Provisionner l'infrastructure (Infrastructure as Code)

### Pourquoi Ansible ?

- ✅ **Agentless** : Pas d'agent à installer (SSH/WinRM)
- ✅ **Simple** : YAML lisible par tous
- ✅ **Puissant** : 3000+ modules pour tout automatiser
- ✅ **Idempotent** : Exécutions répétées = même résultat
- ✅ **Extensible** : Custom modules, plugins, callbacks

## Structure du cours

### [01-Introduction](./01-Introduction/README.md) 🎯
**Découvrir Ansible**

- Qu'est-ce qu'Ansible ?
- Architecture (Control node, Managed nodes)
- Comparaison avec autres outils (Puppet, Chef, Salt)
- Cas d'usage et écosystème
- Concepts clés (Playbooks, Inventory, Modules, Roles)

**Durée estimée :** 1 jour

### [02-Installation-Setup](./02-Installation-Setup/README.md) ⚙️
**Installer et configurer Ansible**

- Installation (pip, apt, yum)
- Configuration ansible.cfg
- SSH setup et clés
- Premier ping et ad-hoc commands
- Environnement de test (Vagrant/Docker)

**Durée estimée :** 0.5 jour

### [03-Playbooks-Basics](./03-Playbooks-Basics/README.md) 📝
**Les Playbooks - Fondamentaux**

- Syntaxe YAML
- Tasks, plays, playbooks
- Handlers et notifications
- Idempotence
- Check mode et diff
- Tags et limits

**Exemples inclus :**
- `hello-world.yml` - Premier playbook
- `webserver.yml` - Installer Apache/Nginx
- `with-handlers.yml` - Utiliser les handlers

**Durée estimée :** 2 jours

### [04-Inventory](./04-Inventory/README.md) 📋
**Gestion de l'inventaire**

- Static inventory (INI, YAML)
- Dynamic inventory (AWS, Azure, GCP)
- Groups et patterns
- Variables d'inventaire
- Inventory plugins

**Exemples inclus :**
- `static-inventory/` - Inventaires statiques
- `dynamic-inventory/` - Scripts et plugins dynamiques
- `aws-inventory.yml` - Inventaire AWS EC2

**Durée estimée :** 1 jour

### [05-Modules](./05-Modules/README.md) 🔧
**Les Modules Ansible**

- Modules système (apt, yum, service, user)
- Modules fichiers (copy, template, file, lineinfile)
- Modules cloud (aws, azure, gcp)
- Modules réseau (command, shell vs modules)
- Modules Docker et Kubernetes

**Exemples inclus :**
- `package-management.yml` - Gérer les packages
- `file-operations.yml` - Opérations sur fichiers
- `service-management.yml` - Gérer les services
- `cloud-provisioning.yml` - Provisionner dans le cloud

**Durée estimée :** 2 jours

### [06-Roles](./06-Roles/README.md) 📦
**Rôles - Réutilisation du code**

- Structure d'un rôle
- Créer des rôles
- Dependencies entre rôles
- Ansible Galaxy
- Collections

**Exemples inclus :**
- `roles/webserver/` - Rôle serveur web
- `roles/database/` - Rôle base de données
- `roles/monitoring/` - Rôle monitoring
- `requirements.yml` - Gérer les dépendances

**Durée estimée :** 2 jours

### [07-Variables-Facts](./07-Variables-Facts/README.md) 🔢
**Variables et Facts**

- Types de variables (playbook, inventory, command-line)
- Precedence des variables
- Facts (gather_facts)
- Registered variables
- Magic variables
- group_vars et host_vars

**Exemples inclus :**
- `variables-demo.yml` - Utilisation des variables
- `group_vars/` - Variables par groupe
- `host_vars/` - Variables par host
- `facts-usage.yml` - Utiliser les facts

**Durée estimée :** 1.5 jours

### [08-Templates-Jinja2](./08-Templates-Jinja2/README.md) 📄
**Templates avec Jinja2**

- Syntaxe Jinja2
- Filters
- Conditions et loops
- Macros
- Templates de configuration

**Exemples inclus :**
- `nginx.conf.j2` - Template Nginx
- `app-config.yml.j2` - Configuration applicative
- `hosts.j2` - Fichier /etc/hosts dynamique
- `filters-demo.yml` - Utilisation des filters

**Durée estimée :** 1.5 jours

### [09-Ansible-Galaxy](./09-Ansible-Galaxy/README.md) 🌟
**Ansible Galaxy et Collections**

- Utiliser des rôles Galaxy
- Créer et publier des rôles
- Collections Ansible
- requirements.yml
- Namespaces et versioning

**Durée estimée :** 1 jour

### [10-Best-Practices](./10-Best-Practices/README.md) ⭐
**Bonnes pratiques et production**

- Directory structure
- Testing (Molecule, ansible-lint)
- CI/CD avec Ansible
- Ansible Vault (secrets)
- Performance et optimisation
- Troubleshooting

**Durée estimée :** 2 jours

### [Projets](./Projets/)
**Projets pratiques de bout en bout**

- **01-LAMP-Stack** : Déployer une stack LAMP complète
- **02-Kubernetes-Cluster** : Setup cluster K8s avec Ansible
- **03-Multi-Tier-App** : Application multi-tier avec load balancer

**Durée estimée :** 1 semaine

---

## Prérequis

### Connaissances requises

- **Linux** : Ligne de commande, administration système
- **SSH** : Connexion et clés SSH
- **YAML** : Syntaxe de base (ou à apprendre)
- **Réseau** : Concepts de base (IP, ports, firewall)

### Connaissances recommandées

- **Git** : Version control
- **Docker** : Pour environnement de test
- **Cloud** : AWS/Azure/GCP pour déploiements cloud
- **Python** : Pour modules custom (optionnel)

### Logiciels à installer

```bash
# Python 3.8+
python3 --version

# Ansible
ansible --version

# SSH
ssh -V

# (Optionnel) Vagrant pour VMs de test
vagrant --version

# (Optionnel) Docker
docker --version
```

---

## Installation rapide

### Option 1 : pip (Recommandé)

```bash
# Installer Ansible via pip
pip install ansible

# Vérifier l'installation
ansible --version
```

### Option 2 : Package manager

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# RHEL/CentOS
sudo yum install ansible

# macOS
brew install ansible
```

### Option 3 : Docker (pour tester)

```bash
docker run -it --rm \
  -v $(pwd):/ansible \
  cytopia/ansible:latest \
  ansible-playbook playbook.yml
```

---

## Parcours d'apprentissage

### Débutant (1 semaine)
1. 01-Introduction
2. 02-Installation-Setup
3. 03-Playbooks-Basics
4. 04-Inventory
5. 05-Modules (bases)
6. Mini-projet : Setup simple web server

### Intermédiaire (2 semaines)
1. Parcours Débutant
2. 05-Modules (complet)
3. 06-Roles
4. 07-Variables-Facts
5. 08-Templates-Jinja2
6. Projet 01 : LAMP Stack

### Avancé (4 semaines)
1. Parcours Intermédiaire
2. 09-Ansible-Galaxy
3. 10-Best-Practices
4. Les 3 projets pratiques
5. Testing avec Molecule
6. CI/CD avec Ansible

---

## Concepts clés à maîtriser

### 1. Architecture Ansible

```
Control Node (votre machine)
  ↓ SSH/WinRM
Managed Nodes (serveurs cibles)
```

**Agentless** : Pas besoin d'installer d'agent sur les serveurs cibles.

### 2. Inventory

```ini
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com
db2.example.com

[all:vars]
ansible_user=admin
```

### 3. Playbook

```yaml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present

    - name: Start Apache
      service:
        name: apache2
        state: started
```

### 4. Rôles

```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    │   └── nginx.conf.j2
    ├── files/
    ├── vars/
    │   └── main.yml
    └── defaults/
        └── main.yml
```

### 5. Idempotence

```yaml
# Cette tâche peut être exécutée plusieurs fois
# Résultat identique à chaque fois
- name: Ensure Apache is installed
  apt:
    name: apache2
    state: present
```

---

## Comparaison des outils

| Outil | Architecture | Langage | Courbe apprentissage | Cas d'usage |
|-------|--------------|---------|----------------------|-------------|
| **Ansible** | Agentless (SSH) | YAML | ⭐⭐ (Facile) | Config Management, Orchestration |
| **Puppet** | Agent-based | DSL propriétaire | ⭐⭐⭐⭐ (Difficile) | Config Management |
| **Chef** | Agent-based | Ruby | ⭐⭐⭐⭐ (Difficile) | Config Management |
| **SaltStack** | Agent-based | YAML/Python | ⭐⭐⭐ (Moyen) | Config Management, Event-driven |
| **Terraform** | Agentless | HCL | ⭐⭐ (Facile) | Infrastructure Provisioning |

### Quand utiliser Ansible ?

**✅ Utilisez Ansible pour :**
- Configuration management (installer packages, configurer services)
- Application deployment
- Orchestration de workflows
- Automatisation de tâches répétitives
- Configuration multi-OS (Linux, Windows)

**❌ N'utilisez PAS Ansible pour :**
- Provisioning infrastructure cloud → Utilisez Terraform
- Monitoring → Utilisez Prometheus, Grafana
- Log management → Utilisez ELK Stack

**💡 Combinez Ansible + Terraform :**
- Terraform → Provisionner l'infra (VMs, réseau, cloud)
- Ansible → Configurer les systèmes (packages, apps, config)

---

## Écosystème Ansible

```
Ansible Core
├── Ansible Engine
├── Ansible Playbooks
├── Ansible Modules (3000+)
└── Ansible Collections

Outils connexes
├── Ansible Galaxy (partage de rôles)
├── Ansible Tower / AWX (Web UI, entreprise)
├── Ansible Lint (validation)
├── Molecule (testing)
└── Ansible Vault (secrets)

Intégrations
├── Cloud (AWS, Azure, GCP, OpenStack)
├── Container (Docker, Kubernetes)
├── Network (Cisco, Juniper, Arista)
├── Monitoring (Prometheus, Grafana)
└── CI/CD (Jenkins, GitLab, GitHub Actions)
```

---

## Ressources

### Documentation officielle
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible Collections](https://docs.ansible.com/ansible/latest/collections/index.html)

### Livres recommandés
- **"Ansible for DevOps"** - Jeff Geerling
- **"Ansible: Up and Running"** - Lorin Hochstein & René Moser
- **"Mastering Ansible"** - James Freeman & Jesse Keating

### Cours en ligne
- [Ansible 101 by Jeff Geerling](https://www.youtube.com/watch?v=goclfp6a2IQ&list=PL2_OBreMn7FqZkvMYt6ATmgC0KAGGJNAN)
- [Red Hat Ansible Automation](https://www.redhat.com/en/services/training/do007-ansible-essentials-simplicity-automation-technical-overview)
- [Udemy Ansible Courses](https://www.udemy.com/topic/ansible/)

### Communautés
- [Ansible Community Forum](https://forum.ansible.com/)
- [Stack Overflow - ansible](https://stackoverflow.com/questions/tagged/ansible)
- [Reddit - r/ansible](https://reddit.com/r/ansible)
- [IRC - #ansible on Libera.Chat](https://web.libera.chat/#ansible)

---

## Certifications

- **Red Hat Certified Engineer (RHCE)** - Ansible Automation
- **Red Hat Certified Specialist in Ansible Automation**

---

## FAQ

**Q: Ansible vs Terraform, quelle différence ?**
A: Terraform provisionne l'infrastructure (créer VMs, réseaux). Ansible configure les systèmes (installer packages, configurer services). Ils sont complémentaires !

**Q: Faut-il connaître Python pour Ansible ?**
A: Non pour utiliser Ansible. Oui pour créer des modules custom.

**Q: Ansible Tower/AWX, c'est quoi ?**
A: Interface web pour Ansible (entreprise = Tower, open-source = AWX). Pas nécessaire pour débuter.

**Q: Ansible supporte Windows ?**
A: Oui, via WinRM au lieu de SSH.

**Q: Ansible est-il gratuit ?**
A: Oui, Ansible est open-source (GPL v3). Ansible Tower est payant, AWX est gratuit.

---

## Workflow type Terraform + Ansible

```
1. Terraform → Créer infrastructure
   ├─ VPC, subnets
   ├─ EC2 instances
   └─ Security groups

2. Terraform output → IPs des instances

3. Ansible → Configurer les instances
   ├─ Installer packages
   ├─ Configurer services
   ├─ Déployer applications
   └─ Setup monitoring

4. Terraform + Ansible → Infrastructure as Code complète
```

---

## Roadmap du cours

```
Semaine 1 : Fondamentaux
  ├─ Introduction et installation
  ├─ Playbooks basics
  └─ Inventory et modules

Semaine 2 : Intermédiaire
  ├─ Rôles et réutilisation
  ├─ Variables et facts
  └─ Templates Jinja2

Semaine 3 : Avancé
  ├─ Ansible Galaxy
  ├─ Best practices
  └─ Testing et CI/CD

Semaine 4 : Projets
  ├─ LAMP Stack
  ├─ Kubernetes Cluster
  └─ Multi-tier Application
```

---

**Bon apprentissage avec Ansible ! 🚀**

"Ansible makes infrastructure simple, powerful, and agentless."
