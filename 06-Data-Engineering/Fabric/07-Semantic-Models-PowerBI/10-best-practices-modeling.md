# Best Practices de Modélisation

## Introduction

Ce fichier résume les meilleures pratiques pour concevoir des modèles sémantiques Power BI performants, maintenables, et sécurisés.

```
Best Practices Framework:
┌─────────────────────────────────────────┐
│  1. Architecture & Design               │
│  2. Performance Optimization            │
│  3. Security (RLS)                      │
│  4. Documentation & Maintenance         │
│  5. Testing & Validation                │
└─────────────────────────────────────────┘
```

## Architecture Optimale

### Star Schema

```
✅ Always use star schema for BI models

Structure:
  • Fact tables (center): Transactions, events, measures
  • Dimension tables (points): Descriptive attributes
  • Relationships: One-to-Many (Dim → Fact)

Benefits:
  ✅ Simple to understand
  ✅ Optimal query performance
  ✅ Easy filtering and slicing
  ✅ Predictable filter behavior

Example:
       Dim_Date
          │ 1
          ▼
Dim_Customer ← (*) Fact_Sales (*) → Dim_Product
```

### Avoid Snowflake

```
❌ Don't normalize dimensions in Power BI

Bad (Snowflake):
  Product → Category → Subcategory → Brand

Good (Star):
  Product (denormalized with Category, Subcategory, Brand columns)

Reasons:
  ❌ Snowflake: More joins, slower queries
  ✅ Star: Single join, faster queries
```

### Single Date Table

```
✅ Use one date dimension table for all dates

Structure:
  Dim_Date table with all calendar attributes

Relationships:
  Sales[OrderDateKey] → Date[DateKey] (Active)
  Sales[ShipDateKey] → Date[DateKey] (Inactive)
  Sales[DueDateKey] → Date[DateKey] (Inactive)

Benefits:
  ✅ Consistent time intelligence
  ✅ Single source for calendar logic
  ✅ Smaller model (one table, not three)

DAX:
  Mark date table:
    Table tools → Mark as date table → Date column
```

## Normalisation vs Dénormalisation

### When to Denormalize

```
✅ Denormalize for BI models:
  • Flatten dimension hierarchies
  • Merge related attributes
  • Reduce table count

Example:
  Before: Customer → Address → City → Country
  After: Customer (with City, Country columns)

Benefits:
  ✅ Faster queries (fewer joins)
  ✅ Simpler model
  ✅ Better compression (VertiPaq)
```

### When to Keep Separate

```
✅ Keep separate tables when:
  • Many-to-many relationship needed
  • Security requires isolation
  • Reusable dimension (multiple facts)

Example:
  Dim_Date used by multiple facts
  Dim_Customer shared across Sales and Support

Don't merge:
  ❌ Fact tables with dimensions
  ❌ Different granularity facts
```

## Granularité des Tables de Fait

### Define Grain

```
Grain = Level of detail in fact table

Examples:
  • Transaction level: One row per order line
  • Daily level: One row per day
  • Monthly level: One row per month

Choose based on:
  ✅ Business requirements (what analysis needed?)
  ✅ Data volume (can model handle it?)
  ✅ Performance (too detailed = slow)

Rule:
  Use finest grain that meets requirements
  Don't over-detail if not needed
```

### Aggregation Tables

```
For very large datasets, create aggregation tables:

Detail table:
  Fact_Sales_Detail: 1 billion rows (by transaction)

Aggregation tables:
  Fact_Sales_Daily: 100 million rows (by day)
  Fact_Sales_Monthly: 5 million rows (by month)
  Fact_Sales_Yearly: 60K rows (by year)

Power BI automatically routes queries to best level
  • Summary visual → Uses aggregated table (fast)
  • Drill-down → Uses detail table (slower but available)
```

## Hiérarchies et Drill-down

### Creating Hierarchies

```
Define natural hierarchies:

Date Hierarchy:
  Year → Quarter → Month → Day

Geography Hierarchy:
  Country → Region → City

Product Hierarchy:
  Category → Subcategory → Product Name

Benefits:
  ✅ Easy drill-down in reports
  ✅ Consistent navigation
  ✅ Better user experience
```

### Hierarchy Best Practices

```
✅ Use meaningful levels:
  Year → Month → Day (logical progression)

❌ Avoid skipping levels:
  Year → Day (skips month, confusing)

✅ Balanced hierarchies:
  Each level has children
  No "orphan" branches

✅ Single path:
  Each child has one parent
  No circular references
```

## Sécurité (RLS - Row Level Security)

### What is RLS

```
RLS = Row-Level Security

Purpose:
  • Restrict data access based on user
  • France users see only France data
  • Managers see their team's data only

Implementation:
  1. Define roles
  2. Create filter expressions (DAX)
  3. Assign users to roles
```

### Static RLS

```dax
-- Static RLS: Fixed filter
-- Role: "France Sales"
[Country] = "France"

-- Users in this role only see France data
-- Simple to implement
-- One role per region/category
```

### Dynamic RLS

```dax
-- Dynamic RLS: User-based filter
-- Role: "Regional Managers"
[RegionManager] = USERPRINCIPALNAME()

-- Or lookup from security table:
[Region] IN
VALUES(
    FILTER(
        SecurityTable,
        SecurityTable[UserEmail] = USERPRINCIPALNAME()
    )[Region]
)

-- Users see only their assigned data
-- Scales better than static (one role for all)
```

### Testing RLS

```
Power BI Desktop:
1. Modeling tab → View as
2. Select role to test
3. See data filtered as that role

Power BI Service:
1. Dataset settings → Security
2. Test as specific user
3. Verify correct filtering

Important:
  ✅ Test with actual users
  ✅ Verify no data leakage
  ✅ Document roles and permissions
```

## Documentation du Modèle

### Table Descriptions

```
Add descriptions to all tables:

Table: Fact_Sales
Description:
  "Daily sales transactions.
   Granularity: One row per order line item.
   Source: ERP Sales module (updated daily 2 AM UTC).
   Key measures: Amount, Quantity, Profit.
   Partitioned by OrderDate (monthly)."

Benefits:
  ✅ Self-documenting model
  ✅ Helps other developers
  ✅ Assists business users
```

### Column Descriptions

```
Document important columns:

Column: CustomerKey
Description:
  "Surrogate key for customer dimension.
   Integer (4 bytes) for optimal join performance.
   References Dim_Customer[CustomerKey].
   Never expose to end users (use CustomerID instead)."

Column: Amount
Description:
  "Net sales amount in USD.
   Excludes tax and shipping.
   Additive measure (can SUM across all dimensions).
   Format: Currency with 2 decimals."
```

### Measure Descriptions

```
Document all measures:

Measure: Sales YoY Growth %
Description:
  "Year-over-year sales growth percentage.
   Compares current period to same period last year.
   Formula: (Current - Previous) / Previous
   Returns BLANK if no prior year data.
   Format: Percentage with 1 decimal."

DAX:
  // Year-over-year growth percentage
  VAR CurrentYear = [Total Sales]
  VAR PreviousYear = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))
  RETURN DIVIDE(CurrentYear - PreviousYear, PreviousYear, BLANK())
```

## Naming Conventions

### Tables

```
✅ Consistent prefixes:
  Fact_Sales, Fact_Orders, Fact_Inventory
  Dim_Customer, Dim_Product, Dim_Date

✅ Clear names:
  Fact_Sales (not F_Sales or Sales_Fact)
  Dim_Customer (not D_Customer or Customer_Dim)

✅ Avoid spaces:
  Dim_Customer (not "Dim Customer" or "Customer Dimension")
  Easier to reference in DAX
```

### Columns

```
✅ Descriptive names:
  CustomerKey (not CustKey or CK)
  OrderDate (not OrdDt or Date1)
  ProductCategory (not ProdCat)

✅ Consistent casing:
  PascalCase: CustomerKey, OrderDate, TotalAmount
  Or: customer_key, order_date, total_amount

✅ Avoid abbreviations:
  CustomerID (not CustID)
  ProductName (not ProdNm)
```

### Measures

```
✅ Action-oriented names:
  Total Sales (describes result)
  Average Order Value (clear meaning)
  Sales YoY Growth % (includes unit)

✅ Group by function:
  📁 Base Measures
     └─ _Total Sales (underscore for base)
  📁 Sales Analysis
     └─ Sales Last Year
     └─ Sales YoY Growth %

✅ Include units in name:
  Sales YoY Growth % (percentage)
  Average Order Value $ (currency)
  Order Count # (count)
```

## Testing et Validation

### Data Validation

```sql
-- Verify row counts match source
SELECT COUNT(*) FROM Sales;
-- Lakehouse: 10,500,000 rows

-- Compare to Power BI:
Total Rows = COUNTROWS(Sales)
-- Should equal: 10,500,000

-- Verify totals match source
SELECT SUM(Amount) FROM Sales;
-- Source: $125,432,567.89

-- Power BI:
Total Sales = SUM(Sales[Amount])
-- Should equal: $125,432,567.89
```

### Cross-Validation

```
1. Compare to source system reports
   • Match known KPIs
   • Verify historical data

2. Test edge cases
   • Null values handled correctly
   • Zero values (no division errors)
   • Extreme values (outliers)

3. Validate relationships
   • All foreign keys match
   • No orphan records
   • Cardinality correct
```

### User Acceptance Testing

```
Checklist:
  ✅ Business users validate results
  ✅ Numbers match expectations
  ✅ Filters work correctly
  ✅ RLS enforced properly
  ✅ Performance acceptable
  ✅ Documentation clear

Sign-off:
  Get formal approval before production
  Document any known limitations
```

## Maintenance

### Regular Tasks

```
Weekly:
  • Monitor refresh times
  • Check for failures
  • Review error logs

Monthly:
  • Performance review (slow queries)
  • Model size check
  • User feedback collection

Quarterly:
  • Model optimization (remove unused)
  • Security audit (RLS roles)
  • Documentation update
```

### Change Management

```
1. Version control
   • Use Git for .pbix files (limited support)
   • Use Tabular Editor for better versioning
   • Document all changes

2. Test environment
   • Develop → Test → Production
   • Never push directly to production
   • User testing in Test environment

3. Deployment
   • Scheduled deployment windows
   • Notify users of changes
   • Rollback plan if issues
```

### Performance Monitoring

```
Track over time:
  • Query durations (should stay stable)
  • Model size (watch for growth)
  • Refresh times (should not increase dramatically)
  • User complaints (increasing = investigate)

Alerts:
  • Refresh failure → Email notification
  • Query > 10 seconds → Investigate
  • Model size > threshold → Optimize

Tools:
  • Power BI Capacity Metrics app
  • Performance Analyzer (regular checks)
  • DAX Studio (detailed analysis)
```

## Summary Checklist

### Before Production

```
✅ Architecture
  [ ] Star schema implemented
  [ ] Single date dimension table
  [ ] Denormalized dimensions
  [ ] Appropriate grain for facts

✅ Performance
  [ ] < 3 second page load
  [ ] < 1 second per visual
  [ ] Model size optimized
  [ ] Aggregation tables (if large data)

✅ Security
  [ ] RLS roles defined
  [ ] RLS tested with actual users
  [ ] No data leakage
  [ ] Permissions documented

✅ Documentation
  [ ] Table descriptions
  [ ] Column descriptions
  [ ] Measure descriptions
  [ ] Naming conventions followed

✅ Testing
  [ ] Data validation (source match)
  [ ] Cross-validation (KPIs match)
  [ ] Edge cases tested
  [ ] User acceptance signed off

✅ Maintenance Plan
  [ ] Monitoring setup
  [ ] Refresh schedule configured
  [ ] Change management process
  [ ] Support contacts defined
```

## Points Clés

- Use star schema (fact + dimension tables, one-to-many relationships)
- Denormalize dimensions for Power BI (no snowflaking)
- Single date table with multiple inactive relationships
- Define grain carefully (finest that meets requirements)
- Create aggregation tables for large datasets
- Implement RLS (static or dynamic) for security
- Document everything (tables, columns, measures)
- Follow naming conventions consistently
- Test thoroughly (data validation, user acceptance)
- Monitor and maintain regularly

**Module 07 complet!** Vous maîtrisez maintenant les Semantic Models, DAX, et les best practices de modélisation Power BI.

---

[⬅️ Fichier précédent](./09-performance-analyzer.md) | [⬅️ Retour au README du module](./README.md)
