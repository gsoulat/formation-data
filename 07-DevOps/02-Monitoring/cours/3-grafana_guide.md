# Guide 3 : Visualisation Avancée avec Grafana sur GCP

## Introduction

Ce guide vous explique comment déployer Grafana sur une machine virtuelle Google Cloud Platform dédiée, le connecter à votre instance Prometheus existante, et créer des tableaux de bord dynamiques pour visualiser vos métriques.

## Prérequis

- Une VM Prometheus fonctionnelle sur GCP (voir Guide 1).
- Une VM `vm-webserver` avec Node Exporter qui envoie des métriques à Prometheus (voir Guide 1).
- Un fichier `docker-compose.yml` pour Grafana disponible sur votre machine locale.

---

## 1. Préparation et Déploiement de Grafana

### Étape 1.1 : Création du bucket pour la configuration Grafana

Nous allons créer un bucket Cloud Storage pour stocker le fichier de configuration de Grafana.

1.  Dans la console GCP, allez à **Cloud Storage > Buckets**.
2.  Cliquez sur **CRÉER UN BUCKET**.
3.  Configurez le bucket :
    *   **Nom :** `grafana-config-[VOTRE-PROJECT-ID]`
    *   **Emplacement :** `europe-west9` (Paris), la même que votre VM Prometheus.
4.  Cliquez sur **CRÉER**.


### Étape 1.2 : Upload du dossier `grafana`

1.  Ouvrez votre nouveau bucket.
2.  Cliquez sur **IMPORTER UN DOSSIER** et sélectionnez votre dossier `grafana` local. Il doit contenir le `docker-compose.yml`, le dashboard JSON et le dossier `provisioning`.

### Étape 1.3 : Création de la VM Grafana

1.  Allez à **Compute Engine > Instances de VM** et cliquez sur **CRÉER UNE INSTANCE**.
2.  Configurez l'instance :
    *   **Nom :** `vm-grafana`
    *   **Région :** `europe-west9`
    *   **Configuration de la machine :** `e2-medium` (ou similaire).
    *   **Disque de démarrage :** `Ubuntu 25.04 LTS`.
    *   **Pare-feu :** Cochez `Autoriser le trafic HTTP` et `Autoriser le trafic HTTPS`.
    *   **Tags réseau :** Ajoutez `grafana-server`.

3.  Dans la section **Gestion, sécurité, disques, réseau, location unique**, collez le script de démarrage suivant :

```bash
#!/bin/bash

# Configuration
PROJECT_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")

# Installation de Docker et Docker Compose
apt-get update
apt-get install -y docker.io docker-compose
systemctl start docker
systemctl enable docker

# Installation de l'outil gcloud
apt-get install -y google-cloud-sdk

# Récupération du dossier de configuration Grafana
cd /home
gsutil -m cp -r gs://grafana-config-${PROJECT_ID}/grafana .

# Démarrage de Grafana
cd /home/grafana
docker-compose up -d
```

4.  Cliquez sur **CRÉER**.

### Étape 1.4 : Configuration de la règle de pare-feu

1.  Allez à **VPC Network > Pare-feu** et cliquez sur **CRÉER UNE RÈGLE DE PARE-FEU**.
2.  Configurez la règle :
    *   **Nom :** `allow-grafana`
    *   **Direction :** `Entrée`
    *   **Cibles :** `Tags cibles spécifiés`
    *   **Tags cibles :** `grafana-server`
    *   **Filtre source :** `Plages d'adresses IP` : `0.0.0.0/0`
    *   **Protocoles et ports :** `TCP`, port `3000`.
3.  Cliquez sur **CRÉER**.

---

## 2. Connexion de Grafana à Prometheus

### Étape 2.1 : Premier accès à Grafana

1.  Récupérez l'**IP externe** de votre `vm-grafana` depuis la console Compute Engine.
2.  Ouvrez votre navigateur et allez à `http://[IP_EXTERNE_GRAFANA]:3000`.
3.  Connectez-vous avec les identifiants par défaut (`admin`/`admin`) ou ceux que vous avez configurés. (attention, au mdp, votre docker compose)


### Étape 2.2 : Ajout de la source de données Prometheus

1.  Dans le menu de gauche, cliquez sur **Connections**.
2.  Dans le sous-menu qui apparaît, cliquez sur **Data Sources**.
3.  Cliquez sur le bouton bleu **Add new data source**.
4.  Sélectionnez **Prometheus** dans la liste.
5.  Dans les réglages, configurez l'URL du serveur Prometheus :
    *   **URL :** `http://[IP_INTERNE_PROMETHEUS]:9090`
    *   Pour trouver l'IP interne, allez sur la page des instances de VM et regardez la colonne "IP interne" de votre `vm-prometheus`.

6.  Cliquez sur **Save & test**. Un message "Data source is working" doit apparaître.

---

## 3. Création d'un Dashboard de A à Z avec 10 Métriques

Nous allons maintenant créer un tableau de bord complet pour superviser notre application FastAPI avec 10 métriques essentielles et différents types de graphiques.

### Étape 3.1 : Créer un nouveau Dashboard

1.  Dans le menu de gauche, allez à **Dashboards**.
2.  Cliquez sur le bouton **New** en haut à droite, puis sélectionnez **New Dashboard**.
3.  Cliquez sur **Add visualization** pour créer votre premier panel.

### Étape 3.2 : Panel 1 - Statut de l'application (Up/Down)

Ce panel affichera si l'application est en ligne ou non.

1.  **Source de données :** Assurez-vous que `Prometheus` est sélectionné.
2.  **Requête :** Dans l'onglet "Query", entrez la métrique `up{job="fastapi"}`.
3.  **Visualisation :** Sur la droite, choisissez la visualisation **Stat**.
4.  **Personnalisation :**
    *   **Title :** `Statut Application FastAPI`
    *   Dans la section **Value mappings**, cliquez sur **Add value mappings** :
        *   Ajoutez une condition : `Value: 1`, `Display text: UP`, `Color: green`.
        *   Ajoutez une autre condition : `Value: 0`, `Display text: DOWN`, `Color: red`.
5.  Cliquez sur **Save dashboard** en haut à droite.

### Étape 3.3 : Panel 2 - Requêtes HTTP par seconde (Time Series)

Ce panel montrera le trafic reçu par l'application.

1.  Cliquez sur l'icône **Add panel** en haut à droite, puis **Add visualization**.
2.  **Requête :** Entrez la requête PromQL `rate(fastapi_http_requests_total[5m])`.
3.  **Visualisation :** Gardez la visualisation par défaut, **Time series**.
4.  **Personnalisation :**
    *   **Title :** `Requêtes HTTP (par seconde)`
    *   En dessous de la métrique, dans option, dans la section **Legend**, personnalisez avec `{{handler}} - {{method}}`.
    *   **Couleurs :** Allez dans **Field > Standard options > Color scheme** et choisissez "Green-Yellow-Red".
5.  Cliquez sur **Save dashboard**.

### Étape 3.4 : Panel 3 - Utilisation CPU (Gauge)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`.
3.  **Visualisation :** Choisissez la visualisation **Gauge**.
4.  **Personnalisation :**
    *   **Title :** `Utilisation CPU (%)`
    *   Dans **Field > Thresholds**, ajustez les seuils :
        *   Seuil 1 : 0 (vert)
        *   Seuil 2 : 70 (orange)
        *   Seuil 3 : 85 (rouge)
    *   **Unit :** Dans **Field > Standard options > Unit > Misc**, choisissez "Percent (0-100)".
5.  Cliquez sur **Save dashboard**.

### Étape 3.5 : Panel 4 - Utilisation Mémoire (Bar Gauge)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`.
3.  **Visualisation :** Choisissez **Bar gauge**.
4.  **Personnalisation :**
    *   **Title :** `Utilisation Mémoire (%)`
    *   **Orientation :** Dans **Display > Orientation**, choisissez "Horizontal".
    *   **Unit :** "Percent (0-100)".
    *   **Thresholds :** 0 (vert), 75 (orange), 90 (rouge).
5.  Cliquez sur **Save dashboard**.

### Étape 3.6 : Panel 5 - Temps de Réponse Moyen (Single Stat)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `avg(fastapi_http_request_duration_seconds)`.
3.  **Visualisation :** Choisissez **Stat**.
4.  **Personnalisation :**
    *   **Title :** `Temps de Réponse Moyen`
    *   **Unit :** "Time > seconds (s)".
    *   **Decimals :** 3.
    *   **Thresholds :** 0 (vert), 0.5 (orange), 1 (rouge).
5.  Cliquez sur **Save dashboard**.

### Étape 3.7 : Panel 6 - Codes de Statut HTTP (Pie Chart)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `sum by (status_code) (rate(fastapi_http_requests_total[5m]))`.
3.  **Visualisation :** Choisissez **Pie chart**.
4.  **Personnalisation :**
    *   **Title :** `Répartition des Codes de Statut HTTP`
    *   **Legend :** Dans **Legend > Options**, activez "Show legend".
    *   **Display :** Dans **Display > Values**, choisissez "Percent".
5.  Cliquez sur **Save dashboard**.

### Étape 3.8 : Panel 7 - Espace Disque Libre (Table)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100`.
3.  **Visualisation :** Choisissez **Table**.
4.  **Personnalisation :**
    *   **Title :** `Espace Disque Libre par Partition`
    *   **Transformations :** Ajoutez une transformation "Organize fields" pour réorganiser les colonnes.
    *   **Unit :** "Percent (0-100)".
    *   **Thresholds :** 0 (rouge), 10 (orange), 20 (vert).
5.  Cliquez sur **Save dashboard**.

### Étape 3.9 : Panel 8 - Charge Système (Heatmap)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `node_load1`.
3.  **Visualisation :** Choisissez **Heatmap**.
4.  **Personnalisation :**
    *   **Title :** `Charge Système (Load Average 1m)`
    *   **Buckets :** Définissez les buckets dans **Heatmap > Buckets**.
    *   **Color scheme :** Choisissez "Spectral".
5.  Cliquez sur **Save dashboard**.

### Étape 3.10 : Panel 9 - Nombre de Connexions Actives (Graph)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `fastapi_http_requests_currently_active`.
3.  **Visualisation :** Choisissez **Time series**.
4.  **Personnalisation :**
    *   **Title :** `Connexions HTTP Actives`
    *   **Draw style :** Dans **Graph styles > Draw style**, choisissez "Bars".
    *   **Fill opacity :** 0.7.
    *   **Stack series :** Activez "Stack series".
5.  Cliquez sur **Save dashboard**.

### Étape 3.11 : Panel 10 - Erreurs par Minute (Alert Graph)

1.  Ajoutez un nouveau panel.
2.  **Requête :** `sum(rate(fastapi_http_requests_total{status_code=~"5.."}[1m])) * 60`.
3.  **Visualisation :** Choisissez **Time series**.
4.  **Personnalisation :**
    *   **Title :** `Erreurs 5xx par Minute`
    *   **Color :** Rouge.
    *   **Thresholds :** Dans **Field > Thresholds**, ajoutez un seuil à 5 erreurs/min.
    *   **Alert :** Configurez une alerte si > 10 erreurs/min.
5.  Cliquez sur **Save dashboard**.

### Étape 3.12 : Panel 11 - Métriques Système Combinées (Mixed Graph) - Guide Détaillé

1.  Ajoutez un nouveau panel.

2.  **Configuration des requêtes multiples :**

    **Query A - CPU System :**
    *   Expression : `rate(node_cpu_seconds_total{mode="system"}[5m]) * 100`
    *   Legend : `CPU System - {{instance}}`
    *   Refid : `A`

    **Query B - CPU User :**
    *   Expression : `rate(node_cpu_seconds_total{mode="user"}[5m]) * 100`
    *   Legend : `CPU User - {{instance}}`
    *   Refid : `B`

    **Query C - Network In :**
    *   Expression : `rate(node_network_receive_bytes_total[5m]) * 8`
    *   Legend : `Network In - {{device}}`
    *   Refid : `C`

3.  **Visualisation :** Time series.

4.  **Configuration du Dual Y-axis (méthode détaillée) :**

    a) Allez dans l'onglet "Field" (panneau de droite)
    b) Cliquez sur "Overrides"
    
    **Configuration pour Network (Query C) :**
    *   Cliquez sur "Add field override"
    *   Matcher : Sélectionnez "Fields with name"
    *   Field name : Tapez ou sélectionnez `Network In - eth0` (ou le nom exact de votre série)
    *   Cliquez sur "Add override property"
    *   Sélectionnez "Axis" → "Placement"
    *   Choisissez "Right"
    *   Ajoutez une autre propriété : "Standard options" → "Unit"
    *   Sélectionnez "Data rate" → "bits/second"
    *   Ajoutez une couleur : "Standard options" → "Color" → "Fixed color" → Bleu

    **Configuration pour CPU System (Query A) :**
    *   Add field override
    *   Matcher : "Fields with name"
    *   Field name : `CPU System`
    *   Add override property :
        *   Axis → Placement → Left
        *   Unit → Percent (0-100)
        *   Color → Fixed color → Rouge

    **Configuration pour CPU User (Query B) :**
    *   Add field override
    *   Matcher : "Fields with name"
    *   Field name : `CPU User`
    *   Add override property :
        *   Axis → Placement → Left
        *   Unit → Percent (0-100)
        *   Color → Fixed color → Orange


5.  **Personnalisation avancée :**
    *   **Title :** `Métriques Système Combinées`
    *   Dans l'onglet "Panel options" :
        *   Description : `Affichage combiné des métriques CPU (%) et réseau (bps) avec double axe Y`
    *   Dans "Legend" :
        *   Mode : List
        *   Placement : Bottom
        *   Values : Cochez "Last" pour afficher la dernière valeur
    *   Dans "Tooltip" :
        *   Mode : Multi
        *   Sort : None

6.  **Vérification du résultat :**
    *   Axe Y gauche : Valeurs en pourcentage (0-100) pour CPU System et User
    *   Axe Y droit : Valeurs en bits/sec pour Network In
    *   Couleurs distinctes : Rouge (CPU System), Orange (CPU User), Bleu (Network)
    *   Légendes claires avec les unités

7.  Cliquez sur **Apply** puis **Save dashboard**.

### Étape 3.13 : Organiser et Personnaliser le Dashboard

1.  **Redimensionnement :** Faites glisser les coins des panels pour les redimensionner.
2.  **Réorganisation :** Glissez-déposez les panels pour les réorganiser.
3.  **Disposition suggérée :**
    *   Ligne 1 : Statut (large), CPU (moyen), Mémoire (moyen)
    *   Ligne 2 : Requêtes HTTP (large), Temps de réponse (moyen)
    *   Ligne 3 : Pie Chart (moyen), Table (large)
    *   Ligne 4 : Heatmap (full width)
    *   Ligne 5 : Connexions actives (moyen), Erreurs (moyen)
    *   Ligne 6 : Métriques combinées (full width)

### Étape 3.14 : Configuration Avancée du Dashboard

#### 3.14  Variables de Dashboard

**Accès aux variables :**
1.  Cliquez sur settings en haut à droite
2.  Dans le menu de gauche, cliquez sur "Variables"
3.  Cliquez sur "New variable" (bouton bleu)

**Configuration de la variable $instance :**

**Onglet "General" :**
*   Name : `instance`
*   Label : `Instance`
*   Description : `Sélectionnez une ou plusieurs instances à surveiller`
*   Type : `Query`
*   Hide : `Nothing` (pour afficher la variable)

**Onglet "Query options" :**
*   Data source : Sélectionnez votre source Prometheus
*   Query type : `Label values`
*   Label : `instance`
*   Metric : `up`
*   Regex : (laissez vide)
*   Sort : `Alphabetical (asc)`

**Onglet "Selection options" :**
*   Multi-value : Coché (permet de sélectionner plusieurs instances)
*   Include All option : Coché (ajoute une option "All")
*   All value : `.*` (regex pour toutes les instances)

**Onglet "Preview of values" :**
*   Vous devriez voir vos instances listées : localhost:9090, 10.132.0.3:9100, etc.

4.  Cliquez sur "Update" pour sauvegarder la variable.

**Variable $job (optionnelle mais recommandée) :**
1.  Créez une nouvelle variable
2.  Configuration :
    *   Name : `job`
    *   Type : `Query`
    *   Query : `label_values(up, job)`
    *   Multi-value : Coché
    *   Include All : Coché

**Variable $interval (pour optimiser les performances) :**
1.  Créez une nouvelle variable
2.  Configuration :
    *   Name : `interval`
    *   Type : `Interval`
    *   Values : `1m,5m,10m,30m,1h`
    *   Auto : Coché (s'adapte automatiquement à la période)

#### 3.14.2 Utilisation des Variables dans les Panels

**Modifier vos queries pour utiliser les variables :**
1.  Retournez à vos panels et modifiez les queries
2.  Exemples de queries avec variables :
    *   `up{job="$job", instance=~"$instance"}`
    *   `rate(fastapi_http_requests_total{instance=~"$instance"}[$interval])`
    *   `node_cpu_seconds_total{instance=~"$instance", mode="idle"}`

#### 3.14.3 Configuration du Rafraîchissement

**Rafraîchissement automatique :**
1.  En haut à droite du dashboard, cliquez sur l'icône de rafraîchissement
2.  Sélectionnez une fréquence : `30s`, `1m`, `5m`, `15m`
3.  Pour un environnement de production, recommandé : `30s` ou `1m`

**Période par défaut :**
1.  En haut à droite, cliquez sur l'icône d'horloge
2.  Configurez la période : `Last 1 hour`, `Last 6 hours`, `Last 24 hours`
3.  Pour le monitoring en temps réel : `Last 1 hour`

### Étape 3.15 : Configuration des Alertes - Guide Complet

Les alertes dans Grafana permettent de surveiller automatiquement vos métriques et de vous notifier en cas de problème. Voici comment configurer un système d'alertes complet.

#### 3.15.1 Concepts Fondamentaux des Alertes

**Architecture des alertes Grafana :**
*   **Alert Rules** : Définissent les conditions de déclenchement
*   **Contact Points** : Définissent où envoyer les notifications
*   **Notification Policies** : Définissent comment router les alertes
*   **Silences** : Permettent de désactiver temporairement les alertes

#### 3.15.2 Configuration des Contact Points

**Étape 1 : Accéder aux Contact Points**
1.  Dans le menu de gauche, allez à **Alerting** > **Contact points**
2.  Cliquez sur **New contact point**

**Étape 2 : Configuration Email**
*   **Name :** `email-ops-team`
*   **Contact point type :** `Email`
*   **Addresses :** `ops@monentreprise.com, admin@monentreprise.com`
*   **Subject :** `[ALERT] {{.CommonLabels.alertname}} - {{.CommonLabels.severity}}`
*   **Message :** 
```
ALERTE GRAFANA

Nom de l'alerte : {{.CommonLabels.alertname}}
Sévérité : {{.CommonLabels.severity}}
Instance : {{.CommonLabels.instance}}
Valeur actuelle : {{.CommonAnnotations.current_value}}

Détails :
{{range .Alerts}}
- {{.Annotations.summary}}
- {{.Annotations.description}}
{{end}}

Dashboard : {{.CommonAnnotations.dashboard_url}}
Heure : {{.CommonLabels.timestamp}}
```

**Étape 3 : Configuration Slack (optionnel)**
*   **Name :** `slack-monitoring`
*   **Contact point type :** `Slack`
*   **Webhook URL :** `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK`
*   **Channel :** `#monitoring`
*   **Username :** `Grafana Alerts`
*   **Title :** `ALERTE {{.CommonLabels.alertname}}`
*   **Text :** 
```
*Alerte :* {{.CommonLabels.alertname}}
*Sévérité :* {{.CommonLabels.severity}}
*Instance :* {{.CommonLabels.instance}}
*Valeur :* {{.CommonAnnotations.current_value}}
```

**Étape 4 : Configuration Webhook (avancé)**
*   **Name :** `webhook-custom`
*   **Contact point type :** `Webhook`
*   **URL :** `https://mon-api.com/alerts`
*   **HTTP Method :** `POST`
*   **Headers :** `Content-Type: application/json`

#### 3.15.3 Création de Règles d'Alerte

**Alerte 1 : CPU élevé**

1.  Allez dans **Alerting** > **Alert rules**
2.  Cliquez sur **New rule**

**Configuration de base :**
*   **Rule name :** `CPU Utilization High`
*   **Type :** `Grafana managed alert`

**Définition de la query :**
*   **A - Query :** `100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
*   **B - Reduce :** `last()` de A
*   **C - Threshold :** `IS ABOVE 85`

**Conditions d'évaluation :**
*   **Condition :** C
*   **Evaluate every :** `1m`
*   **Evaluate for :** `5m`
*   **No data state :** `No Data`
*   **Execution error state :** `Alerting`

**Labels et annotations :**
*   **Labels :**
    *   `severity: warning`
    *   `team: ops`
    *   `service: infrastructure`
*   **Annotations :**
    *   **Summary :** `CPU utilization is high on {{$labels.instance}}`
    *   **Description :** `CPU usage is {{$value}}% on instance {{$labels.instance}}, which is above the 85% threshold`
    *   **Current Value :** `{{$value}}%`
    *   **Dashboard URL :** `http://your-grafana.com/d/dashboard-uid`

**Alerte 2 : Application FastAPI Down**

**Configuration de base :**
*   **Rule name :** `FastAPI Application Down`
*   **Type :** `Grafana managed alert`

**Définition de la query :**
*   **A - Query :** `up{job="fastapi"}`
*   **B - Reduce :** `last()` de A
*   **C - Threshold :** `IS BELOW 1`

**Conditions d'évaluation :**
*   **Evaluate every :** `30s`
*   **Evaluate for :** `1m`

**Labels et annotations :**
*   **Labels :**
    *   `severity: critical`
    *   `team: dev`
    *   `service: fastapi`
*   **Annotations :**
    *   **Summary :** `FastAPI application is down`
    *   **Description :** `The FastAPI application on {{$labels.instance}} is not responding`

**Alerte 3 : Erreurs HTTP élevées**

**Configuration de base :**
*   **Rule name :** `High HTTP Error Rate`

**Définition de la query :**
*   **A - Query :** `sum(rate(fastapi_http_requests_total{status_code=~"5.."}[5m]))`
*   **B - Reduce :** `last()` de A
*   **C - Threshold :** `IS ABOVE 10`

**Conditions d'évaluation :**
*   **Evaluate every :** `1m`
*   **Evaluate for :** `3m`

**Labels et annotations :**
*   **Labels :**
    *   `severity: warning`
    *   `team: dev`
    *   `service: fastapi`

**Alerte 4 : Mémoire critique**

**Configuration de base :**
*   **Rule name :** `Memory Usage Critical`

**Définition de la query :**
*   **A - Query :** `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
*   **B - Reduce :** `last()` de A
*   **C - Threshold :** `IS ABOVE 90`

**Conditions d'évaluation :**
*   **Evaluate every :** `1m`
*   **Evaluate for :** `5m`

**Alerte 5 : Disque presque plein**

**Configuration de base :**
*   **Rule name :** `Disk Space Low`

**Définition de la query :**
*   **A - Query :** `(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100`
*   **B - Reduce :** `min()` de A
*   **C - Threshold :** `IS BELOW 10`

#### 3.15.4 Configuration des Notification Policies

**Accès aux Notification Policies :**
1.  Allez à **Alerting** > **Notification policies**
2.  Cliquez sur **Edit** sur la politique par défaut

**Configuration hiérarchique :**

**Politique par défaut :**
*   **Contact point :** `email-ops-team`
*   **Group by :** `alertname, instance`
*   **Group wait :** `10s`
*   **Group interval :** `5m`
*   **Repeat interval :** `12h`

**Sous-politique pour alertes critiques :**
*   **Matcher :** `severity = critical`
*   **Contact point :** `email-ops-team + slack-monitoring`
*   **Group wait :** `0s`
*   **Repeat interval :** `30m`
*   **Continue matching :** `false`

**Sous-politique pour équipe dev :**
*   **Matcher :** `team = dev`
*   **Contact point :** `slack-monitoring`
*   **Group interval :** `2m`

#### 3.15.5 Test et Validation des Alertes

**Test des Contact Points :**
1.  Dans **Contact points**, cliquez sur **Test** à côté de votre contact point
2.  Vérifiez que vous recevez bien la notification test

**Test des Règles d'Alerte :**
1.  Simulez une condition d'alerte (ex: arrêtez votre application FastAPI)
2.  Vérifiez dans **Alerting** > **Alert rules** que l'alerte se déclenche
3.  Confirmez que vous recevez la notification

**Simulation de charge pour tester CPU :**
```bash
# Sur votre serveur, créez une charge CPU temporaire
stress --cpu 8 --timeout 300s
```

#### 3.15.6 Gestion des Silences

**Créer un silence :**
1.  Allez à **Alerting** > **Silences**
2.  Cliquez sur **New silence**
3.  Configuration :
    *   **Matcher :** `alertname = "CPU Utilization High"`
    *   **Start time :** Maintenant
    *   **End time :** Dans 2 heures
    *   **Comment :** `Maintenance planifiée du serveur`

#### 3.15.7 Dashboard des Alertes

**Créer un dashboard dédié aux alertes :**
1.  Créez un nouveau dashboard : `Alertes - Vue d'ensemble`
2.  Ajoutez ces panels :

**Panel 1 - État des alertes :**
*   Query : `ALERTS{alertstate="firing"}`
*   Visualisation : **Stat**
*   Titre : `Alertes Actives`

**Panel 2 - Historique des alertes :**
*   Query : `increase(prometheus_notifications_total[1h])`
*   Visualisation : **Time series**
*   Titre : `Notifications Envoyées (dernière heure)`

**Panel 3 - Top des alertes :**
*   Query : `topk(5, count by (alertname) (ALERTS))`
*   Visualisation : **Bar chart**
*   Titre : `Top 5 des Alertes`

#### 3.15.8 Bonnes Pratiques pour les Alertes

**Seuils appropriés :**
*   **CPU :** 85% (warning), 95% (critical)
*   **Mémoire :** 85% (warning), 95% (critical)
*   **Disque :** 20% libre (warning), 10% libre (critical)
*   **Erreurs HTTP :** 1% (warning), 5% (critical)

**Nommage des alertes :**
*   Utilisez des noms explicites : `CPU_High_Instance_Web01`
*   Incluez la sévérité dans les labels
*   Groupez par service/équipe

**Éviter l'alert fatigue :**
*   Ne pas alerter sur des fluctuations normales
*   Utiliser des périodes d'évaluation appropriées
*   Regrouper les alertes similaires
*   Définir des heures de silence pour la maintenance

**Documentation des alertes :**
*   Inclure des liens vers les runbooks
*   Expliquer les actions à prendre
*   Fournir le contexte métier

### Étape 3.16 : Sauvegarder le Dashboard

1.  Cliquez sur l'icône de disquette **Save dashboard** en haut à droite.
2.  Donnez un nom à votre dashboard : `Monitoring FastAPI - Complet`.
3.  Ajoutez des tags : `fastapi`, `monitoring`, `production`.
4.  Cliquez sur **Save**.

### Étape 3.17 : Exporter le Dashboard

1.  Allez dans **Dashboard settings** > **JSON Model**.
2.  Copiez le JSON complet.
3.  Sauvegardez-le dans un fichier `fastapi-dashboard-complet.json`.

### Types de Graphiques Utilisés et Leurs Cas d'Usage

| Type | Cas d'Usage | Exemple |
|------|-------------|---------|
| **Stat** | Valeurs instantanées, statuts | Statut UP/DOWN, compteurs |
| **Time series** | Évolution temporelle | Requêtes/sec, CPU dans le temps |
| **Gauge** | Valeurs avec seuils | Utilisation CPU, mémoire |
| **Bar gauge** | Comparaison de valeurs | Utilisation par partition |
| **Pie chart** | Répartition proportionnelle | Codes de statut HTTP |
| **Table** | Données tabulaires | Détails par instance |
| **Heatmap** | Densité de données | Charge système |
| **Graph (bars)** | Données discrètes | Connexions actives |

### Conseils pour un Dashboard Efficace

1.  **Hiérarchie visuelle :** Placez les métriques les plus importantes en haut.
2.  **Cohérence des couleurs :** Utilisez le même schéma de couleurs pour des métriques similaires.
3.  **Seuils appropriés :** Définissez des seuils basés sur votre infrastructure.
4.  **Performance :** Évitez trop de panels complexes sur un même dashboard.
5.  **Documentation :** Ajoutez des descriptions aux panels complexes.

---


