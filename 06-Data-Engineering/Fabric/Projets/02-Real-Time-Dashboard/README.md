# Projet 2 : Real-Time IoT Dashboard

## Vue d'ensemble

Dans ce projet, vous allez construire un **système de monitoring temps réel** pour une usine de fabrication fictive "SmartFactory". Vous implémenterez une solution complète d'analytics temps réel avec alertes automatiques et dashboards interactifs.

**Durée estimée :** 8-10 heures
**Niveau :** Intermédiaire
**Modules prérequis :** 08 (Real-Time Analytics)

## Contexte Business

### L'entreprise : SmartFactory

SmartFactory est une usine de fabrication de composants électroniques. Ils disposent de :
- 50 capteurs de température sur les machines
- 30 capteurs d'humidité dans les zones de stockage
- 20 capteurs de pression dans les systèmes pneumatiques
- 10 capteurs de vibration sur les équipements critiques

### Problématique

L'usine fait face à plusieurs défis :
- **Pannes imprévues** : coûtant 50K€/heure d'arrêt
- **Qualité variable** : défauts liés aux conditions environnementales
- **Maintenance réactive** : pas de visibilité sur l'état des équipements
- **Temps de réponse lent** : alertes manuelles avec délai

**Objectif :** Créer un système de monitoring temps réel avec alertes automatiques pour prédire et prévenir les pannes.

## Objectifs d'Apprentissage

À la fin de ce projet, vous serez capable de :

- ✅ Configurer un EventStream pour l'ingestion de données en streaming
- ✅ Créer et gérer une KQL Database pour l'analytics temps réel
- ✅ Écrire des requêtes KQL avancées (agrégations, time series, anomalies)
- ✅ Construire des dashboards temps réel interactifs
- ✅ Implémenter des alertes automatiques avec Data Activator
- ✅ Analyser des patterns et détecter des anomalies
- ✅ Optimiser les performances d'ingestion et de requêtes

## 📦 Données Fournies

**IMPORTANT : Les données pour ce projet sont disponibles dans `../../Ressources/datasets/`**

| Fichier | Description | Usage dans ce projet |
|---------|-------------|---------------------|
| **`iot_telemetry.json`** (2.0 MB, 10K events) | Télémétrie IoT avec temperature, pressure, humidity | → Simulateur de capteurs IoT |
| **`web_logs.json`** (17 MB, 50K logs) | Logs web avec timestamps, status codes, response times | → Analytics temps réel optionnel |

### Option 1 : Utiliser les Données JSON Fournies

```python
# Charger les données IoT dans un notebook Fabric
import json
from datetime import datetime, timedelta

# Lire le fichier JSON
with open("Files/raw/iot_telemetry.json", "r") as f:
    telemetry_data = json.load(f)

# Convertir en DataFrame Spark
df_telemetry = spark.createDataFrame(telemetry_data)
print(f"Events IoT: {df_telemetry.count()} lignes")
df_telemetry.show(5)
```

### Option 2 : Simulateur Temps Réel (Recommandé)

Le projet inclut un **simulateur Python complet** (voir section "Simulateur IoT" plus bas) qui génère des données en temps réel. Ce simulateur peut :
- Utiliser `iot_telemetry.json` comme base de données historiques
- Générer de nouveaux événements en continu
- Envoyer les données vers EventStream

### Chargement dans Fabric

1. **Uploadez** `iot_telemetry.json` dans `Files/raw/`
2. **Pour le streaming** : Utilisez le simulateur Python fourni dans ce README
3. **Configuration EventStream** : Le simulateur peut publier vers Azure Event Hub ou Custom Endpoint

## Architecture Cible

```
┌─────────────────────────────────────────────────────────────────┐
│                        SOURCES IoT                               │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ Temperature  │ Humidity     │ Pressure     │ Vibration         │
│ Sensors (50) │ Sensors (30) │ Sensors (20) │ Sensors (10)      │
└──────┬───────┴──────┬───────┴──────┬───────┴─────────┬─────────┘
       │              │              │                 │
       └──────────────┴──────────────┴─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Azure IoT Hub  │  (Simulé)
                    │   / Event Hub    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   EventStream   │
                    │   (Ingestion)   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐           ┌─────────────────┐
    │  KQL Database   │           │  Data Activator │
    │  (Analytics)    │           │  (Alerts)       │
    └────────┬────────┘           └────────┬────────┘
             │                             │
             ▼                             ▼
    ┌─────────────────┐           ┌─────────────────┐
    │ Real-Time       │           │  Teams/Email    │
    │ Dashboard       │           │  Notifications  │
    └─────────────────┘           └─────────────────┘
```

## Phase 1: Génération de Données IoT (1h)

### 1.1 Simulateur de Capteurs

Créez un script Python pour générer des données IoT réalistes :

```python
import json
import random
from datetime import datetime
import time

class IoTSimulator:
    """Simulateur de capteurs IoT pour SmartFactory"""

    def __init__(self):
        self.devices = self._initialize_devices()

    def _initialize_devices(self):
        """Créer les configurations des capteurs"""
        devices = []

        # Temperature sensors (machines)
        for i in range(1, 51):
            devices.append({
                "device_id": f"TEMP_{i:03d}",
                "type": "temperature",
                "location": f"Machine_{(i-1)//5 + 1}",
                "zone": f"Production_Zone_{(i-1)//10 + 1}",
                "normal_value": 45 + random.uniform(-5, 5),
                "noise": 2.0
            })

        # Humidity sensors (storage)
        for i in range(1, 31):
            devices.append({
                "device_id": f"HUM_{i:03d}",
                "type": "humidity",
                "location": f"Storage_Area_{(i-1)//6 + 1}",
                "zone": f"Storage_Zone_{(i-1)//10 + 1}",
                "normal_value": 55 + random.uniform(-10, 10),
                "noise": 5.0
            })

        # Pressure sensors
        for i in range(1, 21):
            devices.append({
                "device_id": f"PRESS_{i:03d}",
                "type": "pressure",
                "location": f"Pneumatic_System_{(i-1)//4 + 1}",
                "zone": f"Production_Zone_{(i-1)//5 + 1}",
                "normal_value": 100 + random.uniform(-10, 10),
                "noise": 3.0
            })

        # Vibration sensors
        for i in range(1, 11):
            devices.append({
                "device_id": f"VIB_{i:03d}",
                "type": "vibration",
                "location": f"Critical_Equipment_{i}",
                "zone": "Critical_Zone",
                "normal_value": 0.5 + random.uniform(-0.1, 0.1),
                "noise": 0.1
            })

        return devices

    def generate_reading(self, device):
        """Générer une lecture pour un capteur"""
        # Valeur normale avec bruit
        value = device["normal_value"] + random.gauss(0, device["noise"])

        # Simuler occasionnellement des anomalies (5% chance)
        if random.random() < 0.05:
            if device["type"] == "temperature":
                value += random.uniform(15, 30)  # Surchauffe
            elif device["type"] == "vibration":
                value *= random.uniform(2, 4)    # Vibration excessive
            elif device["type"] == "pressure":
                value += random.uniform(-20, 20)  # Pression anormale

        return {
            "device_id": device["device_id"],
            "device_type": device["type"],
            "location": device["location"],
            "zone": device["zone"],
            "value": round(value, 2),
            "unit": self._get_unit(device["type"]),
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "quality": "good" if not self._is_anomaly(device, value) else "warning"
        }

    def _get_unit(self, device_type):
        units = {
            "temperature": "celsius",
            "humidity": "percent",
            "pressure": "bar",
            "vibration": "mm/s"
        }
        return units.get(device_type, "unknown")

    def _is_anomaly(self, device, value):
        threshold = 3 * device["noise"]
        return abs(value - device["normal_value"]) > threshold

    def generate_batch(self):
        """Générer un batch de données pour tous les capteurs"""
        return [self.generate_reading(device) for device in self.devices]

    def stream_data(self, interval_seconds=1):
        """Streamer des données en continu"""
        while True:
            batch = self.generate_batch()
            for reading in batch:
                yield json.dumps(reading)
            time.sleep(interval_seconds)

# Usage
simulator = IoTSimulator()

# Générer un fichier de test
with open("iot_sample_data.json", "w") as f:
    for _ in range(1000):
        batch = simulator.generate_batch()
        for reading in batch:
            f.write(json.dumps(reading) + "\n")

print(f"Generated {1000 * 111} readings")
```

### 1.2 Structure des Données

```json
{
  "device_id": "TEMP_001",
  "device_type": "temperature",
  "location": "Machine_1",
  "zone": "Production_Zone_1",
  "value": 47.32,
  "unit": "celsius",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "quality": "good"
}
```

## Phase 2: Configuration EventStream (2h)

### 2.1 Créer EventStream

1. Dans Fabric Workspace → New → EventStream
2. Nommer : "SmartFactory_Telemetry_Stream"
3. Description : "Real-time ingestion of IoT sensor data"

### 2.2 Configurer la Source

**Option A : Sample Data (pour tests)**
```
Source Type: Sample Data
Data Format: JSON
Schema: Custom (IoT telemetry)
```

**Option B : Azure Event Hub (production)**
```
Source Type: Azure Event Hub
Connection String: <your-connection-string>
Consumer Group: $Default
Data Format: JSON
```

**Option C : Custom Endpoint**
```python
# Envoyer des données vers EventStream
import requests

eventstream_endpoint = "https://your-eventstream-endpoint"

simulator = IoTSimulator()
for reading in simulator.stream_data(interval_seconds=1):
    requests.post(eventstream_endpoint, data=reading, headers={"Content-Type": "application/json"})
```

### 2.3 Configurer Transformations (Optionnel)

Dans EventStream, ajoutez des transformations :

```sql
-- Filtrer les données de qualité
SELECT *
FROM InputStream
WHERE quality IN ('good', 'warning')

-- Enrichir avec calculs
SELECT
    device_id,
    device_type,
    location,
    zone,
    value,
    unit,
    timestamp,
    quality,
    CASE
        WHEN device_type = 'temperature' AND value > 70 THEN 'critical'
        WHEN device_type = 'vibration' AND value > 2.0 THEN 'critical'
        ELSE 'normal'
    END AS alert_level
FROM InputStream
```

### 2.4 Configurer la Destination

1. Ajouter destination : KQL Database
2. Sélectionner la database (créée dans Phase 3)
3. Table : `Telemetry`
4. Mapping : Auto-detect ou manuel

## Phase 3: KQL Database Setup (2h)

### 3.1 Créer KQL Database

1. Fabric Workspace → New → KQL Database
2. Nom : "SmartFactory_Analytics"
3. Type : Eventhouse

### 3.2 Créer les Tables

```kql
// Table principale de télémétrie
.create table Telemetry (
    DeviceId: string,
    DeviceType: string,
    Location: string,
    Zone: string,
    Value: real,
    Unit: string,
    Timestamp: datetime,
    Quality: string
)

// Politique de rétention (garder 30 jours)
.alter-merge table Telemetry policy retention
```
{
    "SoftDeletePeriod": "30.00:00:00",
    "Recoverability": "Enabled"
}
```

// Table des seuils d'alerte
.create table AlertThresholds (
    DeviceType: string,
    MinValue: real,
    MaxValue: real,
    CriticalMin: real,
    CriticalMax: real
)

// Insérer les seuils
.ingest inline into table AlertThresholds
<| temperature,20,60,10,75
| humidity,30,70,20,80
| pressure,80,120,70,130
| vibration,0,1.5,0,3.0
```

### 3.3 Configurer l'Ingestion Mapping

```kql
// Créer le mapping JSON
.create table Telemetry ingestion json mapping 'IoTMapping'
'['
'  {"column": "DeviceId", "path": "$.device_id"},'
'  {"column": "DeviceType", "path": "$.device_type"},'
'  {"column": "Location", "path": "$.location"},'
'  {"column": "Zone", "path": "$.zone"},'
'  {"column": "Value", "path": "$.value"},'
'  {"column": "Unit", "path": "$.unit"},'
'  {"column": "Timestamp", "path": "$.timestamp"},'
'  {"column": "Quality", "path": "$.quality"}'
']'
```

### 3.4 Vérifier l'Ingestion

```kql
// Vérifier les données entrantes
Telemetry
| take 10

// Compter par type
Telemetry
| summarize Count = count() by DeviceType
| render piechart

// Vérifier la latence
Telemetry
| extend IngestionLatency = now() - Timestamp
| summarize avg(IngestionLatency), max(IngestionLatency)
```

## Phase 4: Queries KQL Avancées (2h)

### 4.1 Monitoring en Temps Réel

```kql
// ========================================
// DASHBOARD PRINCIPAL
// ========================================

// KPI 1: Nombre de devices actifs (dernière minute)
Telemetry
| where Timestamp > ago(1m)
| summarize ActiveDevices = dcount(DeviceId)

// KPI 2: Température moyenne globale
Telemetry
| where DeviceType == "temperature" and Timestamp > ago(5m)
| summarize AvgTemperature = round(avg(Value), 1)

// KPI 3: Nombre d'alertes actives
Telemetry
| where Timestamp > ago(5m)
| join kind=inner AlertThresholds on $left.DeviceType == $right.DeviceType
| where Value < CriticalMin or Value > CriticalMax
| summarize AlertCount = dcount(DeviceId)
```

### 4.2 Analyse de Tendances

```kql
// Température moyenne par zone (5 min bins)
Telemetry
| where DeviceType == "temperature"
| where Timestamp > ago(1h)
| summarize AvgTemp = avg(Value) by bin(Timestamp, 5m), Zone
| render timechart

// Comparaison des zones
Telemetry
| where DeviceType == "temperature"
| where Timestamp > ago(1h)
| summarize
    AvgTemp = avg(Value),
    MaxTemp = max(Value),
    MinTemp = min(Value),
    StdDev = stdev(Value)
  by Zone
| order by AvgTemp desc
| render columnchart
```

### 4.3 Détection d'Anomalies

```kql
// Détection d'anomalies par série temporelle
Telemetry
| where DeviceType == "temperature"
| where Timestamp > ago(24h)
| make-series AvgTemp = avg(Value) default=0 on Timestamp step 10m by Zone
| extend anomalies = series_decompose_anomalies(AvgTemp, 1.5)
| mv-expand Timestamp, AvgTemp, anomalies
| where toint(anomalies) != 0
| project Timestamp = todatetime(Timestamp), Zone, AvgTemp = todouble(AvgTemp), AnomalyScore = toint(anomalies)

// Devices avec comportement anormal
Telemetry
| where Timestamp > ago(1h)
| join kind=inner AlertThresholds on $left.DeviceType == $right.DeviceType
| extend
    IsOutOfRange = Value < MinValue or Value > MaxValue,
    IsCritical = Value < CriticalMin or Value > CriticalMax
| summarize
    TotalReadings = count(),
    OutOfRangeCount = countif(IsOutOfRange),
    CriticalCount = countif(IsCritical)
  by DeviceId, DeviceType, Location
| where OutOfRangeCount > 0
| extend AnomalyRate = round(100.0 * OutOfRangeCount / TotalReadings, 2)
| order by CriticalCount desc, AnomalyRate desc
| take 20
```

### 4.4 Pattern Analysis

```kql
// Patterns horaires (détection de cycles)
Telemetry
| where DeviceType == "temperature"
| where Timestamp > ago(7d)
| extend Hour = hourofday(Timestamp)
| summarize AvgValue = avg(Value) by Hour, Zone
| order by Zone, Hour
| render linechart

// Corrélation entre capteurs
Telemetry
| where Timestamp > ago(1h)
| where DeviceType in ("temperature", "humidity")
| summarize Value = avg(Value) by bin(Timestamp, 1m), DeviceType
| evaluate pivot(DeviceType, avg(Value))
| extend Correlation = temperature / humidity
| render timechart
```

### 4.5 Fonctions Réutilisables

```kql
// Créer une fonction pour les alertes
.create-or-alter function GetActiveAlerts() {
    Telemetry
    | where Timestamp > ago(5m)
    | join kind=inner AlertThresholds on $left.DeviceType == $right.DeviceType
    | where Value < CriticalMin or Value > CriticalMax
    | extend AlertType = iff(Value < CriticalMin, "LOW", "HIGH")
    | project
        Timestamp,
        DeviceId,
        DeviceType,
        Location,
        Zone,
        Value,
        AlertType,
        Threshold = iff(AlertType == "LOW", CriticalMin, CriticalMax)
    | order by Timestamp desc
}

// Utilisation
GetActiveAlerts()
| take 50
```

## Phase 5: Real-Time Dashboard (2h)

### 5.1 Créer le Dashboard

1. Fabric Workspace → New → Real-Time Dashboard
2. Nom : "SmartFactory_Operations_Dashboard"
3. Source : KQL Database "SmartFactory_Analytics"

### 5.2 Page 1: Vue d'Ensemble

**Tile 1: Active Devices (Card)**
```kql
Telemetry
| where Timestamp > ago(1m)
| summarize ActiveDevices = dcount(DeviceId)
```

**Tile 2: Average Temperature (Gauge)**
```kql
Telemetry
| where DeviceType == "temperature" and Timestamp > ago(5m)
| summarize Value = round(avg(Value), 1)
```
- Min: 0, Max: 100, Target: 50

**Tile 3: Active Alerts (Card - with conditional color)**
```kql
Telemetry
| where Timestamp > ago(5m)
| join kind=inner AlertThresholds on $left.DeviceType == $right.DeviceType
| where Value < CriticalMin or Value > CriticalMax
| summarize AlertCount = dcount(DeviceId)
```

**Tile 4: Temperature Trend (Time Chart)**
```kql
Telemetry
| where DeviceType == "temperature"
| where Timestamp > ago(1h)
| summarize AvgTemp = avg(Value) by bin(Timestamp, 1m), Zone
| render timechart
```

**Tile 5: Alert Table (Table)**
```kql
GetActiveAlerts()
| take 20
```

### 5.3 Page 2: Zone Analysis

**Tile 1: Temperature by Zone (Heatmap)**
```kql
Telemetry
| where DeviceType == "temperature"
| where Timestamp > ago(30m)
| summarize AvgTemp = avg(Value) by Zone, bin(Timestamp, 5m)
```

**Tile 2: Device Status (Donut Chart)**
```kql
Telemetry
| where Timestamp > ago(5m)
| join kind=inner AlertThresholds on $left.DeviceType == $right.DeviceType
| extend Status = case(
    Value < CriticalMin or Value > CriticalMax, "Critical",
    Value < MinValue or Value > MaxValue, "Warning",
    "Normal"
  )
| summarize Count = dcount(DeviceId) by Status
| render piechart
```

**Tile 3: Zone Performance (Bar Chart)**
```kql
Telemetry
| where Timestamp > ago(1h)
| summarize
    AvgValue = avg(Value),
    Readings = count(),
    Anomalies = countif(Quality == "warning")
  by Zone
| extend AnomalyRate = round(100.0 * Anomalies / Readings, 2)
| order by AnomalyRate desc
| render barchart
```

### 5.4 Page 3: Device Details

**Tile 1: Device Selector (Parameter)**
- Type: Dynamic
- Query: `Telemetry | distinct DeviceId | order by DeviceId`

**Tile 2: Device History (Time Chart)**
```kql
Telemetry
| where DeviceId == "${DeviceSelector}"
| where Timestamp > ago(24h)
| project Timestamp, Value
| render timechart
```

**Tile 3: Device Statistics (Table)**
```kql
Telemetry
| where DeviceId == "${DeviceSelector}"
| where Timestamp > ago(24h)
| summarize
    MinValue = min(Value),
    MaxValue = max(Value),
    AvgValue = round(avg(Value), 2),
    StdDev = round(stdev(Value), 2),
    Readings = count()
```

### 5.5 Configuration du Refresh

1. Dashboard Settings → Auto-refresh
2. Interval: 30 seconds
3. Scope: All tiles

## Phase 6: Data Activator Alerts (2h)

### 6.1 Créer un Reflex

1. Fabric Workspace → New → Reflex
2. Nom : "SmartFactory_Alerts"
3. Source : KQL Database

### 6.2 Définir les Objets

**Object: High Temperature Alert**
```
Property: DeviceId
Property: Temperature (Value where DeviceType == "temperature")
Property: Location
Property: Zone
```

### 6.3 Configurer les Triggers

**Trigger 1: Critical Temperature**
```
Condition: Temperature > 70
Duration: Any occurrence
Cooldown: 5 minutes
Action: Send Teams message
```

Message template:
```
🚨 CRITICAL TEMPERATURE ALERT

Device: {DeviceId}
Location: {Location}
Zone: {Zone}
Temperature: {Temperature}°C
Time: {Timestamp}

Immediate action required!
```

**Trigger 2: Device Offline**
```
Condition: No data for 10 minutes
Duration: 10 minutes
Action: Send email
```

**Trigger 3: Vibration Anomaly**
```
Condition: Vibration > 2.0 mm/s
Duration: 3 consecutive readings
Action: Power Automate flow
```

### 6.4 Power Automate Integration

```json
{
  "trigger": "When Reflex trigger fires",
  "actions": [
    {
      "type": "Create_Teams_Notification",
      "channel": "Operations_Alerts",
      "message": "Alert from SmartFactory"
    },
    {
      "type": "Create_ServiceNow_Incident",
      "priority": "High",
      "description": "Automated incident from IoT monitoring"
    },
    {
      "type": "Log_to_SharePoint",
      "list": "Alert_History"
    }
  ]
}
```

## Phase 7: Tests et Validation (1h)

### 7.1 Tests Fonctionnels

**Test 1: Ingestion Performance**
```kql
// Vérifier le débit d'ingestion
Telemetry
| where Timestamp > ago(1h)
| summarize EventsPerMinute = count() by bin(Timestamp, 1m)
| summarize
    AvgEventsPerMin = avg(EventsPerMinute),
    MaxEventsPerMin = max(EventsPerMinute),
    MinEventsPerMin = min(EventsPerMinute)
```

**Test 2: Latence End-to-End**
```kql
// Mesurer la latence
Telemetry
| where Timestamp > ago(10m)
| extend Latency = ingestion_time() - Timestamp
| summarize
    AvgLatencySeconds = avg(Latency) / 1s,
    P95LatencySeconds = percentile(Latency, 95) / 1s
```

**Test 3: Data Quality**
```kql
// Vérifier la qualité des données
Telemetry
| where Timestamp > ago(1h)
| summarize
    TotalRecords = count(),
    GoodQuality = countif(Quality == "good"),
    Warnings = countif(Quality == "warning"),
    NullValues = countif(isnull(Value))
| extend QualityRate = round(100.0 * GoodQuality / TotalRecords, 2)
```

### 7.2 Tests d'Alertes

1. Injecter une valeur anormale manuellement
2. Vérifier que l'alerte se déclenche en < 1 minute
3. Confirmer la réception de la notification
4. Vérifier le cooldown (pas de spam)

### 7.3 Tests de Performance

```kql
// Performance des requêtes
.show queries
| where StartedOn > ago(1h)
| summarize
    AvgDuration = avg(Duration),
    MaxDuration = max(Duration),
    QueryCount = count()
```

## Livrables

### Checklist Technique
- [ ] EventStream configuré et fonctionnel
- [ ] KQL Database créée avec tables et mappings
- [ ] 10+ requêtes KQL optimisées
- [ ] Dashboard temps réel avec 10+ tiles sur 3 pages
- [ ] 3+ alertes Data Activator configurées
- [ ] Tests de validation documentés
- [ ] Documentation architecture complète

### Documentation Requise
- [ ] Schéma d'architecture détaillé
- [ ] Dictionnaire des données (tous les champs)
- [ ] Catalogue des requêtes KQL avec explications
- [ ] Guide utilisateur du dashboard
- [ ] Procédure de gestion des alertes
- [ ] SLA et métriques de performance

### Métriques de Succès
```
Performance:
  ✓ Latence d'ingestion < 5 secondes
  ✓ Dashboard refresh < 30 secondes
  ✓ Queries KQL < 2 secondes
  ✓ Uptime EventStream > 99.5%

Fonctionnel:
  ✓ 100% des capteurs monitorés
  ✓ Alertes déclenchées en < 1 minute
  ✓ Taux de faux positifs < 5%
  ✓ Dashboard accessible 24/7
```

## Critères d'Évaluation

- Architecture et configuration EventStream (20%)
- Qualité et performance des requêtes KQL (25%)
- Complétude et UX du dashboard (25%)
- Configuration et fiabilité des alertes (15%)
- Documentation et tests (15%)

## Extensions Possibles

1. **Machine Learning** : Prédiction de pannes avec ML dans Fabric
2. **Historical Analysis** : Archivage long terme vers Lakehouse
3. **Multi-site** : Extension à plusieurs usines
4. **Mobile Dashboard** : Accès mobile pour équipes terrain
5. **Integration ERP** : Connexion avec SAP/Oracle pour contexte business

---

**Durée estimée: 8-10 heures**

**Note:** Ce projet utilise des données simulées. Pour une implémentation production, configurez Azure IoT Hub et des capteurs réels.

[⬅️ Retour aux projets](../README.md)
