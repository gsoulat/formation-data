# CI/CD Best Practices for Microsoft Fabric

## Introduction

L'implémentation efficace de CI/CD dans Microsoft Fabric nécessite l'adoption de bonnes pratiques spécifiques au contexte des données et de l'analytics. Ce guide consolide les meilleures pratiques pour construire des pipelines robustes, sécurisés et maintenables.

## Principes Fondamentaux

### 1. Everything as Code

```yaml
# Principe: Toute configuration doit être versionnée
fabric-project/
├── .github/workflows/          # CI/CD pipelines
├── infrastructure/             # IaC (Terraform, Bicep)
├── config/                     # Environment configs
│   ├── dev.json
│   ├── test.json
│   └── prod.json
├── src/
│   ├── notebooks/             # PySpark notebooks
│   ├── pipelines/             # Data pipeline definitions
│   ├── models/                # Semantic models (TMDL)
│   └── reports/               # Report definitions
├── tests/                     # Automated tests
├── docs/                      # Documentation
└── scripts/                   # Automation scripts
```

### 2. Fail Fast, Fail Safe

```python
# Validation précoce dans le pipeline
class PipelineValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def validate_all(self, workspace_path):
        """Exécute toutes les validations"""
        validations = [
            self.validate_json_syntax,
            self.validate_naming_conventions,
            self.validate_no_hardcoded_credentials,
            self.validate_schema_compatibility,
            self.validate_data_quality_rules
        ]

        for validation in validations:
            try:
                validation(workspace_path)
            except ValidationError as e:
                self.errors.append(e)

        if self.errors:
            raise PipelineValidationError(
                f"Pipeline validation failed with {len(self.errors)} errors",
                self.errors
            )

    def validate_no_hardcoded_credentials(self, path):
        """Vérifie qu'aucun secret n'est hardcodé"""
        import re

        patterns = [
            r'password\s*=\s*["\'][^"\']+["\']',
            r'api[_-]?key\s*=\s*["\'][^"\']+["\']',
            r'connection[_-]?string\s*=\s*["\'][^"\']+["\']',
            r'secret\s*=\s*["\'][^"\']+["\']'
        ]

        for file in self._get_all_files(path):
            content = open(file, 'r').read()
            for pattern in patterns:
                if re.search(pattern, content, re.IGNORECASE):
                    raise ValidationError(
                        f"Potential hardcoded credential found in {file}"
                    )

    def validate_naming_conventions(self, path):
        """Vérifie le respect des conventions de nommage"""
        conventions = {
            'Lakehouse': r'^LH_[A-Z][a-z]+_[A-Za-z]+$',
            'Warehouse': r'^DW_[A-Z][a-z]+_[A-Za-z]+$',
            'Pipeline': r'^PL_[A-Z][a-z]+_[A-Za-z]+$',
            'Notebook': r'^NB_[A-Z][a-z]+_[A-Za-z]+$',
            'Report': r'^RPT_[A-Z][a-z]+_[A-Za-z]+$'
        }

        for artifact_type, pattern in conventions.items():
            artifacts = self._get_artifacts_by_type(path, artifact_type)
            for artifact in artifacts:
                if not re.match(pattern, artifact['name']):
                    self.warnings.append(
                        f"{artifact_type} '{artifact['name']}' does not follow naming convention"
                    )
```

## Pipeline Design Patterns

### Pattern 1: Multi-Stage Pipeline

```yaml
# azure-pipelines.yml
stages:
  # Stage 1: Build & Validate
  - stage: Build
    jobs:
      - job: Validate
        steps:
          - script: python -m pytest tests/unit --junitxml=unit-results.xml
            displayName: 'Run Unit Tests'

          - script: python scripts/validate_artifacts.py
            displayName: 'Validate Fabric Artifacts'

          - task: PublishTestResults@2
            inputs:
              testResultsFiles: '**/unit-results.xml'

  # Stage 2: Deploy to Dev (Auto)
  - stage: DeployDev
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
    jobs:
      - deployment: DeployDev
        environment: 'fabric-dev'
        strategy:
          runOnce:
            deploy:
              steps:
                - template: templates/deploy-fabric.yml
                  parameters:
                    environment: 'dev'
                    workspaceId: $(DevWorkspaceId)

  # Stage 3: Integration Tests
  - stage: IntegrationTests
    dependsOn: DeployDev
    jobs:
      - job: RunIntegrationTests
        steps:
          - script: python -m pytest tests/integration --junitxml=integration-results.xml
            displayName: 'Run Integration Tests'

  # Stage 4: Deploy to Test (With Approval)
  - stage: DeployTest
    dependsOn: IntegrationTests
    jobs:
      - deployment: DeployTest
        environment: 'fabric-test'  # Approval gate configured here
        strategy:
          runOnce:
            deploy:
              steps:
                - template: templates/deploy-fabric.yml
                  parameters:
                    environment: 'test'

  # Stage 5: Performance & Regression Tests
  - stage: PerformanceTests
    dependsOn: DeployTest
    jobs:
      - job: RunPerformanceTests
        steps:
          - script: python scripts/performance_tests.py
            displayName: 'Run Performance Tests'

          - script: python scripts/regression_tests.py
            displayName: 'Run Regression Tests'

  # Stage 6: Deploy to Production
  - stage: DeployProd
    dependsOn: PerformanceTests
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployProd
        environment: 'fabric-production'  # Multiple approvals required
        strategy:
          runOnce:
            deploy:
              steps:
                - template: templates/deploy-fabric.yml
                  parameters:
                    environment: 'prod'
```

### Pattern 2: Feature Branch Workflow

```yaml
# .github/workflows/feature-branch.yml
name: Feature Branch CI

on:
  pull_request:
    branches: [develop, main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Lint Python Code
        run: |
          pip install flake8 black
          flake8 src/
          black --check src/

      - name: Validate JSON Schemas
        run: python scripts/validate_schemas.py

      - name: Check for Breaking Changes
        run: python scripts/detect_breaking_changes.py

      - name: Security Scan
        uses: github/codeql-action/analyze@v2

  test:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Unit Tests
        run: pytest tests/unit -v --cov=src --cov-report=xml

      - name: Upload Coverage
        uses: codecov/codecov-action@v3

  preview:
    needs: test
    runs-on: ubuntu-latest
    if: github.event.pull_request.draft == false
    steps:
      - name: Deploy Preview Environment
        run: |
          # Create temporary workspace for PR preview
          python scripts/create_preview_environment.py \
            --pr-number ${{ github.event.pull_request.number }}

      - name: Run Smoke Tests
        run: python scripts/smoke_tests.py --environment preview

      - name: Comment PR with Preview URL
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Preview environment deployed: https://preview-${{ github.event.pull_request.number }}.fabric.com'
            })
```

## Security Best Practices

### Secret Management

```python
# Utilisation de Azure Key Vault pour les secrets
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

class SecureConfigManager:
    def __init__(self, key_vault_url):
        credential = DefaultAzureCredential()
        self.client = SecretClient(vault_url=key_vault_url, credential=credential)

    def get_connection_string(self, environment):
        """Récupère la connection string de manière sécurisée"""
        secret_name = f"fabric-{environment}-connection"
        secret = self.client.get_secret(secret_name)
        return secret.value

    def rotate_secret(self, secret_name):
        """Rotation automatique des secrets"""
        # Générer nouveau secret
        new_secret_value = self._generate_secure_secret()

        # Mettre à jour dans Key Vault
        self.client.set_secret(secret_name, new_secret_value)

        # Mettre à jour les services qui utilisent ce secret
        self._update_dependent_services(secret_name, new_secret_value)
```

### Pipeline Security

```yaml
# Sécurisation du pipeline CI/CD
security:
  # 1. Least Privilege Service Principal
  service_principal:
    permissions:
      - "Fabric.ReadWrite.All"  # Minimum requis
      - "Workspace.ReadWrite.All"
    restricted_actions:
      - "Delete.Capacity"
      - "Modify.TenantSettings"

  # 2. Environment Protection Rules
  environments:
    production:
      required_reviewers: 2
      wait_timer: 15  # minutes
      prevent_self_review: true
      restrict_to_branches: ["main"]

  # 3. Branch Protection
  branch_protection:
    main:
      require_pull_request: true
      require_approvals: 2
      require_linear_history: true
      require_signed_commits: true
      require_status_checks:
        - "build"
        - "test"
        - "security-scan"

  # 4. Secret Scanning
  secret_scanning:
    enabled: true
    push_protection: true
    patterns:
      - "Azure.*Key"
      - "password"
      - "connection.*string"
```

## Monitoring et Observabilité

### Pipeline Metrics

```python
# Collecte des métriques de pipeline
class PipelineMetrics:
    def __init__(self):
        self.metrics = {
            'deployment_frequency': [],
            'lead_time': [],
            'change_failure_rate': [],
            'mean_time_to_recovery': []
        }

    def record_deployment(self, deployment_data):
        """Enregistre les métriques d'un déploiement"""
        self.metrics['deployment_frequency'].append({
            'timestamp': deployment_data['timestamp'],
            'environment': deployment_data['environment'],
            'success': deployment_data['success']
        })

        # Calcul du lead time (commit to deploy)
        lead_time = (deployment_data['deploy_time'] - deployment_data['commit_time']).total_seconds()
        self.metrics['lead_time'].append(lead_time)

        # Taux d'échec
        if not deployment_data['success']:
            self.metrics['change_failure_rate'].append(deployment_data)

    def calculate_dora_metrics(self):
        """Calcule les métriques DORA"""
        return {
            'deployment_frequency': self._calc_deployment_frequency(),
            'lead_time_for_changes': self._calc_average_lead_time(),
            'change_failure_rate': self._calc_failure_rate(),
            'mttr': self._calc_mttr()
        }

    def generate_report(self):
        """Génère un rapport de santé CI/CD"""
        metrics = self.calculate_dora_metrics()

        report = f"""
        # CI/CD Health Report

        ## DORA Metrics
        - Deployment Frequency: {metrics['deployment_frequency']} per day
        - Lead Time for Changes: {metrics['lead_time_for_changes']} hours
        - Change Failure Rate: {metrics['change_failure_rate']}%
        - Mean Time to Recovery: {metrics['mttr']} minutes

        ## Performance Classification
        {self._classify_performance(metrics)}

        ## Recommendations
        {self._generate_recommendations(metrics)}
        """
        return report
```

## Checklist des Best Practices

### Pre-Commit

- [ ] Code formaté (Black, Prettier)
- [ ] Lint passé (Flake8, ESLint)
- [ ] Pas de secrets hardcodés
- [ ] Tests unitaires passent localement
- [ ] Documentation mise à jour

### Pre-Merge

- [ ] Pull request reviewée par pairs
- [ ] Tous les status checks passent
- [ ] Couverture de test maintenue
- [ ] Pas de breaking changes non documentés
- [ ] Release notes préparées

### Pre-Deploy

- [ ] Approbations obtenues
- [ ] Tests d'intégration passent
- [ ] Tests de performance validés
- [ ] Plan de rollback documenté
- [ ] Communication envoyée aux stakeholders

### Post-Deploy

- [ ] Smoke tests passent
- [ ] Monitoring actif
- [ ] Alertes configurées
- [ ] Documentation mise à jour
- [ ] Retrospective planifiée

## Points Clés

- Automatiser tout ce qui peut l'être pour réduire les erreurs humaines
- Valider tôt et souvent (fail fast principle)
- Sécuriser les pipelines avec des gates d'approbation et des scans
- Versionner absolument tout (code, config, infrastructure)
- Monitorer les métriques DORA pour mesurer la performance
- Implémenter des rollbacks automatiques en cas d'échec
- Documenter les processus et maintenir les runbooks
- Réviser régulièrement et améliorer continuellement les pipelines

---

**Navigation** : [Précédent : Release Management](./05-release-management.md) | [Index](../README.md) | [Module 14 : Migration Integration](../14-Migration-Integration/01-migration-strategies.md)
