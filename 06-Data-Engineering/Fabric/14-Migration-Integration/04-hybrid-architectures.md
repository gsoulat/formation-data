# Hybrid Architectures with Microsoft Fabric

## Introduction

Les architectures hybrides permettent d'intégrer Microsoft Fabric avec des systèmes existants on-premises ou multi-cloud. Cette approche est essentielle pour les organisations qui ne peuvent pas migrer entièrement vers le cloud ou qui ont des contraintes réglementaires spécifiques.

## Patterns d'Architecture Hybride

### 1. Hub-and-Spoke Pattern

```python
# Architecture Hub-and-Spoke avec Fabric comme Hub
hub_spoke_architecture = {
    'hub': {
        'platform': 'Microsoft Fabric',
        'role': 'Central data platform',
        'components': [
            'OneLake (data lake central)',
            'Data Warehouse (serving layer)',
            'Semantic Models (single source of truth)',
            'Governance & Security'
        ]
    },
    'spokes': [
        {
            'name': 'On-Premises SQL Server',
            'connection': 'On-premises Data Gateway',
            'pattern': 'Data replication to OneLake',
            'frequency': 'Batch (nightly)'
        },
        {
            'name': 'Azure Services',
            'connection': 'Direct Azure connectivity',
            'pattern': 'Shortcuts & APIs',
            'frequency': 'Near real-time'
        },
        {
            'name': 'Third-party SaaS',
            'connection': 'REST APIs via Data Factory',
            'pattern': 'API-based ingestion',
            'frequency': 'Scheduled'
        },
        {
            'name': 'IoT Devices',
            'connection': 'Event Hubs / IoT Hub',
            'pattern': 'Streaming ingestion',
            'frequency': 'Real-time'
        }
    ]
}
```

### 2. Data Mesh Pattern

```python
class DataMeshWithFabric:
    def __init__(self):
        self.domains = []
        self.fabric_platform = "OneLake"

    def define_domain(self, domain_config):
        """Définit un domaine dans le Data Mesh"""
        domain = {
            'name': domain_config['name'],
            'owner': domain_config['team'],
            'workspace': f"WS-{domain_config['name']}-Analytics",
            'data_products': [],
            'infrastructure': {
                'lakehouse': f"LH_{domain_config['name']}",
                'warehouse': f"DW_{domain_config['name']}",
                'serving_layer': 'Direct Lake Semantic Model'
            }
        }
        self.domains.append(domain)
        return domain

    def create_data_product(self, domain_name, product_config):
        """Crée un data product dans un domaine"""
        data_product = {
            'name': product_config['name'],
            'description': product_config['description'],
            'sla': product_config['sla'],
            'quality_metrics': product_config['quality'],
            'access_patterns': {
                'api': f"/domains/{domain_name}/products/{product_config['name']}/api",
                'sql_endpoint': True,
                'direct_lake': True,
                'shortcuts': True
            },
            'governance': {
                'data_classification': product_config['classification'],
                'retention_policy': product_config['retention'],
                'lineage_tracked': True
            }
        }
        return data_product

    def implement_interoperability(self):
        """Configure l'interopérabilité entre domaines via OneLake"""
        return {
            'cross_domain_sharing': 'OneLake Shortcuts',
            'common_vocabulary': 'Shared Semantic Layer',
            'data_discovery': 'Microsoft Purview',
            'governance': 'Centralized policies with domain autonomy'
        }
```

## On-Premises Data Gateway

### Configuration du Gateway

```powershell
# Installation et configuration du Gateway
# Télécharger depuis https://go.microsoft.com/fwlink/?LinkId=2116849

# Configuration via PowerShell
function Configure-OnPremisesGateway {
    param(
        [string]$GatewayName,
        [string]$RecoveryKey,
        [string]$Region
    )

    # 1. Installation silencieuse
    $installerPath = "GatewayInstall.exe"
    Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

    # 2. Configuration post-installation
    $gatewayConfig = @{
        Name = $GatewayName
        Region = $Region
        RecoveryKey = $RecoveryKey
        CloudDatasourceRefresh = $true
        CustomConnectorsPath = "C:\GatewayConnectors"
    }

    # 3. Enregistrement du gateway
    Import-Module DataGateway

    $gateway = Add-DataGateway -Name $GatewayName `
        -RecoveryKey $RecoveryKey `
        -Region $Region

    # 4. Configuration des datasources
    $sqlDatasource = @{
        Type = "SqlServer"
        Server = "sqlserver.company.local"
        Database = "SalesDB"
        Authentication = "Windows"
        PrivacyLevel = "Organizational"
    }

    Add-DataGatewayDatasource -Gateway $gateway -Datasource $sqlDatasource

    return $gateway
}

# Configuration haute disponibilité (cluster)
function Setup-GatewayCluster {
    param([string]$PrimaryGatewayName)

    # Ajouter des membres au cluster pour la haute disponibilité
    $members = @("Gateway-Node-1", "Gateway-Node-2", "Gateway-Node-3")

    foreach ($member in $members) {
        Add-DataGatewayClusterMember `
            -GatewayClusterName $PrimaryGatewayName `
            -MemberGatewayName $member `
            -RecoveryKey $RecoveryKey
    }

    # Configurer le load balancing
    Set-DataGatewayCluster `
        -Name $PrimaryGatewayName `
        -LoadBalancingMode "DistributeQueriesAcrossAllMembers"
}
```

### Optimisation des Performances Gateway

```python
# Bonnes pratiques pour les gateways
gateway_optimization = {
    'hardware_recommendations': {
        'cpu': 'Minimum 8 cores',
        'ram': 'Minimum 16 GB, recommended 32 GB',
        'storage': 'SSD with at least 100 GB free',
        'network': 'Gigabit ethernet, low latency to sources'
    },
    'configuration_best_practices': [
        'Enable streaming for large datasets',
        'Configure appropriate timeout values',
        'Use connection pooling',
        'Implement query folding where possible',
        'Monitor gateway performance regularly',
        'Set up alerts for gateway health'
    ],
    'data_movement_patterns': {
        'small_datasets': 'DirectQuery through gateway',
        'medium_datasets': 'Scheduled refresh via gateway',
        'large_datasets': 'Batch export to staging, then OneLake',
        'real_time': 'CDC with staging area'
    }
}
```

## Multi-Cloud Integration

### OneLake Shortcuts

```python
# Configuration des shortcuts pour données multi-cloud
class OneLakeShortcutManager:
    def __init__(self, workspace_id, lakehouse_id):
        self.workspace_id = workspace_id
        self.lakehouse_id = lakehouse_id
        self.api_url = "https://api.fabric.microsoft.com/v1"

    def create_adls_gen2_shortcut(self, name, storage_account, container, path):
        """Crée un shortcut vers ADLS Gen2"""
        shortcut_config = {
            "path": f"Tables/{name}",
            "target": {
                "adlsGen2": {
                    "location": f"https://{storage_account}.dfs.core.windows.net",
                    "subpath": f"{container}/{path}"
                }
            }
        }
        return self._create_shortcut(shortcut_config)

    def create_s3_shortcut(self, name, bucket, region, path):
        """Crée un shortcut vers Amazon S3"""
        shortcut_config = {
            "path": f"Files/{name}",
            "target": {
                "amazonS3": {
                    "location": f"https://{bucket}.s3.{region}.amazonaws.com",
                    "subpath": path
                }
            }
        }
        return self._create_shortcut(shortcut_config)

    def create_gcs_shortcut(self, name, bucket, path):
        """Crée un shortcut vers Google Cloud Storage"""
        shortcut_config = {
            "path": f"Files/{name}",
            "target": {
                "googleCloudStorage": {
                    "location": f"https://storage.googleapis.com/{bucket}",
                    "subpath": path
                }
            }
        }
        return self._create_shortcut(shortcut_config)

    def create_onelake_shortcut(self, name, source_workspace, source_lakehouse, source_path):
        """Crée un shortcut vers un autre emplacement OneLake"""
        shortcut_config = {
            "path": f"Tables/{name}",
            "target": {
                "oneLake": {
                    "workspaceId": source_workspace,
                    "itemId": source_lakehouse,
                    "path": source_path
                }
            }
        }
        return self._create_shortcut(shortcut_config)

    def _create_shortcut(self, config):
        """Crée le shortcut via API"""
        url = f"{self.api_url}/workspaces/{self.workspace_id}/items/{self.lakehouse_id}/shortcuts"
        # POST request with config
        return config
```

### Architecture Multi-Cloud

```yaml
# multi-cloud-architecture.yaml
architecture:
  name: "Enterprise Multi-Cloud Data Platform"

  cloud_providers:
    microsoft_azure:
      role: "Primary Analytics Platform"
      services:
        - name: "Microsoft Fabric"
          function: "Unified Analytics"
        - name: "OneLake"
          function: "Central Data Lake"
        - name: "Azure DevOps"
          function: "CI/CD Pipeline"

    amazon_web_services:
      role: "Legacy Data Sources"
      services:
        - name: "Amazon S3"
          function: "Historical Data Storage"
          integration: "OneLake S3 Shortcuts"
        - name: "Amazon Redshift"
          function: "Legacy DWH"
          integration: "Federated Queries"

    google_cloud_platform:
      role: "ML/AI Workloads"
      services:
        - name: "BigQuery"
          function: "Ad-hoc Analysis"
          integration: "Data Export to OneLake"
        - name: "Vertex AI"
          function: "ML Training"
          integration: "Feature Store Sync"

  data_flows:
    - source: "AWS S3 (Raw Data)"
      destination: "OneLake Bronze Layer"
      method: "S3 Shortcut"
      frequency: "Real-time access"

    - source: "On-Premises SQL Server"
      destination: "OneLake Silver Layer"
      method: "Data Gateway + Pipeline"
      frequency: "Hourly batch"

    - source: "OneLake Gold Layer"
      destination: "GCP BigQuery"
      method: "Export via Data Pipeline"
      frequency: "Daily sync"

  governance:
    data_catalog: "Microsoft Purview (cross-cloud)"
    security: "Azure AD + Cross-cloud IAM mapping"
    lineage: "End-to-end across all clouds"
```

## Scénarios d'Intégration

### Scénario 1: Réglementaire (Data Residency)

```python
# Pattern pour conformité réglementaire
class DataResidencyCompliance:
    def __init__(self):
        self.regions = {}

    def setup_regional_fabric(self):
        """Configure Fabric pour respecter les contraintes de résidence"""

        # EU Data - RGPD compliance
        eu_config = {
            'region': 'West Europe',
            'fabric_capacity': 'F16',
            'data_sovereignty': True,
            'allowed_operations': ['process', 'store', 'analyze'],
            'prohibited': ['transfer_outside_eu'],
            'controls': {
                'encryption': 'Customer-managed keys',
                'audit': 'Full logging to EU storage',
                'access': 'EU-based admins only'
            }
        }

        # US Data - CCPA/SOX compliance
        us_config = {
            'region': 'East US',
            'fabric_capacity': 'F32',
            'compliance_frameworks': ['SOX', 'CCPA'],
            'controls': {
                'audit_trail': 'Complete',
                'retention': '7 years',
                'access_reviews': 'Quarterly'
            }
        }

        return {'eu': eu_config, 'us': us_config}

    def implement_cross_region_analytics(self):
        """Analytics sans déplacer les données sensibles"""
        return {
            'pattern': 'Federated Query',
            'method': 'Aggregate in region, share only results',
            'example': '''
                -- Query each region separately
                -- Combine aggregated results only
                -- Never move PII across borders
            '''
        }
```

### Scénario 2: Edge Computing

```python
# Intégration IoT/Edge avec Fabric
edge_architecture = {
    'edge_layer': {
        'devices': 'IoT Sensors',
        'edge_compute': 'Azure IoT Edge',
        'local_processing': 'Stream processing at edge',
        'data_collection': 'Time-series data'
    },
    'connectivity_layer': {
        'protocol': 'MQTT / AMQP',
        'service': 'Azure IoT Hub / Event Hubs',
        'ingestion_rate': '1M events/second'
    },
    'fabric_layer': {
        'real_time': {
            'service': 'Real-Time Analytics (KQL)',
            'use_case': 'Hot path - immediate insights',
            'retention': '30 days'
        },
        'batch': {
            'service': 'OneLake + Lakehouse',
            'use_case': 'Cold path - historical analysis',
            'retention': '7 years'
        }
    },
    'pipeline': '''
        IoT Sensors
            ↓ (Local aggregation)
        Edge Device
            ↓ (MQTT)
        Azure Event Hubs
            ↓
        ┌────────────────┬────────────────┐
        │   Hot Path     │   Cold Path    │
        │ (Real-Time)    │   (Batch)      │
        │                │                │
        │ Eventstream    │  Data Pipeline │
        │      ↓         │       ↓        │
        │ KQL Database   │   OneLake      │
        └────────────────┴────────────────┘
                    ↓
              Power BI Dashboard
    '''
}
```

## Points Clés

- Les architectures hybrides permettent une migration progressive
- OneLake Shortcuts évitent la duplication des données multi-cloud
- Le Data Gateway est crucial pour les connexions on-premises
- Configurer des clusters Gateway pour la haute disponibilité
- Respecter les contraintes de résidence des données
- Implémenter le pattern Data Mesh pour l'autonomie des domaines
- Monitorer les performances des connexions hybrides
- Planifier la latence acceptable pour chaque use case

---

**Navigation** : [Précédent : Power BI Migration](./03-powerbi-migration.md) | [Index](../README.md) | [Suivant : Integration Patterns](./05-integration-patterns.md)
