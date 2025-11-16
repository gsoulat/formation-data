# Module 07 - Semantic Models & Power BI

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre les modèles sémantiques dans Fabric
- ✅ Maîtriser le mode Direct Lake
- ✅ Comparer Import, DirectQuery et Direct Lake
- ✅ Modéliser un schéma en étoile (star schema)
- ✅ Écrire des mesures DAX efficaces
- ✅ Utiliser CALCULATE et FILTER
- ✅ Comprendre les contextes de calcul DAX
- ✅ Optimiser les modèles avec Performance Analyzer

## Contenu du module

### [01 - Semantic Models Overview](./01-semantic-models-overview.md)
- Qu'est-ce qu'un modèle sémantique ?
- Évolution : Datasets → Semantic Models
- Architecture des modèles dans Fabric
- Relation avec Power BI
- Composants (tables, relations, mesures, hiérarchies)
- Default semantic model vs custom

### [02 - Direct Lake Mode](./02-direct-lake-mode.md)
- Révolution Direct Lake dans Fabric
- Architecture technique
- Avantages vs Import et DirectQuery
- Lecture directe depuis OneLake
- Limitations et prérequis
- Fallback to DirectQuery
- Use cases optimaux

### [03 - Import vs DirectQuery vs Direct Lake](./03-import-vs-directquery.md)
- **Import** :
  - Données en mémoire
  - Performance maximale
  - Refresh scheduling
  - Limites de taille
- **DirectQuery** :
  - Requêtes temps réel
  - Pas de limite de taille
  - Performance dépendante de la source
- **Direct Lake** :
  - Meilleur des deux mondes
  - OneLake integration
  - Delta/Parquet optimisé
- Matrice de décision

### [04 - Modélisation Star Schema](./04-modelisation-star-schema.md)
- Principes du star schema
- Tables de dimension (dimension tables)
- Tables de fait (fact tables)
- Clés surrogate
- Slowly Changing Dimensions (SCD Type 1, 2, 3)
- Snowflake schema (quand l'utiliser)
- Role-playing dimensions
- Degenerate dimensions

### [05 - DAX Basics](./05-dax-basics.md)
- Introduction à DAX (Data Analysis Expressions)
- Syntaxe de base
- Colonnes calculées vs mesures
- Variables (VAR)
- Fonctions de base :
  - SUM, AVERAGE, COUNT, MIN, MAX
  - DIVIDE (gestion division par zéro)
  - IF, SWITCH
  - DATE functions (YEAR, MONTH, DATEDIFF)
- Formatting des mesures

### [06 - DAX CALCULATE & FILTER](./06-dax-calculate-filter.md)
- CALCULATE : la fonction la plus puissante
- Syntaxe et comportement
- Filter context modification
- FILTER function
- ALL, ALLEXCEPT, ALLSELECTED
- REMOVEFILTERS
- KEEPFILTERS
- Combinaisons avancées

### [07 - Measures & Calculated Columns](./07-measures-calculated-columns.md)
- Différences fondamentales
- Quand utiliser quoi ?
- Impact sur la performance
- Mesures simples et complexes
- Measure groups
- Format strings
- Description et documentation
- Best practices

### [08 - Relationships & Cardinality](./08-relationships-cardinality.md)
- Types de relations :
  - One-to-Many (1:*)
  - Many-to-One (*:1)
  - One-to-One (1:1)
  - Many-to-Many (*:*)
- Cross-filter direction (single, both)
- Active vs inactive relationships
- USERELATIONSHIP function
- Relation circulaires (comment les éviter)
- Bidirectional filtering (pros/cons)

### [09 - Performance Analyzer](./09-performance-analyzer.md)
- Lancement de Performance Analyzer
- Analyse des requêtes DAX
- DAX query plans
- VertiPaq engine
- Identification des bottlenecks
- Optimisation des mesures
- Optimisation des visuels
- Best practices

### [10 - Best Practices de Modélisation](./10-best-practices-modeling.md)
- Architecture optimale
- Normalisation vs dénormalisation
- Granularité des tables de fait
- Hiérarchies et drill-down
- Sécurité (RLS - Row Level Security)
- Documentation du modèle
- Naming conventions
- Testing et validation
- Maintenance

## Exercices pratiques

### Exercice 1 : Création modèle Direct Lake
1. Créer un Lakehouse avec tables de vente
2. Créer un semantic model Direct Lake
3. Vérifier le mode de connexion
4. Comparer performance avec Import

### Exercice 2 : Star Schema
1. Modéliser un schéma en étoile complet
2. Créer tables de dimension (Date, Customer, Product)
3. Créer table de fait (Sales)
4. Définir les relations
5. Valider les cardinalités

### Exercice 3 : Mesures DAX basics
1. Créer une mesure Total Sales
2. Créer Average Order Value
3. Créer un YoY (Year over Year) comparison
4. Formater les mesures
5. Organiser dans des dossiers

### Exercice 4 : CALCULATE avancé
1. Sales avec filtre sur catégorie
2. Sales Previous Year
3. Sales YTD (Year To Date)
4. Market share calculation
5. Top N products

### Exercice 5 : Relationships complexes
1. Implémenter une role-playing dimension (Date)
2. Créer relations inactive (Order Date, Ship Date, Due Date)
3. Utiliser USERELATIONSHIP
4. Gérer une relation Many-to-Many

### Exercice 6 : Optimisation
1. Analyser un rapport lent avec Performance Analyzer
2. Identifier les mesures coûteuses
3. Optimiser le modèle de données
4. Réduire la cardinalité
5. Mesurer les gains

## Quiz

1. Quelle est la différence entre Direct Lake et DirectQuery ?
2. Qu'est-ce qu'un star schema ?
3. Quand utiliser une colonne calculée vs une mesure ?
4. Expliquez CALCULATE et son impact sur le filter context
5. Qu'est-ce que RLS (Row Level Security) ?

## Exemples de code DAX

### Mesures basiques

```dax
Total Sales = SUM(Sales[Amount])

Average Order Value =
DIVIDE(
    SUM(Sales[Amount]),
    COUNTROWS(Sales),
    0
)

Total Customers = DISTINCTCOUNT(Sales[CustomerID])

Profit Margin =
DIVIDE(
    [Total Profit],
    [Total Sales],
    0
)
```

### CALCULATE avancé

```dax
Sales Last Year =
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR('Date'[Date])
)

Sales YoY Growth =
DIVIDE(
    [Total Sales] - [Sales Last Year],
    [Sales Last Year],
    0
)

Sales Premium Products =
CALCULATE(
    [Total Sales],
    Product[Category] = "Premium"
)

Sales ALL Regions =
CALCULATE(
    [Total Sales],
    ALL(Region)
)

Sales Current & Previous Quarter =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(
        'Date'[Date],
        MAX('Date'[Date]),
        -2,
        QUARTER
    )
)
```

### Time Intelligence

```dax
Sales YTD =
TOTALYTD(
    [Total Sales],
    'Date'[Date]
)

Sales MTD =
TOTALMTD(
    [Total Sales],
    'Date'[Date]
)

Sales Moving Annual Total =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(
        'Date'[Date],
        LASTDATE('Date'[Date]),
        -12,
        MONTH
    )
)
```

### Ranking

```dax
Sales Rank =
RANKX(
    ALL(Product[Name]),
    [Total Sales],
    ,
    DESC,
    DENSE
)

Top 10 Products Sales =
CALCULATE(
    [Total Sales],
    TOPN(
        10,
        ALL(Product[Name]),
        [Total Sales],
        DESC
    )
)
```

### FILTER & ALL

```dax
High Value Customers Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Customer),
        [Total Sales] > 10000
    )
)

Percentage of Total =
DIVIDE(
    [Total Sales],
    CALCULATE(
        [Total Sales],
        ALL(Product)
    )
)
```

## Ressources complémentaires

### Documentation officielle
- [Semantic models in Fabric](https://learn.microsoft.com/fabric/data-engineering/semantic-models)
- [Direct Lake overview](https://learn.microsoft.com/power-bi/enterprise/directlake-overview)
- [DAX reference](https://dax.guide/)

### Livres et guides
- [The Definitive Guide to DAX](https://www.sqlbi.com/books/the-definitive-guide-to-dax-2nd-edition/) - SQLBI
- [Star Schema: The Complete Reference](https://www.kimballgroup.com/)

### Outils
- [DAX Studio](https://daxstudio.org/) - Query and optimization tool
- [Tabular Editor](https://tabulareditor.com/) - Advanced model editing

## Durée estimée

- **Lecture** : 6-7 heures
- **Exercices** : 5-6 heures
- **Total** : 11-13 heures

## Prochaine étape

➡️ [Module 08 - Real-Time Analytics](../08-Real-Time-Analytics/)

---

[⬅️ Module précédent](../06-Notebooks-Spark/) | [⬅️ Retour au sommaire](../README.md)
