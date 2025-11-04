# Exemple 03 : Resource Group

## Objectif
Créer votre première ressource Azure avec Terraform : un **Resource Group**.

## Concepts clés

### Qu'est-ce qu'un Resource Group ?
- Un **conteneur logique** pour organiser les ressources Azure
- Toutes les ressources Azure doivent appartenir à un Resource Group
- Permet de gérer, surveiller et facturer un ensemble de ressources ensemble
- La suppression d'un RG supprime toutes les ressources qu'il contient

### Structure d'une ressource Terraform
```hcl
resource "type_de_ressource" "nom_local" {
  # paramètres de configuration
}
```

- `resource` : Mot-clé Terraform pour déclarer une ressource
- `"type_de_ressource"` : Type de la ressource (ex: `azurerm_resource_group`)
- `"nom_local"` : Nom utilisé dans Terraform pour référencer cette ressource
- Paramètres : Configuration spécifique à la ressource

## Structure du code

```hcl
provider "azurerm" {
  features {}
  subscription_id = "" # TODO : Mettre votre subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "rg1"
  location = "westeurope"
}
```

### Paramètres du Resource Group
- **name** : Nom du RG (doit être unique dans votre subscription)
- **location** : Région Azure où créer le RG
  - Exemples : `westeurope`, `francecentral`, `northeurope`, `eastus`

## Prérequis

1. Avoir configuré le provider Azure (voir exemple 01)
2. Être authentifié avec Azure CLI :
   ```bash
   az login
   ```
3. Connaître votre subscription ID :
   ```bash
   az account show --query id -o tsv
   ```

## Commandes

```bash
# 1. Initialiser Terraform
terraform init

# 2. Valider la syntaxe
terraform validate

# 3. Voir le plan d'exécution (ce qui va être créé)
terraform plan

# 4. Appliquer les changements (créer le RG)
terraform apply

# 5. Vérifier dans Azure
az group show --name rg1

# 6. Voir l'état actuel
terraform show

# 7. Détruire le Resource Group
terraform destroy
```

## Workflow Terraform

```
terraform init    →  terraform plan  →  terraform apply  →  terraform destroy
    ↓                    ↓                   ↓                    ↓
Télécharge        Prévisualise      Applique les         Supprime les
les providers     les changements   changements          ressources
```

## Points d'attention

### ⚠️ Important
- Le **nom** du RG doit être unique dans votre subscription Azure
- La **location** ne peut pas être modifiée après création (nécessite recréation)
- Terraform crée un fichier `terraform.tfstate` qui stocke l'état des ressources

### 📝 Bonnes pratiques
- Utiliser des noms descriptifs : `rg-<projet>-<env>` (ex: `rg-myapp-dev`)
- Choisir une location proche de vos utilisateurs
- Ne pas supprimer manuellement le fichier `terraform.tfstate`
- Toujours faire un `terraform plan` avant `terraform apply`

## Fichier d'état (terraform.tfstate)

Après un `terraform apply`, un fichier `terraform.tfstate` est créé :
```json
{
  "version": 4,
  "terraform_version": "1.x.x",
  "resources": [...]
}
```

Ce fichier :
- Contient l'état actuel de votre infrastructure
- Permet à Terraform de savoir ce qui existe déjà
- **Ne doit pas être modifié manuellement**
- **Doit être versionné avec précaution** (peut contenir des secrets)

## Structure des fichiers

```
03-resource_group/
├── main.tf          # Configuration du provider et du RG
└── README.md        # Ce fichier
```

## Exercices

1. **Modifier le nom** : Changez le nom du RG et faites un `terraform apply`. Que se passe-t-il ?
2. **Changer la location** : Modifiez la location. Terraform va-t-il modifier ou recréer le RG ?
3. **Ajouter des tags** : Ajoutez un bloc `tags` au Resource Group :
   ```hcl
   tags = {
     environment = "dev"
     managed_by  = "terraform"
   }
   ```

## Erreurs courantes

### Erreur : "Resource Group already exists"
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg1" already exists
```
**Solution** : Changez le nom du RG ou importez le RG existant avec `terraform import`

### Erreur : "Invalid location"
```
Error: creating Resource Group: location "paris" was not found
```
**Solution** : Utilisez un nom de location valide. Liste disponible avec :
```bash
az account list-locations -o table
```

### Erreur : "subscription_id is empty"
```
Error: building account: obtaining tenant ID: getting authenticated object ID
```
**Solution** : Remplissez le `subscription_id` ou utilisez `az login`

## Vérification

Pour vérifier que le RG a été créé :

```bash
# Via Azure CLI
az group list --output table

# Via le portail Azure
# https://portal.azure.com → Resource Groups

# Via Terraform
terraform state list
terraform state show azurerm_resource_group.rg
```

## Nettoyage

```bash
# Supprimer le Resource Group
terraform destroy

# Vérifier la suppression
az group show --name rg1
# Devrait retourner une erreur "ResourceGroupNotFound"
```

## Prochaines étapes

Maintenant que vous savez créer un Resource Group, vous pouvez :
- Créer des ressources à l'intérieur (Storage, VM, etc.)
- Utiliser des variables pour rendre le code réutilisable (voir exemple 07)
- Organiser plusieurs ressources ensemble (voir exemple 04)

## Ressources

- [Documentation Terraform - azurerm_resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
- [Azure Locations](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/)
- [Terraform State Documentation](https://www.terraform.io/docs/language/state/index.html)
