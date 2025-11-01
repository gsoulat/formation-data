# Exemple Multi-Organisations GitHub

Cet exemple montre comment utiliser les modules Terraform pour gérer plusieurs organisations GitHub avec des environnements séparés (Production, Staging, Development).

## Architecture

- **Production** : Organisation pour l'environnement de production avec contrôles stricts
- **Staging** : Organisation pour les tests d'intégration et validation
- **Development** : Organisation pour le développement avec plus de flexibilité

## Configuration

### 1. Prérequis

- 3 organisations GitHub créées manuellement :
  - `mycompany-prod`
  - `mycompany-staging` 
  - `mycompany-dev`
- Token GitHub avec permissions `admin:org` sur les 3 organisations

### 2. Configuration

```bash
# Copier la configuration d'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
nano terraform.tfvars
```

### 3. Déploiement

```bash
# Initialiser
terraform init

# Planifier
terraform plan

# Appliquer
terraform apply
```

## Organisations Créées

### Production (`mycompany-prod`)
- **Repositories** : backend-prod, frontend-prod, data-pipeline-prod, infrastructure-prod
- **Utilisateurs** : Lead dev (admin), Senior devs, DevOps engineer
- **Politiques** : Protection stricte, reviews obligatoires

### Staging (`mycompany-staging`)  
- **Repositories** : backend-staging, frontend-staging, data-pipeline-staging, e2e-tests
- **Utilisateurs** : Lead dev (admin), Senior devs, QA engineer
- **Politiques** : Protection avec reviews, tests automatiques

### Development (`mycompany-dev`)
- **Repositories** : backend-dev, frontend-dev, data-pipeline-dev, experimental-features, docs
- **Utilisateurs** : Toute l'équipe incluant juniors et stagiaires
- **Politiques** : Protection avec reviews, plus de flexibilité

## Gestion des Utilisateurs

Chaque organisation peut avoir des utilisateurs différents selon les besoins :

```hcl
# Production - Accès limité
production_users = {
  "lead_dev" = { username = "lead-dev", role = "admin" }
  "senior_dev1" = { username = "senior-dev1", role = "member" }
  "devops" = { username = "devops-eng", role = "member" }
}

# Development - Accès élargi
development_users = {
  "lead_dev" = { username = "lead-dev", role = "admin" }
  "senior_dev1" = { username = "senior-dev1", role = "member" }
  "senior_dev2" = { username = "senior-dev2", role = "member" }
  "junior_dev1" = { username = "junior-dev1", role = "member" }
  "intern" = { username = "intern", role = "member" }
}
```

## Avantages de cette Architecture

- **Séparation claire** entre environnements
- **Contrôle d'accès** différencié par environnement
- **Workflows CI/CD** adaptés à chaque contexte
- **Gestion centralisée** via Terraform
- **Scalabilité** : facile d'ajouter de nouveaux environnements

## Commandes Utiles

```bash
# Cibler une organisation spécifique
terraform plan -target=module.production_org
terraform apply -target=module.development_org

# Voir les outputs
terraform output

# Détruire un environnement spécifique (ATTENTION!)
terraform destroy -target=module.staging_org
```