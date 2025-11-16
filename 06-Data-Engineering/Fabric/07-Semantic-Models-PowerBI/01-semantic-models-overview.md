# Semantic Models Overview

## Introduction

Les **Semantic Models** (anciennement appelés Datasets) sont la couche de modélisation de données dans Microsoft Fabric, permettant de créer des modèles business pour l'analyse et la visualisation.

```
Semantic Model Architecture:
┌──────────────────────────────────────────┐
│  Power BI Reports & Dashboards           │
├──────────────────────────────────────────┤
│  Semantic Model (Business Layer)         │
│  ├─ Tables & Columns                     │
│  ├─ Relationships                        │
│  ├─ Measures (DAX)                       │
│  ├─ Hierarchies                          │
│  └─ Security (RLS)                       │
├──────────────────────────────────────────┤
│  Data Sources                            │
│  ├─ Lakehouse (Direct Lake)              │
│  ├─ Data Warehouse (DirectQuery)         │
│  ├─ Dataflows                            │
│  └─ External sources (Import/DQ)         │
└──────────────────────────────────────────┘
```

## Évolution : Datasets → Semantic Models

### Terminologie

```
Power BI (Legacy)  →  Microsoft Fabric
──────────────────────────────────────────
Dataset            →  Semantic Model
Live Connection    →  Direct Lake
Composite Model    →  Composite Semantic Model
Dataflows          →  Dataflows Gen2
```

### Pourquoi "Semantic" ?

```
Le terme "Semantic Model" met l'accent sur:
✅ Business meaning (sémantique métier)
✅ Logic layer (couche de logique)
✅ Abstraction from raw data
✅ Self-service analytics

Pas juste des "données" (dataset), mais un
modèle qui donne du SENS aux données.
```

## Architecture des Modèles

### Composants

```
Semantic Model Components:
┌─────────────────────────────────────┐
│  Tables                             │
│  ├─ Dimension tables (Customer,     │
│  │   Product, Date)                 │
│  └─ Fact tables (Sales, Orders)     │
├─────────────────────────────────────┤
│  Relationships                      │
│  ├─ One-to-Many (1:*)               │
│  ├─ Many-to-One (*:1)               │
│  └─ Many-to-Many (*:*)              │
├─────────────────────────────────────┤
│  Measures (DAX)                     │
│  ├─ Total Sales                     │
│  ├─ Average Order Value             │
│  └─ YoY Growth %                    │
├─────────────────────────────────────┤
│  Calculated Columns                 │
│  └─ Extended columns (DAX)          │
├─────────────────────────────────────┤
│  Hierarchies                        │
│  └─ Country → Region → City         │
├─────────────────────────────────────┤
│  Security (RLS)                     │
│  └─ Row-level filters               │
└─────────────────────────────────────┘
```

### Storage Modes

**Import Mode:**
```
Data Flow:
Source → Import → VertiPaq Engine (in-memory)
         │
         └─ Compressed columnar storage
         └─ Super fast queries
         └─ Scheduled refresh required

Benefits:
  ✅ Fastest query performance
  ✅ Full DAX capabilities
  ✅ Offline access

Drawbacks:
  ❌ Data latency (refresh schedule)
  ❌ Size limitations
  ❌ Memory consumption
```

**DirectQuery Mode:**
```
Data Flow:
Source ← Query ← Power BI (on-demand)
         │
         └─ Live connection
         └─ No data import
         └─ Real-time data

Benefits:
  ✅ Real-time data
  ✅ No size limit
  ✅ Low memory footprint

Drawbacks:
  ❌ Slower queries (source dependent)
  ❌ Limited DAX support
  ❌ Source performance critical
```

**Direct Lake Mode** (Fabric exclusive):
```
Data Flow:
OneLake (Delta/Parquet) ← Direct read ← Power BI
         │
         └─ No copy, no query translation
         └─ Read Parquet files directly
         └─ Best of both worlds

Benefits:
  ✅ Import-like performance
  ✅ DirectQuery-like freshness
  ✅ No data movement
  ✅ Automatic refresh

Drawbacks:
  ❌ Requires OneLake Delta tables
  ❌ Some DAX limitations
```

## Types de Semantic Models

### Default Semantic Model

```
Automatic creation when you create:
  • Lakehouse
  • Data Warehouse

Default Semantic Model:
  ├─ All tables exposed
  ├─ Auto-detected relationships
  ├─ No custom measures
  ├─ Basic metadata
  └─ Read-only (cannot edit)

Use case:
  ✅ Quick exploration
  ✅ Simple reporting
  ❌ Not for production
```

**Exemple :**
```
When you create "Sales_Lakehouse":
  → Auto-creates "Sales_Lakehouse (default)"
  → Contains all tables from Lakehouse
  → Ready to use in Power BI
```

### Custom Semantic Model

```
User-created semantic model:
  ├─ Selected tables only
  ├─ Custom relationships
  ├─ DAX measures
  ├─ Calculated columns
  ├─ Hierarchies
  ├─ RLS (Row-Level Security)
  ├─ Metadata & documentation
  └─ Full control

Use case:
  ✅ Production models
  ✅ Complex business logic
  ✅ Security requirements
  ✅ Optimized for performance
```

**Creation :**
```
1. Workspace → + New → Semantic model
2. Choose data source:
   • Lakehouse
   • Data Warehouse
   • OneLake
   • External sources
3. Select tables
4. Configure model
5. Publish
```

## Création d'un Semantic Model

### Via UI

```
Step-by-step:
┌─────────────────────────────────────────┐
│ 1. Workspace → + New item               │
│ 2. Semantic model                       │
│ 3. Name: "Sales_Model"                  │
│ 4. Choose source:                       │
│    • Lakehouse: Direct Lake             │
│    • Warehouse: DirectQuery             │
│    • Other: Import/DirectQuery          │
│ 5. Select tables                        │
│ 6. Model view: Define relationships     │
│ 7. Add measures                         │
│ 8. Publish                              │
└─────────────────────────────────────────┘
```

### Model View

```
Power BI Desktop / Fabric Model View:
┌───────────────────────────────────────────┐
│  Tables Pane  │  Diagram View             │
│  ├─ Customers │  ┌──────┐    ┌─────────┐ │
│  ├─ Products  │  │Custor│───→│  Sales  │ │
│  ├─ Sales     │  │mers  │    │         │ │
│  └─ Date      │  └──────┘    └─────────┘ │
│               │       │           │       │
│  Measures     │       │      ┌────────┐  │
│  ├─ Total $   │       └─────→│Products│  │
│  ├─ Avg Order │              └────────┘  │
│  └─ YoY %     │                           │
└───────────────────────────────────────────┘
```

## Relation avec Power BI

### Power BI Service

```
Semantic Model in Power BI Service:
┌──────────────────────────────────────────┐
│  Workspace                               │
│  ├─ Semantic Model (Sales_Model)         │
│  │  ├─ Settings                          │
│  │  ├─ Refresh schedule                  │
│  │  ├─ Data source credentials           │
│  │  ├─ Parameters                        │
│  │  └─ Permissions                       │
│  │                                       │
│  ├─ Reports (use Sales_Model)            │
│  │  ├─ Executive Dashboard               │
│  │  ├─ Sales Analysis                    │
│  │  └─ Customer Insights                 │
│  │                                       │
│  └─ Dashboards (pin from reports)        │
└──────────────────────────────────────────┘
```

### Power BI Desktop

```
Connect to Semantic Model:
1. Power BI Desktop → Get Data
2. Power BI semantic models
3. Select workspace
4. Select semantic model
5. Live connection (read-only model)
6. Create reports on top
```

**Live Connection :**
```
Power BI Desktop (Live Connection)
         ↓ (queries)
Semantic Model in Fabric
         ↓ (data access)
Lakehouse / Warehouse / Source

Benefits:
  ✅ Single source of truth
  ✅ Consistent business logic
  ✅ No model duplication
  ✅ Centralized security
```

## Composants Détaillés

### Tables

```
Table Properties:
  • Name: "Customers"
  • Description: "Customer master data"
  • Hidden: False
  • Storage Mode: Direct Lake / Import / DirectQuery
  • Refresh policy: (for Import mode)
  • Columns: 15
  • Rows: 10,000
  • Size: 2 MB (compressed)
```

**Types de tables :**
```
Dimension Tables:
  • Customers
  • Products
  • Geography
  • Date (calendar table)
  • Lookup/reference tables

Fact Tables:
  • Sales
  • Orders
  • Transactions
  • Measurements

Calculated Tables (DAX):
  • Date table (CALENDAR function)
  • Custom aggregations
```

### Relationships

```
Relationship Definition:
  From: Sales[CustomerID]
  To: Customers[CustomerID]
  Cardinality: Many-to-One (*:1)
  Cross-filter direction: Single (to Sales)
  Active: Yes

Visual representation:
  Sales (*) ────→ (1) Customers
         │ CustomerID
```

### Measures (Mesures DAX)

```dax
-- Simple measure
Total Sales = SUM(Sales[Amount])

-- Complex measure
Sales YoY Growth =
VAR SalesThisYear = [Total Sales]
VAR SalesLastYear =
    CALCULATE(
        [Total Sales],
        SAMEPERIODLASTYEAR('Date'[Date])
    )
RETURN
DIVIDE(
    SalesThisYear - SalesLastYear,
    SalesLastYear,
    0
)
```

**Measure Organization:**
```
Measures Folder Structure:
  📁 Sales Measures
     └─ Total Sales
     └─ Sales Last Year
     └─ Sales YoY Growth %
  📁 Customer Measures
     └─ Total Customers
     └─ New Customers
     └─ Customer Lifetime Value
  📁 Product Measures
     └─ Total Products Sold
     └─ Average Unit Price
```

### Calculated Columns

```dax
-- Calculated column (computed row-by-row)
Sales[Profit] = Sales[Revenue] - Sales[Cost]

Sales[Year] = YEAR(Sales[OrderDate])

Sales[ProfitMargin] =
DIVIDE(
    Sales[Profit],
    Sales[Revenue],
    0
)
```

**Column vs Measure :**
```
Calculated Column:
  ✅ Computed once at refresh
  ✅ Stored in model
  ✅ Can be used as slicer/filter
  ❌ Increases model size
  ❌ Cannot be dynamic

Measure:
  ✅ Computed on-the-fly
  ✅ No storage impact
  ✅ Dynamic (context-aware)
  ❌ Cannot be used as slicer
  ❌ Slightly slower (recomputed)
```

### Hierarchies

```
Date Hierarchy:
  Year
   └─ Quarter
       └─ Month
           └─ Day

Geography Hierarchy:
  Country
   └─ Region
       └─ City
           └─ Postal Code

Product Hierarchy:
  Category
   └─ Subcategory
       └─ Product Name
```

**DAX for drill-down :**
```dax
Sales by Hierarchy Level =
SWITCH(
    TRUE(),
    ISINSCOPE('Date'[Day]), [Total Sales],
    ISINSCOPE('Date'[Month]), [Total Sales],
    ISINSCOPE('Date'[Quarter]), [Total Sales],
    ISINSCOPE('Date'[Year]), [Total Sales],
    BLANK()
)
```

## Metadata & Documentation

### Model Properties

```
Semantic Model Settings:
  • Name: "Enterprise Sales Model"
  • Description: "Comprehensive sales analytics model"
  • Owner: data-engineering@company.com
  • Tags: sales, finance, executive
  • Sensitivity: Confidential
  • Endorsement: Certified
  • Contact: Sales BI Team
  • Documentation: https://wiki.company/sales-model
```

### Table & Column Descriptions

```
Best practice: Document everything

Table: Customers
Description: "Customer master data from CRM.
             Updated daily at 2 AM UTC.
             Contains active and inactive customers."

Column: CustomerID
Description: "Unique customer identifier (primary key)"
Format: Integer
Example: 123456

Column: LifetimeValue
Description: "Total revenue from customer (all-time)"
Format: Currency (USD)
Calculation: SUM(Sales[Amount]) per customer
```

## Refresh & Scheduling

### Import Mode Refresh

```
Refresh Configuration:
  • Frequency: Daily
  • Time: 2:00 AM UTC
  • Retry: 3 times (10 min interval)
  • Notify on failure: Yes
  • Email: data-alerts@company.com
  • Incremental refresh: Yes (last 2 years)
```

### Direct Lake Refresh

```
Direct Lake = Automatic refresh

When underlying Delta table updates:
  → Semantic model reflects changes immediately
  → No manual refresh needed
  → Always fresh data

Exception: Metadata changes
  → Need manual "Refresh metadata"
  → (e.g., new columns, schema changes)
```

## Permissions & Security

### Model Permissions

```
Permission Levels:
┌────────────────────────────────────────┐
│  Admin                                 │
│  ├─ Full control                       │
│  ├─ Manage permissions                 │
│  └─ Delete model                       │
├────────────────────────────────────────┤
│  Member                                │
│  ├─ Edit model                         │
│  ├─ Refresh data                       │
│  └─ Create reports                     │
├────────────────────────────────────────┤
│  Contributor                           │
│  ├─ Create reports                     │
│  └─ Read data                          │
├────────────────────────────────────────┤
│  Viewer                                │
│  └─ Read data only                     │
└────────────────────────────────────────┘
```

### Row-Level Security (RLS)

```dax
-- RLS Role: "France Sales"
-- Filter: Show only France data
[Country] = "France"

-- RLS Role: "Manager - Region"
-- Dynamic filter based on user
[Region] = USERPRINCIPALNAME()

-- Or from security table
[SalesPersonEmail] = LOOKUPVALUE(
    SecurityTable[Email],
    SecurityTable[UserID],
    USERPRINCIPALNAME()
)
```

## Best Practices

### ✅ Model Design

```
1. Use star schema (dimension + fact tables)
2. One date dimension (avoid multiple date tables)
3. Minimize calculated columns (use measures)
4. Hide technical columns from users
5. Create measure folders for organization
6. Document tables, columns, measures
7. Use consistent naming conventions
```

### ✅ Performance

```
1. Choose right storage mode (Direct Lake preferred)
2. Remove unused columns/tables
3. Use integer keys (not strings)
4. Avoid bidirectional relationships
5. Test with Performance Analyzer
6. Monitor query performance
```

### ✅ Governance

```
1. Centralize semantic models (don't duplicate)
2. Apply endorsement (Promoted/Certified)
3. Implement RLS for security
4. Document business logic
5. Version control (via Tabular Editor + Git)
6. Regular model reviews
```

## Points Clés

- Semantic Models = business layer for analytics
- 3 storage modes: Import, DirectQuery, Direct Lake
- Direct Lake = Fabric's innovation (best of both)
- Components: tables, relationships, measures, hierarchies, RLS
- Default models (auto) vs Custom models (full control)
- Live connection enables single source of truth
- Document everything (tables, columns, measures)
- Use star schema for optimal performance
- Refresh: Manual (Import) vs Automatic (Direct Lake)

---

**Prochain fichier :** [02 - Direct Lake Mode](./02-direct-lake-mode.md)

[⬅️ Retour au README du module](./README.md)
