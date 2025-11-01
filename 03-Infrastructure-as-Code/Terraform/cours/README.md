# Formation Terraform - Infrastructure as Code

> **Formation complète pour maîtriser Terraform de zéro à expert**
> _Formation Data Engineering - Simplon_

## 🚀 Bienvenue !

Cette formation vous guide à travers l'apprentissage complet de Terraform, de l'installation jusqu'au déploiement d'infrastructures complexes en production. Avec **8 modules théoriques**, **5+ exemples de code pratiques**, et **6 exercices progressifs**, vous aurez toutes les clés pour devenir autonome sur Terraform.

---

## 📋 Table des Matières

- [À propos](#-à-propos)
- [Prérequis](#-prérequis)
- [Modules de Formation](#-modules-de-formation)
- [Structure du Cours](#-structure-du-cours)
- [Comment Utiliser Ce Cours](#-comment-utiliser-ce-cours)
- [Ressources Complémentaires](#-ressources-complémentaires)

---

## 🎯 À propos

Cette formation vous guide à travers l'apprentissage de **Terraform**, l'outil d'Infrastructure as Code (IaC) le plus populaire. Vous apprendrez à provisionner, gérer et versionner votre infrastructure cloud de manière déclarative et automatisée.

### Objectifs de la formation

- ✅ Comprendre les concepts fondamentaux de l'Infrastructure as Code
- ✅ Maîtriser la syntaxe et les commandes Terraform
- ✅ Déployer des infrastructures complètes sur Azure et AWS
- ✅ Gérer l'état (state) et les backends distants
- ✅ Créer des modules réutilisables
- ✅ Implémenter les best practices et l'automatisation CI/CD

### Durée estimée
**6 à 8 heures** pour l'ensemble de la formation (théorie + pratique)

---

## 📚 Prérequis

### Connaissances
- Bases de la ligne de commande (bash/shell)
- Compréhension générale du cloud computing
- Notions de Git (versionning)

### Outils requis
- Un compte Azure ou AWS (niveau gratuit acceptable)
- Un terminal (bash, zsh, PowerShell)
- Un éditeur de code (VS Code recommandé)
- Git installé

---

## 📖 Modules de Formation

### [Module 1 : Introduction à Terraform](modules/01-introduction.md)
**Durée : 45 min**

Découvrez Terraform et les concepts de l'Infrastructure as Code
- Qu'est-ce que Terraform ?
- Infrastructure as Code (IaC)
- Terraform vs autres outils (ARM, Bicep, Ansible, CloudFormation)
- Architecture et workflow Terraform
- Concepts clés : Providers, Resources, State

### [Module 2 : Installation et Configuration](modules/02-installation.md)
**Durée : 30 min**

Installez et configurez votre environnement de développement
- Installation de Terraform (macOS, Windows, Linux)
- Installation des CLI cloud (Azure CLI, AWS CLI)
- Authentification avec les providers cloud
- Configuration de VS Code et extensions

### [Module 3 : Premier Projet Terraform](modules/03-premier-projet.md)
**Durée : 1h**

Créez votre première infrastructure avec Terraform
- Structure d'un projet Terraform
- Fichiers de configuration (.tf)
- Commandes de base : `init`, `plan`, `apply`, `destroy`
- Workflow complet de déploiement
- Projet pratique : Déployer un Resource Group Azure

### [Module 4 : Variables et Outputs](modules/04-variables-outputs.md)
**Durée : 1h**

Rendez votre code flexible et réutilisable
- Déclarer et utiliser des variables
- Types de variables (string, number, bool, list, map, object)
- Valeurs par défaut et validation
- Fichiers .tfvars et variables d'environnement
- Outputs pour extraire des informations
- Projet pratique : Infrastructure paramétrable

### [Module 5 : Créer des Ressources Cloud](modules/05-ressources-cloud.md)
**Durée : 1h30**

Déployez des ressources complètes sur Azure et AWS
- **Azure** : VNet, VMs, Storage Account, Azure SQL, AKS
- **AWS** : VPC, EC2, S3, RDS, EKS
- Dépendances entre ressources
- Data sources pour référencer des ressources existantes
- Projet pratique : Application 3-tier sur Azure

### [Module 6 : Gestion du State](modules/06-gestion-state.md)
**Durée : 45 min**

Maîtrisez la gestion du state pour la production
- Comprendre le fichier terraform.tfstate
- State local vs remote
- Backends distants (Azure Storage, S3, Terraform Cloud)
- Verrouillage du state (state locking)
- Commandes state : list, show, mv, rm
- Sécurité et best practices

### [Module 7 : Modules Terraform](modules/07-modules.md)
**Durée : 1h**

Créez des composants d'infrastructure réutilisables
- Qu'est-ce qu'un module ?
- Structure d'un module
- Variables d'entrée et outputs de module
- Créer un module custom
- Utiliser des modules du Terraform Registry
- Versioning des modules
- Projet pratique : Module réseau Azure réutilisable

### [Module 8 : Best Practices et CI/CD](modules/08-best-practices-cicd.md)
**Durée : 1h30**

Professionnalisez vos déploiements Terraform
- Structure de projet recommandée
- Conventions de nommage et tags
- Gestion des secrets (Azure Key Vault, AWS Secrets Manager)
- Workspaces Terraform
- Pipelines CI/CD avec Azure DevOps
- Pipelines CI/CD avec GitHub Actions
- Tests automatisés (terratest)
- Projet final : Infrastructure complète avec CI/CD

---

## 📁 Structure du Cours

```
markdown/
├── README.md                           # 👋 Ce fichier - Guide principal
│
├── modules/                            # 📚 Modules théoriques
│   ├── 01-introduction.md              #     Introduction à Terraform & IaC
│   ├── 02-installation.md              #     Installation et configuration
│   ├── 03-premier-projet.md            #     Premier projet Terraform
│   ├── 04-variables-outputs.md         #     Variables et Outputs
│   ├── 05-ressources-cloud.md          #     Créer des ressources cloud
│   ├── 06-gestion-state.md             #     Gestion du State
│   ├── 07-modules.md                   #     Modules Terraform
│   └── 08-best-practices-cicd.md       #     Best Practices & CI/CD
│
├── exemples/                           # 💻 Exemples de code prêts à l'emploi
│   ├── README.md                       #     Guide des exemples
│   ├── azure/                          #     Exemples Azure
│   │   ├── README.md                   #     Guide exemples Azure
│   │   ├── storage-account/            #     ✅ Storage Account simple
│   │   ├── simple-vm/                  #     ✅ VM Linux complète
│   │   ├── network-module/             #     ✅ Module réseau réutilisable
│   │   ├── 3-tier-app/                 #     🚧 Application 3-tier
│   │   └── aks-cluster/                #     🚧 Cluster AKS
│   └── aws/                            #     Exemples AWS
│       ├── README.md                   #     Guide exemples AWS
│       ├── s3-bucket/                  #     ✅ S3 Bucket sécurisé
│       ├── simple-ec2/                 #     ✅ Instance EC2 + VPC
│       └── vpc-module/                 #     🚧 Module VPC
│
└── exercices/                          # ✏️ Exercices pratiques progressifs
    ├── README.md                       #     Guide des exercices
    ├── exercice-01-premiers-pas.md     #     Débutant - Premier projet
    ├── exercice-02-variables.md        #     Débutant - Variables & Outputs
    ├── exercice-03-ressources-multiples.md # Intermédiaire
    ├── exercice-04-remote-state.md     #     Intermédiaire
    ├── exercice-05-module.md           #     Avancé - Créer un module
    ├── exercice-06-cicd.md             #     Avancé - Pipeline CI/CD
    └── projet-final.md                 #     Expert - Projet complet
```

**Légende :**
- ✅ Disponible et complet
- 🚧 En construction (structure définie)

---

## 🚀 Comment Utiliser Ce Cours

### 1. Parcours Recommandé
Suivez les modules dans l'ordre numérique. Chaque module s'appuie sur les connaissances des précédents.

### 2. Apprentissage Pratique
- 📖 Lisez la théorie dans chaque module
- 💻 Testez tous les exemples de code
- ✏️ Réalisez les exercices pratiques
- 🎯 Complétez les projets de fin de module

### 3. Environnement de Pratique
Créez un dossier de travail pour vos exercices :
```bash
mkdir -p ~/terraform-formation
cd ~/terraform-formation
```

### 4. Versioning
Utilisez Git pour versionner vos exercices :
```bash
git init
git add .
git commit -m "Mon premier projet Terraform"
```

---

## 📚 Ressources Complémentaires

### Documentation Officielle
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Outils Utiles
- [Terraform Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
- [Azure CLI](https://docs.microsoft.com/cli/azure/)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform Cloud](https://app.terraform.io/)

### Communauté
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [Terraform GitHub](https://github.com/hashicorp/terraform)
- [r/Terraform sur Reddit](https://www.reddit.com/r/Terraform/)

---

## 🤝 Contribution et Feedback

Cette formation est un document vivant. Si vous trouvez des erreurs, avez des suggestions d'amélioration ou souhaitez contribuer :

1. Ouvrez une issue
2. Proposez une pull request
3. Contactez l'équipe pédagogique

---

## 📝 Licence

© 2025 - Formation Data Engineering - Simplon
Tous droits réservés - Usage pédagogique uniquement

---

**Prêt à commencer ?** 👉 [Module 1 : Introduction à Terraform](modules/01-introduction.md)
