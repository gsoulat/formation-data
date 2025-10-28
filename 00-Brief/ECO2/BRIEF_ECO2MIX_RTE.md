# Brief Projet : Analyse de la Production Energetique Francaise avec eCO2mix RTE

## Contexte du projet

### Presentation

Vous etes Data Engineer au sein de **RTE** (Reseau de Transport d'Electricite), l'entreprise responsable du reseau de transport d'electricite haute tension en France.

RTE met a disposition via son dispositif **eCO2mix** des donnees en temps reel sur la production et la consommation d'electricite en France. Ces donnees sont essentielles pour :

- Piloter l'equilibre production/consommation
- Optimiser le mix energetique
- Reduire les emissions de CO2
- Anticiper les pics de consommation
- Gerer les echanges avec les pays voisins

### Mission

Votre mission consiste a concevoir et implementer une **plateforme d'analyse complete** des donnees eCO2mix en utilisant **Azure Databricks** et les services Azure pour :

1. Ingerer et transformer les donnees energetiques temps reel
2. Analyser la production par source d'energie (nucleaire, renouvelables, fossiles)
3. Etudier la consommation et les previsions
4. Analyser les echanges energetiques avec l'Europe
5. Predire la consommation future avec du Machine Learning
6. Calculer l'empreinte carbone du mix energetique
7. Creer des visualisations et dashboards

---

## Dataset : eCO2mix RTE

### Description des donnees

Le fichier `eCO2mix_RTE_En-cours-TR.xls` contient des donnees toutes les 15 minutes sur :

#### Colonnes principales

**Informations temporelles** :
- `Perimetre` : Zone geographique (France)
- `Nature` : Type de donnees (Donnees temps reel)
- `Date` : Date de la mesure (format YYYY-MM-DD)
- `Heures` : Heure de la mesure (format HH:MM)

**Consommation** :
- `Consommation` : Consommation reelle en MW
- `Prevision J-1` : Prevision faite la veille
- `Prevision J` : Prevision du jour meme

**Production par source (en MW)** :
- `Nucleaire` : Production nucleaire
- `Eolien` : Production eolienne totale
- `Eolien terrestre` : Detail eolien terrestre
- `Eolien offshore` : Detail eolien offshore
- `Solaire` : Production photovoltaique
- `Hydraulique` : Production hydraulique totale
- `Hydraulique - Fil de l'eau + eclusee` : Hydraulique au fil de l'eau
- `Hydraulique - Lacs` : Barrages de retenue
- `Hydraulique - STEP turbinage` : Stations de transfert d'energie par pompage
- `Gaz` : Production au gaz naturel
- `Gaz - TAC`, `Gaz - Cogen.`, `Gaz - CCG`, `Gaz - Autres` : Details gaz
- `Fioul` : Production au fioul
- `Charbon` : Production au charbon
- `Bioenergies` : Production biomasse/biogaz/dechets
- `Pompage` : Consommation pour pompage (valeur negative)

**Stockage** :
- `Stockage batterie` : Energie stockee (negatif)
- `Destockage batterie` : Energie destockee (positif)

**Echanges internationaux (en MW)** :
- `Ech. physiques` : Total des echanges physiques
- `Ech. comm. Angleterre` : Echanges avec UK
- `Ech. comm. Espagne` : Echanges avec Espagne
- `Ech. comm. Italie` : Echanges avec Italie
- `Ech. comm. Suisse` : Echanges avec Suisse
- `Ech. comm. Allemagne-Belgique` : Echanges avec DE/BE

**Environnement** :
- `Taux de Co2` : Emissions de CO2 (g/kWh)

### Volumetrie

- **Frequence** : Donnees toutes les 15 minutes
- **Periode** : Janvier 2025 (donnees temps reel)
- **Volume** : ~2 900 lignes par mois (96 mesures/jour x 30 jours)
- **Colonnes** : 40 colonnes
- **Taille** : ~5-10 MB par mois

---

## Architecture technique

### Stack Azure

- **Azure Databricks** : Traitement et analyse des donnees
- **Azure Data Lake Storage Gen2** : Stockage des donnees brutes et transformees
- **Delta Lake** : Format de stockage optimise avec ACID
- **MLflow** : Suivi des experiences de Machine Learning
- **Power BI** (optionnel) : Visualisation et dashboards

### Architecture Medallion

```
┌─────────────────────────────────────────────────────┐
│                   BRONZE LAYER                      │
│              (Donnees brutes)                       │
│                                                     │
│  - Fichier Excel/CSV ingere tel quel               │
│  - Schema initial preserve                         │
│  - Historisation complete                          │
│  - Format : Delta Table                            │
└────────────────┬────────────────────────────────────┘
                 │
                 │ Nettoyage, validation, enrichissement
                 ▼
┌─────────────────────────────────────────────────────┐
│                   SILVER LAYER                      │
│            (Donnees nettoyees)                      │
│                                                     │
│  - Conversion des types de donnees                 │
│  - Gestion des valeurs manquantes                  │
│  - Timestamp unifie (Date + Heures)                │
│  - Calculs derives :                               │
│    * Total production renouvelable                 │
│    * Total production fossile                      │
│    * Part des renouvelables (%)                    │
│    * Ecart prevision/reel                          │
│    * Solde import/export                           │
│  - Format : Delta Table partitionnee par date      │
└────────────────┬────────────────────────────────────┘
                 │
                 │ Agregation et KPIs metier
                 ▼
┌─────────────────────────────────────────────────────┐
│                    GOLD LAYER                       │
│              (Donnees analytiques)                  │
│                                                     │
│  Tables specialisees :                             │
│                                                     │
│  1. production_par_source_horaire                  │
│     - Agregation par source et heure               │
│     - Moyenne, min, max par periode                │
│                                                     │
│  2. consommation_previsions                        │
│     - Analyse ecarts previsions                    │
│     - Precision des modeles de prevision           │
│                                                     │
│  3. mix_energetique_quotidien                      │
│     - Repartition quotidienne par source           │
│     - Evolution du mix energetique                 │
│                                                     │
│  4. echanges_internationaux                        │
│     - Flux par pays                                │
│     - Balance import/export                        │
│                                                     │
│  5. empreinte_carbone                              │
│     - Evolution du taux CO2                        │
│     - Impact par source d'energie                  │
│                                                     │
│  6. statistiques_hebdomadaires                     │
│     - KPIs agreges par semaine                     │
│                                                     │
│  Format : Delta Tables optimisees (Z-ORDER)        │
└─────────────────────────────────────────────────────┘
```

---

## Objectifs du projet

### Jour 1 : Ingestion et Architecture Bronze-Silver (6-8h)

#### Objectif 1.1 : Configuration de l'environnement (1h)

**Prerequis** :
- Workspace Azure Databricks actif
- Cluster configure
- Acces a Azure Data Lake Storage Gen2 (ou DBFS)

**Taches** :
- [ ] Creer un notebook `01_Setup_Environnement`
- [ ] Configurer les connexions Azure
- [ ] Creer la structure de dossiers (bronze/silver/gold)
- [ ] Importer le fichier `eCO2mix_RTE_En-cours-TR.xls`

#### Objectif 1.2 : Couche Bronze - Ingestion des donnees (1.5h)

**Taches** :
- [ ] Creer un notebook `02_Bronze_Ingestion`
- [ ] Lire le fichier Excel/CSV (attention a l'encodage ISO-8859)
- [ ] Analyser le schema et les types de donnees
- [ ] Gerer les caracteres speciaux dans les noms de colonnes
- [ ] Identifier les valeurs manquantes et aberrantes
- [ ] Sauvegarder en table Delta `eco2mix_bronze`
- [ ] Ajouter des metadonnees (date d'ingestion, fichier source)

**Criteres de validation** :
- Table `eco2mix_bronze` creee avec toutes les lignes
- Aucune perte de donnees
- Schema correct avec les bons types

#### Objectif 1.3 : Couche Silver - Nettoyage et enrichissement (2.5h)

**Taches** :
- [ ] Creer un notebook `03_Silver_Transformation`
- [ ] Nettoyer les noms de colonnes (supprimer accents, espaces)
- [ ] Convertir les types de donnees :
  - Date + Heures → Timestamp unique
  - Valeurs numeriques en Double
- [ ] Gerer les valeurs manquantes :
  - Remplacer les nulls par 0 pour les productions
  - Interpoler si necessaire
- [ ] Creer des colonnes derivees :
  ```python
  # Total renouvelables
  renouvelables_total = eolien + solaire + hydraulique + bioenergies

  # Total fossiles
  fossiles_total = gaz + fioul + charbon

  # Part renouvelables
  part_renouvelables = (renouvelables_total / production_totale) * 100

  # Ecart prevision
  ecart_prevision_j1 = consommation - prevision_j1
  ecart_prevision_j = consommation - prevision_j

  # Solde echanges
  solde_echanges = sum(tous_les_echanges)
  ```
- [ ] Partitionner la table par date
- [ ] Sauvegarder en table Delta `eco2mix_silver`

**Criteres de validation** :
- Toutes les transformations executees sans erreur
- Colonnes derivees calculees correctement
- Table partitionnee et optimisee

#### Objectif 1.4 : Analyse exploratoire des donnees (1h)

**Taches** :
- [ ] Creer un notebook `04_Analyse_Exploratoire`
- [ ] Calculer les statistiques descriptives par colonne
- [ ] Identifier les pics de consommation
- [ ] Analyser la distribution des sources de production
- [ ] Verifier la qualite des donnees (completude, coherence)
- [ ] Documenter les insights cles

**Livrables Jour 1** :
- 4 notebooks fonctionnels
- Table Bronze avec donnees brutes
- Table Silver nettoyee et enrichie
- Rapport d'analyse exploratoire

---

### Jour 2 : Couche Gold et Analyses Avancees (6-8h)

#### Objectif 2.1 : Tables Gold - Production par source (1.5h)

**Taches** :
- [ ] Creer un notebook `05_Gold_Production`
- [ ] Creer la table `production_par_source_horaire` :
  ```sql
  Colonnes :
  - date
  - heure (00-23)
  - source_energie (nucleaire, eolien, solaire, etc.)
  - production_moyenne_mw
  - production_min_mw
  - production_max_mw
  - ecart_type
  ```
- [ ] Creer la table `mix_energetique_quotidien` :
  ```sql
  Colonnes :
  - date
  - nucleaire_total_mwh
  - renouvelables_total_mwh
  - fossiles_total_mwh
  - part_nucleaire_pct
  - part_renouvelables_pct
  - part_fossiles_pct
  ```
- [ ] Optimiser avec Z-ORDER sur date

#### Objectif 2.2 : Tables Gold - Consommation et previsions (1.5h)

**Taches** :
- [ ] Creer la table `consommation_previsions` :
  ```sql
  Colonnes :
  - timestamp
  - consommation_reelle
  - prevision_j1
  - prevision_j
  - ecart_j1_mw
  - ecart_j_mw
  - erreur_j1_pct
  - erreur_j_pct
  ```
- [ ] Analyser la precision des previsions
- [ ] Identifier les heures avec plus d'erreurs
- [ ] Calculer le MAPE (Mean Absolute Percentage Error)

#### Objectif 2.3 : Tables Gold - Echanges internationaux (1h)

**Taches** :
- [ ] Creer la table `echanges_internationaux` :
  ```sql
  Colonnes :
  - date
  - pays (UK, Espagne, Italie, Suisse, DE-BE)
  - import_total_mwh (valeurs positives)
  - export_total_mwh (valeurs negatives)
  - solde_net_mwh
  ```
- [ ] Analyser les flux par pays
- [ ] Identifier les periodes d'import massif
- [ ] Identifier les periodes d'export

#### Objectif 2.4 : Analyses avancees avec Window Functions (1.5h)

**Taches** :
- [ ] Creer un notebook `06_Analyses_Avancees`
- [ ] Calculer les moyennes mobiles :
  - Consommation moyenne sur 24h glissantes
  - Production renouvelable moyenne sur 7 jours
- [ ] Identifier les tendances :
  - Evolution de la part des renouvelables
  - Croissance de l'eolien offshore
- [ ] Detecter les anomalies :
  - Pics de consommation inhabituels
  - Chutes de production
- [ ] Analyser la saisonnalite :
  - Profil de consommation par jour de la semaine
  - Impact du weekend

#### Objectif 2.5 : Analyse environnementale (1h)

**Taches** :
- [ ] Creer la table `empreinte_carbone` :
  ```sql
  Colonnes :
  - date
  - heure
  - taux_co2_gkwh
  - co2_total_tonnes
  - part_sources_bas_carbone_pct
  ```
- [ ] Calculer les emissions totales de CO2
- [ ] Analyser la correlation entre mix energetique et CO2
- [ ] Identifier les heures les plus propres/polluantes

**Livrables Jour 2** :
- 2 notebooks d'analyses
- 5 tables Gold optimisees
- Rapport d'analyse avec insights cles

---

### Jour 3 : Machine Learning et Visualisation (6-8h)

#### Objectif 3.1 : Preparation des donnees pour le ML (1h)

**Taches** :
- [ ] Creer un notebook `07_ML_Preparation`
- [ ] Extraire les features pour la prevision :
  - Timestamp features : heure, jour semaine, mois, jour ferie
  - Lag features : consommation N-1, N-24, N-168 (1 semaine)
  - Rolling features : moyenne mobile 24h, 7j
  - Meteo (si disponible) : temperature, etc.
  - Production renouvelable actuelle
- [ ] Creer le dataset d'entrainement
- [ ] Train/Test split (80/20)

#### Objectif 3.2 : Modele de prevision de consommation (2h)

**Taches** :
- [ ] Creer un notebook `08_ML_Prevision_Consommation`
- [ ] Entrainer plusieurs modeles avec MLflow :
  - Random Forest Regressor
  - Gradient Boosted Trees
  - Linear Regression (baseline)
- [ ] Comparer les performances (MAE, RMSE, MAPE)
- [ ] Selectionner le meilleur modele
- [ ] Enregistrer dans MLflow Model Registry
- [ ] Faire des predictions sur le test set
- [ ] Analyser les residus

**Metriques cibles** :
- MAPE < 5% (Mean Absolute Percentage Error)
- RMSE < 2000 MW

#### Objectif 3.3 : Modele de classification du mix energetique (1.5h)

**Taches** :
- [ ] Creer un notebook `09_ML_Classification_Mix`
- [ ] Definir des categories de mix energetique :
  - "Tres_Renouvelable" : >70% renouvelables
  - "Renouvelable" : 50-70% renouvelables
  - "Mixte" : 30-50% renouvelables
  - "Fossile_Nucleaire" : <30% renouvelables
- [ ] Entrainer un modele de classification
- [ ] Predire le type de mix pour les prochaines heures
- [ ] Analyser les features importantes

#### Objectif 3.4 : Dashboard et visualisations (2h)

**Taches** :
- [ ] Creer un notebook `10_Visualisations`
- [ ] Creer des visualisations avec matplotlib/plotly :

  **Vue d'ensemble** :
  - Evolution de la consommation sur le mois
  - Repartition du mix energetique (pie chart)
  - Production par source (stacked area chart)

  **Analyse temporelle** :
  - Profil journalier moyen (courbe de charge)
  - Heatmap consommation par jour x heure
  - Comparaison weekend vs semaine

  **Renouvelables** :
  - Evolution de la production eolienne
  - Production solaire vs heure du jour
  - Part des renouvelables dans le temps

  **Echanges** :
  - Balance import/export par pays (bar chart)
  - Flux energetiques (Sankey diagram)

  **Environnement** :
  - Evolution du taux de CO2
  - Correlation mix energetique vs CO2

  **Machine Learning** :
  - Predictions vs reel
  - Feature importance
  - Erreurs de prevision

#### Objectif 3.5 : Optimisation et deploiement (1.5h)

**Taches** :
- [ ] Optimiser toutes les tables Gold avec OPTIMIZE
- [ ] Appliquer Z-ORDER sur les colonnes de filtre
- [ ] Nettoyer avec VACUUM (retention 7 jours)
- [ ] Creer un notebook `11_Pipeline_Complete` qui :
  - Execute toute la pipeline Bronze → Silver → Gold
  - Entraine le modele ML
  - Genere les visualisations
  - Cree un rapport automatique
- [ ] Documenter le code
- [ ] Creer un README pour le projet

**Livrables Jour 3** :
- 5 notebooks ML et visualisation
- 2 modeles ML deployes dans MLflow
- Dashboard complet
- Pipeline automatisee
- Documentation complete

---

## Criteres d'evaluation

### Technique (60%)

#### Architecture et Code (20%)
- [ ] Architecture Medallion respectee (Bronze/Silver/Gold)
- [ ] Code propre, commente et structure
- [ ] Bonnes pratiques Spark (optimisations, partitionnement)
- [ ] Gestion des erreurs et logging

#### Qualite des donnees (15%)
- [ ] Nettoyage complet des donnees
- [ ] Gestion des valeurs manquantes
- [ ] Validation de la coherence des donnees
- [ ] Documentation du schema

#### Transformations (15%)
- [ ] Calculs derives corrects
- [ ] Agregations pertinentes
- [ ] Window functions utilisees a bon escient
- [ ] Performance optimisee (Z-ORDER, OPTIMIZE)

#### Machine Learning (10%)
- [ ] Features engineering pertinent
- [ ] Plusieurs modeles compares
- [ ] MLflow utilise correctement
- [ ] Metriques de performance acceptables

### Analyse et insights (30%)

#### Analyses (15%)
- [ ] Analyses exploratoires approfondies
- [ ] Insights pertinents sur la production energetique
- [ ] Analyse de la transition energetique
- [ ] Correlation entre variables identifiee

#### Visualisations (15%)
- [ ] Graphiques clairs et informatifs
- [ ] Choix de visualisations adaptes
- [ ] Dashboard coherent
- [ ] Interpretation des resultats

### Documentation (10%)

- [ ] README complet avec instructions
- [ ] Code commente
- [ ] Notebooks avec cellules markdown explicatives
- [ ] Rapport final avec conclusions

---

## Livrables attendus

### Notebooks Databricks (11 notebooks)

1. `01_Setup_Environnement.ipynb`
2. `02_Bronze_Ingestion.ipynb`
3. `03_Silver_Transformation.ipynb`
4. `04_Analyse_Exploratoire.ipynb`
5. `05_Gold_Production.ipynb`
6. `06_Analyses_Avancees.ipynb`
7. `07_ML_Preparation.ipynb`
8. `08_ML_Prevision_Consommation.ipynb`
9. `09_ML_Classification_Mix.ipynb`
10. `10_Visualisations.ipynb`
11. `11_Pipeline_Complete.ipynb`

### Tables Delta

**Bronze** :
- `eco2mix_bronze`

**Silver** :
- `eco2mix_silver` (partitionee par date)

**Gold** :
- `production_par_source_horaire`
- `consommation_previsions`
- `mix_energetique_quotidien`
- `echanges_internationaux`
- `empreinte_carbone`
- `statistiques_hebdomadaires`

### Machine Learning

- 2+ modeles entraines et enregistres dans MLflow
- Rapport de performances des modeles
- Predictions sur donnees de test

### Documentation

- `README.md` avec :
  - Presentation du projet
  - Instructions d'installation
  - Structure des donnees
  - Guide d'utilisation
- `RAPPORT_ANALYSE.md` avec :
  - Insights cles
  - Recommandations
  - Conclusions

---

## Extensions possibles (bonus)

### Extension 1 : Streaming en temps reel

- [ ] Simuler un flux de donnees temps reel
- [ ] Implementer Structured Streaming
- [ ] Creer des alertes sur anomalies
- [ ] Dashboard temps reel

### Extension 2 : Integration Power BI

- [ ] Connecter Power BI a Delta Lake
- [ ] Creer des dashboards interactifs
- [ ] Publier sur Power BI Service

### Extension 3 : Donnees meteo

- [ ] Integrer des donnees meteo (temperature, vent, ensoleillement)
- [ ] Analyser la correlation avec la production renouvelable
- [ ] Ameliorer le modele de prevision

### Extension 4 : Optimisation economique

- [ ] Integrer les prix de l'electricite
- [ ] Analyser la rentabilite par source
- [ ] Optimiser le mix energetique cout/CO2

### Extension 5 : Workflow automatise

- [ ] Creer un Databricks Job
- [ ] Planifier l'execution quotidienne
- [ ] Configurer des notifications

---

## Ressources et aide

### Documentation RTE

- [eCO2mix - RTE](https://www.rte-france.com/eco2mix)
- [Documentation des donnees](https://www.rte-france.com/eco2mix/les-donnees-de-consommation)
- [Glossaire energetique](https://www.rte-france.com/eco2mix/glossaire)

### Documentation technique

- [Azure Databricks](https://docs.microsoft.com/azure/databricks/)
- [Delta Lake](https://docs.delta.io/)
- [MLflow](https://mlflow.org/)
- [PySpark](https://spark.apache.org/docs/latest/api/python/)

### Tutoriels recommandes

- Architecture Medallion
- Structured Streaming
- Window Functions avancees
- MLflow pour le MLOps

---

## Conseils et bonnes pratiques

### Performance

- Utilisez le cache pour les DataFrames reutilises
- Partitionnez les tables par date
- Appliquez Z-ORDER sur les colonnes de filtre frequentes
- Optimisez regulierement avec OPTIMIZE

### Qualite du code

- Commentez votre code
- Utilisez des noms de variables explicites
- Structurez vos notebooks avec des sections claires
- Gerez les erreurs avec try/except

### Machine Learning

- Documentez vos choix de features
- Comparez plusieurs algorithmes
- Validez vos modeles avec cross-validation
- Interpretez les resultats (feature importance)

### Visualisations

- Choisissez le type de graphique adapte
- Ajoutez des titres et legendes clairs
- Utilisez des couleurs coherentes
- Interpretez chaque visualisation

---

## Planning suggere

### Jour 1 (6-8h)

| Temps | Tache |
|-------|-------|
| 9h00 - 10h00 | Setup environnement et comprehension du projet |
| 10h00 - 11h30 | Bronze : Ingestion des donnees |
| 11h30 - 14h00 | Silver : Nettoyage et enrichissement |
| 14h00 - 15h00 | Analyse exploratoire |
| 15h00 - 17h00 | Finalisation Jour 1 et documentation |

### Jour 2 (6-8h)

| Temps | Tache |
|-------|-------|
| 9h00 - 10h30 | Gold : Production par source |
| 10h30 - 12h00 | Gold : Consommation et echanges |
| 12h00 - 13h30 | Analyses avancees (Window Functions) |
| 13h30 - 15h00 | Analyse environnementale |
| 15h00 - 17h00 | Finalisation tables Gold et optimisations |

### Jour 3 (6-8h)

| Temps | Tache |
|-------|-------|
| 9h00 - 10h00 | Preparation donnees ML |
| 10h00 - 12h00 | Modele de prevision consommation |
| 12h00 - 13h30 | Modele classification mix energetique |
| 13h30 - 15h30 | Visualisations et dashboard |
| 15h30 - 17h00 | Pipeline complete et documentation |

---

## Checklist finale

### Avant la presentation

- [ ] Tous les notebooks executent sans erreur
- [ ] Toutes les tables sont creees et optimisees
- [ ] Les modeles ML sont enregistres dans MLflow
- [ ] Les visualisations sont generees
- [ ] La documentation est complete
- [ ] Le README est clair et complet
- [ ] Le code est commente
- [ ] La pipeline complete est testee

### Pendant la presentation

- [ ] Presenter l'architecture Medallion
- [ ] Montrer quelques insights cles
- [ ] Demontrer le modele ML
- [ ] Montrer les visualisations
- [ ] Expliquer les choix techniques
- [ ] Discuter des ameliorations possibles

---

## Conclusion

Ce projet vous permettra de maitriser :

- L'architecture Medallion avec Delta Lake
- Les transformations Spark avancees
- Les Window Functions
- Le Machine Learning avec MLflow
- Les analyses de series temporelles
- Les visualisations de donnees energetiques

**Objectif final** : Creer une plateforme d'analyse complete et operationnelle pour les donnees energetiques francaises, demontrant votre maitrise de Databricks et des bonnes pratiques Data Engineering.

Bon courage et bonne analyse ! ⚡🔋

---

**Duree totale estimee** : 18-24 heures (3 jours)
**Niveau** : Intermediaire/Avance
**Technologies** : Azure Databricks, Delta Lake, PySpark, MLflow, Python
**Dataset** : eCO2mix RTE (donnees reelles)
