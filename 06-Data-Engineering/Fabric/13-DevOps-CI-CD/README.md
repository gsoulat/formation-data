# Module 13 - DevOps & CI/CD

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Intégrer Git avec Fabric workspaces
- ✅ Implémenter des stratégies de branching efficaces
- ✅ Utiliser les deployment pipelines
- ✅ Intégrer avec Azure DevOps
- ✅ Automatiser avec les APIs Fabric
- ✅ Suivre les best practices de version control

## Contenu du module

### [01 - Git Integration dans Fabric](./01-git-integration-fabric.md)
- Git integration overview
- Connexion à Azure DevOps / GitHub
- Synchronisation bidirectionnelle
- Items supportés (notebooks, pipelines, semantic models)
- Commit et push depuis Fabric
- Pull et merge
- Conflict resolution
- Limitations actuelles

### [02 - Branching Strategies](./02-branching-strategies.md)
- Git Flow
- GitHub Flow
- Trunk-based development
- Feature branches
- Hotfix branches
- Branch protection rules
- Pull requests et code review
- Best practices pour Fabric

### [03 - Deployment Pipelines](./03-deployment-pipelines.md)
- Concept de deployment pipeline dans Fabric
- Stages : Development → Test → Production
- Deployment rules
- Parameterization entre stages
- Comparison view
- Selective deployment
- Rollback strategies
- Automation

### [04 - Azure DevOps Integration](./04-azure-devops-integration.md)
- Connexion Azure DevOps
- Azure Pipelines pour Fabric
- Build pipelines
- Release pipelines
- Service connections
- Variable groups
- Gated deployments
- Approval workflows

### [05 - Automation via APIs](./05-automation-apis.md)
- Fabric REST APIs
- Authentication (service principal)
- Automation de déploiement
- CI/CD avec PowerShell/Python
- Terraform pour Fabric (preview)
- Infrastructure as Code
- Automated testing
- Monitoring automation

### [06 - Version Control Best Practices](./06-version-control-best-practices.md)
- Naming conventions
- Commit messages standards
- .gitignore pour Fabric
- Secrets management
- Code review guidelines
- Documentation
- Change log
- Release notes

## Exercices pratiques

### Exercice 1 : Git integration
1. Connecter un workspace à Azure DevOps
2. Faire un commit initial
3. Modifier un notebook localement
4. Push vers le repo
5. Pull dans Fabric

### Exercice 2 : Feature branch workflow
1. Créer une feature branch
2. Développer une nouvelle fonctionnalité
3. Créer un pull request
4. Code review
5. Merge dans main

### Exercice 3 : Deployment Pipeline
1. Créer un deployment pipeline (Dev → Test → Prod)
2. Déployer depuis Dev vers Test
3. Configurer des deployment rules (paramètres)
4. Comparer les environnements
5. Déployer en Production

### Exercice 4 : Azure DevOps Pipeline
1. Créer un pipeline YAML
2. Automatiser le déploiement
3. Ajouter des gates d'approbation
4. Tester le rollback
5. Monitorer les déploiements

### Exercice 5 : Automation avec API
1. Créer un service principal
2. Authentifier avec l'API Fabric
3. Automatiser la création d'un workspace
4. Déployer un artifact via API
5. Créer un script de déploiement réutilisable

### Exercice 6 : CI/CD complet
1. Setup complet Dev → Test → Prod
2. Git integration + Deployment Pipeline
3. Automated tests
4. Gated deployments
5. Documentation du processus

## Quiz

1. Quels items Fabric sont supportés par Git integration ?
2. Expliquez la différence entre Git integration et Deployment Pipeline
3. Comment gérer les secrets dans un pipeline CI/CD ?
4. Qu'est-ce qu'un service principal et pourquoi l'utiliser ?
5. Décrivez un workflow complet de déploiement

## Exemples de code

### Git dans Fabric (UI workflow)

```
1. Workspace Settings → Git integration
2. Connect to Azure DevOps / GitHub
3. Select repository and branch
4. Commit changes:
   - Review changes
   - Write commit message
   - Commit
5. Push to remote
6. Pull latest changes
```

### Azure DevOps Pipeline (YAML)

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: Fabric-Variables

stages:
  - stage: Build
    jobs:
      - job: Validate
        steps:
          - task: PowerShell@2
            displayName: 'Validate Notebooks'
            inputs:
              targetType: 'inline'
              script: |
                # Validation logic
                Write-Host "Validating notebooks..."

  - stage: DeployTest
    dependsOn: Build
    condition: succeeded()
    jobs:
      - deployment: DeployToTest
        environment: 'Test'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: PowerShell@2
                  displayName: 'Deploy to Test Workspace'
                  inputs:
                    targetType: 'filePath'
                    filePath: '$(System.DefaultWorkingDirectory)/scripts/deploy.ps1'
                    arguments: '-Environment Test -WorkspaceId $(TestWorkspaceId)'

  - stage: DeployProd
    dependsOn: DeployTest
    condition: succeeded()
    jobs:
      - deployment: DeployToProduction
        environment: 'Production'
        strategy:
          runOnce:
            deploy:
              steps:
                - task: PowerShell@2
                  displayName: 'Deploy to Production'
                  inputs:
                    targetType: 'filePath'
                    filePath: '$(System.DefaultWorkingDirectory)/scripts/deploy.ps1'
                    arguments: '-Environment Prod -WorkspaceId $(ProdWorkspaceId)'
```

### PowerShell - Déploiement avec API

```powershell
# Script de déploiement automatisé

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$ClientSecret,

    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory=$true)]
    [string]$NotebookPath
)

# Authentification avec Service Principal
$securePassword = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($ClientId, $securePassword)

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "https://analysis.windows.net/powerbi/api/.default"
        grant_type    = "client_credentials"
    }

$token = $tokenResponse.access_token
$headers = @{
    'Authorization' = "Bearer $token"
    'Content-Type' = 'application/json'
}

# Déployer un notebook
$notebookContent = Get-Content -Path $NotebookPath -Raw
$body = @{
    displayName = "MyNotebook"
    definition = @{
        parts = @(
            @{
                path = "notebook-content.py"
                payload = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($notebookContent))
                payloadType = "InlineBase64"
            }
        )
    }
} | ConvertTo-Json -Depth 10

$apiUrl = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/notebooks"

Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $body

Write-Host "Notebook deployed successfully!"
```

### Python - Automation avec API

```python
import requests
import msal
import json

class FabricDeployer:
    def __init__(self, tenant_id, client_id, client_secret):
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.client_secret = client_secret
        self.base_url = "https://api.fabric.microsoft.com/v1"
        self.token = self._get_token()

    def _get_token(self):
        """Obtenir un access token via MSAL"""
        authority = f"https://login.microsoftonline.com/{self.tenant_id}"
        app = msal.ConfidentialClientApplication(
            self.client_id,
            authority=authority,
            client_credential=self.client_secret
        )

        result = app.acquire_token_for_client(
            scopes=["https://analysis.windows.net/powerbi/api/.default"]
        )

        if "access_token" in result:
            return result["access_token"]
        else:
            raise Exception(f"Could not acquire token: {result}")

    def create_workspace(self, workspace_name, capacity_id):
        """Créer un workspace"""
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

        payload = {
            "displayName": workspace_name,
            "capacityId": capacity_id
        }

        response = requests.post(
            f"{self.base_url}/workspaces",
            headers=headers,
            json=payload
        )

        return response.json()

    def deploy_notebook(self, workspace_id, notebook_name, notebook_path):
        """Déployer un notebook"""
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

        with open(notebook_path, 'r') as f:
            content = f.read()

        # Encoder en base64
        import base64
        encoded_content = base64.b64encode(content.encode()).decode()

        payload = {
            "displayName": notebook_name,
            "definition": {
                "parts": [
                    {
                        "path": "notebook-content.py",
                        "payload": encoded_content,
                        "payloadType": "InlineBase64"
                    }
                ]
            }
        }

        response = requests.post(
            f"{self.base_url}/workspaces/{workspace_id}/notebooks",
            headers=headers,
            json=payload
        )

        return response.json()

# Usage
deployer = FabricDeployer(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-client-secret"
)

# Créer workspace
workspace = deployer.create_workspace("Production", "capacity-id")

# Déployer notebook
result = deployer.deploy_notebook(
    workspace["id"],
    "ETL_Notebook",
    "./notebooks/etl.ipynb"
)

print(f"Deployment successful: {result}")
```

### .gitignore pour Fabric

```gitignore
# Fabric specific
.fabric/
*.pbix.tmp
*.Dataset/cache/

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
venv/
env/

# Jupyter
.ipynb_checkpoints/
*.ipynb~

# Secrets
.env
secrets.json
*.key
*.pem

# Logs
*.log

# OS
.DS_Store
Thumbs.db
```

## Architecture CI/CD

### Pipeline complet

```
[Developer] → [Feature Branch] → [Pull Request] → [Code Review]
                                                        ↓
                                                   [Merge to main]
                                                        ↓
                                                  [Azure Pipeline]
                                                        ↓
                                        ┌───────────────┴───────────────┐
                                  [Deploy Test]              [Run Tests]
                                        ↓                          ↓
                                  [Manual Approval]          [Validation]
                                        ↓                          ↓
                                  [Deploy Prod] ← ← ← ← ← [Pass/Fail]
```

## Best practices

### Git workflow
- [ ] Feature branches pour chaque nouvelle fonctionnalité
- [ ] Pull requests obligatoires pour merge
- [ ] Code review par au moins 1 personne
- [ ] Branch protection sur main/prod
- [ ] Commit messages descriptifs
- [ ] Squash commits avant merge

### Deployment
- [ ] Au moins 3 environnements (Dev, Test, Prod)
- [ ] Déploiements automatisés
- [ ] Gated deployments pour Production
- [ ] Rollback strategy documentée
- [ ] Smoke tests post-déploiement
- [ ] Change log maintenu

### Sécurité
- [ ] Service principals pour automation
- [ ] Secrets dans Key Vault
- [ ] Pas de credentials en clair
- [ ] Principe du moindre privilège
- [ ] Audit des déploiements
- [ ] MFA pour approbations manuelles

## Ressources complémentaires

### Documentation officielle
- [Git integration in Fabric](https://learn.microsoft.com/fabric/cicd/git-integration/intro-to-git-integration)
- [Deployment pipelines](https://learn.microsoft.com/fabric/cicd/deployment-pipelines/intro-to-deployment-pipelines)
- [Fabric REST API](https://learn.microsoft.com/rest/api/fabric/articles/)

### Outils
- [Azure DevOps](https://azure.microsoft.com/services/devops/)
- [GitHub Actions for Fabric](https://github.com/marketplace?type=actions&query=fabric)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 4-5 heures
- **Total** : 8-10 heures

## Prochaine étape

➡️ [Module 14 - Migration & Intégration](../14-Migration-Integration/)

---

[⬅️ Module précédent](../12-Administration-Monitoring/) | [⬅️ Retour au sommaire](../README.md)
