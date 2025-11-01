# Projets Pratiques Apache Spark

Ces projets vous permettent de mettre en pratique les connaissances acquises dans les modules 01 à 10.

## Vue d'ensemble

| Projet | Niveau | Durée | Concepts clés |
|--------|--------|-------|---------------|
| **01-Analyse-Logs** | Débutant | 2h | ETL, Regex, Agrégations |
| **02-ETL-E-commerce** | Intermédiaire | 4h | Joins, Window functions, KPIs |
| **03-Streaming-IoT** | Avancé | 4h | Structured Streaming, Kafka, Real-time |

---

## Projet 01 : Analyse de Logs Web

**Objectif** : Analyser des logs Apache/Nginx pour extraire des insights.

**Ce que vous allez apprendre** :
- Parser des logs avec regex
- Nettoyer et valider des données
- Créer des agrégations (top pages, hourly stats)
- Détecter des anomalies (scans, bots)

**Livrables** :
- Pipeline ETL complet
- Logs nettoyés (Parquet partitionné)
- Rapport d'analyse
- Détection d'anomalies

**Prérequis** :
- Modules 03-04 (RDDs, DataFrames)
- Module 05 (Spark SQL)
- Module 06 (ETL Pipelines)

**Durée estimée** : 2 heures

➡️ [Voir le projet](./01-Analyse-Logs/README.md)

---

## Projet 02 : ETL E-commerce

**Objectif** : Pipeline ETL pour plateforme e-commerce (orders, customers, products).

**Ce que vous allez apprendre** :
- Joindre multiples sources de données
- Calculer des KPIs business (CLV, RFM)
- Créer un Data Warehouse
- Segmentation clients
- Window functions avancées

**Livrables** :
- Pipeline ETL multi-sources
- Data Lake (Bronze/Silver/Gold)
- Data Warehouse (Fact/Dim tables)
- Dashboard KPIs

**Prérequis** :
- Modules 04-05 (DataFrames, SQL)
- Module 06 (ETL)
- Module 07 (Performance)

**Durée estimée** : 4 heures

➡️ [Voir le projet](./02-ETL-E-commerce/README.md)

---

## Projet 03 : Streaming IoT en Temps Réel

**Objectif** : Traiter des données de capteurs IoT en temps réel avec alertes.

**Ce que vous allez apprendre** :
- Structured Streaming
- Window operations (tumbling, sliding)
- Watermarking
- Détection d'anomalies en temps réel
- Multiple sinks (Kafka, Parquet, Console)

**Livrables** :
- Pipeline streaming fonctionnel
- Système d'alertes temps réel
- Agrégations windowed
- Dashboard temps réel (optionnel)

**Prérequis** :
- Tous les modules 01-07
- Module 08 (Spark Streaming)

**Durée estimée** : 4 heures

➡️ [Voir le projet](./03-Streaming-IoT/README.md)

---

## Parcours recommandé

### Parcours Débutant (1 semaine)

1. **Modules** : 01, 02, 04, 05, 06
2. **Projet** : 01-Analyse-Logs
3. **Objectif** : Maîtriser les bases de Spark (DataFrames, SQL, ETL)

### Parcours Intermédiaire (2 semaines)

1. **Modules** : Tous jusqu'au 07
2. **Projets** : 01 + 02
3. **Objectif** : ETL production-ready avec optimisations

### Parcours Avancé (3 semaines)

1. **Modules** : Tous (01-10)
2. **Projets** : Les 3 projets
3. **Objectif** : Maîtriser Spark de bout en bout (batch + streaming + production)

---

## Critères d'évaluation

### Technique (60%)

- ✅ Code fonctionnel et testé
- ✅ Architecture appropriée
- ✅ Optimisations (partitioning, caching, broadcast)
- ✅ Gestion des erreurs robuste
- ✅ Code lisible et commenté

### Business (25%)

- ✅ Résultats pertinents
- ✅ KPIs business corrects
- ✅ Insights actionnables
- ✅ Visualisations claires

### Production-ready (15%)

- ✅ Logging configuré
- ✅ Configuration externalisée
- ✅ Data quality checks
- ✅ Documentation complète
- ✅ Tests unitaires (bonus)

---

## Extensions possibles

### Pour tous les projets

1. **CI/CD** :
   - Pipeline GitLab/GitHub Actions
   - Tests automatisés
   - Déploiement automatique

2. **Monitoring** :
   - Métriques Prometheus
   - Dashboard Grafana
   - Alertes

3. **Machine Learning** :
   - Prédictions avec MLlib
   - Détection d'anomalies ML
   - Recommandations

4. **Cloud** :
   - Déployer sur AWS EMR / GCP Dataproc / Azure Synapse
   - Utiliser S3/GCS/Blob Storage
   - Databricks

---

## Ressources

### Datasets publics

- **Logs** : [Common Crawl](https://commoncrawl.org/)
- **E-commerce** : [Kaggle E-commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **IoT** : [UCI IoT Dataset](https://archive.ics.uci.edu/ml/datasets/Air+Quality)

### Outils utiles

- **Databricks Community Edition** : Gratuit pour tester
- **Docker Compose** : Kafka + Spark local
- **Jupyter** : Notebooks interactifs

### Communauté

- [Spark Users Mailing List](https://spark.apache.org/community.html)
- [Stack Overflow - apache-spark](https://stackoverflow.com/questions/tagged/apache-spark)
- [Reddit - r/apachespark](https://reddit.com/r/apachespark)

---

## Support

Pour des questions sur les projets :

1. Consultez d'abord les README de chaque projet
2. Relisez les modules correspondants
3. Utilisez la documentation Spark officielle
4. Demandez de l'aide sur les forums

---

**Bon courage pour vos projets ! 🚀**

N'oubliez pas : l'apprentissage se fait par la pratique. N'hésitez pas à expérimenter, à casser des choses, et à apprendre de vos erreurs !
