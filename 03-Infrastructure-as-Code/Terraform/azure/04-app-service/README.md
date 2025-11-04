# Exemple 04 : App Service

## Objectif
Créer un **App Service** complet avec Terraform, incluant un Resource Group, un Service Plan, un App Service et un Storage Account.

## Concepts clés

### Architecture Azure App Service
```
Resource Group
    ├── App Service Plan (Hébergement)
    │   └── App Service (Application Web)
    └── Storage Account (Stockage de fichiers)
```

### Composants

#### 1. App Service Plan
- Définit les **ressources de calcul** pour votre application
- Équivalent à une "machine virtuelle" pour héberger plusieurs apps
- Paramètres : SKU (tier + size), OS (Linux/Windows)

#### 2. App Service
- L'**application web** elle-même
- Peut héberger plusieurs types d'apps : Web, API, Mobile backend
- Supporte Docker, Node.js, .NET, Python, Java, etc.

#### 3. Storage Account
- Service de **stockage** Azure
- Permet de stocker des blobs, files, tables, queues
- Paramètres : Tier (Standard/Premium), Replication (LRS, GRS, etc.)

### Génération de noms uniques
```hcl
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
```
- Génère une chaîne aléatoire pour garantir l'unicité des noms
- Nécessaire car les noms d'App Service et Storage doivent être **uniques globalement**

## Structure du code

Cet exemple crée :
1. Un Resource Group
2. Un App Service Plan (S1 Standard, Linux)
3. Un App Service avec Docker (nginx)
4. Un Storage Account

### Dépendances implicites
Terraform comprend automatiquement l'ordre de création grâce aux références :
```hcl
resource_group_name = azurerm_resource_group.rg.name
```
Cette référence crée une dépendance : le RG sera créé avant l'App Service

## Prérequis

1. Provider Azure configuré
2. Subscription Azure avec crédit suffisant (App Service S1 est payant !)
3. Authentification configurée (`az login`)

## Commandes

```bash
# 1. Initialiser (télécharge aussi le provider "random")
terraform init

# 2. Voir le plan (notez l'ordre de création)
terraform plan

# 3. Appliquer (création de ~4-5 ressources)
terraform apply

# 4. Récupérer l'URL de l'App Service
terraform state show azurerm_app_service.as | grep default_site_hostname

# 5. Tester l'application
curl https://<app-name>.azurewebsites.net

# 6. Détruire (attention aux coûts !)
terraform destroy
```

## Particularités

### App Service Plan - SKU
```hcl
sku {
  tier = "Standard"
  size = "S1"
}
```

Tiers disponibles :
- **Free (F1)** : Gratuit, limité
- **Shared (D1)** : Partagé, peu cher
- **Basic (B1-B3)** : Basique, bon pour dev/test
- **Standard (S1-S3)** : Production, support scaling
- **Premium (P1-P3)** : Haute performance

### Docker sur App Service
```hcl
site_config {
  linux_fx_version = "DOCKER|nginx:latest"
}
```
- Format : `DOCKER|<image>:<tag>`
- Peut utiliser Docker Hub ou Azure Container Registry
- Autres exemples :
  - `DOCKER|node:18-alpine`
  - `DOCKER|python:3.11-slim`

### Storage Account - Naming
```hcl
name = "gsobucket${random_string.suffix.result}"
```
- Doit être **unique globalement** (dans tout Azure)
- Autorise uniquement : lettres minuscules et chiffres
- Longueur : 3-24 caractères

## Points d'attention

### ⚠️ Coûts
- App Service Plan S1 : ~50-70€/mois
- Storage Account : Quelques centimes (selon usage)
- **N'oubliez pas de détruire** après les tests !

### 📝 Bonnes pratiques
- Toujours utiliser `random_string` pour les noms uniques
- Choisir le tier le plus bas pour les tests (Free ou B1)
- Utiliser le même `location` pour toutes les ressources d'un groupe
- Ajouter des tags pour identifier les ressources

## Structure des fichiers

```
04-app-service/
├── main.tf          # Configuration complète
└── README.md        # Ce fichier
```

## Exercices

1. **Changer l'image Docker** : Remplacez nginx par une autre image (node, python, etc.)
2. **Downgrade vers Free** : Modifiez le SKU pour utiliser le tier gratuit
3. **Ajouter des tags** : Ajoutez des tags aux ressources créées
4. **Storage Container** : Ajoutez un conteneur dans le Storage Account :
   ```hcl
   resource "azurerm_storage_container" "container" {
     name                  = "mycontainer"
     storage_account_name  = azurerm_storage_account.sa.name
     container_access_type = "private"
   }
   ```

## Vérification

```bash
# Lister toutes les ressources créées
terraform state list

# Voir les détails de l'App Service
az webapp show --name <app-name> --resource-group rg-soulat

# Voir les logs de l'App Service
az webapp log tail --name <app-name> --resource-group rg-soulat

# Tester l'application
curl https://<app-name>.azurewebsites.net
```

## Dépannage

### App Service ne démarre pas
```bash
# Voir les logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Vérifier la configuration
az webapp config show --name <app-name> --resource-group <rg-name>
```

### Nom de Storage déjà pris
```
Error: creating Storage Account: storage account name is already taken
```
**Solution** : Changez le préfixe ou relancez pour générer un nouveau suffix

### Quota dépassé
```
Error: creating App Service Plan: quota exceeded
```
**Solution** : Supprimez d'autres App Service Plans ou contactez le support Azure

## Différence avec les ressources dépréciées

⚠️ **Note importante** : Les ressources utilisées dans cet exemple sont dépréciées :
- `azurerm_app_service_plan` → Remplacé par `azurerm_service_plan`
- `azurerm_app_service` → Remplacé par `azurerm_linux_web_app` ou `azurerm_windows_web_app`

Cet exemple garde l'ancienne syntaxe à des fins pédagogiques, mais pour du nouveau code, utilisez :
```hcl
resource "azurerm_service_plan" "asp" {
  name                = "asp1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "app" {
  name                = "myapp${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      docker_image     = "nginx"
      docker_image_tag = "latest"
    }
  }
}
```

## Prochaines étapes

- Ajouter une base de données (voir exemple 05)
- Utiliser des variables pour la configuration (voir exemple 07)
- Configurer des slots de déploiement pour le blue/green deployment
- Ajouter Application Insights pour le monitoring

## Ressources

- [Documentation Terraform - App Service](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [App Service Pricing](https://azure.microsoft.com/en-us/pricing/details/app-service/)
- [Random Provider](https://registry.terraform.io/providers/hashicorp/random/latest/docs)
