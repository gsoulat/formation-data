# 🎓 Formation Terraform avec Azure

## Bienvenue dans votre formation Infrastructure as Code !

Ce cours vous permettra de maîtriser Terraform pour gérer votre infrastructure Azure de manière automatisée, reproductible et versionnée.

## 📺 Vidéo d'introduction

Avant de commencer, regardez cette vidéo qui présente Terraform et ses concepts fondamentaux :

[![Introduction à Terraform](https://img.youtube.com/vi/225uiqGmXsM/maxresdefault.jpg)](https://www.youtube.com/watch?v=225uiqGmXsM&t=6s)

**[▶️ Regarder la vidéo d'introduction sur YouTube](https://www.youtube.com/watch?v=225uiqGmXsM&t=6s)**

## 🎯 Objectifs de la formation

À la fin de cette formation, vous serez capable de :

- ✅ Installer et configurer Terraform sur votre OS
- ✅ Comprendre les concepts clés de l'Infrastructure as Code
- ✅ Créer et gérer des ressources Azure avec Terraform
- ✅ Organiser votre code Terraform de manière professionnelle
- ✅ Utiliser les variables, outputs et modules
- ✅ Gérer plusieurs environnements (dev, staging, prod)
- ✅ Collaborer en équipe avec un état distant
- ✅ Appliquer les bonnes pratiques du marché

## 👥 Public visé

Ce cours s'adresse aux :
- Développeurs souhaitant automatiser leurs déploiements
- DevOps débutants ou intermédiaires
- Administrateurs systèmes et cloud
- Toute personne voulant apprendre l'Infrastructure as Code

**Prérequis** :
- Connaissances de base en ligne de commande
- Compréhension des concepts cloud (VM, réseau, stockage)
- Un compte Azure (gratuit pour débuter)

## 📚 Structure du cours

### Module 1 : Introduction et Installation
**Durée estimée : 2 heures**

- [01 - Qu'est-ce que l'Infrastructure as Code ?](./parties/01-introduction.md)
- [02 - Installation de Terraform](./parties/02-installation.md)
- [03 - Installation et configuration Azure CLI](./parties/03-azure-cli.md)
- [04 - Premier projet Terraform](./parties/04-premier-projet.md)

### Module 2 : Les Fondamentaux
**Durée estimée : 4 heures**

- [05 - Syntaxe HCL (HashiCorp Configuration Language)](./parties/05-syntaxe-hcl.md)
- [06 - Providers et Resources](./parties/06-providers-resources.md)
- [07 - Variables et Outputs](./parties/07-variables-outputs.md)
- [08 - Le cycle de vie Terraform](./parties/08-cycle-de-vie.md)
- [09 - L'état Terraform (State)](./parties/09-etat-terraform.md)

### Module 3 : Concepts Avancés
**Durée estimée : 6 heures**

- [10 - Gestion des dépendances](./parties/10-dependances.md)
- [11 - Les boucles (count, for_each, for)](./parties/11-boucles.md)
- [12 - Les modules](./parties/12-modules.md)
- [13 - Data Sources](./parties/13-data-sources.md)
- [14 - Workspaces](./parties/14-workspaces.md)

### Module 4 : Pratiques Professionnelles
**Durée estimée : 4 heures**

- [15 - Backend distant](./parties/15-backend-distant.md)
- [16 - Organisation du code](./parties/16-organisation-code.md)
- [17 - Bonnes pratiques](./parties/17-bonnes-pratiques.md)
- [18 - Tests et validation](./parties/18-tests-validation.md)
- [19 - CI/CD avec Terraform](./parties/19-cicd.md)

### Module 5 : Projet Final
**Durée estimée : 4 heures**

- [20 - Projet guidé : Infrastructure complète](./parties/20-projet-final.md)

## 🗂️ Organisation des fichiers

```
cours/
├── README.md                    # Ce fichier
├── parties/                     # Modules du cours
│   ├── 01-introduction.md
│   ├── 02-installation.md
│   ├── ...
│   └── 20-projet-final.md
└── assets/                      # Images et ressources
    ├── diagrams/
    └── screenshots/

../azure/                        # Exemples pratiques (16 exemples)
├── 01-resource-group/
├── 02-depend_on/
├── 03-locals/
├── ...
└── 16-workspace/
```

## 💻 Exemples pratiques

Le cours est accompagné de **16 exemples pratiques** disponibles dans le dossier `../azure/` :

| Exemple | Concept | Difficulté |
|---------|---------|------------|
| 01 | Resource Group | ⭐ Débutant |
| 02 | Dépendances (depends_on) | ⭐⭐ Intermédiaire |
| 03 | Locals | ⭐ Débutant |
| 04 | Provisionneurs | ⭐⭐ Intermédiaire |
| 05 | Data Sources | ⭐⭐ Intermédiaire |
| 06 | Null Resources | ⭐⭐ Intermédiaire |
| 07 | Random Provider | ⭐ Débutant |
| 08 | Variables (tfvars) | ⭐⭐ Intermédiaire |
| 09 | Outputs | ⭐ Débutant |
| 10 | Backend distant | ⭐⭐⭐ Avancé |
| 11 | Import | ⭐⭐ Intermédiaire |
| 12 | Les boucles (count, for_each, for, dynamic) | ⭐⭐⭐ Avancé |
| 13 | Modules | ⭐⭐⭐ Avancé |
| 14 | Data Sources avancés | ⭐⭐ Intermédiaire |
| 15 | Provisionneurs avancés | ⭐⭐ Intermédiaire |
| 16 | Workspaces | ⭐⭐⭐ Avancé |

**Chaque exemple contient** :
- 📄 `main.tf` - Code principal
- 📝 `variables.tf` - Déclaration des variables
- 📤 `outputs.tf` - Sorties
- 📖 `README.md` - Documentation complète
- 📋 `dev.tfvars.example` - Exemple de configuration

## 📖 Comment suivre ce cours ?

### Approche recommandée

1. **Suivez l'ordre des modules** - Ils sont conçus pour progresser graduellement
2. **Pratiquez avec les exemples** - Testez chaque exemple dans `../azure/`
3. **Tapez le code vous-même** - Ne copiez-collez pas, c'est en codant qu'on apprend
4. **Prenez des notes** - Notez ce qui vous semble important
5. **Expérimentez** - Modifiez le code, cassez des choses, apprenez en corrigeant

### Temps estimé

- **Mode intensif** : 3-4 jours (temps plein)
- **Mode normal** : 2 semaines (2-3h par jour)
- **Mode tranquille** : 1 mois (1h par jour)

### Environnement de travail

Vous aurez besoin de :
- Un ordinateur (Windows, macOS ou Linux)
- Un compte Azure (gratuit pour commencer)
- Un éditeur de texte (VS Code recommandé)
- 2-3 heures de temps concentré

## 🛠️ Outils requis

### Obligatoires
- **Terraform** - L'outil que nous allons apprendre
- **Azure CLI** - Pour interagir avec Azure
- **Éditeur de texte** - VS Code recommandé

### Recommandés
- **Git** - Pour versionner votre code
- **VS Code extensions** :
  - HashiCorp Terraform
  - Azure Terraform
  - Azure Account
  - GitLens

## 💰 Coûts Azure

### Compte gratuit Azure

Microsoft offre :
- **200$ de crédit** valable 30 jours
- **Services gratuits** pendant 12 mois
- **Services toujours gratuits**

**Important** :
- ⚠️ Surveillez votre consommation
- ⚠️ Détruisez les ressources après les exercices
- ⚠️ Activez les alertes de budget

### Estimer les coûts

Pour ce cours, les ressources créées coûteront environ :
- **Resource Groups** : Gratuit
- **Storage Accounts** : ~0.50€/mois
- **App Services (B1)** : ~10€/mois
- **SQL Database (Basic)** : ~5€/mois

**Total estimé** : 15-20€ si vous laissez tourner un mois complet

**Astuce** : Détruisez tout avec `terraform destroy` après chaque session !

## 📋 Checklist avant de commencer

Avant de démarrer le Module 1, assurez-vous d'avoir :

- [ ] Un compte Azure actif
- [ ] Un ordinateur avec droits d'administration
- [ ] Une connexion internet stable
- [ ] 2-3 heures de disponibilité
- [ ] Un espace de travail calme

## 🎓 Méthodologie pédagogique

Chaque module suit cette structure :

1. **📖 Théorie** - Explication des concepts
2. **💡 Exemples** - Code commenté et expliqué
3. **🔧 Pratique** - Exercices guidés
4. **✅ Quiz** - Validation des acquis
5. **🎯 Projet** - Mise en application réelle

## 🆘 Besoin d'aide ?

### Ressources officielles
- [Documentation Terraform](https://www.terraform.io/docs)
- [Registry Terraform](https://registry.terraform.io/)
- [Documentation Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Documentation Azure](https://docs.microsoft.com/azure)

### Communauté
- [Forum Terraform](https://discuss.hashicorp.com/c/terraform-core)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/terraform)
- [Reddit r/Terraform](https://www.reddit.com/r/Terraform/)

### Erreurs courantes
Consultez le fichier [FAQ.md](./FAQ.md) pour les problèmes fréquents

## 🎯 Par où commencer ?

➡️ **Démarrez par le [Module 1 : Introduction](./parties/01-introduction.md)**

Cliquez sur le lien ci-dessus ou naviguez vers `parties/01-introduction.md` pour commencer votre apprentissage !

## 📊 Progression

Cochez au fur et à mesure de votre avancement :

### Module 1 : Introduction et Installation
- [ ] 01 - Introduction
- [ ] 02 - Installation
- [ ] 03 - Azure CLI
- [ ] 04 - Premier projet

### Module 2 : Les Fondamentaux
- [ ] 05 - Syntaxe HCL
- [ ] 06 - Providers et Resources
- [ ] 07 - Variables et Outputs
- [ ] 08 - Cycle de vie
- [ ] 09 - État Terraform

### Module 3 : Concepts Avancés
- [ ] 10 - Dépendances
- [ ] 11 - Boucles
- [ ] 12 - Modules
- [ ] 13 - Data Sources
- [ ] 14 - Workspaces

### Module 4 : Pratiques Professionnelles
- [ ] 15 - Backend distant
- [ ] 16 - Organisation
- [ ] 17 - Bonnes pratiques
- [ ] 18 - Tests
- [ ] 19 - CI/CD

### Module 5 : Projet Final
- [ ] 20 - Projet complet

## 🏆 Certification

Après avoir terminé ce cours, vous serez prêt pour :
- **HashiCorp Certified: Terraform Associate**
- **Microsoft Azure certifications** (AZ-104, AZ-400)

## 📝 Licence

Ce cours est fourni à des fins éducatives.

---

**Prêt à commencer ?** ➡️ [Module 1 : Introduction](./parties/01-introduction.md)

Bonne formation ! 🚀
