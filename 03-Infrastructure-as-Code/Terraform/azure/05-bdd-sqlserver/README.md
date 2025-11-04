# Exemple 05 : Base de données SQL Server

## Objectif
Créer un **Resource Group** basique pour préparer le déploiement d'une base de données SQL Server.

## Concepts clés

### Azure SQL Database
Azure propose plusieurs services de bases de données :
- **Azure SQL Database** : Base SQL managée (PaaS)
- **Azure SQL Managed Instance** : SQL Server quasi complet (PaaS)
- **SQL Server sur VM** : Contrôle total (IaaS)

### Architecture typique
```
Resource Group
    ├── SQL Server (Serveur logique)
    │   ├── SQL Database 1
    │   ├── SQL Database 2
    │   └── Firewall Rules
    └── Autres ressources...
```

## Structure du code

Cet exemple crée simplement :
- Un Resource Group avec un nom unique
- Utilise `random_string` pour éviter les conflits de noms

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-soulat"  # Nom du Resource Group
  location = "francecentral"  # Région France
}
```

## Localisation France

Le code utilise `francecentral` qui correspond au datacenter français :
- **France Central** : Paris (région principale)
- **France South** : Marseille (région secondaire)

Avantages :
- ✅ Données stockées en France
- ✅ Conformité RGPD
- ✅ Latence réduite pour les utilisateurs français

## Prérequis

1. Provider Azure configuré
2. Authentification Azure (`az login`)
3. Subscription ID configuré

## Commandes

```bash
# 1. Initialiser Terraform
terraform init

# 2. Voir le plan
terraform plan

# 3. Créer le Resource Group
terraform apply

# 4. Vérifier la création
az group show --name rg-soulat

# 5. Détruire
terraform destroy
```

## Extension : Ajouter une base SQL complète

Pour créer une base SQL Server complète, vous pouvez étendre cet exemple :

```hcl
# Générer un mot de passe aléatoire sécurisé
resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# Créer le serveur SQL
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sqlserver-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin_password.result

  tags = {
    environment = "dev"
  }
}

# Créer la base de données
resource "azurerm_mssql_database" "database" {
  name      = "mydb"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic"  # Tier le moins cher

  tags = {
    environment = "dev"
  }
}

# Règle de firewall (autoriser Azure services)
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Règle de firewall (votre IP locale)
resource "azurerm_mssql_firewall_rule" "allow_local" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "YOUR_IP_HERE"  # Remplacer par votre IP
  end_ip_address   = "YOUR_IP_HERE"
}

# Output pour récupérer les infos de connexion
output "sql_server_fqdn" {
  value     = azurerm_mssql_server.sql_server.fully_qualified_domain_name
  sensitive = false
}

output "sql_admin_password" {
  value     = random_password.sql_admin_password.result
  sensitive = true  # Masqué dans les logs
}
```

## SKU Database tiers

| SKU | vCore/DTU | RAM | Coût estimé | Usage |
|-----|-----------|-----|-------------|--------|
| Basic | 5 DTU | Basique | ~5€/mois | Dev/Test |
| S0 | 10 DTU | 250 MB | ~15€/mois | Petites apps |
| S1 | 20 DTU | 250 MB | ~30€/mois | Apps moyennes |
| P1 | 125 DTU | 500 MB | ~450€/mois | Production |

⚠️ **Attention aux coûts** : Même Basic peut coûter quelques euros par mois !

## Sécurité

### Règles de firewall
Par défaut, SQL Server bloque toutes les connexions. Vous devez :
1. Autoriser Azure Services (`0.0.0.0`)
2. Autoriser votre IP pour les tests
3. En production : utiliser Private Endpoint

### Mots de passe
- Utilisez `random_password` pour générer des mots de passe sécurisés
- Stockez les mots de passe dans Azure Key Vault
- Utilisez Managed Identity quand possible

## Points d'attention

### ⚠️ Important
- Les noms de serveur SQL doivent être **uniques globalement**
- Le mot de passe admin doit respecter les règles de complexité Azure
- Les bases SQL génèrent des coûts même si elles ne sont pas utilisées

### 📝 Bonnes pratiques
- Toujours utiliser `sensitive = true` pour les mots de passe dans les outputs
- Configurer le firewall de manière restrictive
- Activer les audits et la détection des menaces en production
- Utiliser le tier le plus bas pour les tests

## Structure des fichiers

```
05-bdd-sqlserver/
├── main.tf          # Configuration du Resource Group
└── README.md        # Ce fichier
```

## Se connecter à la base

```bash
# Via Azure CLI
az sql db show-connection-string --client sqlcmd --name mydb

# Via SQL Server Management Studio (SSMS)
# Serveur : <server-name>.database.windows.net
# Login : sqladmin
# Password : <from terraform output>

# Via psql ou autre client SQL
sqlcmd -S <server-name>.database.windows.net -U sqladmin -P <password> -d mydb
```

## Erreurs courantes

### Erreur : Server name already taken
```
Error: creating SQL Server: name is already taken
```
**Solution** : Utilisez un suffix aléatoire

### Erreur : Firewall blocking
```
Error: Cannot open server requested by the login
```
**Solution** : Ajoutez votre IP dans les règles de firewall

### Erreur : Password doesn't meet requirements
```
Error: Password does not meet complexity requirements
```
**Solution** : Le mot de passe doit contenir majuscules, minuscules, chiffres et caractères spéciaux

## Exercice

À partir de ce Resource Group, créez :
1. Un SQL Server avec un nom unique
2. Une base de données avec le tier Basic
3. Des règles de firewall appropriées
4. Des outputs pour afficher l'URL de connexion

## Prochaines étapes

- Connecter l'App Service à la base de données
- Configurer le backup automatique
- Mettre en place la géo-réplication
- Utiliser Azure Key Vault pour les secrets

## Ressources

- [Documentation Terraform - Azure SQL](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server)
- [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/database/)
- [SQL Database Pricing](https://azure.microsoft.com/en-us/pricing/details/sql-database/)
- [Connection Strings](https://docs.microsoft.com/en-us/azure/azure-sql/database/connect-query-content-reference-guide)
