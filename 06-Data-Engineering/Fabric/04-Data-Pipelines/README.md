# Module 04 - Data Pipelines

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre l'intégration de Data Factory dans Fabric
- ✅ Créer et orchestrer des pipelines complexes
- ✅ Utiliser les Copy activities pour ingérer des données
- ✅ Implémenter des transformations dans les pipelines
- ✅ Gérer le scheduling et les dépendances
- ✅ Utiliser les paramètres et variables
- ✅ Monitorer et débugger les pipelines
- ✅ Implémenter le chargement incrémental

## Contenu du module

### [01 - Data Factory Integration](./01-data-factory-integration.md)
- Data Factory dans Fabric vs Azure Data Factory
- Composants principaux (pipelines, activities, datasets)
- Integration runtime
- Linked services et connections
- Différences et limitations vs ADF

### [02 - Création de Pipelines](./02-pipeline-creation.md)
- Interface de création de pipeline
- Activities disponibles :
  - Copy Data
  - Dataflow Gen2
  - Notebook
  - Stored Procedure
  - Web
  - Script
- Control flow activities (If/Switch/ForEach/Until)
- Chaînage d'activities
- Success/Failure paths

### [03 - Copy Activities](./03-copy-activities.md)
- Configuration de Copy activity
- Sources de données supportées (100+ connecteurs)
- Formats de fichiers (CSV, JSON, Parquet, Avro, ORC)
- Mapping de schéma
- Options de performance (DIU, parallel copies)
- Fault tolerance et retry policy
- Logging et monitoring

### [04 - Transformations](./04-transformations.md)
- Transformations simples dans Copy activity
- Utilisation de Dataflow Gen2 dans pipeline
- Script activity (SQL, Python, Shell)
- Notebook activity pour transformations Spark
- Stored procedures
- Comparaison des approches

### [05 - Orchestration et Scheduling](./05-orchestration-scheduling.md)
- Triggers :
  - Schedule trigger (cron expressions)
  - Tumbling window trigger
  - Event-based trigger (storage events)
- Orchestration patterns :
  - Sequential processing
  - Parallel processing
  - Conditional branching
  - Error handling
- Pipeline chaining
- Dependencies et wait activities

### [06 - Paramètres et Variables](./06-parameters-variables.md)
- Pipeline parameters
- Activity variables
- System variables (@pipeline, @trigger, @activity)
- Dynamic content et expressions
- Paramétrage des datasets
- Use case : pipelines génériques et réutilisables

### [07 - Monitoring et Debugging](./07-monitoring-debugging.md)
- Monitoring hub dans Fabric
- Pipeline runs et activity runs
- Detailed input/output inspection
- Debug mode
- Breakpoints
- Log analytics integration
- Alertes et notifications
- Best practices de troubleshooting

### [08 - Chargement Incrémental](./08-incremental-loading.md)
- Patterns de chargement :
  - Full load
  - Incremental load (watermark)
  - Change Data Capture (CDC)
  - Delta load
- Watermark table pattern
- Last modified date approach
- Change tracking
- Optimisation des performances

## Exercices pratiques

### Exercice 1 : Premier pipeline
1. Créer un pipeline simple
2. Ajouter une Copy activity
3. Copier des données CSV vers Lakehouse
4. Exécuter et monitorer

### Exercice 2 : Pipeline orchestré
1. Créer un pipeline avec plusieurs Copy activities
2. Implémenter du parallel processing
3. Ajouter des conditions (If activity)
4. Gérer les erreurs avec Success/Failure paths

### Exercice 3 : Paramétrage
1. Créer un pipeline paramétré
2. Passer des paramètres depuis le trigger
3. Utiliser des variables pour la logique dynamique
4. Créer un dataset paramétré

### Exercice 4 : Scheduling
1. Créer un schedule trigger (tous les jours à 8h)
2. Créer un tumbling window trigger
3. Configurer un event-based trigger (nouveau fichier)
4. Tester les différents triggers

### Exercice 5 : Chargement incrémental
1. Implémenter un watermark table
2. Créer un pipeline de chargement incrémental
3. Gérer les updates et deletes
4. Optimiser avec partitionnement

### Exercice 6 : Monitoring et alertes
1. Explorer le monitoring hub
2. Analyser les execution logs
3. Débugger un pipeline en erreur
4. Configurer une alerte sur échec

## Quiz

1. Quelle est la différence entre un schedule trigger et un tumbling window trigger ?
2. Comment implémenter un chargement incrémental avec watermark ?
3. Qu'est-ce qu'une DIU (Data Integration Unit) ?
4. Comment gérer les erreurs dans un pipeline ?
5. Expliquez le concept de pipeline paramétré

## Exemples de code

### Pipeline paramétré (JSON)

```json
{
    "name": "GenericCopyPipeline",
    "properties": {
        "parameters": {
            "sourceTable": {
                "type": "string"
            },
            "targetContainer": {
                "type": "string"
            },
            "loadDate": {
                "type": "string",
                "defaultValue": "@utcnow()"
            }
        },
        "activities": [
            {
                "name": "CopyData",
                "type": "Copy",
                "inputs": [
                    {
                        "referenceName": "SourceDataset",
                        "parameters": {
                            "tableName": "@pipeline().parameters.sourceTable"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "SinkDataset",
                        "parameters": {
                            "container": "@pipeline().parameters.targetContainer"
                        }
                    }
                ]
            }
        ]
    }
}
```

### Expression pour watermark

```python
# Dans une Copy activity - filter query
@concat('SELECT * FROM ', pipeline().parameters.tableName,
        ' WHERE ModifiedDate > ''', activity('LookupWatermark').output.firstRow.WatermarkValue, '''')
```

### Schedule trigger (cron)

```json
{
    "name": "DailyTrigger",
    "properties": {
        "type": "ScheduleTrigger",
        "typeProperties": {
            "recurrence": {
                "frequency": "Day",
                "interval": 1,
                "schedule": {
                    "hours": [8],
                    "minutes": [0]
                },
                "timeZone": "Romance Standard Time"
            }
        }
    }
}
```

## Architecture patterns

### Pattern 1 : ETL orchestré
```
[Source DB] → [Copy to Bronze] → [Notebook Transformation] → [Copy to Silver] → [Dataflow to Gold]
```

### Pattern 2 : Parallel ingestion
```
                 ┌─ [Copy Activity 1] ─┐
[Trigger] ──────┼─ [Copy Activity 2] ─┼──→ [Success]
                 └─ [Copy Activity 3] ─┘
```

### Pattern 3 : Error handling
```
[Copy Activity] ──Success──→ [Notebook Processing] ──→ [Success]
       │
       └──Failure──→ [Log Error] ──→ [Send Alert] ──→ [Fail]
```

## Ressources complémentaires

### Documentation officielle
- [Data pipelines in Fabric](https://learn.microsoft.com/fabric/data-factory/data-factory-overview)
- [Copy activity](https://learn.microsoft.com/fabric/data-factory/copy-data-activity)
- [Pipeline expressions](https://learn.microsoft.com/azure/data-factory/control-flow-expression-language-functions)

### Patterns
- [Incremental loading patterns](https://learn.microsoft.com/azure/data-factory/tutorial-incremental-copy-overview)
- [Pipeline best practices](https://learn.microsoft.com/azure/data-factory/concepts-pipelines-activities)

## Durée estimée

- **Lecture** : 5-6 heures
- **Exercices** : 4-5 heures
- **Total** : 9-11 heures

## Prochaine étape

➡️ [Module 05 - Dataflows Gen2](../05-Dataflows-Gen2/)

---

[⬅️ Module précédent](../03-Data-Warehouse/) | [⬅️ Retour au sommaire](../README.md)
