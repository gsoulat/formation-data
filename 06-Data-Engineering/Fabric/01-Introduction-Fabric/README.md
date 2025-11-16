# Module 01 - Introduction à Microsoft Fabric

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre l'architecture et la vision de Microsoft Fabric
- ✅ Identifier les différents workloads et composants de la plateforme
- ✅ Naviguer dans l'interface Fabric et créer des workspaces
- ✅ Comprendre le modèle de capacités et les SKU disponibles
- ✅ Choisir la licence appropriée selon vos besoins

## Contenu du module

### [01 - Overview de Fabric](./01-overview-fabric.md)
- Qu'est-ce que Microsoft Fabric ?
- Évolution depuis Power BI / Synapse / Data Factory
- Vision "OneLake, One Platform"
- Les 7 workloads principaux
- Avantages et cas d'usage

### [02 - Architecture OneLake](./02-architecture-onelake.md)
- Concept de OneLake (Data Lake unifié)
- Architecture technique (Delta Lake, Parquet)
- Organisation des données
- Shortcuts et virtualisation
- Comparaison avec Azure Data Lake Storage Gen2

### [03 - Workloads et Composants](./03-workloads-composants.md)
- **Data Engineering** : Lakehouse, notebooks Spark, pipelines
- **Data Warehouse** : Synapse Data Warehouse
- **Data Science** : Notebooks ML, MLflow, AutoML
- **Real-Time Analytics** : EventStream, KQL Database
- **Power BI** : Semantic models, dashboards, reports
- **Data Factory** : Pipelines, Dataflows Gen2
- **Data Activator** : Alertes et automatisations

### [04 - Workspaces et Capacités](./04-workspaces-capacites.md)
- Création et gestion de workspaces
- Rôles et permissions (Admin, Member, Contributor, Viewer)
- Concept de capacité (Capacity)
- Différence workspace / capacity
- Partage et collaboration

### [05 - Licences, SKU et Pricing](./05-licences-sku-pricing.md)
- Modèle de licence Fabric
- Capacités F-SKU (F2, F4, F8, F16, F32, F64, F128, etc.)
- Trial gratuit (60 jours)
- Fabric vs Power BI Premium
- Capacity Units (CU) et consommation
- Estimation des coûts
- Best practices pour optimiser les coûts

## Exercices pratiques

### Exercice 1 : Découverte de l'interface
1. Se connecter à Fabric (https://app.fabric.microsoft.com)
2. Explorer les différents workloads via le switcher
3. Créer votre premier workspace

### Exercice 2 : Création d'environnement
1. Activer un trial Fabric (si nécessaire)
2. Créer un workspace dédié au cours
3. Inviter un collègue en tant que Member
4. Explorer les paramètres de capacité

### Exercice 3 : Navigation dans OneLake
1. Accéder au OneLake data hub
2. Explorer la structure de stockage
3. Comprendre l'organisation des dossiers

## Quiz

1. Qu'est-ce que OneLake dans Microsoft Fabric ?
2. Citez les 7 workloads principaux de Fabric
3. Quelle est la différence entre un workspace et une capacité ?
4. Quel SKU minimum est requis pour utiliser Fabric en production ?
5. Combien de jours dure le trial gratuit de Fabric ?

## Ressources complémentaires

### Documentation officielle
- [What is Microsoft Fabric?](https://learn.microsoft.com/fabric/get-started/microsoft-fabric-overview)
- [OneLake documentation](https://learn.microsoft.com/fabric/onelake/onelake-overview)
- [Fabric capacities](https://learn.microsoft.com/fabric/enterprise/licenses)

### Vidéos
- [Microsoft Fabric in a Day](https://www.youtube.com/watch?v=X_c7gLfJz_Q)
- [OneLake deep dive](https://www.youtube.com/watch?v=xHv-Aa65gSs)

### Articles
- [Fabric Blog - Announcements](https://blog.fabric.microsoft.com/)
- [Fabric Community](https://community.fabric.microsoft.com/)

## Durée estimée

- **Lecture** : 2-3 heures
- **Exercices** : 1-2 heures
- **Total** : 3-5 heures

## Prochaine étape

➡️ [Module 02 - Lakehouse](../02-Lakehouse/)

---

[⬅️ Retour au sommaire](../README.md)
