# Measures & Calculated Columns

## Introduction

Comprendre la différence entre **Measures** (mesures) et **Calculated Columns** (colonnes calculées) est fondamental pour créer des modèles performants dans Power BI.

```
Key Difference:
┌────────────────────────────────────────┐
│  Calculated Column                     │
│  ├─ Computed at refresh time           │
│  ├─ Stored in model                    │
│  └─ Row context                        │
├────────────────────────────────────────┤
│  Measure                               │
│  ├─ Computed at query time             │
│  ├─ Not stored (dynamic)               │
│  └─ Filter context                     │
└────────────────────────────────────────┘
```

## Différences Fondamentales

### Calculated Columns

**Definition:**
```dax
-- Calculated column (in Sales table)
Sales[Profit] = Sales[Revenue] - Sales[Cost]

Sales[Year] = YEAR(Sales[OrderDate])

Sales[Full Name] = Sales[FirstName] & " " & Sales[LastName]
```

**Characteristics:**
```
✅ Row-by-row calculation
✅ Computed once at data refresh
✅ Stored in model (increases size)
✅ Available for slicers/filters
✅ Can be used in relationships
✅ Uses row context

❌ Not dynamic (fixed at refresh)
❌ Increases model size
❌ Slower refresh for large tables
❌ Cannot reference measures
```

### Measures

**Definition:**
```dax
-- Measure (not tied to table, but usually in dedicated table)
Total Sales = SUM(Sales[Amount])

Average Sale = AVERAGE(Sales[Amount])

YoY Growth =
DIVIDE(
    [Total Sales] - [Sales Last Year],
    [Sales Last Year],
    0
)
```

**Characteristics:**
```
✅ Computed on-the-fly at query time
✅ No storage impact (not persisted)
✅ Dynamic (context-aware)
✅ Can reference other measures
✅ Aggregation-optimized
✅ Uses filter context

❌ Cannot be used in slicers/filters
❌ Slightly slower (recomputed each time)
❌ Cannot be used in relationships
```

## Contexte: Row vs Filter

### Row Context

```
Row Context = Current row being evaluated

Used by:
  • Calculated columns
  • Iterator functions (SUMX, FILTER, etc.)

Example:
  Sales[Profit] = Sales[Revenue] - Sales[Cost]

  For each row in Sales:
    Row 1: Profit = Revenue[Row1] - Cost[Row1]
    Row 2: Profit = Revenue[Row2] - Cost[Row2]
    ...
```

### Filter Context

```
Filter Context = Active filters from report/slicers

Used by:
  • Measures
  • Aggregation functions (SUM, COUNT, etc.)

Example:
  Total Sales = SUM(Sales[Amount])

  User selects:
    - Country: France
    - Year: 2024

  Filter context = {Country=France, Year=2024}
  → SUM only rows matching filters
```

### Context Transition

```dax
-- Calculated column with measure (context transition)
Sales[Customer Total Sales] =
CALCULATE([Total Sales])  -- CALCULATE creates filter context

-- Without CALCULATE (error):
Sales[Customer Total Sales] =
[Total Sales]  -- ❌ Measure needs filter context
```

## Quand Utiliser Quoi ?

### Use Calculated Column When

```
✅ Need to filter/slice by value
Example:
  Sales[Year] = YEAR(Sales[OrderDate])
  → Use as slicer to filter by year

✅ Need in relationship
Example:
  Sales[CustomerKey] = RELATED(Dim_Customer[CustomerKey])
  → Use to create relationship

✅ Static categorization
Example:
  Sales[Price Category] =
  IF(Sales[Amount] < 50, "Low",
     IF(Sales[Amount] < 200, "Medium", "High"))
  → Category doesn't change with filters

✅ Row-level calculation (not aggregation)
Example:
  Sales[Tax] = Sales[Amount] * 0.20
```

### Use Measure When

```
✅ Aggregation (SUM, COUNT, AVG)
Example:
  Total Sales = SUM(Sales[Amount])

✅ Dynamic calculation
Example:
  % of Total = DIVIDE([Sales], CALCULATE([Sales], ALL(Sales)))
  → Changes based on filters

✅ Time intelligence
Example:
  Sales YoY = [Sales] - CALCULATE([Sales], SAMEPERIODLASTYEAR('Date'[Date]))

✅ Complex business logic
Example:
  Weighted Average Price =
  SUMX(Sales, Sales[Quantity] * Sales[Price]) / SUM(Sales[Quantity])

✅ Performance critical
  → Measures don't increase model size
  → Calculated at query time (optimized)
```

## Impact sur la Performance

### Storage Impact

```
Calculated Column:
  Table: Sales (10M rows)
  New column: Profit (8 bytes per row)
  Storage increase: 10M × 8 = 80 MB (uncompressed)
  Compressed: ~8 MB (10:1 ratio typical)

  Impact:
    ❌ Larger model size
    ❌ Longer refresh time
    ❌ More memory consumption

Measure:
  Storage: 0 bytes (not stored)
  Computed on-demand

  Impact:
    ✅ No model size increase
    ✅ No refresh impact
    ✅ No memory impact
```

### Query Performance

```
Calculated Column:
  ✅ Fast (pre-computed)
  ✅ Already materialized
  ❌ But increases overall model size

Measure:
  ⚠️ Computed on-the-fly
  ✅ VertiPaq engine optimized
  ✅ Formula engine caching
  → Usually fast enough

Recommendation:
  Prefer measures for aggregations
  Use calculated columns only when necessary
```

## Mesures Simples

### Basic Aggregations

```dax
-- Sum
Total Sales = SUM(Sales[Amount])

Total Quantity = SUM(Sales[Quantity])

-- Count
Order Count = COUNTROWS(Sales)

-- Distinct count
Unique Customers = DISTINCTCOUNT(Sales[CustomerID])

Unique Products = DISTINCTCOUNT(Sales[ProductID])

-- Average
Average Sale = AVERAGE(Sales[Amount])

Average Order Value =
DIVIDE(
    SUM(Sales[Amount]),
    DISTINCTCOUNT(Sales[OrderID]),
    0
)

-- Min/Max
Earliest Order = MIN(Sales[OrderDate])

Latest Order = MAX(Sales[OrderDate])

Lowest Price = MIN(Product[Price])

Highest Price = MAX(Product[Price])
```

### Conditional Aggregations

```dax
-- Count with condition
High Value Orders =
COUNTROWS(
    FILTER(
        Sales,
        Sales[Amount] > 1000
    )
)

-- Or simpler:
High Value Orders =
CALCULATE(
    COUNTROWS(Sales),
    Sales[Amount] > 1000
)

-- Sum with multiple conditions
Premium Sales France =
CALCULATE(
    SUM(Sales[Amount]),
    Product[Category] = "Premium",
    Customer[Country] = "France"
)
```

## Mesures Complexes

### Multi-Step Calculations

```dax
-- Customer Lifetime Value
Customer LTV =
VAR CustomerSales =
    CALCULATE(
        SUM(Sales[Amount]),
        ALLEXCEPT(Sales, Sales[CustomerID])
    )
VAR CustomerOrders =
    CALCULATE(
        COUNTROWS(Sales),
        ALLEXCEPT(Sales, Sales[CustomerID])
    )
VAR AvgOrderValue = DIVIDE(CustomerSales, CustomerOrders, 0)
VAR EstimatedLifetimeOrders = 10  -- Assumption
RETURN
    AvgOrderValue * EstimatedLifetimeOrders
```

### Nested Aggregations

```dax
-- Average Daily Sales
Avg Daily Sales =
AVERAGEX(
    VALUES('Date'[Date]),
    [Total Sales]
)

-- Max Monthly Sales
Max Monthly Sales =
MAXX(
    VALUES('Date'[YearMonth]),
    [Total Sales]
)

-- Count of Customers with >5 Orders
Active Customers =
COUNTROWS(
    FILTER(
        VALUES(Customer[CustomerID]),
        CALCULATE(COUNTROWS(Sales)) > 5
    )
)
```

## Measure Groups

### Organization

```
Create Display Folders for better organization:

📁 _Base Measures
   └─ Total Sales
   └─ Total Quantity
   └─ Order Count

📁 Sales Analysis
   └─ Sales Last Year
   └─ Sales YoY Growth
   └─ Sales YoY Growth %

📁 Customer Metrics
   └─ Total Customers
   └─ New Customers
   └─ Customer Lifetime Value
   └─ Customer Retention Rate

📁 Product Analysis
   └─ Total Products Sold
   └─ Average Unit Price
   └─ Best Selling Product

📁 _Calculations (Hidden)
   └─ _Helper Measure 1
   └─ _Helper Measure 2
```

### Base Measures

```dax
-- Create reusable base measures
-- Prefix with underscore to indicate "base"
_Total Sales = SUM(Sales[Amount])

_Total Quantity = SUM(Sales[Quantity])

_Order Count = COUNTROWS(Sales)

_Customer Count = DISTINCTCOUNT(Sales[CustomerID])

-- Then build on top:
Average Order Value =
DIVIDE(
    [_Total Sales],
    [_Order Count],
    0
)

Sales per Customer =
DIVIDE(
    [_Total Sales],
    [_Customer Count],
    0
)
```

## Format Strings

### Numeric Formats

```dax
-- Currency
Total Sales = SUM(Sales[Amount])
-- Format string: $#,##0.00

-- Percentage
Growth Rate = DIVIDE([Sales This Year] - [Sales Last Year], [Sales Last Year])
-- Format string: 0.00%

-- Number with decimals
Average Price = AVERAGE(Product[Price])
-- Format string: #,##0.00

-- Whole number
Order Count = COUNTROWS(Sales)
-- Format string: #,##0

-- Abbreviated (K, M, B)
Sales Abbreviated = [Total Sales]
-- Format string: $0.0,,"M"  (Shows 1,500,000 as $1.5M)
```

### Dynamic Format Strings

```dax
-- Dynamic format based on value (requires DAX expression)
Sales Formatted =
VAR Value = [Total Sales]
RETURN
    SWITCH(
        TRUE(),
        Value >= 1000000000, FORMAT(Value / 1000000000, "$#,##0.0") & "B",
        Value >= 1000000, FORMAT(Value / 1000000, "$#,##0.0") & "M",
        Value >= 1000, FORMAT(Value / 1000, "$#,##0.0") & "K",
        FORMAT(Value, "$#,##0")
    )

-- Examples:
-- 2,500,000,000 → $2.5B
-- 1,500,000 → $1.5M
-- 25,000 → $25.0K
-- 500 → $500
```

## Description et Documentation

### Measure Description

```
In Power BI Desktop:
1. Select measure
2. Properties pane → Description
3. Enter detailed description

Example:
  Name: Sales YoY Growth %
  Description:
    "Year-over-year sales growth percentage.
     Compares current period sales to same period last year.
     Returns BLANK if last year has no data.
     Formula: (Current - Last Year) / Last Year"

Benefits:
  ✅ Self-documenting model
  ✅ Helps other developers
  ✅ Visible in tooltip
  ✅ Searchable
```

### Commenting DAX

```dax
-- Complex measure with comments
Customer Churn Rate =
/*
  Calculates monthly customer churn rate
  Churn = Customers who made purchases last month but not this month
  Formula: Churned Customers / Active Customers Last Month
*/
VAR LastMonth =
    CALCULATE(
        VALUES(Customer[CustomerID]),
        DATEADD('Date'[Date], -1, MONTH)
    )
VAR ThisMonth =
    VALUES(Customer[CustomerID])
VAR ChurnedCustomers =
    COUNTROWS(
        EXCEPT(LastMonth, ThisMonth)  -- In last month but not this month
    )
VAR ActiveLastMonth =
    COUNTROWS(LastMonth)
RETURN
    DIVIDE(ChurnedCustomers, ActiveLastMonth, 0)
```

## Best Practices

### ✅ Naming Conventions

```dax
-- ✅ Good: Clear, descriptive names
Total Sales = SUM(Sales[Amount])
Sales Year over Year Growth % = ...
Average Customer Lifetime Value = ...

-- ❌ Bad: Abbreviations, unclear
TotSls = SUM(Sales[Amount])
SYOY = ...
ACLV = ...
```

### ✅ Measure vs Calculated Column

```dax
-- ❌ Bad: Calculated column for aggregation
Sales[Total Sales] = SUM(Sales[Amount])  -- Wrong! This is measure logic

-- ✅ Good: Measure for aggregation
Total Sales = SUM(Sales[Amount])

-- ❌ Bad: Measure for static value
Product Category = RELATED(Product[Category])  -- Should be calc column

-- ✅ Good: Calculated column for static reference
Product[Category] = RELATED(Dim_Product[Category])
```

### ✅ Use Base Measures

```dax
-- ✅ Good: Reusable base measures
_Total Sales = SUM(Sales[Amount])
_Order Count = COUNTROWS(Sales)

Average Order Value = DIVIDE([_Total Sales], [_Order Count], 0)
Sales per Day = DIVIDE([_Total Sales], COUNTROWS('Date'), 0)

-- ❌ Bad: Repeat SUM(Sales[Amount]) everywhere
Average Order Value = DIVIDE(SUM(Sales[Amount]), COUNTROWS(Sales), 0)
Sales per Day = DIVIDE(SUM(Sales[Amount]), COUNTROWS('Date'), 0)
```

### ✅ Hide Helper Measures

```
Hidden measures (for internal use):
  _Total Sales (base)
  _Customer Count (base)
  _Helper Calculation 1
  _Intermediate Result

Visible measures (for end users):
  Total Sales
  Average Order Value
  Customer Lifetime Value

Naming:
  • Prefix with _ for base/helper measures
  • Hide from client tools
  • Document purpose in description
```

### ✅ Test Incrementally

```dax
-- Build complex measures step-by-step
-- Step 1: Base calculation
Test Step 1 = SUM(Sales[Amount])

-- Step 2: Add filter
Test Step 2 = CALCULATE([Test Step 1], Sales[Country] = "France")

-- Step 3: Add comparison
Test Step 3 = [Test Step 2] - [Sales Last Year]

-- Step 4: Add percentage
Test Step 4 = DIVIDE([Test Step 3], [Sales Last Year], 0)

-- Final: Rename and clean up
Sales YoY Growth % = [Test Step 4]
-- Delete test measures
```

## Common Patterns

### Running Totals

```dax
-- Running Total Sales
Sales Running Total =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL('Date'),
        'Date'[Date] <= MAX('Date'[Date])
    )
)
```

### Rank

```dax
-- Product Rank by Sales
Product Rank =
RANKX(
    ALL(Product[Name]),
    [Total Sales],
    ,
    DESC,
    DENSE
)
```

### Same Period Last Year

```dax
-- Sales Same Period Last Year
Sales SPLY =
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR('Date'[Date])
)
```

## Points Clés

- Calculated Column: row context, stored, computed at refresh
- Measure: filter context, not stored, computed at query time
- Prefer measures for aggregations (better performance, no storage)
- Use calculated columns only when needed (filters, relationships)
- Organize measures in display folders
- Create reusable base measures
- Format measures appropriately (currency, percentage)
- Document complex measures with descriptions
- Hide helper/internal measures from end users
- Test complex measures incrementally
- Use clear naming conventions

---

**Prochain fichier :** [08 - Relationships & Cardinality](./08-relationships-cardinality.md)

[⬅️ Fichier précédent](./06-dax-calculate-filter.md) | [⬅️ Retour au README du module](./README.md)
