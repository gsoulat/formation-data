# Terraform GitHub Organization Management

Ce système Terraform modulaire permet de créer et gérer des organisations GitHub avec des politiques de sécurité strictes, protection des branches, et validation des commits conventionnels.

## Fonctionnalités

- 🏢 **Gestion d'organisations** : Configuration automatisée des paramètres d'organisation
- 👥 **Gestion d'utilisateurs** : Ajout automatique d'utilisateurs avec rôles définis
- 📁 **Création de repositories** : Repositories par défaut (backend, frontend, data) + ajouts personnalisés
- 🔒 **Protection des branches** : Protection stricte de main/develop avec obligation de PR + review
- 📝 **Validation des commits** : Commits conventionnels obligatoires sur toutes les branches
- 🌿 **Nommage des branches** : Validation sémantique des noms de branches
- 🚀 **CI/CD automatique** : Workflows GitHub Actions intégrés
- ⚡ **Architecture modulaire** : Possibilité de dupliquer pour plusieurs organisations

## Structure du Projet

```
├── main.tf                     # Configuration principale
├── variables.tf                # Variables globales
├── outputs.tf                  # Sorties
├── terraform.tfvars.example    # Exemple de configuration
├── modules/
│   ├── github-org/            # Module organisation
│   ├── github-users/          # Module utilisateurs
│   ├── github-repo/           # Module repositories
│   └── github-policies/       # Module politiques et workflows
└── examples/
    └── multi-org/             # Exemple multi-organisations
```

## Prérequis

1. **Token GitHub** : Personal Access Token avec permissions `admin:org`
2. **Terraform** : Version >= 1.0
3. **Organisations GitHub** : Les organisations doivent exister (créées manuellement via l'interface web)

## Utilisation Rapide

### 1. Configuration de base

```bash
# Cloner et configurer
git clone <votre-repo>
cd github_terraform

# Copier et modifier la configuration
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs
```

### 2. Exemple terraform.tfvars

```hcl
# Configuration GitHub
github_token = "ghp_your_token_here"

# Configuration organisation
organization_name         = "my-company"
organization_display_name = "My Company"
organization_description  = "My Company GitHub Organization"
organization_email        = "admin@mycompany.com"

# Reviewer principal
reviewer_username = "your-github-username"

# Utilisateurs à ajouter
users = {
  "dev1" = {
    username = "developer1-github"
    role     = "member"
  }
  "dev2" = {
    username = "developer2-github" 
    role     = "member"
  }
}

# Repositories supplémentaires (optionnel)
repositories = {
  backend = {
    name        = "backend"
    description = "Backend application"
    private     = true
  }
  frontend = {
    name        = "frontend"  
    description = "Frontend application"
    private     = true
  }
  data = {
    name        = "data-pipeline"
    description = "Data processing"
    private     = true
  }
  mobile = {
    name        = "mobile-app"
    description = "Mobile application"
    private     = true
  }
}
```

### 3. Déploiement

```bash
# Initialiser Terraform
terraform init

# Planifier les changements
terraform plan

# Appliquer la configuration
terraform apply
```

## Gestion Multi-Organisations

Pour gérer plusieurs organisations (prod, staging, dev), utilisez l'exemple dans `examples/multi-org/` :

```bash
cd examples/multi-org
cp terraform.tfvars.example terraform.tfvars
# Configurer les 3 organisations
terraform init
terraform apply
```

## Politiques Appliquées

### Protection des Branches

- **main/develop** : Aucun push direct autorisé
- **Obligation de PR** : Toutes les modifications via Pull Request
- **Review obligatoire** : 1 approbation minimum requise
- **Reviewer automatique** : Le reviewer défini est automatiquement assigné

### Validation des Commits

**Format obligatoire** : `type(scope): description`

**Types autorisés** :
- `feat` : nouvelle fonctionnalité
- `fix` : correction de bug  
- `docs` : documentation
- `style` : formatage
- `refactor` : refactoring
- `perf` : amélioration performance
- `test` : tests
- `chore` : tâches de maintenance
- `ci` : intégration continue
- `build` : build
- `revert` : annulation

### Nommage des Branches

**Formats autorisés** :
- `feature/description` : nouvelles fonctionnalités
- `bugfix/description` : corrections de bugs
- `hotfix/description` : corrections urgentes
- `release/version` : branches de release
- `chore/description` : tâches de maintenance
- `docs/description` : documentation
- `refactor/description` : refactoring
- `test/description` : améliorations des tests

## Workflows CI/CD Intégrés

Chaque repository créé inclut automatiquement :

- **Validation des commits** : Vérification du format conventionnel
- **Validation des branches** : Vérification du nommage sémantique
- **Tests automatiques** : Support Node.js et Python
- **Linting** : Vérification qualité du code
- **Sécurité** : Scan de vulnérabilités avec Trivy

## Ajout d'Utilisateurs

Pour ajouter des utilisateurs, modifiez la variable `users` dans `terraform.tfvars` :

```hcl
users = {
  "nouvel_utilisateur" = {
    username = "github-username"
    role     = "member"  # ou "admin"
  }
}
```

Puis appliquez : `terraform apply`

## Ajout de Repositories

Pour ajouter des repositories, modifiez la variable `repositories` :

```hcl
repositories = {
  # Repositories existants...
  nouveau_repo = {
    name        = "nouveau-repository"
    description = "Description du nouveau repo"
    private     = true
  }
}
```

## Commandes Utiles

```bash
# Voir l'état actuel
terraform show

# Voir les sorties
terraform output

# Cibler un module spécifique
terraform plan -target=module.github_repositories

# Supprimer tout (ATTENTION!)
terraform destroy
```

## Dépannage

### Erreur de token
Vérifiez que votre token GitHub a les permissions `admin:org` et n'est pas expiré.

### Organisation inexistante  
Les organisations doivent être créées manuellement via l'interface GitHub avant d'utiliser Terraform.

### Conflit de noms
Assurez-vous que les noms de repositories sont uniques dans l'organisation.

## Sécurité

- Stockez le token GitHub de manière sécurisée (variables d'environnement, Terraform Cloud, etc.)
- Ne commitez jamais les fichiers `.tfvars` contenant des secrets
- Utilisez Terraform state encryption pour les environnements de production

## Support

Pour toute question ou problème, créez une issue dans ce repository.