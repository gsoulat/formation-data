# Import vs DirectQuery vs Direct Lake

## Introduction

Le choix du mode de stockage (Storage Mode) est une décision cruciale qui impacte la performance, la fraîcheur des données, et les coûts. Ce fichier compare les trois modes disponibles dans Fabric.

```
Storage Modes Comparison:
┌────────────┬─────────────┬──────────────┐
│   Import   │ DirectQuery │ Direct Lake  │
├────────────┼─────────────┼──────────────┤
│ In-Memory  │ Live Query  │ Direct Read  │
│ Fast ✅    │ Fresh ✅    │ Both ✅      │
│ Stale ❌   │ Slow ❌     │ Best 🚀      │
└────────────┴─────────────┴──────────────┘
```

## Import Mode

### Architecture

```
Import Mode Data Flow:
┌──────────┐
│  Source  │ (SQL Server, CSV, API, etc.)
└────┬─────┘
     │ ETL/Copy
     ▼
┌──────────────────────────────┐
│  Power BI Import             │
│  ├─ VertiPaq Engine          │
│  ├─ Compressed columnar      │
│  ├─ In-memory storage        │
│  └─ Data snapshot            │
└──────────────────────────────┘
     │ Query
     ▼
┌──────────┐
│Power BI  │
│Reports   │
└──────────┘

Key characteristic:
  Data is COPIED into Power BI model
```

### Avantages ✅

```
1. Performance maximale
   • Données en mémoire (RAM)
   • Compression 10:1 ratio typical
   • Sub-second query response
   • Optimal pour visualizations complexes

2. Full DAX Support
   • Toutes fonctions DAX disponibles
   • Calculated columns
   • Calculated tables
   • Complex measures

3. Offline Access
   • Power BI Desktop hors ligne
   • Données disponibles localement
   • Pas de connexion requise

4. Data Transformations
   • Power Query (M language)
   • Riche set de transformations
   • Merge/append queries
   • Custom functions

5. Predictable Performance
   • Indépendant de la source
   • Pas de latence réseau
   • Pas de charge sur source
```

### Inconvénients ❌

```
1. Data Latency
   • Refresh schedule required
   • Data can be hours/days old
   • Not real-time

2. Size Limitations
   • Pro: 1 GB compressed
   • Premium: 10 GB compressed (per SKU)
   • Fabric: varies by capacity (F2-F2048)

3. Memory Consumption
   • Uses Capacity memory
   • Large models = high CU cost
   • Can cause throttling

4. Refresh Duration
   • Large datasets = long refresh
   • Impacts capacity availability
   • Scheduled downtime

5. Data Duplication
   • Source + Power BI copy
   • Storage cost 2x
   • Sync management
```

### Use Cases

```
✅ Best for:
  • Small to medium datasets (< 1 GB)
  • Data changes infrequently (daily/weekly)
  • Complex DAX calculations needed
  • Need offline access
  • Source has poor query performance
  • Historical analysis (no real-time need)

Examples:
  ✅ Monthly financial reports
  ✅ HR dashboards (updated weekly)
  ✅ Customer segmentation analysis
  ✅ Historical trend analysis
```

### Configuration

```
Power BI Desktop:
1. Home → Get Data → [Source]
2. Transform Data (Power Query)
3. Load to model
4. Storage mode: Import (default)

Refresh Schedule (Power BI Service):
1. Dataset settings
2. Scheduled refresh
3. Frequency: Daily/Weekly
4. Time slots: Choose off-peak hours
5. Notify on failure: Yes
```

## DirectQuery Mode

### Architecture

```
DirectQuery Mode Data Flow:
┌──────────┐
│  Source  │ (SQL Server, Synapse, Oracle)
└────▲─────┘
     │ Live Query (on each visual interaction)
     │
┌────┴─────────────────────────┐
│  Power BI DirectQuery        │
│  ├─ No data storage          │
│  ├─ Query translation        │
│  ├─ DAX → SQL                │
│  └─ Result cache (limited)   │
└──────────────────────────────┘
     │ Render
     ▼
┌──────────┐
│Power BI  │
│Reports   │
└──────────┘

Key characteristic:
  Every visual interaction = query to source
```

### Avantages ✅

```
1. Data Freshness
   • Real-time or near real-time
   • Always current
   • No refresh schedule needed

2. No Size Limit
   • Billions of rows supported
   • No import size restrictions
   • Unlimited data volume

3. Low Memory Footprint
   • No data in Power BI model
   • Minimal capacity usage
   • Lower CU consumption

4. Source Security
   • RLS enforced at source
   • Single security model
   • Compliance (data locality)

5. No Data Duplication
   • Single source of truth
   • No sync issues
   • Lower storage cost
```

### Inconvénients ❌

```
1. Performance Variability
   • Depends on source performance
   • Network latency impact
   • Can be very slow

2. Limited DAX Support
   • Some functions not supported
   • No calculated columns
   • Limited time intelligence

3. Source Load
   • Every query hits source
   • Can overwhelm source DB
   • Concurrent users = scaling issues

4. No Offline Access
   • Requires active connection
   • Won't work offline
   • Connectivity dependent

5. Query Limitations
   • 1 million row limit per visual
   • Some complex queries fail
   • No cross-source queries
```

### Use Cases

```
✅ Best for:
  • Very large datasets (> 100 GB)
  • Need real-time data
  • Source has excellent query performance
  • Compliance requires no data copy
  • Operational dashboards
  • Shared data source (multiple tools)

Examples:
  ✅ Real-time manufacturing dashboards
  ✅ Live sales monitoring
  ✅ Call center analytics
  ✅ Fraud detection systems
```

### Configuration

```
Power BI Desktop:
1. Home → Get Data → [Source]
2. Connection mode: DirectQuery ⚠️
3. Limited Power Query transformations
4. Load to model

Optimize source:
  • Create indexes on filter columns
  • Create indexed views
  • Optimize query plans
  • Consider caching layer (Redis)
```

## Direct Lake Mode

### Architecture

```
Direct Lake Mode Data Flow (Fabric only):
┌──────────────────┐
│  OneLake         │
│  (Delta Tables)  │
│  └─ Parquet files│
└────▲─────────────┘
     │ Direct Read (columnar scan)
     │
┌────┴─────────────────────────┐
│  Power BI Direct Lake        │
│  ├─ VertiPaq reads Parquet   │
│  ├─ Smart caching            │
│  ├─ No data copy             │
│  └─ Delta metadata           │
└──────────────────────────────┘
     │ Query
     ▼
┌──────────┐
│Power BI  │
│Reports   │
└──────────┘

Key characteristic:
  Reads Delta Parquet files directly into VertiPaq
```

### Avantages ✅

```
1. Import-like Performance
   • Sub-second queries
   • Columnar read from Parquet
   • In-memory caching

2. DirectQuery-like Freshness
   • Near real-time (seconds)
   • Auto-refresh on Delta update
   • No manual refresh

3. No Data Duplication
   • Single copy in OneLake
   • Reads directly from source
   • Lower storage cost

4. Large Scale
   • TBs of data supported
   • Capacity-based limits
   • Incremental refresh

5. Full DAX Support
   • Almost all DAX functions
   • Calculated columns
   • Complex measures
```

### Inconvénients ❌

```
1. Fabric Only
   • Requires Microsoft Fabric
   • Needs F-SKU capacity
   • Not available in Power BI Pro

2. OneLake Requirement
   • Must use OneLake storage
   • Delta Lake format required
   • Can't use external sources directly

3. Data Type Limitations
   • Some types unsupported
   • Complex types need flattening
   • ARRAY/STRUCT not supported

4. Fallback to DirectQuery
   • When limits exceeded
   • Performance degradation
   • Need monitoring

5. Capacity Limits
   • Size limit per capacity SKU
   • F2: 10 GB, F64: 64 GB, etc.
   • Need right-sizing
```

### Use Cases

```
✅ Best for:
  • Large datasets in OneLake
  • Need both speed and freshness
  • Medallion architecture (Bronze/Silver/Gold)
  • Fabric-native workloads
  • Lakehouse-based analytics
  • Modern data platform

Examples:
  ✅ Executive dashboards on Lakehouse
  ✅ Self-service BI on OneLake
  ✅ Near real-time operational reports
  ✅ Large-scale customer analytics
```

### Configuration

```
Fabric Workspace:
1. Create Lakehouse with Delta tables
2. Optimize with V-Order:
   ALTER TABLE sales
   SET TBLPROPERTIES ('delta.parquet.vorder.enabled' = 'true')

3. Create Semantic Model
   • Source: Lakehouse
   • Auto-detected as Direct Lake
   • Select tables

4. Verify Direct Lake mode
   • Settings → Storage mode = "Direct Lake"
```

## Comparison Matrix

### Performance

```
Scenario              │ Import │ DirectQuery │ Direct Lake
──────────────────────┼────────┼─────────────┼────────────
Simple aggregation    │  ⚡⚡⚡ │    ⚡       │    ⚡⚡⚡
Complex calculation   │  ⚡⚡⚡ │    ❌      │    ⚡⚡
Large scans           │  ⚡⚡⚡ │    🐌      │    ⚡⚡
Filtering             │  ⚡⚡⚡ │    ⚡       │    ⚡⚡⚡
Drill-down            │  ⚡⚡⚡ │    ⚡       │    ⚡⚡
Cross-table joins     │  ⚡⚡⚡ │    🐌      │    ⚡⚡⚡

Legend:
  ⚡⚡⚡ = Excellent (< 1 sec)
  ⚡⚡  = Good (1-3 sec)
  ⚡   = OK (3-10 sec)
  🐌  = Slow (> 10 sec)
  ❌  = Not supported
```

### Features

```
Feature                │ Import │ DirectQuery │ Direct Lake
───────────────────────┼────────┼─────────────┼────────────
Full DAX support       │   ✅   │     ⚠️      │      ✅
Calculated columns     │   ✅   │     ❌      │      ✅
Calculated tables      │   ✅   │     ❌      │      ✅
Power Query (M)        │   ✅   │     ⚠️      │      ⚠️
Offline access         │   ✅   │     ❌      │      ⚠️
Incremental refresh    │   ✅   │     ❌      │      ✅
Aggregations           │   ✅   │     ⚠️      │      ✅
Real-time data         │   ❌   │     ✅      │      ✅
Unlimited size         │   ❌   │     ✅      │      ⚠️
RLS (model-level)      │   ✅   │     ✅      │      ✅
```

### Cost & Resources

```
Resource Usage        │ Import │ DirectQuery │ Direct Lake
──────────────────────┼────────┼─────────────┼────────────
Memory (model)        │  High  │    Low      │    Medium
CPU (refresh)         │  High  │    Low      │    Low
Storage (duplication) │  2x    │    1x       │    1x
Network bandwidth     │  Low   │    High     │    Medium
Source DB load        │  Low   │    High     │    Low
Capacity CU cost      │  High  │    Low      │    Medium
```

## Décision Matrix

### Decision Tree

```
START: Choose Storage Mode
│
├─ Is data in OneLake Delta?
│  ├─ Yes → ✅ Direct Lake (best option)
│  └─ No → Continue
│
├─ Need real-time data?
│  ├─ Yes
│  │  ├─ Source has good performance?
│  │  │  ├─ Yes → DirectQuery
│  │  │  └─ No → Improve source OR Import
│  │  └─ Can data move to OneLake?
│  │     ├─ Yes → Direct Lake
│  │     └─ No → DirectQuery
│  │
│  └─ No (daily/weekly refresh OK)
│     ├─ Dataset < 1 GB?
│     │  ├─ Yes → ✅ Import
│     │  └─ No
│     │     ├─ Can move to OneLake?
│     │     │  ├─ Yes → ✅ Direct Lake
│     │     │  └─ No
│     │     │     ├─ Source performant?
│     │     │     │  ├─ Yes → DirectQuery
│     │     │     │  └─ No → Aggregations + Import
```

### By Scenario

```
Scenario: Executive Dashboard (updated daily)
  Data size: 500 MB
  Freshness: Daily OK
  Complexity: High DAX
  → Recommendation: Import ✅

Scenario: Real-time Sales Monitor
  Data size: 50 GB
  Freshness: Real-time required
  Complexity: Simple aggregations
  Source: SQL Server (optimized)
  → Recommendation: DirectQuery ✅

Scenario: Customer 360 Analytics
  Data size: 2 TB
  Freshness: Near real-time
  Complexity: Medium DAX
  Source: Fabric Lakehouse
  → Recommendation: Direct Lake ✅ ✅

Scenario: Financial Reporting
  Data size: 10 GB
  Freshness: Monthly
  Complexity: Very complex DAX
  Need offline: Yes
  → Recommendation: Import ✅
```

## Composite Models

### Mixing Modes

```
Composite Model = Multiple storage modes in one model

Example:
┌────────────────────────────────────┐
│  Semantic Model (Composite)        │
│  ├─ Fact_Sales (Direct Lake) 📊    │
│  ├─ Dim_Customer (Import) 📥       │
│  ├─ Dim_Product (Import) 📥        │
│  └─ Fact_Realtime (DirectQuery) 🔗 │
└────────────────────────────────────┘

Benefits:
  ✅ Optimize each table individually
  ✅ Import small dimensions (fast joins)
  ✅ Direct Lake/DQ large facts
  ✅ Best performance/freshness mix
```

### Aggregations

```
Aggregation Strategy:
┌────────────────────────────────────┐
│  Detail Table (DirectQuery/DL)     │
│  └─ Billions of rows               │
│                                    │
│  Aggregation Table (Import)        │
│  └─ Pre-aggregated (thousands)     │
│                                    │
│  Automatic query routing:          │
│  ├─ Summary view → Agg (fast ⚡)   │
│  └─ Drill to detail → Detail (OK)  │
└────────────────────────────────────┘

Example:
  Detail: Sales_DirectQuery (1B rows)
  Agg: Sales_Monthly_Import (120K rows)
  → Dashboard uses Agg (instant)
  → Drill-down uses Detail (acceptable)
```

## Migration Strategies

### Import → Direct Lake

```
Step 1: Move data to OneLake
  • Create Lakehouse
  • Load data into Delta tables
  • Optimize with V-Order

Step 2: Create Direct Lake model
  • New semantic model
  • Source: Lakehouse
  • Select same tables

Step 3: Migrate measures
  • Copy DAX measures
  • Test compatibility
  • Adjust if needed

Step 4: Test & validate
  • Compare results
  • Test performance
  • Check fallback status

Step 5: Switch reports
  • Point reports to new model
  • Monitor performance
  • Decommission old Import model
```

### DirectQuery → Direct Lake

```
Step 1: ETL to OneLake
  • Data pipeline: Source → Lakehouse
  • Schedule: Match freshness needs
  • Delta table format

Step 2: Optimize Delta
  • OPTIMIZE tables
  • Z-Order on filter columns
  • Enable V-Order

Step 3: Create Direct Lake model
  • Same schema as DirectQuery
  • Test DAX compatibility

Step 4: Performance comparison
  • Direct Lake should be faster
  • Validate data freshness
  • Check query patterns

Step 5: Cutover
  • Update reports
  • Monitor
  • Optimize as needed
```

## Best Practices

### ✅ Import Mode

```
1. Incremental refresh for large tables
2. Remove unnecessary columns/rows
3. Optimize data types (int vs string)
4. Schedule refresh during off-peak hours
5. Monitor refresh duration
6. Set up failure alerts
```

### ✅ DirectQuery Mode

```
1. Optimize source database (indexes, views)
2. Limit data volume with filters
3. Use aggregations for performance
4. Test query performance before deployment
5. Monitor source load
6. Consider caching layer (Redis)
```

### ✅ Direct Lake Mode

```
1. Use V-Order on Delta tables
2. Optimize with ZORDER
3. Regular OPTIMIZE and VACUUM
4. Monitor capacity usage
5. Watch for fallback to DirectQuery
6. Partition large tables appropriately
```

## Points Clés

- Import: Fast, stale data, size limits
- DirectQuery: Fresh, slower, no limits
- Direct Lake: Fast + fresh (Fabric innovation)
- Choose based on: size, freshness, source, complexity
- Composite models mix modes for optimal balance
- Aggregations boost DirectQuery/Direct Lake performance
- Direct Lake is default choice for Fabric workloads
- Migration to Direct Lake recommended when possible
- Monitor fallback and capacity usage
- Test performance before production deployment

---

**Prochain fichier :** [04 - Modélisation Star Schema](./04-modelisation-star-schema.md)

[⬅️ Fichier précédent](./02-direct-lake-mode.md) | [⬅️ Retour au README du module](./README.md)
