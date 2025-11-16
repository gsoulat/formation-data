# Deployment Pipelines

## Introduction

Les Deployment Pipelines dans Microsoft Fabric permettent de gérer le cycle de vie des artefacts à travers différents environnements (Dev, Test, Prod). Cette fonctionnalité native facilite les déploiements contrôlés, les tests de non-régression et la promotion sécurisée des modifications.

## Architecture des Deployment Pipelines

### Concept de Base

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Dev WS    │    │   Test WS   │    │   Prod WS   │
│  (Stage 1)  │ => │  (Stage 2)  │ => │  (Stage 3)  │
└─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │
       └──────────────────┴──────────────────┘
                    Deployment Pipeline
```

### Création d'un Pipeline

```powershell
# Création d'un deployment pipeline via API REST
$pipelineName = "Sales-Analytics-Pipeline"

$createPipelineBody = @{
    displayName = $pipelineName
    description = "Pipeline de déploiement pour les analytics ventes"
} | ConvertTo-Json

$pipelineUri = "https://api.fabric.microsoft.com/v1/deploymentPipelines"

$newPipeline = Invoke-RestMethod -Uri $pipelineUri `
    -Method Post `
    -Headers $headers `
    -Body $createPipelineBody

$pipelineId = $newPipeline.id
Write-Host "Pipeline created: $pipelineId"

# Assignation des workspaces aux stages
$stages = @(
    @{ stageOrder = 0; workspaceId = $devWorkspaceId },
    @{ stageOrder = 1; workspaceId = $testWorkspaceId },
    @{ stageOrder = 2; workspaceId = $prodWorkspaceId }
)

foreach ($stage in $stages) {
    $assignBody = @{
        workspaceId = $stage.workspaceId
    } | ConvertTo-Json

    $stageUri = "$pipelineUri/$pipelineId/stages/$($stage.stageOrder)/assignWorkspace"

    Invoke-RestMethod -Uri $stageUri -Method Post -Headers $headers -Body $assignBody
}
```

## Opérations de Déploiement

### Déploiement Sélectif

```python
import requests
import time

class DeploymentPipelineManager:
    def __init__(self, access_token):
        self.token = access_token
        self.base_url = "https://api.fabric.microsoft.com/v1/deploymentPipelines"
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }

    def get_pipeline_stages(self, pipeline_id):
        """
        Récupère les informations des stages
        """
        response = requests.get(
            f"{self.base_url}/{pipeline_id}/stages",
            headers=self.headers
        )
        return response.json()

    def compare_stages(self, pipeline_id, source_stage, target_stage):
        """
        Compare les artefacts entre deux stages
        """
        payload = {
            "sourceStageOrder": source_stage,
            "targetStageOrder": target_stage
        }

        response = requests.post(
            f"{self.base_url}/{pipeline_id}/stages/{source_stage}/compare",
            headers=self.headers,
            json=payload
        )
        return response.json()

    def deploy_all(self, pipeline_id, source_stage, target_stage):
        """
        Déploie tous les artefacts d'un stage à l'autre
        """
        payload = {
            "sourceStageOrder": source_stage,
            "isBackwardDeployment": False,
            "newWorkspace": None,
            "options": {
                "allowOverwriteArtifact": True,
                "allowCreateArtifact": True,
                "allowSkipTilesWithMissingPrerequisites": True
            }
        }

        response = requests.post(
            f"{self.base_url}/{pipeline_id}/deploy",
            headers=self.headers,
            json=payload
        )

        operation = response.json()
        return self._wait_for_operation(pipeline_id, operation['id'])

    def deploy_selective(self, pipeline_id, source_stage, target_stage, items):
        """
        Déploie des artefacts spécifiques
        """
        payload = {
            "sourceStageOrder": source_stage,
            "items": [
                {"itemId": item["id"], "itemType": item["type"]}
                for item in items
            ],
            "options": {
                "allowOverwriteArtifact": True,
                "allowCreateArtifact": True
            }
        }

        response = requests.post(
            f"{self.base_url}/{pipeline_id}/deploySelected",
            headers=self.headers,
            json=payload
        )

        operation = response.json()
        return self._wait_for_operation(pipeline_id, operation['id'])

    def _wait_for_operation(self, pipeline_id, operation_id, timeout=300):
        """
        Attend la fin d'une opération de déploiement
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            response = requests.get(
                f"{self.base_url}/{pipeline_id}/operations/{operation_id}",
                headers=self.headers
            )
            status = response.json()

            if status['status'] == 'Succeeded':
                return {'status': 'Success', 'details': status}
            elif status['status'] == 'Failed':
                return {'status': 'Failed', 'error': status.get('error')}

            time.sleep(10)

        return {'status': 'Timeout'}

# Exemple d'utilisation
# manager = DeploymentPipelineManager(token)
# comparison = manager.compare_stages(pipeline_id, 0, 1)
# result = manager.deploy_all(pipeline_id, 0, 1)
```

### Règles de Déploiement

```json
{
  "deploymentRules": {
    "dataSourceRules": [
      {
        "sourceType": "Sql",
        "sourceValue": {
          "server": "dev-server.database.windows.net",
          "database": "sales_dev"
        },
        "targetValue": {
          "server": "test-server.database.windows.net",
          "database": "sales_test"
        },
        "applyToStage": 1
      },
      {
        "sourceType": "Sql",
        "sourceValue": {
          "server": "test-server.database.windows.net",
          "database": "sales_test"
        },
        "targetValue": {
          "server": "prod-server.database.windows.net",
          "database": "sales_prod"
        },
        "applyToStage": 2
      }
    ],
    "parameterRules": [
      {
        "name": "Environment",
        "targetValue": {
          "0": "DEV",
          "1": "TEST",
          "2": "PROD"
        }
      },
      {
        "name": "RefreshSchedule",
        "targetValue": {
          "0": "Manual",
          "1": "Daily6AM",
          "2": "Daily5AM"
        }
      }
    ]
  }
}
```

## Automatisation CI/CD

### Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main

variables:
  - group: fabric-deployment-vars
  - name: pipelineId
    value: 'your-deployment-pipeline-id'

stages:
  - stage: DeployToTest
    displayName: 'Deploy Dev to Test'
    jobs:
      - job: Deploy
        steps:
          - task: PowerShell@2
            displayName: 'Authenticate to Fabric'
            inputs:
              targetType: 'inline'
              script: |
                $body = @{
                    grant_type    = "client_credentials"
                    client_id     = "$(ClientId)"
                    client_secret = "$(ClientSecret)"
                    resource      = "https://api.fabric.microsoft.com"
                }

                $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$(TenantId)/oauth2/token" -Method Post -Body $body
                Write-Host "##vso[task.setvariable variable=AccessToken;issecret=true]$($response.access_token)"

          - task: PowerShell@2
            displayName: 'Compare Stages'
            inputs:
              targetType: 'inline'
              script: |
                $headers = @{
                    Authorization = "Bearer $(AccessToken)"
                    'Content-Type' = 'application/json'
                }

                $compareUri = "https://api.fabric.microsoft.com/v1/deploymentPipelines/$(pipelineId)/stages/0/compare"
                $body = @{
                    sourceStageOrder = 0
                    targetStageOrder = 1
                } | ConvertTo-Json

                $comparison = Invoke-RestMethod -Uri $compareUri -Method Post -Headers $headers -Body $body
                Write-Host "Items to deploy: $($comparison.items.Count)"

          - task: PowerShell@2
            displayName: 'Execute Deployment'
            inputs:
              targetType: 'filePath'
              filePath: 'scripts/deploy-pipeline.ps1'
              arguments: '-PipelineId $(pipelineId) -SourceStage 0 -TargetStage 1'

  - stage: ApprovalForProd
    displayName: 'Wait for Production Approval'
    dependsOn: DeployToTest
    jobs:
      - job: WaitForApproval
        pool: server
        steps:
          - task: ManualValidation@0
            inputs:
              notifyUsers: 'approvers@company.com'
              instructions: 'Please validate Test environment before Production deployment'
              onTimeout: 'reject'

  - stage: DeployToProd
    displayName: 'Deploy Test to Production'
    dependsOn: ApprovalForProd
    jobs:
      - deployment: DeployProd
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: PowerShell@2
                  displayName: 'Deploy to Production'
                  inputs:
                    targetType: 'filePath'
                    filePath: 'scripts/deploy-pipeline.ps1'
                    arguments: '-PipelineId $(pipelineId) -SourceStage 1 -TargetStage 2'
```

### GitHub Actions

```yaml
# .github/workflows/fabric-deploy.yml
name: Fabric Deployment Pipeline

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-to-test:
    runs-on: ubuntu-latest
    environment: test
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Get Access Token
        id: get-token
        run: |
          TOKEN=$(curl -X POST \
            "https://login.microsoftonline.com/${{ secrets.TENANT_ID }}/oauth2/token" \
            -d "grant_type=client_credentials" \
            -d "client_id=${{ secrets.CLIENT_ID }}" \
            -d "client_secret=${{ secrets.CLIENT_SECRET }}" \
            -d "resource=https://api.fabric.microsoft.com" \
            | jq -r '.access_token')
          echo "::add-mask::$TOKEN"
          echo "token=$TOKEN" >> $GITHUB_OUTPUT

      - name: Deploy Dev to Test
        run: |
          python scripts/deploy.py \
            --pipeline-id ${{ secrets.PIPELINE_ID }} \
            --source-stage 0 \
            --target-stage 1 \
            --token ${{ steps.get-token.outputs.token }}

  deploy-to-prod:
    needs: deploy-to-test
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Get Access Token
        id: get-token
        run: |
          TOKEN=$(curl -X POST \
            "https://login.microsoftonline.com/${{ secrets.TENANT_ID }}/oauth2/token" \
            -d "grant_type=client_credentials" \
            -d "client_id=${{ secrets.CLIENT_ID }}" \
            -d "client_secret=${{ secrets.CLIENT_SECRET }}" \
            -d "resource=https://api.fabric.microsoft.com" \
            | jq -r '.access_token')
          echo "::add-mask::$TOKEN"
          echo "token=$TOKEN" >> $GITHUB_OUTPUT

      - name: Deploy Test to Production
        run: |
          python scripts/deploy.py \
            --pipeline-id ${{ secrets.PIPELINE_ID }} \
            --source-stage 1 \
            --target-stage 2 \
            --token ${{ steps.get-token.outputs.token }}
```

## Gestion des Versions

### Historique des Déploiements

```sql
-- Table de suivi des déploiements
CREATE TABLE deployment_tracking.deployment_history (
    deployment_id UNIQUEIDENTIFIER PRIMARY KEY,
    pipeline_name VARCHAR(255),
    source_stage VARCHAR(50),
    target_stage VARCHAR(50),
    deployed_by VARCHAR(255),
    deployment_time DATETIME2,
    status VARCHAR(50),
    items_count INT,
    duration_seconds INT,
    notes TEXT
);

-- Vue des derniers déploiements
SELECT
    pipeline_name,
    source_stage + ' -> ' + target_stage as deployment_path,
    deployed_by,
    deployment_time,
    status,
    items_count,
    FORMAT(DATEADD(second, duration_seconds, 0), 'HH:mm:ss') as duration
FROM deployment_tracking.deployment_history
ORDER BY deployment_time DESC;
```

## Points Clés

- Les Deployment Pipelines offrent un mécanisme natif de promotion entre environnements
- Utiliser les règles de déploiement pour adapter les connexions par environnement
- Automatiser les déploiements avec Azure DevOps ou GitHub Actions
- Implémenter des gates d'approbation pour la production
- Toujours comparer les stages avant de déployer
- Maintenir un historique des déploiements pour la traçabilité
- Tester dans Test avant de promouvoir vers Production
- Configurer des rollback plans en cas d'échec

---

**Navigation** : [Précédent : Git Integration](./01-git-integration.md) | [Index](../README.md) | [Suivant : Automated Testing](./03-automated-testing.md)
