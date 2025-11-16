# Module 08 - Real-Time Analytics

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre EventStream pour le streaming de données
- ✅ Créer et gérer une KQL Database
- ✅ Maîtriser Kusto Query Language (KQL)
- ✅ Implémenter l'ingestion streaming
- ✅ Créer des dashboards temps réel
- ✅ Configurer des alertes avec Data Activator

## Contenu du module

### [01 - EventStream Overview](./01-eventstream-overview.md)
- Qu'est-ce qu'EventStream dans Fabric ?
- Architecture de streaming
- Sources supportées :
  - Azure Event Hubs
  - Azure IoT Hub
  - Kafka
  - Custom endpoints
- Destinations :
  - KQL Database
  - Lakehouse
  - Custom apps
- Use cases typiques

### [02 - KQL Database](./02-kql-database.md)
- Introduction à KQL Database
- Architecture (Azure Data Explorer sous-jacent)
- Création et configuration
- Tables et schémas
- Policies (retention, caching, partitioning)
- Différences avec SQL databases
- Quand utiliser KQL vs SQL

### [03 - Kusto Query Language](./03-kusto-query-language.md)
- Syntaxe de base KQL
- Opérateurs fondamentaux :
  - `where` : filtrage
  - `project` : sélection colonnes
  - `extend` : colonnes calculées
  - `summarize` : agrégation
  - `join` : jointures
  - `union` : union de tables
- Time series functions
- Visualisations intégrées (render)
- Fonctions avancées

### [04 - Streaming Ingestion](./04-streaming-ingestion.md)
- Configuration de l'ingestion streaming
- Mapping de données (JSON, CSV, Avro)
- Batching et throughput
- Error handling
- Monitoring de l'ingestion
- Optimisation des performances
- Latence vs throughput tradeoff

### [05 - Real-Time Dashboards](./05-real-time-dashboards.md)
- Création de dashboards KQL
- Visualisations disponibles
- Auto-refresh configuration
- Filtres et paramètres
- Drill-through
- Sharing et permissions
- Embedding
- Performance tips

### [06 - Data Activator & Alerts](./06-activator-alerts.md)
- Introduction à Data Activator (anciennement Reflex)
- Définition de triggers
- Conditions et seuils
- Actions automatisées :
  - Email notifications
  - Teams messages
  - Power Automate
  - Webhooks
- Use cases : anomaly detection, SLA monitoring
- Best practices

## Exercices pratiques

### Exercice 1 : Création KQL Database
1. Créer une KQL Database
2. Créer une table pour logs
3. Définir le schéma
4. Configurer retention policy

### Exercice 2 : Ingestion streaming
1. Configurer un EventStream
2. Source : générer des événements IoT simulés
3. Destination : KQL Database
4. Vérifier l'ingestion en temps réel

### Exercice 3 : Requêtes KQL basics
1. Filtrer les logs par niveau (error, warning)
2. Compter les événements par minute
3. Calculer des percentiles
4. Créer un time series chart

### Exercice 4 : KQL avancé
1. Analyser des patterns de trafic web
2. Détecter des anomalies (requêtes anormalement lentes)
3. Calculer des métriques glissantes (moving average)
4. Identifier les top utilisateurs

### Exercice 5 : Dashboard temps réel
1. Créer un dashboard KQL
2. Ajouter des visualisations (line chart, bar chart, pie chart)
3. Configurer l'auto-refresh (10 secondes)
4. Ajouter des filtres interactifs
5. Partager avec l'équipe

### Exercice 6 : Alertes
1. Créer un Activator
2. Détecter quand le taux d'erreur > 5%
3. Envoyer une notification Teams
4. Déclencher un Power Automate flow
5. Tester les alertes

## Quiz

1. Quelle est la différence entre KQL Database et SQL Database ?
2. Expliquez l'opérateur `summarize` en KQL
3. Comment configurer l'ingestion streaming depuis Event Hub ?
4. Qu'est-ce que Data Activator ?
5. Comment optimiser les performances d'une requête KQL ?

## Exemples de code KQL

### Requêtes basiques

```kql
// Filtrage simple
Logs
| where Timestamp > ago(1h)
| where Level == "Error"

// Projection
Logs
| project Timestamp, Message, Level, User

// Top N
Logs
| top 100 by Timestamp desc

// Distinct count
Logs
| summarize dcount(User)
```

### Agrégations

```kql
// Count par heure
Logs
| summarize Count = count() by bin(Timestamp, 1h)
| render timechart

// Agrégations multiples
WebLogs
| summarize
    TotalRequests = count(),
    AvgDuration = avg(Duration),
    P95Duration = percentile(Duration, 95),
    UniqueUsers = dcount(UserId)
  by bin(Timestamp, 5m)
```

### Time series

```kql
// Trend sur 7 jours
Metrics
| where Timestamp > ago(7d)
| summarize avg(Value) by bin(Timestamp, 1h)
| render timechart

// Comparaison période actuelle vs précédente
let current = Metrics
    | where Timestamp > ago(1d)
    | summarize CurrentValue = avg(Value);
let previous = Metrics
    | where Timestamp between (ago(2d) .. ago(1d))
    | summarize PreviousValue = avg(Value);
current | extend PreviousValue = toscalar(previous)
```

### Détection d'anomalies

```kql
// Détecter les pics anormaux
Metrics
| make-series Value = avg(Value) on Timestamp step 5m
| extend anomalies = series_decompose_anomalies(Value, 1.5)
| mv-expand Timestamp, Value, anomalies
| where anomalies > 0
```

### Jointures

```kql
// Join avec enrichissement
Requests
| join kind=leftouter (
    Users
    | project UserId, UserName, Country
) on UserId
| project Timestamp, UserName, Country, RequestPath, Duration
```

### Fonctions avancées

```kql
// Fonction custom
.create-or-alter function
    ErrorRate(startTime: datetime, endTime: datetime) {
    Logs
    | where Timestamp between (startTime .. endTime)
    | summarize
        Total = count(),
        Errors = countif(Level == "Error")
    | extend ErrorRate = round(100.0 * Errors / Total, 2)
}

// Utilisation
ErrorRate(ago(1h), now())
```

### Visualisations

```kql
// Line chart
Metrics
| summarize avg(Value) by bin(Timestamp, 1h)
| render timechart

// Pie chart
Logs
| summarize count() by Level
| render piechart

// Bar chart
WebLogs
| summarize Requests = count() by Page
| top 10 by Requests
| render barchart
```

## Architecture patterns

### Pattern 1 : IoT telemetry

```
[IoT Devices] → [IoT Hub] → [EventStream] → [KQL Database] → [Real-Time Dashboard]
                                          ↓
                                    [Activator] → [Alerts]
```

### Pattern 2 : Log analytics

```
[Applications] → [Event Hub] → [EventStream] → [KQL Database] ← [KQL Queries]
                                             ↓
                                       [Lakehouse] (archivage)
```

### Pattern 3 : Monitoring

```
[Metrics] → [KQL Database] → [Dashboard] → [Activator] → [Teams/Email]
```

## Ressources complémentaires

### Documentation officielle
- [Real-Time Analytics in Fabric](https://learn.microsoft.com/fabric/real-time-analytics/)
- [KQL quick reference](https://learn.microsoft.com/azure/data-explorer/kql-quick-reference)
- [EventStream documentation](https://learn.microsoft.com/fabric/real-time-analytics/event-streams/overview)

### Apprentissage
- [KQL tutorial](https://learn.microsoft.com/azure/data-explorer/kusto/query/tutorial)
- [Data Activator](https://learn.microsoft.com/fabric/data-activator/data-activator-introduction)

### Outils
- [Kusto Explorer](https://learn.microsoft.com/azure/data-explorer/kusto/tools/kusto-explorer)
- [Azure Data Explorer Web UI](https://dataexplorer.azure.com/)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 3-4 heures
- **Total** : 7-9 heures

## Prochaine étape

➡️ [Module 09 - Sécurité & Gouvernance](../09-Securite-Gouvernance/)

---

[⬅️ Module précédent](../07-Semantic-Models-PowerBI/) | [⬅️ Retour au sommaire](../README.md)
