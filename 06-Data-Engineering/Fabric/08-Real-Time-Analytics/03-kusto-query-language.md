# Kusto Query Language (KQL)

## Introduction

**KQL (Kusto Query Language)** est le langage de requête optimisé pour l'exploration et l'analyse de données temps réel, logs, et time series.

```
KQL Query Structure:
  TableName
  | operator1
  | operator2
  | operator3
  | ...

Pipe-based: Each step transforms the result
Read left-to-right, top-to-bottom
```

## Syntaxe de Base

### Structure Fondamentale

```kql
// Basic query structure
Logs
| where Timestamp > ago(1h)
| where Level == "Error"
| project Timestamp, Message, Service
| order by Timestamp desc
| take 100

// Flow:
// 1. Start with table (Logs)
// 2. Filter by time (where)
// 3. Filter by level (where)
// 4. Select columns (project)
// 5. Sort (order by)
// 6. Limit results (take)
```

### Comments

```kql
// Single line comment
Logs
| where Level == "Error"  // Filter errors only

/* Multi-line comment
   Use for longer explanations
*/
```

## Opérateurs Fondamentaux

### where (Filtrage)

```kql
// Simple comparison
Logs
| where Level == "Error"

// Multiple conditions (AND)
Logs
| where Level == "Error" and Service == "auth"

// OR condition
Logs
| where Level == "Error" or Level == "Warning"

// Time-based filtering
Logs
| where Timestamp > ago(1h)
| where Timestamp between (datetime(2024-01-15) .. datetime(2024-01-16))

// String operations
Logs
| where Message contains "timeout"
| where Message startswith "Database"
| where Message has "connection"  // Word boundary search (faster)

// Numeric comparisons
Metrics
| where Value > 100
| where Value between (10 .. 50)

// In operator
Logs
| where Service in ("auth", "api", "web")
```

### project (Sélection Colonnes)

```kql
// Select specific columns
Logs
| project Timestamp, Message, Level

// Rename columns
Logs
| project Time = Timestamp, Msg = Message, Severity = Level

// Calculate new columns
Logs
| project Timestamp, Message, Year = datetime_part("Year", Timestamp)

// Remove columns (project-away)
Logs
| project-away TraceId, SpanId, InternalId

// Reorder columns
Logs
| project Timestamp, Level, Service, Message
```

### extend (Colonnes Calculées)

```kql
// Add calculated column
Logs
| extend DurationSeconds = Duration / 1s

// Multiple extensions
Logs
| extend
    Year = datetime_part("Year", Timestamp),
    Month = datetime_part("Month", Timestamp),
    DayOfWeek = dayofweek(Timestamp)

// String manipulation
Logs
| extend
    ServiceLower = tolower(Service),
    MessageLength = strlen(Message)

// Conditional column
Logs
| extend
    Severity = case(
        Level == "Error", "High",
        Level == "Warning", "Medium",
        "Low"
    )
```

### summarize (Agrégation)

```kql
// Count
Logs
| summarize Count = count()

// Count by group
Logs
| summarize Count = count() by Level

// Multiple aggregations
Logs
| summarize
    TotalEvents = count(),
    UniqueUsers = dcount(UserId),
    ErrorCount = countif(Level == "Error")

// Time-based aggregation (bin)
Logs
| summarize Count = count() by bin(Timestamp, 1h)

// Multiple grouping columns
Logs
| summarize Count = count() by Level, Service

// Common aggregation functions
Metrics
| summarize
    Average = avg(Value),
    Minimum = min(Value),
    Maximum = max(Value),
    Sum = sum(Value),
    Percentile95 = percentile(Value, 95),
    StandardDev = stdev(Value)
```

### join (Jointures)

```kql
// Inner join (default)
Logs
| join (Users | project UserId, UserName) on UserId

// Left outer join
Logs
| join kind=leftouter (Users) on UserId

// Join types:
// inner: Only matching rows
// leftouter: All left + matching right
// rightouter: All right + matching left
// fullouter: All rows from both
// anti: Left rows NOT in right
// semi: Left rows that ARE in right

// Example: Find errors without user info
Logs
| where Level == "Error"
| join kind=anti (Users) on UserId
// Returns errors with missing user data
```

### union (Union de Tables)

```kql
// Combine multiple tables
union Logs_January, Logs_February, Logs_March

// Union with different schemas
union withsource=SourceTable
    (Logs | project Timestamp, Message, Source="Logs"),
    (Errors | project Timestamp, Message, Source="Errors")

// Use case: Query across time periods
union Logs_*  // Wildcard: all tables starting with Logs_
| where Timestamp > ago(7d)
```

## Time Series Functions

### ago()

```kql
// Relative time
Logs
| where Timestamp > ago(1h)   // Last hour
| where Timestamp > ago(24h)  // Last 24 hours
| where Timestamp > ago(7d)   // Last 7 days
| where Timestamp > ago(30d)  // Last 30 days
```

### bin() - Time Bucketing

```kql
// Group by time intervals
Logs
| summarize Count = count() by bin(Timestamp, 1h)
| order by Timestamp asc

// Common bin sizes
bin(Timestamp, 1m)   // 1 minute
bin(Timestamp, 5m)   // 5 minutes
bin(Timestamp, 1h)   // 1 hour
bin(Timestamp, 1d)   // 1 day
```

### make-series (Time Series)

```kql
// Create time series for analysis
Metrics
| make-series AvgValue = avg(Value) on Timestamp step 1h
| project Timestamp, AvgValue

// Returns array of timestamps and values
// Useful for anomaly detection, trends

// Fill gaps with default
Metrics
| make-series AvgValue = avg(Value) default=0 on Timestamp step 1h
```

### Time Intelligence

```kql
// Year over year comparison
let current = Metrics | where Timestamp > ago(1d) | summarize CurrentAvg = avg(Value);
let previous = Metrics | where Timestamp between (ago(2d) .. ago(1d)) | summarize PrevAvg = avg(Value);
current | extend PreviousAvg = toscalar(previous), Growth = CurrentAvg - toscalar(previous)
```

## Visualisations Intégrées

### render (Charts)

```kql
// Time chart (line)
Metrics
| summarize avg(Value) by bin(Timestamp, 1h)
| render timechart

// Bar chart
Logs
| summarize Count = count() by Service
| render barchart

// Pie chart
Logs
| summarize Count = count() by Level
| render piechart

// Column chart
Sales
| summarize Revenue = sum(Amount) by Product
| top 10 by Revenue
| render columnchart

// Scatter plot
Performance
| project CPU, Memory
| render scatterchart

// Area chart
Metrics
| summarize sum(Value) by bin(Timestamp, 1h), Category
| render areachart
```

## Fonctions Avancées

### String Functions

```kql
// String manipulation
Logs
| extend
    Lower = tolower(Message),
    Upper = toupper(Message),
    Length = strlen(Message),
    Substring = substring(Message, 0, 50),
    Split = split(Message, " "),
    Replace = replace_string(Message, "error", "ERROR"),
    Trim = trim(" ", Message)

// Extract patterns (regex)
Logs
| extend
    IpAddress = extract(@"(\d+\.\d+\.\d+\.\d+)", 1, Message),
    ErrorCode = extract(@"Error: (\d+)", 1, Message)

// Parse structured text
Logs
| parse Message with * "User " UserId " performed " Action " on " Resource
```

### Dynamic/JSON Functions

```kql
// Parse JSON
Events
| extend ParsedPayload = parse_json(PayloadString)
| extend User = ParsedPayload.user
| extend Amount = ParsedPayload.amount

// Array operations
Events
| extend ItemCount = array_length(Payload.items)
| extend FirstItem = Payload.items[0]

// Expand arrays (mv-expand)
Events
| mv-expand Item = Payload.items
| summarize Count = count() by tostring(Item)
```

### Aggregation Functions

```kql
// Statistical functions
Metrics
| summarize
    Count = count(),
    Sum = sum(Value),
    Avg = avg(Value),
    Min = min(Value),
    Max = max(Value),
    Stdev = stdev(Value),
    Variance = variance(Value),
    P50 = percentile(Value, 50),
    P95 = percentile(Value, 95),
    P99 = percentile(Value, 99)

// Conditional aggregations
Logs
| summarize
    Total = count(),
    Errors = countif(Level == "Error"),
    Warnings = countif(Level == "Warning"),
    ErrorRate = round(100.0 * countif(Level == "Error") / count(), 2)
```

### Anomaly Detection

```kql
// Detect anomalies in time series
Metrics
| make-series Value = avg(Value) on Timestamp step 1h
| extend anomalies = series_decompose_anomalies(Value, 1.5)
| mv-expand Timestamp, Value, anomalies
| where anomalies > 0
| project Timestamp, Value, anomalies

// series_decompose_anomalies:
// Threshold: 1.5 = 1.5 standard deviations
// Returns: -1 (low anomaly), 0 (normal), 1 (high anomaly)
```

## Examples Pratiques

### Log Analysis

```kql
// Error rate by hour
Logs
| where Timestamp > ago(24h)
| summarize
    Total = count(),
    Errors = countif(Level == "Error"),
    ErrorRate = round(100.0 * countif(Level == "Error") / count(), 2)
  by bin(Timestamp, 1h)
| render timechart

// Top error messages
Logs
| where Level == "Error"
| summarize Count = count() by Message
| top 10 by Count
| render barchart

// Service health
Logs
| summarize
    Requests = count(),
    Errors = countif(Level == "Error"),
    AvgDuration = avg(Duration)
  by Service
| extend HealthScore = round(100.0 * (1 - Errors / Requests), 2)
| order by HealthScore asc
```

### IoT Telemetry

```kql
// Average temperature by hour
Telemetry
| where Timestamp > ago(7d)
| summarize AvgTemp = avg(Temperature) by bin(Timestamp, 1h)
| render timechart

// Devices with high temperature
Telemetry
| where Temperature > 80
| summarize AlertCount = count() by DeviceId
| top 10 by AlertCount

// Temperature trends by location
Telemetry
| summarize AvgTemp = avg(Temperature) by bin(Timestamp, 1d), Location
| render timechart
```

### Performance Monitoring

```kql
// Request latency percentiles
WebLogs
| summarize
    P50 = percentile(Duration, 50),
    P95 = percentile(Duration, 95),
    P99 = percentile(Duration, 99)
  by bin(Timestamp, 5m)
| render timechart

// Slow requests
WebLogs
| where Duration > 1s
| top 100 by Duration desc
| project Timestamp, RequestPath, Duration, UserId

// Error patterns
WebLogs
| where StatusCode >= 400
| summarize Count = count() by StatusCode, RequestPath
| top 20 by Count
```

## Best Practices

### ✅ Query Optimization

```kql
// 1. Filter early
Logs
| where Timestamp > ago(1h)  // First: time filter
| where Service == "api"     // Then: other filters
| project Timestamp, Message // Finally: select columns

// 2. Use 'has' instead of 'contains' for word search
Logs
| where Message has "error"  // Faster (word boundary)
// vs
| where Message contains "error"  // Slower (substring)

// 3. Avoid expensive operations on large datasets
Logs
| take 10000  // Limit first
| extend ParsedJson = parse_json(LargeField)  // Then parse
```

### ✅ Code Organization

```kql
// Use let for variables
let StartTime = ago(7d);
let EndTime = now();
let ErrorThreshold = 100;

Logs
| where Timestamp between (StartTime .. EndTime)
| summarize Errors = countif(Level == "Error") by Service
| where Errors > ErrorThreshold

// Create reusable functions
.create function ErrorRate(hours: int) {
    Logs
    | where Timestamp > ago(hours * 1h)
    | summarize
        Total = count(),
        Errors = countif(Level == "Error")
    | extend Rate = round(100.0 * Errors / Total, 2)
}

// Use function
ErrorRate(24)
```

## Points Clés

- KQL = pipe-based query language optimized for analytics
- Core operators: where, project, extend, summarize, join, union
- Time functions: ago(), bin(), make-series for time-series analysis
- Visualizations: render timechart, barchart, piechart, etc.
- String functions: extract, parse, split, contains, has
- Dynamic/JSON: parse_json, mv-expand for nested data
- Anomaly detection: series_decompose_anomalies
- Best practices: filter early, use 'has' over 'contains', limit results
- Use let for variables, create functions for reusability

---

**Prochain fichier :** [04 - Streaming Ingestion](./04-streaming-ingestion.md)

[⬅️ Fichier précédent](./02-kql-database.md) | [⬅️ Retour au README du module](./README.md)
