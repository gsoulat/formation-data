# Azure DevOps CI/CD

## Table des matières

1. [Introduction](#introduction)
2. [Azure Pipelines](#azure-pipelines)
3. [Syntaxe YAML](#syntaxe-yaml)
4. [Déploiement](#déploiement)
5. [Intégration Azure](#intégration-azure)
6. [Exemples pratiques](#exemples-pratiques)

---

## Introduction

Azure DevOps est une suite complète d'outils DevOps proposée par Microsoft, incluant boards, repos, pipelines, test plans, et artifacts.

### Composants d'Azure DevOps

**Azure Boards** : Gestion de projet Agile

**Azure Repos** : Dépôts Git

**Azure Pipelines** : CI/CD

**Azure Test Plans** : Tests manuels et exploratoires

**Azure Artifacts** : Packages NuGet, npm, Maven

### Avantages

- Intégration native avec Azure
- Support Windows, Linux, macOS
- Agents hébergés gratuits (1800 min/mois)
- Excellent support .NET
- Interface moderne
- Bonne documentation

---

## Azure Pipelines

### Concepts clés

**Pipeline** : Workflow automatisé

**Stage** : Groupe logique de jobs

**Job** : Séquence de steps sur un agent

**Step** : Tâche ou script individuel

**Agent** : Machine qui exécute les jobs

---

## Syntaxe YAML

### Pipeline basique

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: NodeTool@0
    inputs:
      versionSpec: '18.x'
    displayName: 'Install Node.js'

  - script: |
      npm ci
      npm run build
    displayName: 'npm install and build'

  - script: npm test
    displayName: 'Run tests'
```

### Multi-stages pipeline

```yaml
trigger:
  - main

stages:
  - stage: Build
    displayName: 'Build Stage'
    jobs:
      - job: BuildJob
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '18.x'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm run build
            displayName: 'Build application'

          - publish: $(System.DefaultWorkingDirectory)/dist
            artifact: dist

  - stage: Test
    displayName: 'Test Stage'
    dependsOn: Build
    jobs:
      - job: TestJob
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '18.x'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm test
            displayName: 'Run tests'

          - task: PublishTestResults@2
            inputs:
              testResultsFormat: 'JUnit'
              testResultsFiles: '**/test-results.xml'

  - stage: Deploy
    displayName: 'Deploy Stage'
    dependsOn: Test
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployJob
        environment: 'production'
        pool:
          vmImage: 'ubuntu-latest'
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: dist

                - script: |
                    echo "Deploying to production..."
                  displayName: 'Deploy'
```

### Templates

```yaml
# templates/build-template.yml
parameters:
  - name: nodeVersion
    type: string
    default: '18.x'

steps:
  - task: NodeTool@0
    inputs:
      versionSpec: ${{ parameters.nodeVersion }}

  - script: npm ci
    displayName: 'Install dependencies'

  - script: npm run build
    displayName: 'Build'

# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - template: templates/build-template.yml
            parameters:
              nodeVersion: '18.x'
```

### Variables et secrets

```yaml
variables:
  - name: nodeVersion
    value: '18.x'
  - name: buildConfiguration
    value: 'Release'

# Variables de groupe (définis dans Azure DevOps)
  - group: 'production-vars'

stages:
  - stage: Build
    variables:
      - name: stageName
        value: 'Build Stage'

    jobs:
      - job: BuildJob
        steps:
          - script: |
              echo "Node version: $(nodeVersion)"
              echo "Configuration: $(buildConfiguration)"
              echo "Stage: $(stageName)"
            displayName: 'Display variables'

          # Utiliser un secret
          - script: |
              echo "Deploying with API key"
              curl -H "Authorization: Bearer $(API_KEY)" https://api.example.com
            env:
              API_KEY: $(api-key-secret)
```

---

## Déploiement

### Déploiement avec environnements

```yaml
stages:
  - stage: DeployStaging
    jobs:
      - deployment: DeployToStaging
        environment:
          name: 'staging'
          resourceType: VirtualMachine
          tags: web
        strategy:
          runOnce:
            deploy:
              steps:
                - script: ./deploy.sh staging
                  displayName: 'Deploy to staging'

  - stage: DeployProduction
    dependsOn: DeployStaging
    condition: succeeded()
    jobs:
      - deployment: DeployToProduction
        environment:
          name: 'production'
        strategy:
          runOnce:
            preDeploy:
              steps:
                - script: echo "Running pre-deployment checks..."

            deploy:
              steps:
                - script: ./deploy.sh production
                  displayName: 'Deploy to production'

            postRouteTraffic:
              steps:
                - script: |
                    curl -f https://myapp.com/health
                  displayName: 'Health check'

            on:
              failure:
                steps:
                  - script: ./rollback.sh
                    displayName: 'Rollback on failure'
```

### Stratégies de déploiement

```yaml
# Stratégie Rolling
strategy:
  rolling:
    maxParallel: 2
    preDeploy:
      steps:
        - script: echo "Pre-deployment step"
    deploy:
      steps:
        - script: echo "Deployment step"
    postRouteTraffic:
      steps:
        - script: echo "Post-deployment step"

# Stratégie Canary
strategy:
  canary:
    increments: [10, 20, 50, 100]
    preDeploy:
      steps:
        - script: echo "Pre-deployment validation"
    deploy:
      steps:
        - script: echo "Deploying canary"
    postRouteTraffic:
      steps:
        - script: echo "Monitor canary metrics"
    on:
      failure:
        steps:
          - script: echo "Canary rollback"
```

---

## Intégration Azure

### Déploiement vers Azure App Service

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  azureSubscription: 'azure-connection'
  webAppName: 'myapp'

stages:
  - stage: Build
    jobs:
      - job: BuildJob
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '18.x'

          - script: |
              npm ci
              npm run build
            displayName: 'Build application'

          - task: ArchiveFiles@2
            inputs:
              rootFolderOrFile: '$(System.DefaultWorkingDirectory)/dist'
              includeRootFolder: false
              archiveType: 'zip'
              archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'

          - publish: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip
            artifact: drop

  - stage: Deploy
    dependsOn: Build
    jobs:
      - deployment: DeployWeb
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: '$(azureSubscription)'
                    appName: '$(webAppName)'
                    package: '$(Pipeline.Workspace)/drop/$(Build.BuildId).zip'
```

### Déploiement vers Azure Container Instances

```yaml
stages:
  - stage: BuildDocker
    jobs:
      - job: BuildImage
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: Docker@2
            displayName: 'Build Docker image'
            inputs:
              command: build
              repository: 'myapp'
              tags: |
                $(Build.BuildId)
                latest

          - task: Docker@2
            displayName: 'Push to ACR'
            inputs:
              command: push
              containerRegistry: 'myacr'
              repository: 'myapp'
              tags: |
                $(Build.BuildId)
                latest

  - stage: DeployACI
    dependsOn: BuildDocker
    jobs:
      - job: Deploy
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'azure-connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az container create \
                  --resource-group myapp-rg \
                  --name myapp \
                  --image myacr.azurecr.io/myapp:$(Build.BuildId) \
                  --cpu 1 --memory 1.5 \
                  --registry-login-server myacr.azurecr.io \
                  --registry-username $(ACR_USERNAME) \
                  --registry-password $(ACR_PASSWORD) \
                  --ip-address Public \
                  --ports 80
```

### Déploiement Terraform sur Azure

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  terraformVersion: '1.6.0'
  workingDirectory: '$(System.DefaultWorkingDirectory)/terraform'

stages:
  - stage: Validate
    jobs:
      - job: ValidateTerraform
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: '$(terraformVersion)'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(workingDirectory)'
              backendServiceArm: 'azure-connection'
              backendAzureRmResourceGroupName: 'tfstate-rg'
              backendAzureRmStorageAccountName: 'tfstatestorage'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'terraform.tfstate'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Validate'
            inputs:
              provider: 'azurerm'
              command: 'validate'
              workingDirectory: '$(workingDirectory)'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: PlanTerraform
        steps:
          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: '$(workingDirectory)'
              environmentServiceNameAzureRM: 'azure-connection'

  - stage: Apply
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: ApplyTerraform
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    workingDirectory: '$(workingDirectory)'
                    environmentServiceNameAzureRM: 'azure-connection'
```

---

## Exemples pratiques

### Pipeline complet

Voir : [azure-pipelines.yml](./azure-pipelines.yml)

---

## Ressources

- [Azure Pipelines Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [Azure DevOps Labs](https://azuredevopslabs.com/)
- [YAML Schema Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/)

---

## Prochaines étapes

Passez à la section suivante : **[07-Best-Practices](../07-Best-Practices/README.md)**
