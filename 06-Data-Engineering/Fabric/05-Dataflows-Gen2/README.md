# Module 05 - Dataflows Gen2

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Comprendre l'intégration de Power Query dans Fabric
- ✅ Créer et gérer des Dataflows Gen2
- ✅ Maîtriser les transformations avec le langage M
- ✅ Configurer les destinations multiples
- ✅ Comparer Dataflow vs Pipeline
- ✅ Implémenter le refresh incrémental

## Contenu du module

### [01 - Power Query Integration](./01-power-query-integration.md)
- Qu'est-ce que Power Query ?
- Dataflows Gen1 vs Gen2
- Avantages de Dataflows Gen2 dans Fabric
- Architecture et exécution
- Use cases typiques
- Limitations

### [02 - Création de Dataflow](./02-dataflow-creation.md)
- Interface Power Query Online
- Connexion aux sources de données
- Import vs DirectQuery
- Query settings et properties
- Query folding (délégation des opérations)
- Diagnostic et performance
- Paramètres de dataflow

### [03 - Transformations avec M](./03-transformations-m.md)
- Introduction au langage M
- Transformations courantes :
  - Filtrage et tri
  - Colonnes calculées
  - Groupe et agrégation
  - Pivot/Unpivot
  - Merge et append
  - Conditional columns
- Fonctions M avancées
- Custom functions
- Date/time manipulation
- Text operations

### [04 - Destinations](./04-destinations.md)
- Configuration des destinations :
  - Lakehouse
  - Data Warehouse
  - KQL Database
- Modes d'écriture (Replace, Append)
- Mapping de colonnes
- Partitionnement de sortie
- Multi-destinations depuis un dataflow

### [05 - Dataflow vs Pipeline](./05-dataflow-vs-pipeline.md)
- Comparaison détaillée
- Quand utiliser Dataflow ?
- Quand utiliser Pipeline ?
- Pattern hybride (dataflow dans pipeline)
- Performance comparison
- Cas d'usage recommandés

### [06 - Refresh Incrémental](./06-incremental-refresh.md)
- Configuration du refresh incrémental
- Paramètres RangeStart et RangeEnd
- Détection des changements
- Partitions et rétention
- Optimisation des performances
- Best practices

## Exercices pratiques

### Exercice 1 : Premier Dataflow
1. Créer un Dataflow Gen2
2. Se connecter à une source CSV
3. Appliquer des transformations basiques
4. Écrire vers un Lakehouse
5. Exécuter le refresh

### Exercice 2 : Transformations M
1. Importer des données sales (erreurs, duplicats)
2. Nettoyer les données (remove duplicates, handle nulls)
3. Créer des colonnes calculées
4. Agréger par catégorie
5. Pivoter les résultats

### Exercice 3 : Merge de données
1. Charger deux sources (Customers et Orders)
2. Effectuer un merge (left join)
3. Expand les colonnes
4. Calculer des métriques agrégées
5. Écrire le résultat

### Exercice 4 : Paramètres et fonctions
1. Créer des paramètres pour dates de début/fin
2. Créer une custom function pour nettoyage
3. Invoquer la fonction sur plusieurs queries
4. Utiliser les paramètres dans les filtres

### Exercice 5 : Multi-destinations
1. Créer un dataflow avec transformation complexe
2. Configurer sortie vers Lakehouse (Silver)
3. Configurer sortie vers Warehouse (Gold)
4. Vérifier les données dans les deux destinations

### Exercice 6 : Refresh incrémental
1. Configurer le refresh incrémental sur une grande table
2. Définir la politique de rétention
3. Tester le refresh avec nouvelles données
4. Analyser les partitions créées

## Quiz

1. Quelle est la différence entre Dataflow Gen1 et Gen2 ?
2. Qu'est-ce que le query folding ?
3. Comment créer une colonne calculée en M ?
4. Quand privilégier Dataflow plutôt que Pipeline ?
5. Comment fonctionne le refresh incrémental ?

## Exemples de code M

### Transformations basiques

```m
let
    // Charger la source
    Source = Csv.Document(File.Contents("sales.csv"), [Delimiter=",", Encoding=65001]),

    // Promouvoir les headers
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // Changer les types
    ChangedTypes = Table.TransformColumnTypes(PromotedHeaders, {
        {"OrderDate", type date},
        {"Amount", type number},
        {"Quantity", Int64.Type}
    }),

    // Filtrer
    Filtered = Table.SelectRows(ChangedTypes, each [Amount] > 0),

    // Colonne calculée
    AddedColumn = Table.AddColumn(Filtered, "TotalPrice", each [Amount] * [Quantity]),

    // Arrondir
    Rounded = Table.TransformColumns(AddedColumn, {{"TotalPrice", Number.Round, 2}})
in
    Rounded
```

### Merge de tables

```m
let
    Customers = Source1,
    Orders = Source2,

    // Left join
    Merged = Table.NestedJoin(
        Orders, {"CustomerID"},
        Customers, {"ID"},
        "CustomerInfo",
        JoinKind.LeftOuter
    ),

    // Expand columns
    Expanded = Table.ExpandTableColumn(
        Merged,
        "CustomerInfo",
        {"Name", "Email", "Country"},
        {"CustomerName", "CustomerEmail", "CustomerCountry"}
    )
in
    Expanded
```

### Custom function

```m
// Function pour nettoyer les noms
(inputText as text) as text =>
let
    Trimmed = Text.Trim(inputText),
    ProperCase = Text.Proper(Trimmed),
    Cleaned = Text.Clean(ProperCase)
in
    Cleaned
```

### Agrégation

```m
let
    Source = ...,

    // Group by avec agrégations
    Grouped = Table.Group(
        Source,
        {"Category", "Region"},
        {
            {"TotalSales", each List.Sum([Amount]), type number},
            {"OrderCount", each Table.RowCount(_), Int64.Type},
            {"AvgOrderValue", each List.Average([Amount]), type number}
        }
    )
in
    Grouped
```

### Refresh incrémental

```m
let
    // Paramètres automatiques pour refresh incrémental
    Source = Sql.Database("server", "database"),

    // Filtrer avec RangeStart et RangeEnd
    Filtered = Table.SelectRows(
        Source,
        each [ModifiedDate] >= RangeStart and [ModifiedDate] < RangeEnd
    )
in
    Filtered
```

## Patterns communs

### Pattern 1 : Bronze → Silver transformation
```
[Raw CSV] → [Clean] → [Type conversion] → [Remove duplicates] → [Add business logic] → [Write to Silver]
```

### Pattern 2 : Multiple sources consolidation
```
[Source A] ┐
[Source B] ├─→ [Append] → [Deduplicate] → [Transform] → [Output]
[Source C] ┘
```

### Pattern 3 : Dimension enrichment
```
[Fact Table] → [Merge with Dim1] → [Merge with Dim2] → [Calculations] → [Output]
```

## Ressources complémentaires

### Documentation officielle
- [Dataflows Gen2 overview](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-overview)
- [Power Query M reference](https://learn.microsoft.com/powerquery-m/power-query-m-reference)
- [Incremental refresh](https://learn.microsoft.com/fabric/data-factory/dataflows-gen2-incremental-refresh)

### Guides
- [Power Query best practices](https://learn.microsoft.com/power-query/best-practices)
- [M language specification](https://learn.microsoft.com/powerquery-m/power-query-m-language-specification)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 3-4 heures
- **Total** : 7-9 heures

## Prochaine étape

➡️ [Module 06 - Notebooks & Spark](../06-Notebooks-Spark/)

---

[⬅️ Module précédent](../04-Data-Pipelines/) | [⬅️ Retour au sommaire](../README.md)
