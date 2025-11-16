# Projets Pratiques - Microsoft Fabric

## Vue d'ensemble

Les 6 projets pratiques de ce cours vous permettent de mettre en application l'ensemble des compétences acquises dans les modules. Chaque projet est conçu pour être **réaliste** et refléter des scénarios d'entreprise réels.

## Structure des Projets

Chaque projet contient :
- **README.md** : Description détaillée et objectifs
- **instructions.md** : Guide pas-à-pas
- **data/** : Jeux de données pour le projet
- **solution/** : Solution complète de référence

## Liste des Projets

### [Projet 1 : Lakehouse ETL Pipeline](./01-Lakehouse-ETL-Pipeline/)
**Niveau :** Intermédiaire
**Durée :** 8-10 heures
**Modules concernés :** 02, 04, 05, 06

Construire un pipeline ETL complet avec architecture Medallion (Bronze/Silver/Gold) pour traiter des données de ventes e-commerce.

**Compétences :**
- Création de Lakehouse
- Ingestion de données multi-sources
- Transformations Spark
- Architecture Medallion
- Optimisation (partitionnement, V-Order)

---

### [Projet 2 : Real-Time Dashboard](./02-Real-Time-Dashboard/)
**Niveau :** Intermédiaire
**Durée :** 6-8 heures
**Modules concernés :** 08, 07

Créer un dashboard temps réel pour monitorer des événements IoT avec EventStream et KQL Database.

**Compétences :**
- EventStream configuration
- KQL Database et queries
- Dashboards temps réel
- Data Activator (alertes)
- Visualisations KQL

---

### [Projet 3 : Data Warehouse Analytics](./03-Data-Warehouse-Analytics/)
**Niveau :** Intermédiaire
**Durée :** 8-10 heures
**Modules concernés :** 03, 07

Modéliser un Data Warehouse avec star schema et créer des rapports Power BI avec Direct Lake.

**Compétences :**
- Modélisation dimensionnelle (star schema)
- T-SQL avancé
- Semantic models
- DAX (mesures, CALCULATE)
- Power BI reports

---

### [Projet 4 : ML Pipeline End-to-End](./04-ML-Pipeline-End-to-End/)
**Niveau :** Avancé
**Durée :** 10-12 heures
**Modules concernés :** 10, 06, 04

Développer un pipeline ML complet de prédiction de churn client, du feature engineering au déploiement.

**Compétences :**
- Feature engineering avec Spark
- MLflow tracking
- Model training et tuning
- Model deployment
- Batch scoring pipeline

---

### [Projet 5 : Gouvernance & Sécurité](./05-Gouvernance-Securite/)
**Niveau :** Avancé
**Durée :** 6-8 heures
**Modules concernés :** 09, 12

Implémenter une stratégie complète de sécurité et gouvernance sur une architecture Fabric existante.

**Compétences :**
- Row-Level Security (RLS)
- Column-Level Security (CLS)
- Sensitivity labels
- Microsoft Purview integration
- Data lineage
- Audit et compliance

---

### [Projet 6 : Migration Synapse → Fabric](./06-Migration-Synapse-Fabric/)
**Niveau :** Expert
**Durée :** 12-15 heures
**Modules concernés :** 14, 13, 04, 03

Planifier et exécuter une migration d'une architecture Azure Synapse existante vers Microsoft Fabric.

**Compétences :**
- Assessment et planning
- Migration de données (ADLS → OneLake)
- Migration de pipelines (ADF → Fabric)
- Migration de SQL Pools vers Warehouse
- Validation et testing
- DevOps (CI/CD)

---

## Progression Recommandée

### Pour débutants
1. Projet 1 (Lakehouse ETL)
2. Projet 3 (Data Warehouse)
3. Projet 2 (Real-Time)

### Pour profils intermédiaires
1. Projet 1 (Lakehouse ETL)
2. Projet 4 (ML Pipeline)
3. Projet 5 (Gouvernance)

### Pour experts / préparation DP-700
Tous les projets dans l'ordre 1 → 6

## Critères d'Évaluation

Chaque projet sera évalué sur :

### Fonctionnel (40%)
- ✅ Tous les requis fonctionnels implémentés
- ✅ Solution fonctionnelle end-to-end
- ✅ Tests de validation passés

### Architecture (30%)
- ✅ Best practices respectées
- ✅ Patterns appropriés utilisés
- ✅ Scalabilité considérée

### Performance (15%)
- ✅ Optimisations appliquées
- ✅ Performance acceptable
- ✅ Ressources utilisées efficacement

### Documentation (15%)
- ✅ Code commenté
- ✅ README projet
- ✅ Décisions architecturales documentées

## Support et Aide

### Pendant les projets
- Référez-vous aux modules du cours
- Consultez la documentation Microsoft
- Utilisez le forum communautaire

### Bloqué ?
1. Relire le module correspondant
2. Consulter les hints dans instructions.md
3. Vérifier la solution de référence (en dernier recours)

## Jeux de Données

Tous les datasets sont fournis dans le dossier `data/` de chaque projet.

**Sources simulées :**
- E-commerce sales (CSV, JSON)
- IoT sensor data (streaming)
- Customer database (SQL)
- Web logs (JSON)
- Product catalog (CSV)

**Tailles :**
- Dev/Test : ~100 MB - 1 GB
- Production simulation : 10-50 GB (optionnel)

## Livrables Attendus

Pour chaque projet, vous devez produire :

1. **Code source**
   - Notebooks (.ipynb)
   - Scripts SQL (.sql)
   - Pipelines (JSON)

2. **Documentation**
   - README du projet
   - Schémas d'architecture
   - Décisions techniques

3. **Démo**
   - Dashboards fonctionnels
   - Screenshots
   - Vidéo demo (optionnel)

## Certification DP-700

Ces projets couvrent **tous les domaines** de l'examen DP-700 :
- ✅ Implement and manage (Projet 6, 5)
- ✅ Ingest and transform (Projet 1, 2)
- ✅ Monitor and optimize (tous projets)
- ✅ Security (Projet 5)

Compléter les 6 projets = préparation solide pour DP-700.

## Conseils

### Gestion du temps
- Ne pas se précipiter
- Faire les projets dans l'ordre
- Prendre le temps de comprendre vs copier-coller

### Apprentissage
- Essayer seul avant de consulter la solution
- Expérimenter au-delà des requis
- Documenter les problèmes rencontrés et solutions

### Pratique
- Reproduire dans votre environnement
- Adapter avec vos propres données
- Partager avec la communauté

---

## Prêt ? Commencez par le Projet 1 ! 🚀

[➡️ Projet 1 : Lakehouse ETL Pipeline](./01-Lakehouse-ETL-Pipeline/)

[⬅️ Retour au sommaire du cours](../README.md)
