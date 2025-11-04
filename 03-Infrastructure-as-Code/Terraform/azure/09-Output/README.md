# Exemple 09 : Outputs

## Objectif
Apprendre à utiliser les **outputs** pour exposer des informations sur les ressources créées par Terraform.

## Concepts clés

### Qu'est-ce qu'un Output ?
- Un **output** est une valeur exposée par Terraform après l'exécution
- Permet d'**afficher** des informations importantes (URLs, IPs, noms, etc.)
- Peut être utilisé par d'autres **modules** ou **scripts** externes
- Déclaré avec le bloc `output`

### Cas d'usage
1. Afficher l'URL d'une application web
2. Récupérer des IDs de ressources pour d'autres outils
3. Partager des informations entre modules
4. Générer de la documentation automatiquement
5. Utiliser les valeurs dans des scripts post-déploiement

## Structure d'un output

```hcl
output "nom_output" {
  value       = <expression>
  description = "Description de l'output"
  sensitive   = true/false
}
```

### Paramètres

- **value** (obligatoire) : La valeur à exposer
- **description** (optionnel) : Description de l'output
- **sensitive** (optionnel) : Masque la valeur dans les logs si true

## Exemples d'outputs

### 1. Output simple (nom)
```hcl
output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}
```

### 2. Output avec description
```hcl
output "app_service_name" {
  value       = azurerm_app_service.as.name
  description = "Le nom de l'App Service créé"
}
```

### 3. Output d'URL
```hcl
output "app_service_url" {
  value       = azurerm_app_service.as.default_site_hostname
  description = "URL de l'application web"
}

# Utilisation dans la vraie vie :
# https://${azurerm_app_service.as.default_site_hostname}
```

### 4. Output sensible
```hcl
output "database_password" {
  value       = random_password.db_password.result
  sensitive   = true
  description = "Mot de passe de la base de données (masqué)"
}
```

### 5. Output formaté
```hcl
output "connection_string" {
  value = "Server=${azurerm_mssql_server.sql.fully_qualified_domain_name};Database=${azurerm_mssql_database.db.name}"
}
```

### 6. Output de liste
```hcl
output "container_names" {
  value       = azurerm_storage_container.containers[*].name
  description = "Noms de tous les conteneurs créés"
}
```

### 7. Output d'objet
```hcl
output "resource_group_info" {
  value = {
    name     = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    id       = azurerm_resource_group.rg.id
  }
}
```

## Structure du code (exemple 09)

Cet exemple crée :
- Resource Group
- Storage Account
- App Service Plan
- App Service

Et expose 3 outputs :
```hcl
output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "app_service_name" {
  value = azurerm_app_service.as.name
}

output "app_service_url" {
  value = azurerm_app_service.as.default_site_hostname
}
```

## Prérequis

1. Avoir complété les exemples précédents
2. Fichier `dev.tfvars` configuré
3. Provider Azure et authentification

## Commandes

```bash
# 1. Créer dev.tfvars depuis l'example
cp dev.tfvars.example dev.tfvars
# Éditer dev.tfvars avec vos valeurs

# 2. Initialiser
terraform init

# 3. Appliquer
terraform apply -var-file="dev.tfvars"

# 4. Voir tous les outputs
terraform output

# 5. Voir un output spécifique
terraform output app_service_url

# 6. Voir un output au format JSON
terraform output -json

# 7. Utiliser un output dans un script
APP_URL=$(terraform output -raw app_service_url)
echo "Application disponible sur : https://$APP_URL"
curl https://$APP_URL

# 8. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Formats de sortie

### Format par défaut (lisible)
```bash
$ terraform output
app_service_name = "soulatapp123abc"
app_service_url  = "soulatapp123abc.azurewebsites.net"
storage_account_name = "gsobucket123abc"
```

### Format JSON (-json)
```bash
$ terraform output -json
{
  "app_service_name": {
    "sensitive": false,
    "type": "string",
    "value": "soulatapp123abc"
  },
  "app_service_url": {
    "sensitive": false,
    "type": "string",
    "value": "soulatapp123abc.azurewebsites.net"
  }
}
```

### Format brut (-raw)
```bash
$ terraform output -raw app_service_url
soulatapp123abc.azurewebsites.net
```

## Utilisation avancée

### 1. Dans des scripts shell
```bash
#!/bin/bash

# Récupérer les outputs
APP_URL=$(terraform output -raw app_service_url)
STORAGE=$(terraform output -raw storage_account_name)

# Tester l'application
echo "Test de l'application..."
curl -I https://$APP_URL

# Upload un fichier
echo "Upload vers le storage..."
az storage blob upload \
  --account-name $STORAGE \
  --container-name data \
  --name test.txt \
  --file ./test.txt
```

### 2. Avec jq (parsing JSON)
```bash
# Extraire une valeur spécifique
terraform output -json | jq -r '.app_service_url.value'

# Créer un fichier de config
terraform output -json | jq '{
  app_url: .app_service_url.value,
  storage: .storage_account_name.value
}' > config.json
```

### 3. Entre modules
```hcl
# Module network
module "network" {
  source = "./modules/network"
}

# Utiliser l'output du module
resource "azurerm_virtual_machine" "vm" {
  subnet_id = module.network.subnet_id
}
```

### 4. Output conditionnel
```hcl
output "backup_enabled" {
  value       = var.enable_backup ? "Activé" : "Désactivé"
  description = "État du backup"
}
```

## Outputs sensibles

Pour les valeurs sensibles (mots de passe, clés API) :

```hcl
output "admin_password" {
  value     = random_password.password.result
  sensitive = true
}
```

Affichage :
```bash
$ terraform output
admin_password = <sensitive>

# Pour voir la valeur quand même
$ terraform output -raw admin_password
SuperSecretPassword123!
```

## Points d'attention

### ⚠️ Sécurité
- Les outputs **sensibles** sont masqués dans les logs
- Mais ils sont **stockés en clair** dans `terraform.tfstate`
- Ne commitez **jamais** le fichier tfstate !
- Utilisez un backend distant sécurisé pour le state

### 📝 Bonnes pratiques

1. **Ajouter des descriptions** à tous les outputs
2. **Marquer comme sensitive** les valeurs sensibles
3. **Grouper** les outputs par ressource dans le fichier
4. **Exposer** uniquement les informations utiles
5. **Formater** les valeurs pour faciliter l'utilisation

### ✅ Exemple bien organisé

```hcl
# ============================================
# RESOURCE GROUP OUTPUTS
# ============================================
output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Nom du resource group"
}

output "resource_group_location" {
  value       = azurerm_resource_group.rg.location
  description = "Location du resource group"
}

# ============================================
# APP SERVICE OUTPUTS
# ============================================
output "app_service_name" {
  value       = azurerm_app_service.as.name
  description = "Nom de l'App Service"
}

output "app_service_url" {
  value       = "https://${azurerm_app_service.as.default_site_hostname}"
  description = "URL complète de l'application"
}

output "app_service_outbound_ips" {
  value       = azurerm_app_service.as.outbound_ip_addresses
  description = "IPs sortantes de l'App Service"
}

# ============================================
# STORAGE OUTPUTS
# ============================================
output "storage_account_name" {
  value       = azurerm_storage_account.sa.name
  description = "Nom du storage account"
}

output "storage_primary_endpoint" {
  value       = azurerm_storage_account.sa.primary_blob_endpoint
  description = "Endpoint principal du blob storage"
}

output "storage_connection_string" {
  value       = azurerm_storage_account.sa.primary_connection_string
  sensitive   = true
  description = "Connection string du storage (sensible)"
}
```

## Structure des fichiers

```
09-Output/
├── main.tf              # Configuration principale
├── app_service.tf       # Configuration App Service
├── variable.tf          # Variables
├── output.tf            # 📄 Outputs
├── dev.tfvars.example   # Template
└── README.md            # Ce fichier
```

## Exercices

1. **Ajouter un output** : Ajoutez un output pour le Resource Group ID
2. **Output formaté** : Créez un output qui affiche l'URL complète (https://...)
3. **Output complexe** : Créez un output JSON avec toutes les infos importantes
4. **Script d'intégration** : Créez un script shell qui utilise les outputs
5. **Output conditionnel** : Ajoutez un output qui change selon une variable

## Génération de documentation

Les outputs peuvent servir à générer de la documentation :

```bash
# Créer un fichier markdown avec les outputs
cat <<EOF > deployment-info.md
# Deployment Information

## Application
- **Name**: $(terraform output -raw app_service_name)
- **URL**: https://$(terraform output -raw app_service_url)

## Storage
- **Account**: $(terraform output -raw storage_account_name)

## Date
- **Deployed**: $(date)
EOF
```

## Erreurs courantes

### Erreur : Output refers to sensitive value
```
Error: Output refers to sensitive value
```
**Solution** : Ajoutez `sensitive = true` à l'output

### Erreur : Reference to undeclared resource
```
Error: Reference to undeclared resource
```
**Solution** : Vérifiez que la ressource existe et que son nom est correct

### Erreur : No outputs found
```
Warning: No outputs found
```
**Solution** : Ajoutez des blocs `output` dans votre configuration

## Prochaines étapes

- Configurer un backend distant pour le state (voir exemple 10)
- Utiliser les outputs dans des modules (voir exemple 13)
- Intégrer les outputs dans des pipelines CI/CD

## Ressources

- [Documentation Terraform - Outputs](https://www.terraform.io/docs/language/values/outputs.html)
- [Output Values - Best Practices](https://www.terraform.io/docs/cloud/workspaces/outputs.html)
- [Sensitive Data in State](https://www.terraform.io/docs/language/state/sensitive-data.html)
