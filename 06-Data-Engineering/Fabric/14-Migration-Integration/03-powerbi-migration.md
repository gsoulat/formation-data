# Power BI Migration to Microsoft Fabric

## Introduction

La migration des assets Power BI vers Microsoft Fabric permet de tirer parti des nouvelles fonctionnalités comme Direct Lake, les semantic models unifiés, et l'intégration native avec OneLake. Ce guide couvre la migration des datasets, reports, et dashboards existants vers l'écosystème Fabric.

## Évaluation de l'Existant

### Inventaire des Assets Power BI

```python
import requests
import pandas as pd

class PowerBIInventory:
    def __init__(self, access_token):
        self.token = access_token
        self.base_url = "https://api.powerbi.com/v1.0/myorg"
        self.headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }

    def get_complete_inventory(self):
        """Crée un inventaire complet des assets Power BI"""
        inventory = {
            'workspaces': self._get_workspaces(),
            'datasets': self._get_all_datasets(),
            'reports': self._get_all_reports(),
            'dashboards': self._get_all_dashboards(),
            'dataflows': self._get_all_dataflows()
        }

        # Enrichir avec métadonnées
        for dataset in inventory['datasets']:
            dataset['refresh_schedule'] = self._get_refresh_schedule(dataset['id'])
            dataset['datasources'] = self._get_datasources(dataset['id'])
            dataset['size_mb'] = self._get_dataset_size(dataset['id'])

        return inventory

    def analyze_migration_readiness(self, inventory):
        """Analyse la préparation à la migration"""
        analysis = {
            'direct_lake_candidates': [],
            'import_mode_datasets': [],
            'live_connections': [],
            'dataflow_dependencies': []
        }

        for dataset in inventory['datasets']:
            if dataset['isRefreshable']:
                if dataset['size_mb'] < 10000:  # < 10GB
                    analysis['direct_lake_candidates'].append(dataset)
                else:
                    analysis['import_mode_datasets'].append(dataset)
            else:
                analysis['live_connections'].append(dataset)

        return analysis

    def generate_migration_report(self, inventory, analysis):
        """Génère un rapport de migration"""
        report = f"""
        # Power BI Migration Assessment Report

        ## Summary
        - Total Workspaces: {len(inventory['workspaces'])}
        - Total Datasets: {len(inventory['datasets'])}
        - Total Reports: {len(inventory['reports'])}
        - Total Dashboards: {len(inventory['dashboards'])}
        - Total Dataflows: {len(inventory['dataflows'])}

        ## Migration Candidates
        - Direct Lake Candidates: {len(analysis['direct_lake_candidates'])}
        - Import Mode (Large): {len(analysis['import_mode_datasets'])}
        - Live Connections: {len(analysis['live_connections'])}

        ## Estimated Effort
        - Low Complexity: {self._count_by_complexity(inventory, 'low')}
        - Medium Complexity: {self._count_by_complexity(inventory, 'medium')}
        - High Complexity: {self._count_by_complexity(inventory, 'high')}
        """
        return report

    def _get_workspaces(self):
        response = requests.get(f"{self.base_url}/groups", headers=self.headers)
        return response.json().get('value', [])

    def _get_all_datasets(self):
        datasets = []
        workspaces = self._get_workspaces()
        for ws in workspaces:
            response = requests.get(
                f"{self.base_url}/groups/{ws['id']}/datasets",
                headers=self.headers
            )
            datasets.extend(response.json().get('value', []))
        return datasets
```

## Migration vers Direct Lake

### Concept Direct Lake

Direct Lake est le nouveau mode de connectivité qui combine les avantages de DirectQuery (données fraîches) et Import (performances optimales) :

```python
# Architecture Direct Lake
direct_lake_architecture = {
    'data_storage': 'OneLake (Delta Lake format)',
    'semantic_model': 'Power BI Dataset',
    'query_mode': 'Direct Lake',
    'benefits': [
        'Pas de rafraîchissement planifié nécessaire',
        'Données toujours à jour',
        'Performances proches du mode Import',
        'Pas de duplication de données',
        'Supporte les gros volumes (TB)'
    ],
    'prerequisites': [
        'Données en format Delta Lake dans OneLake',
        'Tables avec V-Order optimization',
        'Fabric Capacity (F SKU)',
        'Tables bien modélisées (star schema)'
    ]
}
```

### Conversion Import vers Direct Lake

```sql
-- Étape 1: Préparer les données dans le Lakehouse
-- Créer les tables Delta optimisées pour Direct Lake

-- Table de dimension
CREATE TABLE gold.dim_customer
USING DELTA
AS SELECT
    customer_id,
    customer_name,
    email,
    segment,
    region,
    created_date
FROM silver.customers;

-- Optimiser pour les performances
OPTIMIZE gold.dim_customer ZORDER BY (customer_id);

-- Table de faits
CREATE TABLE gold.fact_sales
USING DELTA
PARTITIONED BY (sale_year, sale_month)
AS SELECT
    sale_id,
    customer_id,
    product_id,
    date_key,
    YEAR(sale_date) as sale_year,
    MONTH(sale_date) as sale_month,
    quantity,
    unit_price,
    total_amount,
    discount_amount
FROM silver.sales;

-- Appliquer V-Order (crucial pour Direct Lake)
ALTER TABLE gold.fact_sales SET TBLPROPERTIES (
    'delta.parquet.vorder.enabled' = 'true'
);

-- Compacter les fichiers pour performances optimales
OPTIMIZE gold.fact_sales;
```

### Création du Semantic Model Direct Lake

```python
# Script de création de semantic model Direct Lake
class DirectLakeModelBuilder:
    def __init__(self, workspace_id, lakehouse_id):
        self.workspace_id = workspace_id
        self.lakehouse_id = lakehouse_id

    def create_model_from_lakehouse(self, model_name, tables):
        """Crée un semantic model Direct Lake"""

        # Définition du modèle en format TMDL/TMSL
        model_definition = {
            "name": model_name,
            "defaultMode": "DirectLake",
            "tables": [],
            "relationships": [],
            "expressions": []
        }

        for table_config in tables:
            table_def = self._create_table_definition(table_config)
            model_definition['tables'].append(table_def)

        # Ajouter les relations
        for relation in self._infer_relationships(tables):
            model_definition['relationships'].append(relation)

        return model_definition

    def _create_table_definition(self, table_config):
        """Crée la définition d'une table Direct Lake"""
        return {
            "name": table_config['name'],
            "columns": [
                {
                    "name": col['name'],
                    "dataType": col['type'],
                    "sourceColumn": col['source_column']
                }
                for col in table_config['columns']
            ],
            "partitions": [
                {
                    "name": f"{table_config['name']}_partition",
                    "source": {
                        "type": "entity",
                        "entityName": table_config['lakehouse_table'],
                        "schemaName": "dbo"
                    }
                }
            ],
            "annotations": [
                {
                    "name": "IsDirectLake",
                    "value": "true"
                }
            ]
        }

    def add_measures(self, model_definition, measures):
        """Ajoute les mesures DAX"""
        for measure in measures:
            table_index = next(
                i for i, t in enumerate(model_definition['tables'])
                if t['name'] == measure['table']
            )

            if 'measures' not in model_definition['tables'][table_index]:
                model_definition['tables'][table_index]['measures'] = []

            model_definition['tables'][table_index]['measures'].append({
                "name": measure['name'],
                "expression": measure['dax_expression'],
                "formatString": measure.get('format', '#,##0')
            })

        return model_definition
```

## Migration des Reports

### Export/Import PBIX

```powershell
# Script de migration des rapports Power BI
function Migrate-PowerBIReports {
    param(
        [string]$SourceWorkspaceId,
        [string]$TargetWorkspaceId,
        [string]$NewDatasetId
    )

    # 1. Lister les rapports du workspace source
    $reports = Get-PowerBIReport -WorkspaceId $SourceWorkspaceId

    foreach ($report in $reports) {
        Write-Host "Migrating report: $($report.Name)"

        # 2. Exporter le rapport
        $exportPath = "temp/$($report.Name).pbix"
        Export-PowerBIReport -Id $report.Id -WorkspaceId $SourceWorkspaceId -OutFile $exportPath

        # 3. Importer dans le nouveau workspace
        $newReport = New-PowerBIReport -Path $exportPath -Name $report.Name -WorkspaceId $TargetWorkspaceId

        # 4. Rebind au nouveau dataset (Direct Lake)
        Set-PowerBIReportDataset -ReportId $newReport.Id -DatasetId $NewDatasetId -WorkspaceId $TargetWorkspaceId

        Write-Host "  Report migrated and rebound to new dataset" -ForegroundColor Green
    }
}

# Utilisation
Migrate-PowerBIReports `
    -SourceWorkspaceId "old-workspace-guid" `
    -TargetWorkspaceId "new-fabric-workspace-guid" `
    -NewDatasetId "direct-lake-dataset-guid"
```

### Thin Reports Pattern

```python
# Migration vers le pattern Thin Reports
# Séparation des données et de la présentation

class ThinReportMigration:
    def __init__(self):
        self.pattern_description = """
        Thin Reports Pattern:
        - Semantic Model contient TOUTES les données et mesures
        - Report ne contient QUE la visualisation
        - Permet le partage du même modèle entre plusieurs rapports
        - Facilite la gouvernance et la cohérence des KPIs
        """

    def convert_to_thin_report(self, thick_report_pbix):
        """
        Convertit un rapport 'thick' (avec données) en 'thin' (sans données)
        """
        # 1. Extraire les mesures du rapport
        measures = self._extract_measures(thick_report_pbix)

        # 2. Extraire la logique de visualisation
        visuals = self._extract_visuals(thick_report_pbix)

        # 3. Créer un rapport thin qui référence le semantic model partagé
        thin_report = {
            'report_pages': visuals,
            'dataset_reference': 'shared_semantic_model_id',
            'local_measures': [],  # Pas de mesures locales
            'metadata': thick_report_pbix['metadata']
        }

        return thin_report, measures

    def create_shared_semantic_model(self, all_measures):
        """
        Crée un semantic model partagé avec toutes les mesures
        """
        model = {
            'tables': [],  # Tables Direct Lake
            'measures': all_measures,  # Toutes les mesures centralisées
            'perspectives': [],
            'security_roles': []
        }
        return model
```

## Migration des Dataflows

### Conversion Dataflows vers Dataflows Gen2

```python
# Dataflow Gen1 vers Dataflow Gen2 (Fabric)
class DataflowMigration:
    def convert_dataflow(self, gen1_dataflow):
        """
        Convertit un Dataflow Gen1 vers Gen2
        """
        # Gen2 utilise des output destinations plus flexibles
        gen2_dataflow = {
            'name': gen1_dataflow['name'],
            'queries': [],
            'outputDestination': 'OneLake'  # Nouveau dans Gen2
        }

        for query in gen1_dataflow['queries']:
            # Convertir les queries Power Query M
            gen2_query = self._convert_query(query)
            gen2_dataflow['queries'].append(gen2_query)

        return gen2_dataflow

    def _convert_query(self, gen1_query):
        """
        Adapte une query pour Gen2
        """
        # La plupart des fonctions M sont compatibles
        # Certaines sources peuvent nécessiter des ajustements

        gen2_query = {
            'name': gen1_query['name'],
            'm_expression': gen1_query['m_expression'],
            'output_table': {
                'destination': 'Lakehouse',
                'lakehouse_name': 'default_lakehouse',
                'table_name': gen1_query['name'],
                'update_method': 'Replace'  # ou 'Append'
            }
        }

        return gen2_query
```

## Validation Post-Migration

```sql
-- Script de validation après migration
-- Comparer les résultats avant/après

-- 1. Validation des totaux
WITH source_totals AS (
    SELECT
        'Source' as system,
        SUM(Amount) as total_revenue,
        COUNT(*) as transaction_count,
        COUNT(DISTINCT CustomerID) as unique_customers
    FROM [SourceDB].[dbo].[Sales]
),
target_totals AS (
    SELECT
        'Target' as system,
        SUM(total_amount) as total_revenue,
        COUNT(*) as transaction_count,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM lakehouse.gold.fact_sales
)
SELECT * FROM source_totals
UNION ALL
SELECT * FROM target_totals;

-- 2. Validation des mesures DAX
-- Exécuter les mêmes requêtes sur ancien et nouveau modèle
-- Comparer les résultats

-- 3. Test de performance
-- Mesurer les temps de réponse des requêtes critiques
```

## Points Clés

- Direct Lake offre le meilleur des deux mondes (fraîcheur + performance)
- Préparer les données en Delta Lake avec V-Order pour Direct Lake
- Adopter le pattern Thin Reports pour une meilleure gouvernance
- Les Dataflows Gen2 supportent des outputs vers OneLake
- Valider systématiquement les données et mesures après migration
- Rebinder les rapports existants aux nouveaux datasets
- Profiter de la migration pour consolider et optimiser les mesures
- Former les utilisateurs sur les nouvelles capacités Fabric

---

**Navigation** : [Précédent : Azure Synapse Migration](./02-azure-synapse-migration.md) | [Index](../README.md) | [Suivant : Hybrid Architectures](./04-hybrid-architectures.md)
