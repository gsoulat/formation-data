# Data Lineage

## Introduction

**Data Lineage** trace le parcours des données depuis leur source jusqu'à leur destination finale, montrant toutes les transformations et dépendances.

```
Lineage Example:
Source DB → Lakehouse Bronze → Silver → Gold → Semantic Model → Report
    ↓           ↓                ↓        ↓           ↓           ↓
  Extract     Raw data        Cleaned  Aggregated   Analysis    Insights
```

## Pourquoi la Data Lineage ?

### Use Cases

```
1. Impact Analysis
   "If I change this column, what breaks?"
   Trace downstream dependencies
   Plan changes safely

2. Root Cause Analysis
   "Why is this report showing wrong numbers?"
   Trace upstream to find data source issue
   Identify transformation errors

3. Compliance/Audit
   "Where does this sensitive data go?"
   Track PII flow through systems
   Document data usage for regulators

4. Trust and Transparency
   "How was this metric calculated?"
   Show complete transformation history
   Build confidence in analytics

5. Data Quality
   "Where did this data come from?"
   Validate source reliability
   Ensure quality at each step
```

### Benefits

```
✅ Understand data flow end-to-end
✅ Identify dependencies before changes
✅ Debug data issues faster
✅ Meet regulatory requirements
✅ Improve collaboration (shared understanding)
✅ Reduce redundant data pipelines
```

## Lineage dans Fabric

### Fabric Lineage View

```
Access:
  Workspace → Lineage view (top right toggle)
  Or: Right-click item → View lineage

Visualization:
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Sources │ →  │Transforms│ →  │ Reports │
└─────────┘    └─────────┘    └─────────┘

Shows:
  • Lakehouses
  • Warehouses
  • Pipelines
  • Dataflows
  • Semantic models
  • Reports
  • Dashboards
```

### Interactive Exploration

```
Lineage view features:

1. Zoom and pan
   Navigate large lineage graphs
   Focus on specific areas

2. Highlight dependencies
   Click asset → Highlight upstream/downstream
   See what feeds into / comes from

3. Expand details
   See columns within tables
   View transformation logic

4. Filter by type
   Show only pipelines
   Show only reports
   Focus on specific layer

5. Search
   Find specific asset in lineage
   Jump to location
```

### Automatic Tracking

```
Fabric automatically tracks:

Data movement:
  Copy activity in pipeline
  Source → Destination captured

Transformations:
  Dataflow Gen2 steps
  SQL queries in Warehouse
  Spark operations in Notebook

Semantic model connections:
  Dataset to report relationships
  Measure calculations

What's NOT automatically tracked:
  ❌ External system origins (before Fabric)
  ❌ Manual file uploads
  ❌ Undocumented transformations
  ❌ Logic in custom scripts without logging
```

## Lineage en Action

### End-to-End Example

```
Scenario: Sales Analytics Pipeline

1. Source (External)
   SQL Server → Sales transactions

2. Bronze Layer (Lakehouse)
   Pipeline copies raw data
   Lineage: External SQL → Bronze.RawSales

3. Silver Layer (Lakehouse)
   Dataflow cleans data
   Removes duplicates, validates
   Lineage: Bronze.RawSales → Silver.CleanedSales

4. Gold Layer (Lakehouse)
   Spark notebook aggregates
   Daily summaries
   Lineage: Silver.CleanedSales → Gold.DailySales

5. Semantic Model
   Power BI dataset
   DAX measures
   Lineage: Gold.DailySales → SalesDataset

6. Report
   Power BI visuals
   User-facing insights
   Lineage: SalesDataset → SalesDashboard

Complete chain visible in one view!
```

### Column-Level Lineage

```
Track individual columns:

Source column: RawSales.OrderAmount
  ↓
Transformation: Apply discount (OrderAmount * 0.9)
  ↓
Silver column: CleanedSales.NetAmount
  ↓
Transformation: SUM aggregation
  ↓
Gold column: DailySales.TotalRevenue
  ↓
Semantic model measure: [Total Revenue]
  ↓
Report visual: Revenue card

Benefits:
  Precise impact analysis
  Understand transformations
  Debug specific calculations
```

### Transformation Logic

```
Document what happens at each step:

Step: Clean Customer Names
  Input: Raw.CustomerName (VARCHAR)
  Logic: TRIM(UPPER(CustomerName))
  Output: Silver.CustomerName

Step: Calculate Profit Margin
  Inputs: Gold.Revenue, Gold.Cost
  Logic: (Revenue - Cost) / Revenue * 100
  Output: Gold.ProfitMarginPct

Step: DAX Measure
  Input: Gold.ProfitMarginPct
  Logic: AVERAGE([ProfitMarginPct])
  Output: [Avg Profit Margin]

Lineage captures not just flow but logic
```

## Impact Analysis

### Downstream Impact

```
Question: "What happens if I delete DimCustomer table?"

Analysis:
1. Find DimCustomer in lineage
2. See downstream dependencies:
   • 5 reports use this table
   • 3 semantic models reference it
   • 2 other tables join to it

3. Impact assessment:
   ❌ SalesReport: Will break (direct dependency)
   ❌ CustomerAnalysis: Will break
   ⚠️ MarketingDashboard: Might break (indirect)

4. Action:
   Communicate to report owners
   Schedule downtime
   Update impacted assets

Without lineage:
  Surprise breakages
  Angry stakeholders
  Difficult debugging
```

### Upstream Analysis

```
Question: "Why is Revenue number wrong in my report?"

Investigation:
1. Start at report visual (Revenue card)
2. Trace upstream:
   Report → Semantic Model measure
   Measure → Gold.TotalRevenue
   Gold → Spark aggregation
   Spark → Silver.NetAmount
   Silver → Bronze.OrderAmount
   Bronze → Source database

3. Find issue:
   Silver transformation: Uses wrong exchange rate
   Currency conversion incorrect

4. Fix:
   Update Silver transformation
   Reprocess data
   Report automatically correct

Lineage accelerates debugging
```

### Change Planning

```
Scenario: Rename column CustomerID to CustomerId

Lineage check:
  CustomerID used in:
    • 12 tables (joins)
    • 8 pipelines (copy activities)
    • 5 dataflows (transformations)
    • 3 semantic models (relationships)
    • 15 reports (filters)

Plan:
  1. List all impacted assets (from lineage)
  2. Prioritize by criticality
  3. Update in reverse dependency order:
     - Reports (update after dataset)
     - Semantic models (update after tables)
     - Dataflows (update after bronze)
     - Pipelines (update source first)
  4. Test each layer
  5. Communicate changes

Lineage makes change management systematic
```

## Lineage dans Purview

### Purview vs Fabric Lineage

```
Fabric native lineage:
  • Within Fabric workspace
  • Automatic for Fabric items
  • Visual and interactive

Purview lineage:
  • Cross-platform (Azure, on-prem, multi-cloud)
  • Includes non-Fabric sources
  • Enterprise-wide view
  • Integrated with governance

Use both:
  Fabric: Day-to-day development
  Purview: Enterprise governance
```

### External Source Lineage

```
Purview tracks outside Fabric:

Example flow:
  On-premises SQL Server
    ↓ (Azure Data Factory)
  Azure Data Lake Gen2
    ↓ (Shortcut in Fabric)
  Fabric Lakehouse
    ↓ (Dataflow)
  Fabric Warehouse
    ↓ (Semantic Model)
  Power BI Report

Purview sees entire chain
Including on-premises origin
Fabric only sees from Lakehouse onward
```

### Lineage Visualization

```
Purview lineage graph:

[SQL Server] ──→ [ADF Pipeline] ──→ [ADLS Gen2] ──→ [Fabric Lakehouse]
     │                  │                │                    │
  Source             Copy               Store              Transform
  Schema           Activity             Layer                 Layer

Features:
  • Click any node for details
  • See column-level flow
  • Export lineage report
  • Filter by time range
```

## Best Practices

### Maintaining Lineage

```
1. Document external sources
   Manual entry for non-scanned systems
   Note origin of data before Fabric

2. Use descriptive names
   Pipeline: "ETL_Bronze_Sales_Daily"
   Not: "Pipeline1"
   Names appear in lineage

3. Add descriptions
   What does this transformation do?
   Why does this step exist?
   Appears in lineage details

4. Regular validation
   Check lineage accuracy
   Update if manual changes
   Ensure completeness

5. Version control
   Track changes to pipelines
   Document transformations
   Historical lineage snapshots
```

### Common Mistakes

```
❌ Breaking lineage with manual steps
  Copy data via Excel
  Lineage chain broken
  No visibility

❌ Ignoring column-level lineage
  Table lineage only
  Miss transformation details
  Incomplete picture

❌ Not updating lineage after changes
  Lineage shows old flow
  Misleading information
  Trust erodes

❌ Overly complex pipelines
  Impossible to understand
  Lineage graph too dense
  Simplify where possible

❌ Not using lineage for planning
  Make changes blindly
  Break downstream consumers
  Avoidable outages
```

### Lineage Governance

```
Establish lineage practices:

1. Lineage review in change process
   Before any schema change
   Check lineage for impact
   Required approval step

2. Lineage documentation
   Part of data asset documentation
   Explain key transformations
   Update with changes

3. Lineage quality metrics
   % of assets with complete lineage
   Gaps identified
   Remediation plan

4. Training
   Teach teams to use lineage
   Show value for debugging
   Include in onboarding
```

## Advanced Scenarios

### Complex Transformations

```
Scenario: Machine learning pipeline

Feature Engineering:
  Raw data → Multiple features
  Multiple sources → Single feature table

Lineage tracking:
  Raw.CustomerAge
  Raw.PurchaseHistory
  Raw.WebBehavior
    ↓
  Feature calculation (Python notebook)
    ↓
  Features.CustomerFeatureVector

Model Training:
  Features.CustomerFeatureVector
  Historical.Outcomes
    ↓
  ML model (training notebook)
    ↓
  Model artifact
    ↓
  Predictions.ChurnProbability

Lineage shows:
  Which features used
  Training data source
  Model lineage
  Prediction data flow
```

### Real-Time Lineage

```
Streaming data scenario:

Event Hub → EventStream → KQL Database → Real-Time Dashboard

Lineage tracking:
  • Source event structure
  • Stream transformations
  • Table ingestion
  • Dashboard queries

Challenges:
  Continuous data flow
  No batch boundaries
  High velocity changes

Solution:
  Schema-level lineage
  Transformation documentation
  Less granular than batch
  Focus on structure not records
```

### Multi-Team Lineage

```
Cross-team data sharing:

Team A: Data Engineering
  Produces: Gold layer tables

Team B: Data Science
  Consumes: Gold tables
  Produces: ML predictions

Team C: Business Analytics
  Consumes: Gold + Predictions
  Produces: Reports

Lineage enables:
  • Clear ownership boundaries
  • Dependency notifications
  • Change coordination
  • Shared understanding

Communication:
  "Team A changing Gold schema"
  → Lineage shows Team B, C impacted
  → Notify before change
  → Coordinate updates
```

## Reporting on Lineage

### Lineage Metrics

```
Track lineage health:

Coverage:
  # of assets with lineage / Total assets
  Target: 100% for critical paths

Completeness:
  # of column-level lineages / Total columns
  Target: 90%+ for sensitive data

Freshness:
  Last lineage update
  Should match last data update

Gaps:
  Assets with broken lineage
  Manual data movements
  External untracked sources
```

### Compliance Reports

```
For auditors:

Report: Sensitive Data Flow
  Shows: All PII columns
  Tracks: Source to final destination
  Documents: Who accessed
  Proves: Proper handling

Report: Data Retention
  Shows: Where data stored
  Tracks: Aging and deletion
  Documents: Compliance with policy

Report: Cross-Border Data
  Shows: Data geographic movement
  Tracks: Residency requirements
  Documents: GDPR compliance
```

## Points Clés

- Data lineage traces data from source to destination
- Fabric provides automatic lineage tracking within workspace
- Impact analysis: Understand downstream effects of changes
- Root cause analysis: Trace upstream to find data issues
- Column-level lineage for precise transformation tracking
- Purview extends lineage to external systems
- Best practices: Document, name descriptively, validate regularly
- Use lineage for change planning before modifications
- Avoid breaking lineage with manual steps
- Compliance: Prove data handling meets regulatory requirements

---

**Prochain fichier :** [07 - Sensitivity Labels](./07-sensitivity-labels.md)

[⬅️ Fichier précédent](./05-purview-integration.md) | [⬅️ Retour au README du module](./README.md)
