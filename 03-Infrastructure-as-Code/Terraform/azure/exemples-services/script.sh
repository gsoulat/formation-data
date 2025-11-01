#!/bin/bash

# Script pour créer l'architecture Azure équivalente à GCP
# Auteur: Assistant
# Date: $(date)

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Création de l'architecture Azure ===${NC}"

# Création du dossier principal
AZURE_DIR="Azure"
mkdir -p "$AZURE_DIR"
cd "$AZURE_DIR"

echo -e "${GREEN}✓ Dossier principal Azure créé${NC}"

# Fonction pour créer un dossier avec des fichiers Terraform de base
create_terraform_module() {
    local folder_name=$1
    local service_name=$2
    
    mkdir -p "$folder_name"
    cd "$folder_name"
    
    # Création du fichier main.tf
    cat > main.tf << EOF
# $service_name - Main configuration
# Generated on $(date)

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Reference to shared resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# $service_name resources will be defined here
EOF

    # Création du fichier variables.tf
    cat > variables.tf << EOF
# Variables for $service_name

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "azure-terraform-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "azure-project"
}
EOF

    # Création du fichier outputs.tf
    cat > outputs.tf << EOF
# Outputs for $service_name

# Add your outputs here
EOF

    cd ..
    echo -e "${GREEN}✓ Module $folder_name créé${NC}"
}

# 0. Credentials et configuration globale
echo -e "${YELLOW}Création du dossier credentials...${NC}"
mkdir -p "0_creds"
cd "0_creds"

cat > providers.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    storage {
      purge_soft_delete_on_destroy = true
    }
  }
}
EOF

cat > main.tf << 'EOF'
# Resource Group principal
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
EOF

cat > variables.tf << 'EOF'
variable "resource_group_name" {
  description = "Name of the main resource group"
  type        = string
  default     = "azure-terraform-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "azure-project"
}
EOF

cat > outputs.tf << 'EOF'
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}
EOF

cd ..

# 1. Azure Storage Account (équivalent Google Storage Bucket)
create_terraform_module "1_azure_storage_account" "Azure Storage Account"
cd "1_azure_storage_account"
cat >> main.tf << 'EOF'

resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}storage${var.environment}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  min_tls_version = "TLS1_2"
  
  tags = {
    Environment = var.environment
    Service     = "Storage"
  }
}

resource "azurerm_storage_container" "main" {
  name                  = "main-container"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
EOF
cd ..

# 2. Azure Virtual Machine (équivalent Google Compute Instance)
create_terraform_module "2_azure_virtual_machine" "Azure Virtual Machine"
cd "2_azure_virtual_machine"
cat >> main.tf << 'EOF'

# Network Security Group
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.project_name}-vm-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.project_name}-vm-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.project_name}-vm"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
EOF

cat >> variables.tf << 'EOF'

variable "subnet_id" {
  description = "ID of the subnet for the VM"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}
EOF
cd ..

# 3. Azure Virtual Network (équivalent Compute Network VPC)
create_terraform_module "3_azure_virtual_network" "Azure Virtual Network"
cd "3_azure_virtual_network"
cat >> main.tf << 'EOF'

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Service     = "Network"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}
EOF

cat >> outputs.tf << 'EOF'

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID of the internal subnet"
  value       = azurerm_subnet.internal.id
}
EOF
cd ..

# 4. Azure Service Bus (équivalent Pub/Sub)
create_terraform_module "4_azure_service_bus" "Azure Service Bus"
cd "4_azure_service_bus"
cat >> main.tf << 'EOF'

resource "azurerm_servicebus_namespace" "main" {
  name                = "${var.project_name}-servicebus"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Service     = "ServiceBus"
  }
}

resource "azurerm_servicebus_topic" "main" {
  name         = "main-topic"
  namespace_id = azurerm_servicebus_namespace.main.id
}

resource "azurerm_servicebus_subscription" "main" {
  name     = "main-subscription"
  topic_id = azurerm_servicebus_topic.main.id
}
EOF
cd ..

# 5. Azure Container Apps (équivalent Cloud Run)
create_terraform_module "5_azure_container_apps" "Azure Container Apps"
cd "5_azure_container_apps"
cat >> main.tf << 'EOF'

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-env"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}
EOF
cd ..

# 6. Azure Functions (équivalent Cloud Function)
create_terraform_module "6_azure_functions" "Azure Functions"
cd "6_azure_functions"
cat >> main.tf << 'EOF'

resource "azurerm_storage_account" "functions" {
  name                     = "${var.project_name}func${var.environment}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "functions" {
  name                = "${var.project_name}-functions-plan"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "main" {
  name                = "${var.project_name}-functions"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  service_plan_id            = azurerm_service_plan.functions.id

  site_config {}
}
EOF
cd ..

# 7. Azure Functions v2 (version alternative)
create_terraform_module "7_azure_functions_v2" "Azure Functions v2"

# 8. Azure App Service (équivalent App Engine)
create_terraform_module "8_azure_app_service" "Azure App Service"
cd "8_azure_app_service"
cat >> main.tf << 'EOF'

resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-appservice-plan"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "main" {
  name                = "${var.project_name}-webapp"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {}
}
EOF
cd ..

# 9. Azure SQL Database (équivalent Cloud SQL)
create_terraform_module "9_azure_sql_database" "Azure SQL Database"
cd "9_azure_sql_database"
cat >> main.tf << 'EOF'

resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-sqlserver"
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "main" {
  name           = "${var.project_name}-sqldb"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  sku_name       = "S0"
}
EOF

cat >> variables.tf << 'EOF'

variable "sql_admin_login" {
  description = "SQL Server administrator login"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}
EOF
cd ..

# 10. Azure Cosmos DB (équivalent Cloud Spanner)
create_terraform_module "10_azure_cosmos_db" "Azure Cosmos DB"
cd "10_azure_cosmos_db"
cat >> main.tf << 'EOF'

resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-cosmos"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
  }
}
EOF
cd ..

# 11. Azure Cosmos DB NoSQL (équivalent Firestore)
create_terraform_module "11_azure_cosmos_nosql" "Azure Cosmos DB NoSQL"
cd "11_azure_cosmos_nosql"
cat >> main.tf << 'EOF'

resource "azurerm_cosmosdb_account" "nosql" {
  name                = "${var.project_name}-cosmosnosql"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "nosql-database"
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.nosql.name
}
EOF
cd ..

# 12. Azure Synapse Analytics (équivalent BigQuery)
create_terraform_module "12_azure_synapse" "Azure Synapse Analytics"
cd "12_azure_synapse"
cat >> main.tf << 'EOF'

resource "azurerm_storage_account" "synapse" {
  name                     = "${var.project_name}synapse${var.environment}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse-filesystem"
  storage_account_id = azurerm_storage_account.synapse.id
}

resource "azurerm_synapse_workspace" "main" {
  name                                 = "${var.project_name}-synapse"
  resource_group_name                  = data.azurerm_resource_group.main.name
  location                             = data.azurerm_resource_group.main.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.synapse_admin_login
  sql_administrator_login_password     = var.synapse_admin_password

  identity {
    type = "SystemAssigned"
  }
}
EOF

cat >> variables.tf << 'EOF'

variable "synapse_admin_login" {
  description = "Synapse administrator login"
  type        = string
  default     = "synapseadmin"
}

variable "synapse_admin_password" {
  description = "Synapse administrator password"
  type        = string
  sensitive   = true
}
EOF
cd ..

# 13. Azure DevOps (équivalent Pipeline Bash)
create_terraform_module "13_azure_devops" "Azure DevOps"
cd "13_azure_devops"
cat >> main.tf << 'EOF'

# Note: Azure DevOps is typically managed outside of Terraform
# This module provides basic automation resources

resource "azurerm_automation_account" "main" {
  name                = "${var.project_name}-automation"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = "Basic"

  tags = {
    Environment = var.environment
    Service     = "Automation"
  }
}
EOF
cd ..

# Création du dossier images
mkdir -p "images"
echo "# Images directory" > images/README.md

# Création du fichier Archive.zip (vide)
touch Archive.zip

# Création du fichier README principal
cat > README.md << 'EOF'
# Architecture Azure avec Terraform

Cette architecture Azure est l'équivalent de l'architecture GCP originale.

## Structure

- `0_creds/` - Configuration des providers et resource group principal
- `1_azure_storage_account/` - Stockage Azure (équivalent Google Storage)
- `2_azure_virtual_machine/` - Machines virtuelles Azure (équivalent Compute Engine)
- `3_azure_virtual_network/` - Réseau virtuel Azure (équivalent VPC)
- `4_azure_service_bus/` - Service Bus Azure (équivalent Pub/Sub)
- `5_azure_container_apps/` - Container Apps Azure (équivalent Cloud Run)
- `6_azure_functions/` - Azure Functions (équivalent Cloud Functions)
- `7_azure_functions_v2/` - Azure Functions v2
- `8_azure_app_service/` - App Service Azure (équivalent App Engine)
- `9_azure_sql_database/` - Base de données SQL Azure (équivalent Cloud SQL)
- `10_azure_cosmos_db/` - Cosmos DB Azure (équivalent Cloud Spanner)
- `11_azure_cosmos_nosql/` - Cosmos DB NoSQL (équivalent Firestore)
- `12_azure_synapse/` - Synapse Analytics (équivalent BigQuery)
- `13_azure_devops/` - DevOps Azure (équivalent Pipeline)

## Prérequis

1. Azure CLI installé et configuré
2. Terraform installé
3. Compte Azure avec les permissions appropriées

## Déploiement

1. Se connecter à Azure :
   ```bash
   az login
   ```

2. Initialiser Terraform dans le dossier principal :
   ```bash
   cd 0_creds
   terraform init
   terraform plan
   terraform apply
   ```

3. Déployer les autres modules selon vos besoins

## Variables importantes

- `resource_group_name` : Nom du groupe de ressources
- `location` : Région Azure
- `environment` : Environnement (dev, staging, prod)
- `project_name` : Nom du projet

## Notes

- Tous les modules référencent le resource group principal
- Les noms des ressources sont générés automatiquement
- Les tags sont appliqués de manière cohérente
EOF

# Création d'un script de déploiement global
cat > deploy_all.sh << 'EOF'
#!/bin/bash

# Script de déploiement global
set -e

echo "=== Déploiement de l'infrastructure Azure ==="

# 1. Déployer le resource group principal
echo "1. Déploiement du resource group principal..."
cd 0_creds
terraform init
terraform plan -out=tfplan
terraform apply tfplan
cd ..

# 2. Déployer le réseau virtuel
echo "2. Déploiement du réseau virtuel..."
cd 3_azure_virtual_network
terraform init
terraform plan -out=tfplan
terraform apply tfplan
cd ..

# 3. Déployer le stockage
echo "3. Déploiement du stockage..."
cd 1_azure_storage_account
terraform init
terraform plan -out=tfplan
terraform apply tfplan
cd ..

echo "=== Déploiement terminé ==="
echo "Vous pouvez maintenant déployer les autres modules selon vos besoins."
EOF

chmod +x deploy_all.sh

# Création d'un script de nettoyage
cat > cleanup_all.sh << 'EOF'
#!/bin/bash

# Script de nettoyage global
set -e

echo "=== Nettoyage de l'infrastructure Azure ==="

# Détruire dans l'ordre inverse
for dir in 13_azure_devops 12_azure_synapse 11_azure_cosmos_nosql 10_azure_cosmos_db 9_azure_sql_database 8_azure_app_service 7_azure_functions_v2 6_azure_functions 5_azure_container_apps 4_azure_service_bus 2_azure_virtual_machine 1_azure_storage_account 3_azure_virtual_network 0_creds; do
    if [ -d "$dir" ]; then
        echo "Nettoyage de $dir..."
        cd "$dir"
        if [ -f "terraform.tfstate" ]; then
            terraform destroy -auto-approve
        fi
        cd ..
    fi
done

echo "=== Nettoyage terminé ==="
EOF

chmod +x cleanup_all.sh

echo -e "${GREEN}=== Architecture Azure créée avec succès ! ===${NC}"
echo -e "${BLUE}Dossiers créés :${NC}"
ls -la

echo -e "\n${YELLOW}Prochaines étapes :${NC}"
echo -e "1. ${GREEN}az login${NC} - Se connecter à Azure"
echo -e "2. ${GREEN}cd 0_creds && terraform init && terraform apply${NC} - Créer le resource group"
echo -e "3. ${GREEN}./deploy_all.sh${NC} - Déployer l'infrastructure de base"
echo -e "4. Modifier les modules selon vos besoins"

echo -e "\n${YELLOW}Scripts utiles :${NC}"
echo -e "- ${GREEN}./deploy_all.sh${NC} - Déploie l'infrastructure de base"
echo -e "- ${GREEN}./cleanup_all.sh${NC} - Supprime toute l'infrastructure"