# Performance Analyzer

## Introduction

**Performance Analyzer** est l'outil intégré de Power BI Desktop pour identifier et résoudre les problèmes de performance dans les rapports et modèles.

```
Performance Analyzer shows:
┌─────────────────────────────────────────┐
│  DAX Query duration                     │
│  Visual display time                    │
│  Other (rendering, data transfer)       │
│  Total duration per visual              │
└─────────────────────────────────────────┘
```

## Lancement de Performance Analyzer

### Activation

```
Power BI Desktop:
1. View tab → Performance Analyzer
2. Click "Start recording"
3. Interact with report (change slicers, visuals)
4. Click "Stop recording"
5. Review results

Pane shows:
  • List of all visuals
  • Duration breakdown per visual
  • Expandable details
```

### Interface

```
Performance Analyzer Pane:
┌──────────────────────────────────────┐
│  [Start recording] [Stop] [Clear]   │
├──────────────────────────────────────┤
│  ▼ Visual 1: Sales by Country        │
│    ├─ DAX query: 1,234 ms (60%)     │
│    ├─ Visual display: 456 ms (22%)   │
│    └─ Other: 370 ms (18%)            │
│    Total: 2,060 ms                   │
├──────────────────────────────────────┤
│  ▼ Visual 2: Top 10 Products         │
│    ├─ DAX query: 3,456 ms (85%)     │
│    ├─ Visual display: 456 ms (11%)   │
│    └─ Other: 162 ms (4%)             │
│    Total: 4,074 ms ⚠️                │
├──────────────────────────────────────┤
│  ...                                 │
└──────────────────────────────────────┘
```

## Analyse des Requêtes DAX

### DAX Query Duration

```
DAX Query = Time to execute DAX and retrieve data

High DAX query time indicates:
  ❌ Inefficient measures
  ❌ Complex calculations
  ❌ Large data volumes
  ❌ Poor model design
  ❌ Missing aggregations

Targets:
  ✅ < 1 second: Good
  ⚠️ 1-3 seconds: Acceptable
  ❌ > 3 seconds: Needs optimization
```

### Copy Query

```
Performance Analyzer → Expand visual → Copy query

Pastes DAX query to clipboard:
  EVALUATE
  SUMMARIZECOLUMNS(
      'Product'[Category],
      "Total Sales", SUM(Sales[Amount])
  )

Use cases:
  ✅ Test in DAX Studio
  ✅ Analyze query plan
  ✅ Identify bottlenecks
  ✅ Optimize measures
```

## DAX Query Plans

### Using DAX Studio

```
1. Install DAX Studio (free tool)
2. Connect to Power BI model
3. Paste query from Performance Analyzer
4. Click "Run" → "Server Timings"
5. Analyze query plan

Metrics shown:
  • Storage Engine (SE) queries
  • Formula Engine (FE) time
  • Total duration
  • Query plan visualization
```

### Storage Engine vs Formula Engine

```
Storage Engine (VertiPaq):
  • Reads data from model
  • Columnar scans
  • Fast (optimized C++)
  • Goal: Maximize SE usage

Formula Engine:
  • Evaluates DAX expressions
  • Row-by-row iteration
  • Slower (interpreted)
  • Goal: Minimize FE usage

Performance:
  ✅ SE query: Fast (< 100ms typical)
  ❌ FE iteration: Slow (can be seconds)

Optimization:
  Push work to SE (simple filters, aggregations)
  Avoid FE iteration (complex row-by-row logic)
```

### Query Plan Analysis

```
DAX Studio query plan shows:

1. Physical Query Plan
   • What SE queries were sent
   • Columns scanned
   • Filters applied
   • Cardinality

2. Logical Query Plan
   • DAX operations
   • Joins
   • Aggregations

Example:
  Scan Sales table (10M rows)
  │  Columns: Amount, CustomerKey
  │  Filter: None
  │  Duration: 50ms ✅

  Scan Customer table (100K rows)
  │  Columns: CustomerKey, Country
  │  Filter: Country = 'France'
  │  Duration: 10ms ✅

  Join Sales ← Customer
  │  Duration: 120ms ✅

  Aggregate SUM(Amount)
  │  Duration: 30ms ✅

  Total: 210ms ✅
```

## VertiPaq Engine

### Architecture

```
VertiPaq = In-memory columnar database

Features:
  ✅ Compressed columnar storage
  ✅ Dictionary encoding
  ✅ Run-length encoding
  ✅ Bitmap indexes
  ✅ Columnar scans (fast)

Compression:
  Typical ratio: 10:1 to 20:1
  Example: 1 GB raw data → 50-100 MB compressed

Performance:
  Scans millions of rows in milliseconds
  Optimized for aggregations
```

### VertiPaq Analyzer

```
Tool: VertiPaq Analyzer (DAX Studio, Tabular Editor)

Shows:
  • Table sizes (compressed)
  • Column cardinality
  • Column sizes
  • Relationships
  • Memory usage

Example output:
  Sales table: 45 MB
    ├─ SalesKey: 8 MB (low cardinality)
    ├─ CustomerKey: 6 MB (medium cardinality)
    ├─ Amount: 12 MB (high cardinality)
    └─ OrderDate: 4 MB (low cardinality, dictionary)

  Customer table: 2 MB
    ├─ CustomerKey: 400 KB
    └─ CustomerName: 1.6 MB (high cardinality)
```

## Identification des Bottlenecks

### High DAX Query Time

```
Problem: Visual takes 5 seconds to load

Analysis:
  1. Check Performance Analyzer
     → DAX query: 4,800 ms (96%)

  2. Copy query to DAX Studio
     → Identify slow operation

  3. Common causes:
     ❌ Complex iterator functions (SUMX, FILTER)
     ❌ Row-by-row calculations
     ❌ Inefficient relationships
     ❌ Missing aggregations

Solutions:
  ✅ Simplify DAX measures
  ✅ Use simple filters instead of FILTER()
  ✅ Add aggregation tables
  ✅ Optimize model design
```

### High Visual Display Time

```
Problem: Visual display takes 2 seconds

Analysis:
  • DAX query: 200 ms ✅
  • Visual display: 2,000 ms ❌

Common causes:
  ❌ Too many data points (>10,000)
  ❌ Complex visual (many series)
  ❌ Custom visuals (slow rendering)
  ❌ Conditional formatting (row-by-row)

Solutions:
  ✅ Limit data points (Top N)
  ✅ Use simpler visuals
  ✅ Remove unnecessary formatting
  ✅ Aggregate data before display
```

### High "Other" Time

```
Problem: "Other" takes 1+ seconds

Causes:
  • Network latency (cloud datasets)
  • Data transfer overhead
  • Visual initialization
  • Browser rendering

Solutions:
  ✅ Use Import mode (not DirectQuery)
  ✅ Reduce visual complexity
  ✅ Optimize network connection
  ⚠️ Limited control (external factors)
```

## Optimisation des Mesures

### Inefficient Patterns

```dax
-- ❌ Bad: FILTER on large table
Sales High Value =
CALCULATE(
    SUM(Sales[Amount]),
    FILTER(
        Sales,  -- 10M rows!
        Sales[Amount] > 1000
    )
)
-- DAX query: 3,000 ms ❌

-- ✅ Good: Simple filter
Sales High Value =
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Amount] > 1000
)
-- DAX query: 150 ms ✅

Performance gain: 20x faster
```

### Iterator Optimization

```dax
-- ❌ Bad: Nested iterators
Customer Avg Order =
AVERAGEX(
    Customer,
    CALCULATE(
        SUMX(
            FILTER(Sales, Sales[CustomerKey] = Customer[CustomerKey]),
            Sales[Amount]
        )
    )
)
-- DAX query: 5,000 ms ❌

-- ✅ Good: Pre-aggregate
Customer Avg Order =
AVERAGEX(
    Customer,
    [Total Sales]
)
-- DAX query: 200 ms ✅

Performance gain: 25x faster
```

### Use Variables

```dax
-- ❌ Bad: Repeated calculation
Profit Margin % =
DIVIDE(
    SUM(Sales[Revenue]) - SUM(Sales[Cost]),
    SUM(Sales[Revenue]),
    0
)
-- SUM(Sales[Revenue]) computed twice ❌

-- ✅ Good: Variable
Profit Margin % =
VAR Revenue = SUM(Sales[Revenue])
VAR Cost = SUM(Sales[Cost])
RETURN
    DIVIDE(Revenue - Cost, Revenue, 0)
-- Each SUM computed once ✅

Performance gain: 2x faster
```

## Optimisation des Visuels

### Limit Data Points

```
Problem: Chart with 50,000 data points
  → Visual display: 4,000 ms ❌

Solution: Top N filter
  1. Add "Top N" filter to visual
  2. Show only top 100 products
  3. Visual display: 200 ms ✅

Performance gain: 20x faster

Alternative: Aggregate before visualizing
  • Group by Category instead of Product
  • Monthly instead of daily
  • Reduces data points significantly
```

### Simplify Visual Types

```
Slow visuals:
  ❌ Custom visuals (variable performance)
  ❌ Maps with many points
  ❌ Scatter charts (many data points)
  ❌ Tables with many rows/columns

Fast visuals:
  ✅ Bar/Column charts
  ✅ Line charts
  ✅ Cards (single value)
  ✅ Simple tables (< 100 rows)

Recommendation:
  Use simplest visual that meets requirement
```

### Conditional Formatting

```
-- ❌ Bad: Complex conditional formatting
Color = IF(
    [Total Sales] > [Sales Target],
    "Green",
    IF([Total Sales] > [Sales Target] * 0.9, "Yellow", "Red")
)

Impact:
  • Evaluated for every cell/bar
  • Can add 100s of milliseconds
  • Row-by-row calculation

-- ✅ Good: Pre-calculate category
Sales Status =
SWITCH(
    TRUE(),
    [Total Sales] >= [Sales Target], "On Target",
    [Total Sales] >= [Sales Target] * 0.9, "Near Target",
    "Below Target"
)

Then use simple categorical formatting
Performance gain: 5-10x faster
```

## Best Practices

### ✅ Testing Workflow

```
1. Start with clean slate
   • Clear Performance Analyzer
   • Refresh page
   • Close other apps

2. Test specific scenario
   • Single slicer change
   • Single visual interaction
   • Isolated test

3. Record performance
   • Start recording
   • Perform action
   • Stop recording

4. Analyze results
   • Identify slowest visual
   • Expand to see breakdown
   • Copy DAX query

5. Optimize
   • Test in DAX Studio
   • Modify measure
   • Repeat until acceptable
```

### ✅ Optimization Priorities

```
1. Focus on worst offenders first
   • Visual taking 5 seconds
   • More impact than 0.5 second visual

2. Set targets
   • Page load < 3 seconds total
   • Individual visual < 1 second
   • Interaction response < 500ms

3. Measure before/after
   • Record baseline performance
   • Apply optimization
   • Verify improvement

4. Test with real data volumes
   • Development: 1K rows (fast)
   • Production: 10M rows (slow!)
   • Always test at scale
```

### ✅ Common Optimizations

```
1. Model design
   ✅ Use star schema
   ✅ Remove unused columns
   ✅ Use integer keys
   ✅ Appropriate data types

2. DAX measures
   ✅ Avoid FILTER on large tables
   ✅ Use variables
   ✅ Simplify complex calculations
   ✅ Use base measures

3. Visuals
   ✅ Limit data points (Top N)
   ✅ Use simple visual types
   ✅ Remove unnecessary formatting
   ✅ Minimize custom visuals

4. Relationships
   ✅ Single direction (default)
   ✅ Avoid many-to-many
   ✅ Remove circular dependencies
```

## Exemples de Performance

### Before Optimization

```
Visual: Top 10 Products by Sales

DAX query: 4,500 ms ❌
Visual display: 800 ms
Total: 5,300 ms

Measure:
  Top 10 Sales =
  CALCULATE(
      SUM(Sales[Amount]),
      TOPN(
          10,
          FILTER(
              ALL(Product),
              [Total Sales] > 0
          ),
          [Total Sales],
          DESC
      )
  )

Problems:
  • FILTER iterates all products (10K rows)
  • [Total Sales] computed for each product
  • Nested calculations
```

### After Optimization

```
Visual: Top 10 Products by Sales

DAX query: 250 ms ✅
Visual display: 200 ms
Total: 450 ms

Optimization:
  1. Remove FILTER (not needed for TOPN)
  2. Use VALUES instead of ALL

Measure:
  Top 10 Sales =
  CALCULATE(
      [Total Sales],
      TOPN(
          10,
          VALUES(Product[ProductName]),
          [Total Sales],
          DESC
      )
  )

Performance gain: 18x faster (5.3s → 0.45s)
```

## Points Clés

- Performance Analyzer: Built-in tool in Power BI Desktop
- Shows: DAX query time, visual display time, other time
- Copy DAX query to test in DAX Studio
- DAX Studio: Server timings, query plan, Storage Engine analysis
- VertiPaq: In-memory columnar engine (fast aggregations)
- Bottlenecks: High DAX time (measure), high visual time (too many points)
- Optimize DAX: Avoid FILTER, use variables, simplify calculations
- Optimize visuals: Limit data points, simple types, minimal formatting
- Test at scale: Production data volumes, not development
- Targets: < 1 second per visual, < 3 seconds per page

---

**Prochain fichier :** [10 - Best Practices de Modélisation](./10-best-practices-modeling.md)

[⬅️ Fichier précédent](./08-relationships-cardinality.md) | [⬅️ Retour au README du module](./README.md)
