# Module 5 : Créer des Ressources Cloud

> **Durée : 1h30**
>
> Déployez des infrastructures complètes sur Azure et AWS

---

## 🎯 Objectifs d'Apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Créer des réseaux virtuels (VNet, VPC)
- ✅ Déployer des machines virtuelles (Azure VMs, AWS EC2)
- ✅ Configurer du stockage (Azure Storage Account, AWS S3)
- ✅ Créer des bases de données (Azure SQL, AWS RDS)
- ✅ Gérer les dépendances entre ressources
- ✅ Utiliser des data sources pour référencer des ressources existantes
- ✅ Construire une application 3-tier complète

---

## 📋 Table des Matières

- [Ressources Azure](#ressources-azure)
  - [Virtual Network et Subnets](#1-virtual-network-et-subnets)
  - [Machines Virtuelles](#2-machine-virtuelle-linux)
  - [Storage Account](#3-storage-account)
  - [Azure Database](#4-azure-database-for-postgresql)
  - [Kubernetes Service](#5-azure-kubernetes-service-aks)
- [Ressources AWS](#ressources-aws)
  - [VPC et Subnets](#1-vpc-et-subnets)
  - [EC2 Instances](#2-instance-ec2)
  - [S3 Buckets](#3-s3-bucket)
  - [RDS Database](#4-rds-database)
- [Concepts Avancés](#concepts-avancés)
- [Projet Pratique](#projet-pratique--application-3-tier)

---

## 🔷 Ressources Azure

### 1. Virtual Network et Subnets

```hcl
# Resource Group
resource "azurerm_resource_group" "network" {
  name     = "rg-network-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  tags = azurerm_resource_group.network.tags
}

# Subnet Web
resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet App
resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet Database
resource "azurerm_subnet" "db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  # Délégation pour Azure Database
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Group
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }
}

# Association NSG-Subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}
```

### 2. Machine Virtuelle Linux

```hcl
# Public IP
resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${var.environment}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = azurerm_resource_group.network.tags
}

# Network Interface
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${var.environment}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = azurerm_resource_group.network.tags
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.environment}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    name                 = "osdisk-vm-${var.environment}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Script de démarrage
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF
  )

  tags = azurerm_resource_group.network.tags
}

# Output
output "vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}
```

### 3. Storage Account

```hcl
# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "st${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.network.name
  location                 = azurerm_resource_group.network.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  account_kind             = "StorageV2"

  # Sécurité
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Network rules
  network_rules {
    default_action             = "Deny"
    ip_rules                   = [var.admin_source_ip]
    virtual_network_subnet_ids = [azurerm_subnet.app.id]
    bypass                     = ["AzureServices"]
  }

  tags = azurerm_resource_group.network.tags
}

# Random suffix pour nom unique
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Blob Container
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# File Share
resource "azurerm_storage_share" "shared" {
  name                 = "shared-files"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50
}

# Output
output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "blob_endpoint" {
  value = azurerm_storage_account.main.primary_blob_endpoint
}
```

### 4. Azure Database for PostgreSQL

```hcl
# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.environment}-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.network.name
  location               = azurerm_resource_group.network.location
  version                = "14"
  delegated_subnet_id    = azurerm_subnet.db.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  storage_mb = 32768
  sku_name   = var.environment == "prod" ? "GP_Standard_D4s_v3" : "B_Standard_B1ms"

  backup_retention_days        = var.environment == "prod" ? 35 : 7
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false

  tags = azurerm_resource_group.network.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Private DNS Zone pour PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.network.name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# Database
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Outputs
output "postgres_fqdn" {
  value     = azurerm_postgresql_flexible_server.main.fqdn
  sensitive = true
}
```

### 5. Azure Kubernetes Service (AKS)

```hcl
# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.environment}"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  dns_prefix          = "aks-${var.environment}"

  kubernetes_version = "1.28.0"

  default_node_pool {
    name                = "default"
    node_count          = var.environment == "prod" ? 3 : 1
    vm_size             = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B2s"
    vnet_subnet_id      = azurerm_subnet.app.id
    enable_auto_scaling = true
    min_count           = 1
    max_count           = var.environment == "prod" ? 5 : 3
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  tags = azurerm_resource_group.network.tags
}

# Output
output "kube_config" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}
```

---

## 🟧 Ressources AWS

### Configuration du Provider AWS

```hcl
# provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 1. VPC et Subnets

```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-${var.environment}"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public-${count.index + 1}-${var.environment}"
    Tier = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "subnet-private-${count.index + 1}-${var.environment}"
    Tier = "Private"
  }
}

# Data source pour les AZs disponibles
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-public-${var.environment}"
  }
}

# Association Route Table - Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group Web
resource "aws_security_group" "web" {
  name        = "sg-web-${var.environment}"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-web-${var.environment}"
  }
}
```

### 2. Instance EC2

```hcl
# Data source pour l'AMI Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.environment}"
  public_key = file("~/.ssh/id_rsa.pub")
}

# EC2 Instance
resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Web Server ${count.index + 1}</h1>" > /var/www/html/index.html
  EOF

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "web-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

# Elastic IP
resource "aws_eip" "web" {
  count    = var.instance_count
  instance = aws_instance.web[count.index].id
  domain   = "vpc"

  tags = {
    Name = "eip-web-${count.index + 1}-${var.environment}"
  }
}

# Output
output "instance_public_ips" {
  value = aws_eip.web[*].public_ip
}
```

### 3. S3 Bucket

```hcl
# S3 Bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "data-bucket-${var.environment}"
    Environment = var.environment
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = var.environment == "prod" ? "Enabled" : "Disabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "archive-old-objects"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# Output
output "s3_bucket_name" {
  value = aws_s3_bucket.data.id
}
```

### 4. RDS Database

```hcl
# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "db-subnet-group-${var.environment}"
  }
}

# Security Group Database
resource "aws_security_group" "db" {
  name        = "sg-db-${var.environment}"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-db-${var.environment}"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = "db-${var.environment}"
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = var.environment == "prod" ? "db.t3.medium" : "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = var.environment == "prod" ? 100 : 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  multi_az               = var.environment == "prod" ? true : false
  publicly_accessible    = false
  skip_final_snapshot    = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "db-${var.environment}-final-snapshot" : null

  tags = {
    Name        = "db-${var.environment}"
    Environment = var.environment
  }
}

# Output
output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}
```

---

## 🔗 Concepts Avancés

### 1. Dépendances Implicites vs Explicites

**Dépendances implicites** (automatiques via références) :

```hcl
resource "azurerm_virtual_network" "main" {
  # ...
}

resource "azurerm_subnet" "web" {
  virtual_network_name = azurerm_virtual_network.main.name  # Dépendance implicite
  # ...
}
```

**Dépendances explicites** (avec `depends_on`) :

```hcl
resource "azurerm_postgresql_flexible_server" "main" {
  # ...

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres  # Dépendance explicite
  ]
}
```

### 2. Data Sources (Ressources Existantes)

Les data sources permettent de référencer des ressources existantes :

```hcl
# Référencer un Resource Group existant
data "azurerm_resource_group" "existing" {
  name = "existing-rg"
}

# Utiliser ses propriétés
resource "azurerm_virtual_network" "new" {
  name                = "new-vnet"
  location            = data.azurerm_resource_group.existing.location
  resource_group_name = data.azurerm_resource_group.existing.name
  address_space       = ["10.0.0.0/16"]
}

# Référencer une image AWS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

### 3. Count et For_Each

**Count** (pour des ressources similaires) :

```hcl
resource "azurerm_subnet" "subnets" {
  count                = 3
  name                 = "subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.${count.index}.0/24"]
}

# Référencer : azurerm_subnet.subnets[0], azurerm_subnet.subnets[1], etc.
```

**For_Each** (pour des ressources avec clés) :

```hcl
variable "subnets" {
  type = map(string)
  default = {
    web = "10.0.1.0/24"
    app = "10.0.2.0/24"
    db  = "10.0.3.0/24"
  }
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = "subnet-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}

# Référencer : azurerm_subnet.subnets["web"], azurerm_subnet.subnets["app"], etc.
```

### 4. Conditionnels

```hcl
# Créer une ressource seulement en production
resource "azurerm_postgresql_flexible_server" "main" {
  count = var.environment == "prod" ? 1 : 0
  # ...
}

# Utiliser une valeur selon l'environnement
resource "azurerm_storage_account" "main" {
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  # ...
}
```

---

## 🏗️ Projet Pratique : Application 3-Tier

Créons une application complète avec 3 tiers (Web, App, Database).

### Architecture

```
┌─────────────────────────────────────────────┐
│              Load Balancer                   │
│           (Public Internet)                  │
└──────────────┬──────────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼────┐          ┌────▼───┐
│  Web1  │          │  Web2  │    ← Tier 1 (Public Subnet)
└───┬────┘          └────┬───┘
    │                     │
    └──────────┬──────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼────┐          ┌────▼───┐
│  App1  │          │  App2  │    ← Tier 2 (Private Subnet)
└───┬────┘          └────┬───┘
    │                     │
    └──────────┬──────────┘
               │
         ┌─────▼─────┐
         │ PostgreSQL│            ← Tier 3 (Private Subnet)
         └───────────┘
```

### Code Complet (Azure)

```hcl
# variables.tf
variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "web_vm_count" {
  type    = number
  default = 2
}

variable "app_vm_count" {
  type    = number
  default = 2
}

variable "db_admin_username" {
  type      = string
  sensitive = true
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}

# main.tf
resource "azurerm_resource_group" "main" {
  name     = "rg-3tier-${var.environment}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-3tier"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnets
resource "azurerm_subnet" "web" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

# Load Balancer
resource "azurerm_public_ip" "lb" {
  name                = "pip-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "main" {
  name                = "lb-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "BackEndAddressPool"
}

# Health Probe
resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "http-probe"
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Load Balancing Rule
resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
}

# Web VMs (simplified, use VMSS in production)
# App VMs
# Database (as shown earlier)

# outputs.tf
output "load_balancer_public_ip" {
  value = azurerm_public_ip.lb.ip_address
}

output "application_url" {
  value = "http://${azurerm_public_ip.lb.ip_address}"
}
```

---

## 📝 Points Clés à Retenir

1. **Réseaux** : Toujours créer des VNet/VPC avec subnets appropriés
2. **Sécurité** : Utiliser des NSG/Security Groups pour contrôler le trafic
3. **Dépendances** : Terraform gère automatiquement l'ordre de création
4. **Data Sources** : Pour référencer des ressources existantes
5. **Count/For_Each** : Pour créer plusieurs ressources similaires
6. **Conditionnels** : Pour adapter les ressources selon l'environnement
7. **Outputs** : Pour exposer les informations importantes (IPs, endpoints)

---

## ✅ Quiz de Compréhension

1. Quelle est la différence entre `count` et `for_each` ?
2. À quoi servent les data sources ?
3. Comment créer une ressource uniquement en production ?
4. Pourquoi utiliser des Security Groups / NSG ?
5. Comment référencer l'ID d'une ressource créée dans une autre ressource ?

---

## 🚀 Prochaine Étape

Vous savez maintenant créer des infrastructures complètes ! Mais comment gérer le state en équipe ?

**➡️ [Module 6 : Gestion du State](06-gestion-state.md)**

Dans le prochain module, vous allez :
- Comprendre le state file en profondeur
- Configurer un backend distant (Azure Storage, S3)
- Gérer le state locking
- Utiliser les commandes state avancées
- Sécuriser le state

---

[⬅️ Module précédent](04-variables-outputs.md) | [🏠 Retour à l'accueil](../README.md) | [➡️ Module suivant](06-gestion-state.md)
