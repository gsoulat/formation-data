# Integration Patterns for Microsoft Fabric

## Introduction

Les patterns d'intégration définissent comment Microsoft Fabric communique avec les systèmes externes, ingère les données et expose les résultats. Comprendre ces patterns est essentiel pour architecturer des solutions robustes et scalables.

## Data Ingestion Patterns

### 1. Batch Ingestion

```python
# Pattern Batch: Ingestion périodique de grands volumes
class BatchIngestionPattern:
    def __init__(self):
        self.pattern_name = "Batch Ingestion"
        self.characteristics = {
            'frequency': 'Scheduled (hourly, daily)',
            'volume': 'Large (GB to TB)',
            'latency': 'Minutes to hours',
            'use_cases': [
                'Data warehouse loading',
                'Historical data migration',
                'Nightly ETL jobs',
                'Report preparation'
            ]
        }

    def implement_with_data_factory(self):
        """Implémentation avec Fabric Data Factory"""
        pipeline_config = {
            'name': 'PL_Batch_Sales_Ingestion',
            'trigger': {
                'type': 'Schedule',
                'frequency': 'Daily',
                'time': '02:00 UTC'
            },
            'activities': [
                {
                    'name': 'Copy_Sales_Data',
                    'type': 'Copy',
                    'source': {
                        'type': 'SqlServerSource',
                        'query': '''
                            SELECT *
                            FROM Sales
                            WHERE ModifiedDate >= @{pipeline().parameters.LastWatermark}
                              AND ModifiedDate < @{pipeline().parameters.CurrentWatermark}
                        '''
                    },
                    'sink': {
                        'type': 'LakehouseTable',
                        'tableName': 'bronze_sales',
                        'writeMethod': 'Append'
                    }
                },
                {
                    'name': 'Transform_To_Silver',
                    'type': 'NotebookActivity',
                    'dependsOn': ['Copy_Sales_Data'],
                    'notebookPath': 'Notebooks/Transform_Sales_Silver'
                },
                {
                    'name': 'Update_Watermark',
                    'type': 'SqlServerStoredProcedure',
                    'dependsOn': ['Transform_To_Silver']
                }
            ]
        }
        return pipeline_config
```

### 2. Streaming Ingestion

```python
# Pattern Streaming: Ingestion temps réel
from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col
from pyspark.sql.types import StructType, StringType, TimestampType, DoubleType

class StreamingIngestionPattern:
    def __init__(self, spark):
        self.spark = spark
        self.pattern_name = "Streaming Ingestion"
        self.characteristics = {
            'frequency': 'Continuous',
            'volume': 'Events per second',
            'latency': 'Milliseconds to seconds',
            'use_cases': [
                'IoT sensor data',
                'Real-time fraud detection',
                'Live dashboards',
                'Event-driven processing'
            ]
        }

    def ingest_from_event_hub(self, connection_string, consumer_group):
        """Streaming depuis Event Hub vers OneLake"""

        # Définir le schéma des événements
        event_schema = StructType() \
            .add("device_id", StringType()) \
            .add("timestamp", TimestampType()) \
            .add("temperature", DoubleType()) \
            .add("humidity", DoubleType()) \
            .add("location", StringType())

        # Configuration Event Hub
        eh_conf = {
            'eventhubs.connectionString': connection_string,
            'eventhubs.consumerGroup': consumer_group,
            'eventhubs.startingPosition': 'earliest'
        }

        # Lecture en streaming
        raw_stream = self.spark.readStream \
            .format("eventhubs") \
            .options(**eh_conf) \
            .load()

        # Parser les événements JSON
        parsed_stream = raw_stream \
            .select(from_json(col("body").cast("string"), event_schema).alias("event")) \
            .select("event.*") \
            .withColumn("ingestion_time", col("timestamp"))

        # Écriture vers Delta Lake avec checkpointing
        query = parsed_stream.writeStream \
            .format("delta") \
            .outputMode("append") \
            .option("checkpointLocation", "Tables/bronze_iot/_checkpoints") \
            .option("mergeSchema", "true") \
            .trigger(processingTime="10 seconds") \
            .toTable("bronze_iot_events")

        return query

    def implement_realtime_analytics(self):
        """Connexion avec Real-Time Analytics (KQL)"""
        kql_config = {
            'database': 'iot_analytics',
            'table': 'sensor_events',
            'ingestion': {
                'type': 'Streaming',
                'source': 'EventHub',
                'mapping': 'SensorMapping'
            },
            'retention': '30d',
            'hot_cache': '7d'
        }
        return kql_config
```

### 3. Change Data Capture (CDC)

```sql
-- Pattern CDC: Capture des changements incrémentaux
-- Configuration côté source (SQL Server)

-- 1. Activer CDC sur la base de données
USE SalesDB;
EXEC sys.sp_cdc_enable_db;

-- 2. Activer CDC sur les tables
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Orders',
    @role_name = NULL,
    @supports_net_changes = 1;

-- 3. Créer une table de tracking
CREATE TABLE cdc_tracking (
    table_name NVARCHAR(128),
    last_lsn BINARY(10),
    last_processed_time DATETIME2
);
```

```python
# Implémentation CDC dans Fabric
class CDCIngestionPattern:
    def __init__(self):
        self.pattern_name = "Change Data Capture"

    def process_cdc_changes(self, source_table, target_lakehouse):
        """Traite les changements CDC"""

        # Lire les changements depuis la dernière LSN
        cdc_query = f"""
        DECLARE @from_lsn BINARY(10), @to_lsn BINARY(10);
        SET @from_lsn = (SELECT last_lsn FROM cdc_tracking WHERE table_name = '{source_table}');
        SET @to_lsn = sys.fn_cdc_get_max_lsn();

        SELECT
            __$operation,
            __$start_lsn,
            __$update_mask,
            *
        FROM cdc.fn_cdc_get_all_changes_dbo_{source_table}(@from_lsn, @to_lsn, 'all update old')
        ORDER BY __$start_lsn;
        """

        # Appliquer les changements dans Delta Lake
        delta_operations = {
            1: 'DELETE',
            2: 'INSERT',
            3: 'UPDATE (before)',
            4: 'UPDATE (after)'
        }

        return {
            'source_query': cdc_query,
            'operations': delta_operations,
            'merge_logic': self._generate_merge_statement()
        }

    def _generate_merge_statement(self):
        """Génère le MERGE pour appliquer les changements"""
        return """
        MERGE INTO silver_orders AS target
        USING cdc_changes AS source
        ON target.order_id = source.order_id
        WHEN MATCHED AND source.__$operation = 1 THEN DELETE
        WHEN MATCHED AND source.__$operation = 4 THEN UPDATE SET *
        WHEN NOT MATCHED AND source.__$operation = 2 THEN INSERT *;
        """
```

## API Integration Patterns

### REST API Connector

```python
import requests
from datetime import datetime, timedelta

class RESTAPIIntegration:
    def __init__(self, base_url, auth_config):
        self.base_url = base_url
        self.auth_config = auth_config
        self.session = self._create_session()

    def _create_session(self):
        """Configure la session avec authentification"""
        session = requests.Session()

        if self.auth_config['type'] == 'oauth2':
            token = self._get_oauth_token()
            session.headers['Authorization'] = f'Bearer {token}'
        elif self.auth_config['type'] == 'api_key':
            session.headers['X-API-Key'] = self.auth_config['key']

        return session

    def paginated_fetch(self, endpoint, page_size=100):
        """Récupère des données paginées"""
        all_data = []
        page = 1
        has_more = True

        while has_more:
            params = {
                'page': page,
                'page_size': page_size
            }

            response = self.session.get(
                f"{self.base_url}/{endpoint}",
                params=params
            )
            response.raise_for_status()

            data = response.json()
            all_data.extend(data['results'])

            has_more = data.get('has_next', False)
            page += 1

        return all_data

    def incremental_sync(self, endpoint, last_sync_time):
        """Synchronisation incrémentale basée sur le timestamp"""
        params = {
            'modified_after': last_sync_time.isoformat(),
            'sort': 'modified_date'
        }

        response = self.session.get(
            f"{self.base_url}/{endpoint}",
            params=params
        )

        return response.json()

    def ingest_to_lakehouse(self, data, table_name):
        """Ingère les données API dans le Lakehouse"""
        # Convertir en DataFrame Spark
        df = spark.createDataFrame(data)

        # Ajouter métadonnées
        df = df.withColumn("_ingestion_time", current_timestamp()) \
               .withColumn("_source", lit("rest_api"))

        # Écrire en Delta Lake
        df.write \
            .format("delta") \
            .mode("append") \
            .saveAsTable(f"bronze.{table_name}")
```

### GraphQL Integration

```python
# Pattern GraphQL pour APIs complexes
class GraphQLIntegration:
    def __init__(self, endpoint, headers):
        self.endpoint = endpoint
        self.headers = headers

    def execute_query(self, query, variables=None):
        """Exécute une requête GraphQL"""
        payload = {
            'query': query,
            'variables': variables or {}
        }

        response = requests.post(
            self.endpoint,
            json=payload,
            headers=self.headers
        )

        return response.json()['data']

    def fetch_nested_data(self):
        """Exemple: récupérer des données hiérarchiques"""
        query = """
        query GetCustomerOrders($customerId: ID!) {
            customer(id: $customerId) {
                id
                name
                email
                orders {
                    id
                    date
                    total
                    items {
                        product {
                            name
                            category
                        }
                        quantity
                        price
                    }
                }
            }
        }
        """

        return self.execute_query(query, {'customerId': '12345'})
```

## Event-Driven Integration

### Event Grid Pattern

```python
# Pattern Event-Driven avec Azure Event Grid
class EventDrivenIntegration:
    def __init__(self):
        self.event_types = {
            'data.created': self._handle_data_created,
            'data.updated': self._handle_data_updated,
            'data.deleted': self._handle_data_deleted,
            'pipeline.completed': self._handle_pipeline_completed
        }

    def configure_event_subscription(self):
        """Configure les abonnements Event Grid"""
        subscription_config = {
            'name': 'fabric-data-events',
            'scope': '/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{sa}',
            'eventTypes': [
                'Microsoft.Storage.BlobCreated',
                'Microsoft.Storage.BlobDeleted'
            ],
            'destination': {
                'endpointType': 'WebHook',
                'properties': {
                    'endpointUrl': 'https://fabric-function.azurewebsites.net/api/HandleEvent'
                }
            },
            'filter': {
                'subjectBeginsWith': '/blobServices/default/containers/landing/',
                'subjectEndsWith': '.parquet'
            }
        }
        return subscription_config

    def process_event(self, event):
        """Traite un événement reçu"""
        event_type = event['eventType']

        if event_type in self.event_types:
            handler = self.event_types[event_type]
            return handler(event['data'])
        else:
            raise ValueError(f"Unknown event type: {event_type}")

    def _handle_data_created(self, data):
        """Déclenche l'ingestion quand un fichier arrive"""
        file_path = data['url']
        # Trigger Fabric pipeline
        trigger_pipeline('PL_Ingest_New_File', {'filePath': file_path})

    def _handle_pipeline_completed(self, data):
        """Déclenche des actions post-pipeline"""
        if data['status'] == 'Succeeded':
            # Refresh downstream dependencies
            refresh_semantic_model('SM_Sales_Analytics')
            notify_stakeholders('Pipeline completed successfully')
```

## Data Export Patterns

### Export vers Systèmes Externes

```python
class DataExportPattern:
    def __init__(self, lakehouse_connection):
        self.lakehouse = lakehouse_connection

    def export_to_sftp(self, query, sftp_config):
        """Exporte des données vers SFTP"""
        # Exécuter la requête
        df = spark.sql(query)

        # Convertir en CSV
        csv_path = f"/tmp/export_{datetime.now().strftime('%Y%m%d')}.csv"
        df.coalesce(1).write.csv(csv_path, header=True)

        # Upload vers SFTP
        self._upload_to_sftp(csv_path, sftp_config)

    def export_to_api(self, data, api_endpoint):
        """Push des données vers une API externe"""
        batch_size = 100
        total_records = len(data)

        for i in range(0, total_records, batch_size):
            batch = data[i:i+batch_size]

            response = requests.post(
                api_endpoint,
                json={'records': batch},
                headers={'Content-Type': 'application/json'}
            )

            if response.status_code != 200:
                raise Exception(f"Export failed: {response.text}")

    def create_external_table(self, table_name, external_location):
        """Crée une table externe accessible depuis l'extérieur"""
        create_sql = f"""
        CREATE EXTERNAL TABLE export.{table_name}
        USING PARQUET
        LOCATION '{external_location}'
        AS SELECT * FROM gold.{table_name};
        """
        return create_sql

    def setup_incremental_export(self):
        """Pattern d'export incrémental"""
        return {
            'trigger': 'Schedule or Event',
            'watermark_tracking': True,
            'format': 'Parquet/CSV/JSON',
            'compression': 'GZIP/SNAPPY',
            'partitioning': 'By date/region',
            'validation': 'Row counts and checksums'
        }
```

## Points Clés

- Choisir le pattern d'ingestion adapté au use case (batch, stream, CDC)
- Implémenter des mécanismes de retry et error handling robustes
- Utiliser le checkpointing pour les streams
- Sécuriser les connexions API avec OAuth/API Keys
- Monitorer les performances et les volumes de données
- Documenter les contrats d'interface (schemas, SLAs)
- Tester les patterns de failover et recovery
- Considérer la latence acceptable pour chaque intégration

---

**Navigation** : [Précédent : Hybrid Architectures](./04-hybrid-architectures.md) | [Index](../README.md) | [Module 15 : Préparation DP-700](../15-Preparation-DP700/01-exam-overview.md)
