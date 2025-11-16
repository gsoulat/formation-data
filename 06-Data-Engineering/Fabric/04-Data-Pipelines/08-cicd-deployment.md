# CI/CD et Deployment

## Introduction

Le **CI/CD** (Continuous Integration / Continuous Deployment) permet de gérer le cycle de vie des pipelines de manière automatisée et fiable.

```
CI/CD Workflow:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│     DEV     │ →  │   STAGING   │ →  │    PROD     │
├─────────────┤    ├─────────────┤    ├─────────────┤
│ Development │    │ Integration │    │ Production  │
│ Testing     │    │ Validation  │    │ Live data   │
└─────────────┘    └─────────────┘    └─────────────┘
       ↓                  ↓                  ↓
    Git Push         CI Pipeline        Deployment
```

## Git Integration (Fabric)

### Connecter Git au Workspace

```
1. Workspace → Settings → Git integration
2. Connect to Azure DevOps ou GitHub
3. Select organization / repository
4. Select branch (main, develop)
5. Sync workspace avec repository
```

**Structure Repository :**
```
my-fabric-repo/
├── Pipelines/
│   ├── ETL_Daily_Sales.json
│   ├── Transform_Customers.json
│   └── Load_Warehouse.json
├── Dataflows/
│   └── Clean_Customer_Data.json
├── Notebooks/
│   └── Transform_Bronze_to_Silver.ipynb
└── README.md
```

### Commit et Push

```
1. Modify pipeline dans Fabric UI
2. Workspace → Source control
3. Review changes (diff viewer)
4. Commit message: "feat: add incremental load to sales pipeline"
5. Commit & Push
```

**Commit Messages Convention :**
```
feat: nouvelle fonctionnalité
fix: correction de bug
refactor: refactoring sans changement fonctionnel
docs: documentation
test: ajout de tests
chore: maintenance (dependencies, config)

Examples:
  feat: add watermark-based incremental load
  fix: handle null values in customer_name column
  refactor: extract common copy logic to shared pipeline
```

### Branches Strategy

**GitFlow Pattern :**
```
main
  └─ Production-ready code

develop
  └─ Integration branch

feature/
  ├─ feature/incremental-load
  ├─ feature/add-customer-dimension
  └─ feature/new-data-source

hotfix/
  └─ hotfix/fix-null-handling
```

**Workflow :**
```
1. Create feature branch from develop
   git checkout -b feature/incremental-load

2. Develop dans Fabric workspace (connected to feature branch)

3. Test et validate

4. Create Pull Request: feature/incremental-load → develop

5. Code review

6. Merge to develop

7. Deploy to STAGING (from develop)

8. Integration testing

9. Pull Request: develop → main

10. Deploy to PROD (from main)
```

## Deployment Pipelines

### Fabric Deployment Pipelines

**Setup :**
```
1. Workspace → Deployment pipelines
2. Create pipeline:
   ├─ Development (workspace: DEV_Workspace)
   ├─ Test (workspace: TEST_Workspace)
   └─ Production (workspace: PROD_Workspace)
3. Assign workspaces to stages
```

**Deployment Process :**
```
1. Develop dans DEV_Workspace
2. Deploy DEV → TEST
   └─ Review changes
   └─ Deploy selected items
3. Test et validate dans TEST
4. Deploy TEST → PROD
   └─ Approval required
   └─ Deploy
```

**Deployment Rules :**
```json
{
  "rules": [
    {
      "stage": "Production",
      "requireApproval": true,
      "approvers": ["data-leads@company.com"],
      "scheduledDeployment": {
        "enabled": true,
        "window": {
          "days": ["Saturday", "Sunday"],
          "hours": [0, 6]
        }
      }
    }
  ]
}
```

### Parameterization par Environment

**Pipeline Parameters :**
```json
{
  "parameters": {
    "environment": {
      "type": "String",
      "defaultValue": "dev"
    },
    "source_server": {
      "type": "String",
      "defaultValue": "@pipeline().parameters.environment == 'prod' ? 'sql-prod.company.com' : 'sql-dev.company.com'"
    },
    "batch_size": {
      "type": "Int",
      "defaultValue": "@if(equals(pipeline().parameters.environment, 'prod'), 10000, 100)"
    }
  }
}
```

**Config File Pattern :**
```json
// config.dev.json
{
  "sourceServer": "sql-dev.company.com",
  "sourceDatabase": "SalesDB_Dev",
  "targetLakehouse": "Lakehouse_Dev",
  "batchSize": 100,
  "enableLogging": true
}

// config.prod.json
{
  "sourceServer": "sql-prod.company.com",
  "sourceDatabase": "SalesDB",
  "targetLakehouse": "Lakehouse_Prod",
  "batchSize": 10000,
  "enableLogging": false
}
```

**Load Config dans Pipeline :**
```json
{
  "name": "Load_Config",
  "type": "WebActivity",
  "typeProperties": {
    "url": "@concat('https://config.company.com/', pipeline().parameters.environment, '/config.json')",
    "method": "GET"
  }
}
```

## Azure DevOps Pipelines

### CI Pipeline (Build)

```yaml
# azure-pipelines-ci.yml

trigger:
  branches:
    include:
      - develop
      - main
  paths:
    include:
      - Pipelines/**
      - Dataflows/**
      - Notebooks/**

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '3.10'

- script: |
    pip install azure-cli
    pip install pyfabric
  displayName: 'Install dependencies'

- script: |
    # Validate JSON syntax
    find ./Pipelines -name '*.json' -exec python -m json.tool {} \; > /dev/null
  displayName: 'Validate Pipeline JSON'

- script: |
    # Run pipeline linting
    python scripts/lint_pipelines.py
  displayName: 'Lint Pipelines'

- script: |
    # Check for secrets in code
    python scripts/check_secrets.py
  displayName: 'Security Scan'

- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: '$(Build.SourcesDirectory)'
    ArtifactName: 'fabric-pipelines'
  displayName: 'Publish Artifacts'
```

### CD Pipeline (Deploy)

```yaml
# azure-pipelines-cd.yml

trigger: none  # Manual ou après CI

stages:
- stage: Deploy_to_Staging
  jobs:
  - deployment: DeployStaging
    environment: 'Fabric-Staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadBuildArtifacts@0
            inputs:
              artifactName: 'fabric-pipelines'

          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Fabric-Service-Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Deploy pipelines to Staging workspace
                az login --service-principal -u $servicePrincipalId -p $servicePrincipalKey --tenant $tenantId

                # Upload pipelines
                python scripts/deploy_pipelines.py \
                  --workspace "Staging_Workspace" \
                  --source "./Pipelines" \
                  --environment "staging"

          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Fabric-Service-Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Run smoke tests
                python scripts/run_smoke_tests.py \
                  --workspace "Staging_Workspace"

- stage: Deploy_to_Production
  dependsOn: Deploy_to_Staging
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployProduction
    environment: 'Fabric-Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Fabric-Service-Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Deploy to Production
                python scripts/deploy_pipelines.py \
                  --workspace "Production_Workspace" \
                  --source "./Pipelines" \
                  --environment "prod"

          - task: AzureCLI@2
            inputs:
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                # Post-deployment validation
                python scripts/validate_deployment.py \
                  --workspace "Production_Workspace"
```

## GitHub Actions

```yaml
# .github/workflows/deploy.yml

name: Deploy Fabric Pipelines

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'Pipelines/**'
      - 'Dataflows/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install azure-cli pyfabric

      - name: Validate JSON
        run: |
          find ./Pipelines -name '*.json' -exec python -m json.tool {} \; > /dev/null

      - name: Lint Pipelines
        run: |
          python scripts/lint_pipelines.py

  deploy-staging:
    needs: validate
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Staging
        run: |
          python scripts/deploy_pipelines.py \
            --workspace "Staging_Workspace" \
            --source "./Pipelines" \
            --environment "staging"

  deploy-production:
    needs: validate
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Production
        run: |
          python scripts/deploy_pipelines.py \
            --workspace "Production_Workspace" \
            --source "./Pipelines" \
            --environment "prod"

      - name: Validate Deployment
        run: |
          python scripts/validate_deployment.py \
            --workspace "Production_Workspace"

      - name: Notify Teams
        if: success()
        uses: actions/github-script@v6
        with:
          script: |
            const webhook = '${{ secrets.TEAMS_WEBHOOK }}';
            await fetch(webhook, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                text: `✅ Deployment successful to Production`
              })
            });
```

## Deployment Scripts

### deploy_pipelines.py

```python
#!/usr/bin/env python3

import argparse
import json
import os
from pathlib import Path
from azure.identity import DefaultAzureCredential
from pyfabric import FabricClient

def deploy_pipelines(workspace_name, source_dir, environment):
    """Deploy pipelines to Fabric workspace."""

    # Authenticate
    credential = DefaultAzureCredential()
    client = FabricClient(credential)

    # Get workspace
    workspace = client.get_workspace(workspace_name)

    # Load environment config
    with open(f'config.{environment}.json') as f:
        config = json.load(f)

    # Deploy each pipeline
    pipeline_dir = Path(source_dir)
    for pipeline_file in pipeline_dir.glob('*.json'):
        with open(pipeline_file) as f:
            pipeline_def = json.load(f)

        # Replace environment-specific values
        pipeline_json = json.dumps(pipeline_def)
        for key, value in config.items():
            pipeline_json = pipeline_json.replace(f'{{${key}}}', str(value))

        pipeline_def = json.loads(pipeline_json)

        # Upload to workspace
        pipeline_name = pipeline_file.stem
        print(f"Deploying {pipeline_name}...")

        try:
            workspace.create_or_update_pipeline(
                name=pipeline_name,
                definition=pipeline_def
            )
            print(f"✅ {pipeline_name} deployed successfully")
        except Exception as e:
            print(f"❌ Failed to deploy {pipeline_name}: {str(e)}")
            raise

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', required=True)
    parser.add_argument('--source', required=True)
    parser.add_argument('--environment', required=True)

    args = parser.parse_args()
    deploy_pipelines(args.workspace, args.source, args.environment)
```

### run_smoke_tests.py

```python
#!/usr/bin/env python3

import argparse
import time
from azure.identity import DefaultAzureCredential
from pyfabric import FabricClient

def run_smoke_tests(workspace_name):
    """Run smoke tests on deployed pipelines."""

    credential = DefaultAzureCredential()
    client = FabricClient(credential)
    workspace = client.get_workspace(workspace_name)

    # Critical pipelines to test
    test_pipelines = [
        'ETL_Daily_Sales',
        'Transform_Customers',
        'Load_Warehouse'
    ]

    for pipeline_name in test_pipelines:
        print(f"Testing {pipeline_name}...")

        # Trigger pipeline run
        run = workspace.run_pipeline(
            pipeline_name,
            parameters={
                'test_mode': True,
                'batch_size': 10  # Small batch for testing
            }
        )

        # Wait for completion (max 5 minutes)
        timeout = 300
        start_time = time.time()

        while time.time() - start_time < timeout:
            status = run.get_status()

            if status == 'Succeeded':
                print(f"✅ {pipeline_name} test passed")
                break
            elif status == 'Failed':
                print(f"❌ {pipeline_name} test failed")
                error = run.get_error()
                print(f"Error: {error}")
                raise Exception(f"Smoke test failed for {pipeline_name}")

            time.sleep(10)

        else:
            raise Exception(f"Smoke test timeout for {pipeline_name}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', required=True)
    args = parser.parse_args()
    run_smoke_tests(args.workspace)
```

## Testing Strategies

### Unit Testing (Pipeline Components)

```python
# tests/test_pipeline_logic.py

import pytest
from unittest.mock import Mock
from pipeline_utils import calculate_watermark, validate_schema

def test_calculate_watermark():
    """Test watermark calculation logic."""
    last_watermark = '2024-01-15 00:00:00'
    new_data = [
        {'id': 1, 'updated_at': '2024-01-15 10:00:00'},
        {'id': 2, 'updated_at': '2024-01-15 12:00:00'},
        {'id': 3, 'updated_at': '2024-01-15 09:00:00'}
    ]

    result = calculate_watermark(last_watermark, new_data)

    assert result == '2024-01-15 12:00:00'

def test_validate_schema_success():
    """Test schema validation with valid data."""
    data = {'customer_id': 123, 'name': 'John', 'email': 'john@example.com'}
    schema = {'customer_id': 'int', 'name': 'string', 'email': 'string'}

    assert validate_schema(data, schema) == True

def test_validate_schema_failure():
    """Test schema validation with invalid data."""
    data = {'customer_id': 'abc', 'name': 'John'}  # Wrong type, missing field
    schema = {'customer_id': 'int', 'name': 'string', 'email': 'string'}

    assert validate_schema(data, schema) == False
```

### Integration Testing

```python
# tests/test_etl_integration.py

import pytest
from pyfabric import FabricClient

@pytest.fixture
def test_workspace():
    """Get test workspace."""
    client = FabricClient()
    return client.get_workspace('Test_Workspace')

def test_end_to_end_etl(test_workspace):
    """Test complete ETL flow."""

    # 1. Setup test data
    test_workspace.upload_file('test_data.csv', 'Files/bronze/sales/')

    # 2. Run ETL pipeline
    run = test_workspace.run_pipeline('ETL_Daily_Sales', parameters={
        'processing_date': '2024-01-15',
        'test_mode': True
    })

    # 3. Wait for completion
    run.wait_for_completion(timeout=600)

    # 4. Verify results
    assert run.status == 'Succeeded'

    # 5. Check output data
    result = test_workspace.query_table('silver_sales',
        "SELECT COUNT(*) as cnt FROM silver_sales WHERE processing_date = '2024-01-15'")

    assert result['cnt'] > 0

    # 6. Cleanup
    test_workspace.delete_partition('silver_sales', "processing_date = '2024-01-15'")
```

## Rollback Strategies

### Git Rollback

```bash
# Revert to previous commit
git revert HEAD
git push

# Fabric workspace will sync automatically
```

### Manual Rollback

```
1. Deployment pipelines → Production stage
2. Compare with previous deployment
3. Revert selected items
4. Validate
5. Publish
```

### Automated Rollback

```python
# scripts/rollback.py

def rollback_deployment(workspace_name, previous_version):
    """Rollback to previous version."""

    client = FabricClient()
    workspace = client.get_workspace(workspace_name)

    # Get deployment history
    history = workspace.get_deployment_history()

    # Find version
    target = next(h for h in history if h.version == previous_version)

    # Rollback
    workspace.rollback_to_version(target.version)

    print(f"✅ Rolled back to version {previous_version}")
```

## Best Practices

### ✅ Version Control

```
1. Git Strategy:
   ✅ Feature branches pour development
   ✅ Pull requests avec code review
   ✅ Protected main branch
   ✅ Semantic versioning (v1.2.3)

2. Commit Practices:
   ✅ Atomic commits (one logical change)
   ✅ Descriptive messages
   ✅ Reference ticket/issue (ABC-123: ...)

3. Branch Protection:
   ✅ Require PR reviews (minimum 1)
   ✅ Require status checks pass
   ✅ No direct commits to main
```

### ✅ Environment Management

```
1. Separation:
   ✅ DEV: Development et testing
   ✅ STAGING: Integration testing
   ✅ PROD: Production live data

2. Configuration:
   ✅ Environment-specific configs
   ✅ No hardcoded values
   ✅ Secrets in Key Vault

3. Data:
   ✅ Synthetic data in DEV
   ✅ Subset of prod data in STAGING
   ✅ Full data in PROD only
```

### ✅ CI/CD Pipeline

```
1. CI (Continuous Integration):
   ✅ Automated validation (JSON syntax, linting)
   ✅ Security scanning (secrets detection)
   ✅ Unit tests
   ✅ Build artifacts

2. CD (Continuous Deployment):
   ✅ Automated deployment to DEV/STAGING
   ✅ Manual approval for PROD
   ✅ Smoke tests post-deployment
   ✅ Rollback capability

3. Notifications:
   ✅ Success/Failure alerts
   ✅ Teams/Slack integration
   ✅ Deployment logs
```

## Points Clés

- Git integration native dans Fabric
- Deployment pipelines DEV → STAGING → PROD
- Azure DevOps ou GitHub Actions pour CI/CD
- Parameterization par environment
- Automated testing (unit, integration, smoke)
- GitFlow branching strategy
- Secrets dans Key Vault (pas dans code)
- Rollback capability essentielle
- Manual approval pour PROD
- Post-deployment validation
- Notifications et logging

---

**Module 04 COMPLET** ✅

[⬅️ Fichier précédent](./07-monitoring-alerts.md) | [➡️ Module suivant : Dataflows Gen2](../../05-Dataflows-Gen2/) | [⬅️ Retour au README du module](./README.md)
