# KQL (Kusto Query Language) Cheatsheet

## Opérateurs de Base

### Filtrage

```kql
// where - Filtrer les lignes
Logs
| where TimeGenerated > ago(1h)
| where Level == "Error"

// Opérateurs de comparaison
| where Duration > 100
| where Status != "Success"
| where Name contains "error"
| where Email has "@gmail.com"

// Regex
| where Message matches regex "error.*timeout"

// IN operator
| where Country in ("France", "Germany", "Spain")

// between
| where Age between (18 .. 65)
```

### Projection

```kql
// project - Sélectionner colonnes
Logs
| project TimeGenerated, Level, Message

// project-away - Exclure colonnes
Logs
| project-away InternalId, Debug

// extend - Ajouter colonnes calculées
Logs
| extend DurationSeconds = Duration / 1000
| extend Hour = bin(TimeGenerated, 1h)
```

### Limitation

```kql
// take / limit - Limiter résultats
Logs
| take 10

// top - Top N
Logs
| top 100 by TimeGenerated desc
```

### Tri

```kql
// sort / order - Trier
Logs
| sort by TimeGenerated desc

// Multiple critères
Logs
| order by Level asc, TimeGenerated desc
```

## Agrégations

### summarize

```kql
// Count simple
Logs
| summarize count()

// Count par groupe
Logs
| summarize Count = count() by Level

// Multiples agrégations
Logs
| summarize
    Total = count(),
    AvgDuration = avg(Duration),
    MaxDuration = max(Duration),
    MinDuration = min(Duration)
  by Level

// Percentiles
Logs
| summarize
    p50 = percentile(Duration, 50),
    p95 = percentile(Duration, 95),
    p99 = percentile(Duration, 99)

// Distinct count
Logs
| summarize UniqueUsers = dcount(UserId)
```

### Time binning

```kql
// Grouper par fenêtre temporelle
Logs
| summarize count() by bin(TimeGenerated, 5m)

// Différentes granularités
| summarize count() by bin(TimeGenerated, 1h)  // Heure
| summarize count() by bin(TimeGenerated, 1d)  // Jour
```

## Time Series

### ago & now

```kql
// Données des dernières 24h
Logs
| where TimeGenerated > ago(24h)

// Entre deux dates
Logs
| where TimeGenerated between (ago(7d) .. ago(1d))

// Aujourd'hui
Logs
| where TimeGenerated > startofday(now())
```

### Fonctions temporelles

```kql
// startof / endof
| extend DayStart = startofday(TimeGenerated)
| extend MonthStart = startofmonth(TimeGenerated)

// datetime_part
| extend Hour = datetime_part("hour", TimeGenerated)
| extend DayOfWeek = dayofweek(TimeGenerated)

// datetime_diff
| extend ElapsedDays = datetime_diff("day", now(), CreatedDate)
```

### make-series

```kql
// Créer une série temporelle
Metrics
| make-series AvgValue = avg(Value) on TimeGenerated step 5m
| render timechart

// Détecter anomalies
Metrics
| make-series Value = avg(Value) on TimeGenerated step 5m
| extend anomalies = series_decompose_anomalies(Value, 1.5)
```

## Jointures

### join

```kql
// Inner join
Requests
| join kind=inner (
    Users
    | project UserId, UserName, Country
) on UserId

// Left outer join
Requests
| join kind=leftouter (
    Users
) on UserId

// Types de join
// inner, leftouter, rightouter, fullouter
// leftanti, rightanti, leftsemi, rightsemi
```

### union

```kql
// Union de tables
Logs_2024
| union Logs_2023
| where Level == "Error"

// Union avec wildcard
Logs_*
| where TimeGenerated > ago(7d)
```

## Fonctions Avancées

### String functions

```kql
// Manipulation de texte
| extend Upper = toupper(Name)
| extend Lower = tolower(Email)
| extend Length = strlen(Message)
| extend Trimmed = trim(" ", Text)

// Extraction
| extend Domain = extract(@"@(.+)", 1, Email)

// Split
| extend Parts = split(Path, "/")
| extend FirstPart = Parts[0]

// Replace
| extend Cleaned = replace_regex(Text, @"[0-9]", "X")
```

### Numerical functions

```kql
// Math
| extend Rounded = round(Value, 2)
| extend Absolute = abs(Delta)
| extend Power = pow(Value, 2)
| extend SquareRoot = sqrt(Value)

// Conversion
| extend IntValue = toint(StringValue)
| extend DoubleValue = todouble(StringValue)
```

### Array functions

```kql
// array_length
| extend TagCount = array_length(Tags)

// mv-expand - Expand array
Logs
| mv-expand Tags
| where Tags == "critical"

// set operations
| extend AllTags = set_union(Tags1, Tags2)
| extend CommonTags = set_intersect(Tags1, Tags2)
```

## Visualisations

```kql
// Line chart
Metrics
| summarize avg(Value) by bin(TimeGenerated, 1h)
| render timechart

// Bar chart
Logs
| summarize count() by Level
| render barchart

// Pie chart
Logs
| summarize count() by Country
| render piechart

// Scatter chart
Metrics
| render scatterchart with (xcolumn=Duration, ycolumn=ResponseSize)

// Table
Logs
| top 100 by TimeGenerated desc
| render table
```

## Patterns Courants

### Top N par groupe

```kql
// Top 3 products par catégorie
Products
| summarize TotalSales = sum(Sales) by Category, ProductName
| top-nested 10 of Category, top-nested 3 of ProductName by TotalSales desc
```

### Rate calculation

```kql
// Taux d'erreur
Logs
| summarize
    Total = count(),
    Errors = countif(Level == "Error")
  by bin(TimeGenerated, 5m)
| extend ErrorRate = 100.0 * Errors / Total
```

### Window functions

```kql
// Row number
Logs
| serialize
| extend RowNum = row_number()

// Prev / next
Logs
| sort by TimeGenerated asc
| serialize
| extend PreviousValue = prev(Value)
| extend NextValue = next(Value)
```

### Conditional aggregation

```kql
// Agrégation conditionnelle
Logs
| summarize
    TotalRequests = count(),
    SuccessCount = countif(Status == 200),
    ErrorCount = countif(Status >= 400),
    AvgSuccessDuration = avgif(Duration, Status == 200)
  by bin(TimeGenerated, 1h)
```

## Optimisations

```kql
// ✅ DO: Filtrer tôt
Logs
| where TimeGenerated > ago(1h)  // Filtre précoce
| where Level == "Error"
| summarize count() by Source

// ❌ DON'T: Filtrer tard
Logs
| summarize count() by Level, Source
| where Level == "Error"  // Trop tard!

// ✅ DO: Project tôt pour réduire data
Logs
| project TimeGenerated, Level, Message
| where Level == "Error"

// ✅ DO: Utiliser hint.strategy=shuffle pour gros volumes
Logs
| summarize hint.strategy=shuffle count() by UserId
```

## Cas d'Usage Typiques

### Monitoring application

```kql
// Taux d'erreur par endpoint
Requests
| where TimeGenerated > ago(1h)
| summarize
    Total = count(),
    Errors = countif(ResponseCode >= 400)
  by Endpoint, bin(TimeGenerated, 5m)
| extend ErrorRate = 100.0 * Errors / Total
| where ErrorRate > 5  // Alerte si > 5%
```

### Performance analysis

```kql
// P95 latency par région
Requests
| where TimeGenerated > ago(24h)
| summarize
    p50 = percentile(Duration, 50),
    p95 = percentile(Duration, 95),
    p99 = percentile(Duration, 99)
  by Region
| order by p95 desc
```

### User behavior

```kql
// Sessions utilisateurs
Events
| where EventType == "PageView"
| summarize
    SessionStart = min(TimeGenerated),
    SessionEnd = max(TimeGenerated),
    PageViews = count()
  by SessionId
| extend SessionDuration = datetime_diff("minute", SessionEnd, SessionStart)
| where SessionDuration > 0
```

### Anomaly detection

```kql
// Détection de pics anormaux
Metrics
| make-series Value = avg(CPUPercent) on TimeGenerated step 5m
| extend anomalies = series_decompose_anomalies(Value, 2.0)
| mv-expand TimeGenerated, Value, anomalies
| where anomalies > 0
| project TimeGenerated, Value, anomalies
```

## Best Practices

✅ **DO:**
- Filtrer (`where`) le plus tôt possible
- Utiliser `project` pour réduire les colonnes
- Binning temporel approprié (ne pas trop granulaire)
- Commenter les requêtes complexes

❌ **DON'T:**
- Ne pas scanner des grosses périodes sans besoin
- Éviter `SELECT *` équivalent (projeter colonnes nécessaires)
- Ne pas faire trop d'agrégations imbriquées

## Ressources

- [KQL Quick Reference](https://learn.microsoft.com/azure/data-explorer/kql-quick-reference)
- [KQL Tutorial](https://learn.microsoft.com/azure/data-explorer/kusto/query/tutorial)
- [Kusto Detective Agency](https://detective.kusto.io/) - Apprendre par le jeu

[⬅️ Retour aux Ressources](../README.md)
