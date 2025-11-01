# Projet 01 : Analyse de Logs Web

## Objectif

Analyser des logs d'un serveur web Apache/Nginx pour extraire des insights business et détecter des anomalies.

## Dataset

Logs web au format Apache Common Log Format :
```
127.0.0.1 - - [10/Jan/2024:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
192.168.1.1 - - [10/Jan/2024:13:55:37 +0000] "POST /api/login HTTP/1.1" 200 532
10.0.0.1 - - [10/Jan/2024:13:55:38 +0000] "GET /images/logo.png HTTP/1.1" 404 278
```

Format : `IP - - [timestamp] "method path protocol" status size`

## Tâches

### Phase 1 : Extract (30 min)

1. Générer des logs de test (ou utiliser vrais logs)
2. Lire les logs avec Spark
3. Parser avec regex pour extraire les champs

### Phase 2 : Transform (1h)

1. **Nettoyer** :
   - Supprimer lignes malformées
   - Valider les IPs
   - Parser les timestamps

2. **Enrichir** :
   - Extraire heure, jour, mois
   - Catégoriser les codes HTTP (2xx, 3xx, 4xx, 5xx)
   - Identifier le type de ressource (HTML, CSS, JS, images, API)

3. **Analyser** :
   - Compter requêtes par heure
   - Top 10 pages les plus visitées
   - Distribution des codes HTTP
   - Top 10 IPs (utilisateurs les plus actifs)
   - Pages 404 (erreurs)
   - Taille moyenne des réponses

### Phase 3 : Load (30 min)

1. Sauvegarder les résultats :
   - Logs nettoyés en Parquet (partitionné par date)
   - Agrégations en Parquet
   - Exports CSV pour BI

2. Créer un dashboard simple (optionnel)

## Livrables

```
01-Analyse-Logs/
├── README.md
├── generate_logs.py          # Générer des logs de test
├── analyze_logs.py            # Pipeline d'analyse
├── data/
│   └── access.log             # Logs bruts
├── output/
│   ├── logs_cleaned/          # Logs nettoyés
│   ├── hourly_stats/          # Stats par heure
│   ├── top_pages/             # Top pages
│   └── errors/                # Erreurs 4xx/5xx
└── results/
    └── analysis_report.txt    # Rapport d'analyse
```

## Solution

Voir `analyze_logs.py` pour la solution complète.

## Extensions possibles

1. **Détection d'anomalies** :
   - Pics de trafic inhabituels
   - Tentatives de scan (requêtes 404 multiples)
   - Bots/crawlers

2. **Géolocalisation** :
   - Enrichir avec GeoIP
   - Analyser par pays/région

3. **Real-time** :
   - Utiliser Structured Streaming
   - Alertes en temps réel

4. **ML** :
   - Prédire le trafic futur
   - Classifier les types d'utilisateurs

## Critères d'évaluation

- ✅ Parsing correct des logs (regex)
- ✅ Nettoyage et validation
- ✅ Agrégations pertinentes
- ✅ Partitionnement approprié
- ✅ Code lisible et commenté
- ✅ Gestion des erreurs
- ✅ Performance (utilisation cache, broadcast)
