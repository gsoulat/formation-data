# Disaster Recovery and Backup

## Introduction

La stratégie de disaster recovery (DR) et de backup dans Microsoft Fabric est cruciale pour assurer la continuité des activités et protéger les données critiques. Fabric étant un service SaaS, certaines responsabilités sont partagées entre Microsoft et l'organisation, nécessitant une compréhension claire des options disponibles et des bonnes pratiques à implémenter.

## Modèle de Responsabilité Partagée

### Responsabilités Microsoft

- Infrastructure physique des datacenters
- Disponibilité du service (SLA 99.9%)
- Réplication géographique de l'infrastructure
- Mises à jour et patches de sécurité
- Protection contre les pannes matérielles

### Responsabilités Client

- Sauvegarde des configurations et métadonnées
- Protection contre les erreurs utilisateur
- Récupération des données supprimées accidentellement
- Tests réguliers des procédures DR
- Documentation des processus de recovery

## Stratégies de Backup

### 1. Export des Artefacts Fabric

```python
import requests
import json
from datetime import datetime
import os

class FabricBackupManager:
    def __init__(self, access_token):
        self.token = access_token
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
        self.base_url = "https://api.powerbi.com/v1.0/myorg"

    def backup_workspace_metadata(self, workspace_id, backup_path):
        """
        Sauvegarde les métadonnées complètes d'un workspace
        """
        backup_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'workspace_id': workspace_id,
            'artifacts': {}
        }

        # Récupérer les informations du workspace
        workspace_info = requests.get(
            f"{self.base_url}/groups/{workspace_id}",
            headers=self.headers
        ).json()
        backup_data['workspace_info'] = workspace_info

        # Lister tous les artefacts
        items_url = f"{self.base_url}/groups/{workspace_id}/datasets"
        datasets = requests.get(items_url, headers=self.headers).json()
        backup_data['artifacts']['datasets'] = datasets

        reports_url = f"{self.base_url}/groups/{workspace_id}/reports"
        reports = requests.get(reports_url, headers=self.headers).json()
        backup_data['artifacts']['reports'] = reports

        # Sauvegarder
        backup_file = f"{backup_path}/workspace_{workspace_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(backup_file, 'w') as f:
            json.dump(backup_data, f, indent=2)

        return backup_file

    def export_pbix_reports(self, workspace_id, backup_path):
        """
        Exporte tous les rapports PBIX d'un workspace
        """
        reports = requests.get(
            f"{self.base_url}/groups/{workspace_id}/reports",
            headers=self.headers
        ).json()['value']

        exported_files = []
        for report in reports:
            export_url = f"{self.base_url}/groups/{workspace_id}/reports/{report['id']}/Export"
            response = requests.get(export_url, headers=self.headers)

            if response.status_code == 200:
                file_path = f"{backup_path}/{report['name']}.pbix"
                with open(file_path, 'wb') as f:
                    f.write(response.content)
                exported_files.append(file_path)

        return exported_files

# Utilisation
# backup_mgr = FabricBackupManager(token)
# backup_mgr.backup_workspace_metadata("workspace-guid", "/backups")
```

### 2. Backup des Configurations OneLake

```powershell
# Script PowerShell pour backup OneLake via Azure CLI
function Backup-OneLakeData {
    param(
        [string]$WorkspaceName,
        [string]$LakehouseName,
        [string]$BackupStorageAccount,
        [string]$BackupContainer
    )

    # Configuration de l'endpoint OneLake
    $oneLakeEndpoint = "https://onelake.dfs.fabric.microsoft.com"
    $sourcePath = "$WorkspaceName/$LakehouseName/Files"

    # Synchronisation vers Azure Blob Storage
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $destinationPath = "https://$BackupStorageAccount.blob.core.windows.net/$BackupContainer/backup_$timestamp"

    # Utilisation d'AzCopy pour la copie
    azcopy copy `
        "$oneLakeEndpoint/$sourcePath" `
        $destinationPath `
        --recursive `
        --include-pattern "*" `
        --log-level INFO

    Write-Host "Backup completed to $destinationPath"
}

# Backup des Delta Tables
function Backup-DeltaTables {
    param(
        [string]$LakehousePath,
        [string]$BackupLocation
    )

    # Export Delta Lake avec historique
    $deltaPath = "$LakehousePath/Tables"

    # Copie incluant les logs de transaction
    azcopy copy $deltaPath $BackupLocation --recursive

    # Vérification de l'intégrité
    # Les fichiers _delta_log doivent être inclus
}
```

### 3. Git-based Backup

```yaml
# .github/workflows/fabric-backup.yml
name: Fabric Workspace Backup

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install requests azure-storage-blob

      - name: Authenticate to Fabric
        env:
          CLIENT_ID: ${{ secrets.FABRIC_CLIENT_ID }}
          CLIENT_SECRET: ${{ secrets.FABRIC_CLIENT_SECRET }}
          TENANT_ID: ${{ secrets.TENANT_ID }}
        run: |
          python scripts/authenticate.py

      - name: Export workspace configurations
        run: python scripts/backup_workspaces.py

      - name: Commit backup to repository
        run: |
          git config --local user.email "backup@automated.com"
          git config --local user.name "Backup Bot"
          git add backups/
          git commit -m "Daily backup $(date +%Y-%m-%d)" || echo "No changes"
          git push
```

## Plan de Disaster Recovery

### RTO et RPO

| Composant | RPO Target | RTO Target | Stratégie |
|-----------|-----------|-----------|-----------|
| Métadonnées Workspace | 24h | 4h | Git backup quotidien |
| Rapports Power BI | 24h | 2h | Export PBIX automatisé |
| Données OneLake | 1h | 8h | Réplication cross-region |
| Configurations Pipelines | 24h | 4h | Infrastructure as Code |
| Semantic Models | 24h | 6h | Export/Import API |

### Procédure de Recovery

```python
class DisasterRecoveryPlan:
    def __init__(self):
        self.steps = []

    def execute_recovery(self, disaster_type):
        """
        Exécute le plan de recovery selon le type d'incident
        """
        if disaster_type == "ACCIDENTAL_DELETION":
            return self._recover_from_deletion()
        elif disaster_type == "DATA_CORRUPTION":
            return self._recover_from_corruption()
        elif disaster_type == "REGION_OUTAGE":
            return self._failover_to_secondary()
        else:
            raise ValueError(f"Unknown disaster type: {disaster_type}")

    def _recover_from_deletion(self):
        """
        Recovery après suppression accidentelle
        """
        steps = [
            "1. Identifier l'étendue de la suppression via audit logs",
            "2. Vérifier la période de rétention (soft delete)",
            "3. Si dans la période: restaurer depuis la corbeille Fabric",
            "4. Sinon: restaurer depuis le dernier backup",
            "5. Valider l'intégrité des données restaurées",
            "6. Reconfigurer les permissions si nécessaire",
            "7. Tester les dépendances (pipelines, reports)",
            "8. Documenter l'incident et mettre à jour les procédures"
        ]
        return steps

    def _recover_from_corruption(self):
        """
        Recovery après corruption de données
        """
        steps = [
            "1. Isoler les données corrompues",
            "2. Identifier le point de corruption (timestamp)",
            "3. Restaurer depuis snapshot Delta Lake pré-corruption",
            "4. Utiliser TIME TRAVEL si Delta Lake",
            "5. Rejouer les transactions post-corruption si nécessaire",
            "6. Valider avec checksums",
            "7. Notifier les utilisateurs impactés"
        ]
        return steps

    def _failover_to_secondary(self):
        """
        Basculement vers région secondaire
        """
        steps = [
            "1. Confirmer l'indisponibilité de la région primaire",
            "2. Activer la capacité dans la région secondaire",
            "3. Restaurer les workspaces depuis backups",
            "4. Mettre à jour les connexions des gateways",
            "5. Reconfigurer les data sources",
            "6. Valider les pipelines critiques",
            "7. Communiquer aux utilisateurs",
            "8. Monitorer les performances"
        ]
        return steps

# Utilisation
dr_plan = DisasterRecoveryPlan()
recovery_steps = dr_plan.execute_recovery("ACCIDENTAL_DELETION")
for step in recovery_steps:
    print(step)
```

### Delta Lake Time Travel

```sql
-- Restauration de données via Time Travel Delta Lake
-- Voir l'historique des versions
DESCRIBE HISTORY lakehouse.sales_transactions;

-- Restaurer une version spécifique
RESTORE TABLE lakehouse.sales_transactions TO VERSION AS OF 10;

-- Ou restaurer à un timestamp précis
RESTORE TABLE lakehouse.sales_transactions
TO TIMESTAMP AS OF '2024-01-15 10:30:00';

-- Créer une copie de sauvegarde avant modification risquée
CREATE TABLE lakehouse.sales_transactions_backup
AS SELECT * FROM lakehouse.sales_transactions VERSION AS OF 10;
```

## Tests et Validation

### Plan de Test DR

```python
def run_dr_test():
    """
    Exécute un test complet de disaster recovery
    """
    test_results = {
        'timestamp': datetime.now(),
        'tests': []
    }

    # Test 1: Restauration métadonnées
    test1 = {
        'name': 'Workspace Metadata Restoration',
        'steps': [
            'Export current workspace config',
            'Delete test artifact',
            'Restore from backup',
            'Verify restoration'
        ],
        'expected_rto': '4 hours',
        'actual_rto': None,
        'status': 'PENDING'
    }

    # Test 2: Restauration données OneLake
    test2 = {
        'name': 'OneLake Data Restoration',
        'steps': [
            'Backup test table',
            'Corrupt test data',
            'Restore from Delta snapshot',
            'Validate data integrity'
        ],
        'expected_rto': '8 hours',
        'actual_rto': None,
        'status': 'PENDING'
    }

    # Test 3: Failover simulation
    test3 = {
        'name': 'Region Failover',
        'steps': [
            'Simulate primary region unavailable',
            'Activate secondary capacity',
            'Deploy workspaces to secondary',
            'Validate critical workflows'
        ],
        'expected_rto': '12 hours',
        'actual_rto': None,
        'status': 'PENDING'
    }

    test_results['tests'] = [test1, test2, test3]

    return test_results

# Planifier des tests DR trimestriels
```

## Points Clés

- Fabric suit un modèle de responsabilité partagée pour le DR
- Implémenter des backups automatisés des métadonnées et configurations
- Utiliser le versioning Delta Lake pour la récupération de données
- Définir des RTO/RPO clairs pour chaque type d'artefact
- Tester régulièrement les procédures de recovery (au moins trimestriellement)
- Documenter et maintenir à jour le plan de DR
- Considérer la réplication cross-region pour les données critiques
- Utiliser Git pour versionner les configurations Infrastructure as Code

---

**Navigation** : [Précédent : Auditing and Logging](./06-auditing-logging.md) | [Index](../README.md) | [Suivant : Admin Best Practices](./08-admin-best-practices.md)
