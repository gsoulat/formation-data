# Projets Pratiques Ansible

Ces projets vous permettent de mettre en pratique les connaissances acquises dans les modules 01 à 10.

## Vue d'ensemble

| Projet | Niveau | Durée | Concepts clés |
|--------|--------|-------|---------------|
| **01-LAMP-Stack** | Intermédiaire | 5h | Roles, Templates, Multi-tier |
| **02-Kubernetes-Cluster** | Avancé | 6h | Orchestration, Complex deployment |
| **03-Multi-Tier-App** | Avancé | 6h | Full stack, Load balancing, HA |

---

## Projet 01 : Stack LAMP Complète

**Objectif** : Déployer une infrastructure web complète (HAProxy + Apache + MySQL + PHP).

**Ce que vous allez apprendre** :
- Créer et organiser des rôles Ansible
- Gérer un déploiement multi-serveurs
- Utiliser les templates Jinja2 pour la configuration
- Gérer les secrets avec Ansible Vault
- Implémenter un load balancer
- Tester l'idempotence

**Livrables** :
- Load balancer HAProxy configuré
- 2 serveurs web Apache + PHP
- Serveur de base de données MySQL
- Application web déployée
- Monitoring basique

**Prérequis** :
- Modules 01-08
- Connaissance Linux (Apache, MySQL)

**Durée estimée** : 5 heures

➡️ [Voir le projet](./01-LAMP-Stack/README.md)

---

## Projet 02 : Cluster Kubernetes

**Objectif** : Déployer un cluster Kubernetes (1 master + 2 workers) avec Ansible.

**Ce que vous allez apprendre** :
- Automatiser l'installation de Kubernetes
- Configurer le networking (Calico/Flannel)
- Gérer les certificats et la sécurité
- Déployer des applications sur K8s
- Utiliser des rôles Galaxy

**Livrables** :
- Cluster K8s opérationnel (kubeadm)
- CNI plugin configuré (Calico)
- Ingress controller (Nginx)
- Dashboard Kubernetes
- Monitoring (Prometheus + Grafana)

**Prérequis** :
- Tous les modules 01-10
- Connaissance Kubernetes basique
- Docker

**Durée estimée** : 6 heures

➡️ [Voir le projet](./02-Kubernetes-Cluster/README.md)

---

## Projet 03 : Application Multi-Tier

**Objectif** : Déployer une application 3-tiers (frontend + backend + database) avec haute disponibilité.

**Ce que vous allez apprendre** :
- Architecture multi-tier complète
- High availability (HAProxy + Keepalived)
- Database replication (MySQL Master-Slave)
- Application deployment avec rolling updates
- CI/CD avec Ansible
- Monitoring et alerting complets

**Livrables** :
- Frontend (React/Vue) avec Nginx
- Backend API (Node.js/Python)
- Database HA (MySQL replication)
- Load balancer HA (HAProxy + Keepalived)
- Pipeline CI/CD
- Monitoring stack complet

**Prérequis** :
- Tous les modules
- Projet 01 terminé
- Connaissance d'une stack web

**Durée estimée** : 6 heures

➡️ [Voir le projet](./03-Multi-Tier-App/README.md)

---

## Parcours recommandé

### Parcours Débutant/Intermédiaire (1 semaine)

1. **Modules** : 01-06
2. **Mini-projet** : Déployer un simple web server
3. **Projet** : 01-LAMP-Stack (simplifié, sans HA)

### Parcours Avancé (2 semaines)

1. **Modules** : Tous (01-10)
2. **Projets** : 01 + 02
3. **Objectif** : Maîtriser Ansible pour production

### Parcours Expert (3 semaines)

1. **Modules** : Tous avec approfondissement
2. **Projets** : Les 3 projets complets
3. **Extensions** : CI/CD, Monitoring, Sécurité avancée

---

## Critères d'évaluation

### Technique (50%)

- ✅ Infrastructure fonctionnelle
- ✅ Playbooks idempotents
- ✅ Utilisation correcte des rôles
- ✅ Variables bien organisées (group_vars, host_vars)
- ✅ Gestion des erreurs
- ✅ Code lisible et commenté

### Production-Ready (30%)

- ✅ Secrets avec Ansible Vault
- ✅ Tests (ansible-lint, Molecule)
- ✅ Documentation complète
- ✅ Logs configurés
- ✅ Monitoring en place
- ✅ Backup strategy

### Best Practices (20%)

- ✅ Structure de projet claire
- ✅ Réutilisabilité (rôles modulaires)
- ✅ Inventaire bien organisé
- ✅ Tags pour exécutions partielles
- ✅ Check mode fonctionnel
- ✅ Performances optimisées

---

## Extensions possibles

### Pour tous les projets

1. **Sécurité** :
   - SSL/TLS avec Let's Encrypt
   - Fail2ban
   - Audit et hardening

2. **Monitoring** :
   - Prometheus + Grafana
   - Alertmanager
   - ELK Stack pour les logs

3. **Backup** :
   - Backup automatique bases de données
   - Backup fichiers applicatifs
   - Disaster recovery

4. **CI/CD** :
   - GitLab CI / GitHub Actions
   - Tests automatisés
   - Déploiement blue/green

5. **Cloud** :
   - AWS (EC2, RDS, ELB)
   - Azure (VM, Database, Load Balancer)
   - GCP (Compute Engine, Cloud SQL)

---

## Environnement de test

### Option 1 : Vagrant (Recommandé pour débuter)

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  (1..4).each do |i|
    config.vm.define "server#{i}" do |node|
      node.vm.hostname = "server#{i}"
      node.vm.network "private_network", ip: "192.168.56.1#{i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
        vb.cpus = 1
      end
    end
  end
end
```

### Option 2 : Docker (Rapide mais limité)

```bash
# Lancer des conteneurs pour tester
docker run -d --name web1 --hostname web1 \
  -p 2221:22 rastasheep/ubuntu-sshd:18.04
```

### Option 3 : Cloud (AWS, Azure, GCP)

Utiliser Terraform pour provisionner, puis Ansible pour configurer.

---

## Ressources

### Datasets et applications

- **WordPress** : Application LAMP classique
- **Ghost** : Blog platform (Node.js)
- **GitLab** : Git server avec CI/CD
- **Nextcloud** : Cloud storage

### Outils utiles

- **Vagrant** : VMs locales
- **Molecule** : Tests de rôles Ansible
- **ansible-lint** : Validation syntaxe
- **Ansible Tower/AWX** : UI pour Ansible (entreprise)

### Documentation

- [Ansible Docs](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

---

## Support

Pour des questions sur les projets :

1. Consultez les README de chaque projet
2. Relisez les modules correspondants
3. Utilisez `ansible-doc <module>` pour la doc
4. Forums Ansible et Stack Overflow

---

## Checklist avant de commencer

- [ ] Ansible installé et fonctionnel
- [ ] SSH configuré (clés)
- [ ] Serveurs de test disponibles (Vagrant/Cloud)
- [ ] Éditeur configuré (VSCode + extension Ansible)
- [ ] Git configuré pour versioning
- [ ] Documentation Ansible accessible

---

**Bon courage pour vos projets ! 🚀**

"Ansible makes complex changes like code deploys, zero downtime rolling updates, and infrastructure provisioning simple and repeatable." - Jeff Geerling
