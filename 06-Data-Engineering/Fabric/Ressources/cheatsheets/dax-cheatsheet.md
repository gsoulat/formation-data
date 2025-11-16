# DAX Cheatsheet

## Fonctions de Base

### Agrégations

```dax
// Somme
Total Sales = SUM(Sales[Amount])

// Moyenne
Average Price = AVERAGE(Products[Price])

// Compte
Order Count = COUNT(Orders[OrderID])
Distinct Customers = DISTINCTCOUNT(Orders[CustomerID])

// Min/Max
Lowest Price = MIN(Products[Price])
Highest Price = MAX(Products[Price])

// Division sécurisée (évite division par zéro)
Profit Margin =
DIVIDE(
    [Total Profit],
    [Total Sales],
    0  // Valeur par défaut si division par 0
)
```

## CALCULATE - La Fonction Clé

```dax
// Syntaxe de base
Result = CALCULATE(
    <expression>,
    <filter1>,
    <filter2>,
    ...
)

// Exemple : Ventes pour une catégorie spécifique
Electronics Sales =
CALCULATE(
    [Total Sales],
    Products[Category] = "Electronics"
)

// Multiple filtres
High Value Sales France =
CALCULATE(
    [Total Sales],
    Sales[Amount] > 1000,
    Customers[Country] = "France"
)
```

## Modificateurs de Contexte

```dax
// ALL - Retire tous les filtres
Sales All Categories =
CALCULATE(
    [Total Sales],
    ALL(Products[Category])
)

// ALLEXCEPT - Retire tous sauf certains filtres
Sales All Except Country =
CALCULATE(
    [Total Sales],
    ALLEXCEPT(Customers, Customers[Country])
)

// ALLSELECTED - Respecte les filtres du rapport
Sales % of Selected =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALLSELECTED())
)

// REMOVEFILTERS (équivalent moderne de ALL)
Sales No Filters =
CALCULATE(
    [Total Sales],
    REMOVEFILTERS(Products[Category])
)
```

## Time Intelligence

```dax
// Year-to-Date
Sales YTD =
TOTALYTD(
    [Total Sales],
    'Date'[Date]
)

// Quarter-to-Date
Sales QTD =
TOTALQTD(
    [Total Sales],
    'Date'[Date]
)

// Month-to-Date
Sales MTD =
TOTALMTD(
    [Total Sales],
    'Date'[Date]
)

// Période précédente
Sales Last Year =
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR('Date'[Date])
)

// Year over Year
Sales YoY % =
DIVIDE(
    [Total Sales] - [Sales Last Year],
    [Sales Last Year]
)

// Période glissante
Sales Last 12 Months =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(
        'Date'[Date],
        LASTDATE('Date'[Date]),
        -12,
        MONTH
    )
)

// Mois précédent
Sales Previous Month =
CALCULATE(
    [Total Sales],
    PREVIOUSMONTH('Date'[Date])
)
```

## Fonctions de Table

```dax
// FILTER - Filtrer une table
High Value Customers =
FILTER(
    Customers,
    [Total Sales] > 10000
)

// VALUES - Valeurs distinctes d'une colonne
Distinct Categories = VALUES(Products[Category])

// DISTINCT - Alternative à VALUES
Unique Countries = DISTINCT(Customers[Country])

// SUMMARIZE - Créer une table résumée
Category Summary =
SUMMARIZE(
    Sales,
    Products[Category],
    "Total", [Total Sales],
    "Count", [Order Count]
)

// CALCULATETABLE - CALCULATE pour tables
Filtered Sales =
CALCULATETABLE(
    Sales,
    Sales[Amount] > 100
)
```

## Variables

```dax
// VAR pour éviter recalculs
Profit Margin Clean =
VAR TotalRevenue = [Total Sales]
VAR TotalCosts = [Total Costs]
VAR Profit = TotalRevenue - TotalCosts
RETURN
    DIVIDE(Profit, TotalRevenue, 0)

// Multiples variables
Sales Growth =
VAR CurrentSales = [Total Sales]
VAR PreviousSales = [Sales Last Year]
VAR Difference = CurrentSales - PreviousSales
VAR GrowthRate = DIVIDE(Difference, PreviousSales, 0)
RETURN
    GrowthRate
```

## Conditions

```dax
// IF simple
Status =
IF(
    [Total Sales] > 10000,
    "High",
    "Low"
)

// IF imbriqués
Customer Tier =
IF(
    [Total Sales] > 50000, "Platinum",
    IF(
        [Total Sales] > 10000, "Gold",
        IF(
            [Total Sales] > 1000, "Silver",
            "Bronze"
        )
    )
)

// SWITCH (préférable pour multiple conditions)
Customer Segment =
SWITCH(
    TRUE(),
    [Total Sales] > 50000, "Platinum",
    [Total Sales] > 10000, "Gold",
    [Total Sales] > 1000, "Silver",
    "Bronze"  // Default
)
```

## Ranking & Top N

```dax
// RANKX - Ranking
Product Rank =
RANKX(
    ALL(Products[Name]),
    [Total Sales],
    ,
    DESC,
    DENSE
)

// Top N avec TOPN
Top 10 Products =
TOPN(
    10,
    ALL(Products[Name]),
    [Total Sales],
    DESC
)

// Top N Sales
Top 10 Sales =
CALCULATE(
    [Total Sales],
    TOPN(
        10,
        ALL(Products[Name]),
        [Total Sales],
        DESC
    )
)
```

## Relationships

```dax
// RELATED - Accéder à table liée (Many-to-One)
Product Category = RELATED(Products[Category])

// RELATEDTABLE - Accéder à table liée (One-to-Many)
Customer Orders =
COUNTROWS(
    RELATEDTABLE(Orders)
)

// USERELATIONSHIP - Utiliser relation inactive
Sales by Ship Date =
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(Orders[ShipDate], 'Date'[Date])
)
```

## Itération

```dax
// SUMX - Somme avec itération
Total Revenue =
SUMX(
    Sales,
    Sales[Quantity] * Sales[UnitPrice]
)

// AVERAGEX - Moyenne avec itération
Avg Order Value =
AVERAGEX(
    Orders,
    [Total Sales]
)

// FILTER + itération
High Margin Products =
SUMX(
    FILTER(
        Products,
        Products[Margin] > 0.3
    ),
    [Total Sales]
)
```

## Texte & Formatage

```dax
// CONCATENATE
Full Name =
CONCATENATE(
    Customers[FirstName],
    CONCATENATE(" ", Customers[LastName])
)

// & operator (préféré)
Full Name = Customers[FirstName] & " " & Customers[LastName]

// FORMAT - Formatage nombre/date
Sales Formatted =
FORMAT([Total Sales], "#,##0.00 €")

Date Formatted =
FORMAT('Date'[Date], "DD/MM/YYYY")
```

## Gestion des Blanks

```dax
// ISBLANK - Tester si vide
Has Sales =
IF(
    ISBLANK([Total Sales]),
    "No Sales",
    "Has Sales"
)

// COALESCE - Première valeur non-blank
Result =
COALESCE(
    [Actual Sales],
    [Forecast Sales],
    0
)
```

## Patterns Avancés

### Période en cours vs précédente

```dax
Sales Comparison =
VAR CurrentPeriod = [Total Sales]
VAR PreviousPeriod = [Sales Last Year]
VAR Variance = CurrentPeriod - PreviousPeriod
VAR VariancePercent = DIVIDE(Variance, PreviousPeriod, 0)
RETURN
    "Current: " & FORMAT(CurrentPeriod, "$#,##0") &
    " | Previous: " & FORMAT(PreviousPeriod, "$#,##0") &
    " | Variance: " & FORMAT(VariancePercent, "0.0%")
```

### Dynamic Top N

```dax
// Avec paramètre TopN
Dynamic Top N Sales =
CALCULATE(
    [Total Sales],
    TOPN(
        [TopN Parameter],
        ALL(Products[Name]),
        [Total Sales],
        DESC
    )
)
```

### Cohort Analysis

```dax
// Clients de la première année encore actifs
Retained Customers =
CALCULATE(
    DISTINCTCOUNT(Sales[CustomerID]),
    FILTER(
        Customers,
        YEAR(Customers[FirstPurchaseDate]) = 2023
    ),
    Sales[OrderDate] >= DATE(2024,1,1)
)
```

## Best Practices

✅ **DO:**
- Utiliser des variables (VAR) pour clarté et performance
- Préférer DIVIDE vs `/` pour éviter erreurs
- Commenter les mesures complexes
- Nommer clairement les mesures
- Utiliser CALCULATE explicitement même si pas nécessaire (clarté)

❌ **DON'T:**
- Éviter les colonnes calculées si possible (utilisez mesures)
- Ne pas imbriquer trop de IF (utilisez SWITCH)
- Ne pas recalculer la même expression (utilisez VAR)
- Éviter ROW context dans mesures sans itération

---

## Ressources

- [DAX Guide](https://dax.guide/) - Référence complète
- [SQLBI](https://www.sqlbi.com/articles/) - Articles experts
- [DAX Formatter](https://www.daxformatter.com/) - Formatage code

[⬅️ Retour aux Ressources](../README.md)
