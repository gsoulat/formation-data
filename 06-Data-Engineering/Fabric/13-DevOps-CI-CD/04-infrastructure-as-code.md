# Infrastructure as Code for Microsoft Fabric

## Introduction

L'Infrastructure as Code (IaC) permet de définir, déployer et gérer les ressources Microsoft Fabric de manière programmatique et reproductible. Cette approche apporte la traçabilité, la cohérence entre environnements et la possibilité de versionner l'infrastructure.

## Approches IaC pour Fabric

### 1. Terraform avec Azure Provider

```hcl
# main.tf - Configuration Terraform pour Fabric
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = "~> 1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "fabric_rg" {
  name     = "rg-fabric-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "FabricAnalytics"
    ManagedBy   = "Terraform"
  }
}

# Fabric Capacity
resource "azapi_resource" "fabric_capacity" {
  type      = "Microsoft.Fabric/capacities@2023-11-01"
  name      = "fabric-${var.environment}-capacity"
  location  = azurerm_resource_group.fabric_rg.location
  parent_id = azurerm_resource_group.fabric_rg.id

  body = jsonencode({
    sku = {
      name = var.fabric_sku
      tier = "Fabric"
    }
    properties = {
      administration = {
        members = var.capacity_admins
      }
    }
  })

  tags = {
    Environment = var.environment
  }
}

# Variables
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "fabric_sku" {
  description = "Fabric capacity SKU"
  type        = string
  default     = "F8"
}

variable "capacity_admins" {
  description = "List of capacity administrators"
  type        = list(string)
}

# Outputs
output "capacity_id" {
  value = azapi_resource.fabric_capacity.id
}

output "resource_group_name" {
  value = azurerm_resource_group.fabric_rg.name
}
```

### 2. Bicep Templates

```bicep
// fabric-infrastructure.bicep
@description('Environment name')
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('Fabric capacity SKU')
@allowed(['F2', 'F4', 'F8', 'F16', 'F32', 'F64'])
param fabricSku string = 'F8'

@description('Capacity administrators')
param capacityAdmins array

// Fabric Capacity
resource fabricCapacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: 'fabric-${environment}-capacity'
  location: location
  sku: {
    name: fabricSku
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: capacityAdmins
    }
  }
  tags: {
    Environment: environment
    ManagedBy: 'Bicep'
  }
}

// Log Analytics Workspace for monitoring
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-fabric-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

// Storage Account for backups
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stfabricbackup${environment}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

output capacityId string = fabricCapacity.id
output logAnalyticsId string = logAnalytics.id
output storageAccountName string = storageAccount.name
```

### 3. PowerShell Automation

```powershell
# deploy-fabric-infrastructure.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "./config"
)

# Load configuration
$config = Get-Content "$ConfigPath/fabric-config-$Environment.json" | ConvertFrom-Json

function Deploy-FabricCapacity {
    param($Config, $Env)

    Write-Host "Deploying Fabric Capacity for $Env environment..."

    $templatePath = "./bicep/fabric-infrastructure.bicep"
    $parametersPath = "./parameters/fabric-$Env.parameters.json"

    # Deploy using Azure CLI
    $deployment = az deployment group create `
        --resource-group $Config.resourceGroupName `
        --template-file $templatePath `
        --parameters $parametersPath `
        --name "fabric-deploy-$(Get-Date -Format 'yyyyMMddHHmm')" `
        --output json | ConvertFrom-Json

    if ($deployment.properties.provisioningState -eq "Succeeded") {
        Write-Host "Capacity deployment successful" -ForegroundColor Green
        return $deployment.properties.outputs
    } else {
        throw "Deployment failed: $($deployment.properties.error)"
    }
}

function Create-FabricWorkspaces {
    param($Config, $CapacityId)

    Write-Host "Creating Fabric Workspaces..."

    foreach ($workspace in $Config.workspaces) {
        $body = @{
            name = $workspace.name
            description = $workspace.description
            capacityId = $CapacityId
        } | ConvertTo-Json

        $uri = "https://api.fabric.microsoft.com/v1/workspaces"

        try {
            $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $global:headers -Body $body
            Write-Host "Created workspace: $($workspace.name)" -ForegroundColor Green

            # Assign permissions
            foreach ($permission in $workspace.permissions) {
                Add-WorkspacePermission -WorkspaceId $result.id -Permission $permission
            }
        } catch {
            Write-Host "Error creating workspace $($workspace.name): $_" -ForegroundColor Red
        }
    }
}

function Create-FabricArtifacts {
    param($WorkspaceId, $Artifacts)

    foreach ($artifact in $Artifacts) {
        $definitionPath = "./definitions/$($artifact.type)/$($artifact.name).json"
        $definition = Get-Content $definitionPath | ConvertFrom-Json

        $body = @{
            displayName = $artifact.name
            type = $artifact.type
            definition = $definition
        } | ConvertTo-Json -Depth 10

        $uri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items"

        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $global:headers -Body $body
        Write-Host "Created $($artifact.type): $($artifact.name)"
    }
}

# Main execution
try {
    # Authenticate
    $token = Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com"
    $global:headers = @{
        Authorization = "Bearer $($token.Token)"
        'Content-Type' = 'application/json'
    }

    # Set subscription context
    Set-AzContext -SubscriptionId $SubscriptionId

    # Deploy infrastructure
    $outputs = Deploy-FabricCapacity -Config $config -Env $Environment

    # Create workspaces
    Create-FabricWorkspaces -Config $config -CapacityId $outputs.capacityId.value

    Write-Host "Infrastructure deployment completed successfully!" -ForegroundColor Green

} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
```

## Configuration as Code

### Workspace Configuration

```json
// config/workspace-definition.json
{
  "workspaces": [
    {
      "name": "WS-Sales-DataPlatform-Dev",
      "description": "Sales data platform development workspace",
      "permissions": [
        {
          "identifier": "SG-DataEngineers",
          "principalType": "Group",
          "role": "Member"
        },
        {
          "identifier": "admin@company.com",
          "principalType": "User",
          "role": "Admin"
        }
      ],
      "artifacts": [
        {
          "name": "LH_Sales_Bronze",
          "type": "Lakehouse",
          "description": "Bronze layer for raw sales data"
        },
        {
          "name": "LH_Sales_Silver",
          "type": "Lakehouse",
          "description": "Silver layer for cleaned sales data"
        },
        {
          "name": "DW_Sales_Gold",
          "type": "Warehouse",
          "description": "Gold layer data warehouse"
        },
        {
          "name": "PL_Daily_Ingestion",
          "type": "DataPipeline",
          "definition": "pipelines/daily-ingestion.json"
        }
      ],
      "settings": {
        "defaultLakehouse": "LH_Sales_Bronze",
        "gitIntegration": {
          "enabled": true,
          "provider": "AzureDevOps",
          "repository": "fabric-artifacts",
          "branch": "develop"
        }
      }
    }
  ]
}
```

### Pipeline Definition as Code

```json
// definitions/DataPipeline/PL_Daily_Ingestion.json
{
  "name": "PL_Daily_Ingestion",
  "properties": {
    "activities": [
      {
        "name": "Copy_Raw_Sales",
        "type": "Copy",
        "inputs": [
          {
            "referenceName": "Source_SQL",
            "type": "DatasetReference"
          }
        ],
        "outputs": [
          {
            "referenceName": "Sink_Bronze",
            "type": "DatasetReference"
          }
        ],
        "typeProperties": {
          "source": {
            "type": "SqlServerSource",
            "sqlReaderQuery": "SELECT * FROM Sales WHERE ModifiedDate >= '@{pipeline().parameters.LastRunDate}'"
          },
          "sink": {
            "type": "ParquetSink",
            "writeBehavior": "MergeOrUpsert"
          }
        }
      },
      {
        "name": "Transform_Silver",
        "type": "SparkNotebook",
        "dependsOn": [
          {
            "activity": "Copy_Raw_Sales",
            "dependencyConditions": ["Succeeded"]
          }
        ],
        "typeProperties": {
          "notebookPath": "notebooks/transform_to_silver"
        }
      },
      {
        "name": "Load_Gold",
        "type": "DataWarehouseInsert",
        "dependsOn": [
          {
            "activity": "Transform_Silver",
            "dependencyConditions": ["Succeeded"]
          }
        ],
        "typeProperties": {
          "storedProcedure": "sp_LoadFactSales"
        }
      }
    ],
    "parameters": {
      "LastRunDate": {
        "type": "string",
        "defaultValue": "@formatDateTime(addDays(utcNow(), -1), 'yyyy-MM-dd')"
      }
    }
  }
}
```

## CI/CD Pipeline pour IaC

```yaml
# azure-pipelines-iac.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - infrastructure/**
      - config/**

stages:
  - stage: Validate
    jobs:
      - job: ValidateInfrastructure
        steps:
          - task: AzureCLI@2
            displayName: 'Validate Bicep'
            inputs:
              azureSubscription: 'Azure-Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az bicep build --file infrastructure/fabric-infrastructure.bicep

          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'
              workingDirectory: 'infrastructure/terraform'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: PlanChanges
        steps:
          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: 'infrastructure/terraform'
              environmentServiceNameAzureRM: 'Azure-Connection'
              commandOptions: '-out=tfplan'

          - publish: infrastructure/terraform/tfplan
            artifact: terraform-plan

  - stage: DeployDev
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
    jobs:
      - deployment: DeployDevInfra
        environment: 'fabric-dev-infrastructure'
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: terraform-plan

                - task: TerraformTaskV4@4
                  displayName: 'Apply Infrastructure'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    workingDirectory: 'infrastructure/terraform'
                    commandOptions: 'tfplan'
```

## Points Clés

- Utiliser IaC pour garantir la reproductibilité des environnements
- Versionner toutes les définitions d'infrastructure dans Git
- Séparer les configurations par environnement (dev, test, prod)
- Valider automatiquement les templates avant déploiement
- Utiliser des paramètres pour éviter la duplication
- Documenter les dépendances entre ressources
- Implémenter des state management robuste (Terraform state)
- Appliquer les mêmes pratiques de review de code à l'infrastructure

---

**Navigation** : [Précédent : Automated Testing](./03-automated-testing.md) | [Index](../README.md) | [Suivant : Release Management](./05-release-management.md)
