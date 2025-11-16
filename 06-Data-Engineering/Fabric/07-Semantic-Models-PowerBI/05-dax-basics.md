# DAX Basics

## Introduction

**DAX (Data Analysis Expressions)** est le langage de formule utilisé dans Power BI, Analysis Services, et Power Pivot pour créer des calculs personnalisés.

```
DAX Purpose:
┌──────────────────────────────────────┐
│  Measures (Calculated metrics)       │
│  └─ Total Sales, YoY Growth, etc.    │
├──────────────────────────────────────┤
│  Calculated Columns                  │
│  └─ Extended table columns           │
├──────────────────────────────────────┤
│  Calculated Tables                   │
│  └─ Date table, parameter tables     │
├──────────────────────────────────────┤
│  Row-Level Security (RLS)            │
│  └─ Filter expressions               │
└──────────────────────────────────────┘
```

## Syntaxe de Base

### Structure d'une Mesure

```dax
Measure Name =
  Expression

-- Example
Total Sales = SUM(Sales[Amount])

-- With formatting
Total Sales =
FORMAT(
    SUM(Sales[Amount]),
    "$#,##0.00"
)
```

### Commentaires

```dax
-- Single line comment
Total Sales = SUM(Sales[Amount])  -- Inline comment

/*
  Multi-line comment
  Used for longer explanations
*/
Average Sale =
DIVIDE(
    SUM(Sales[Amount]),  -- Numerator
    COUNTROWS(Sales),    -- Denominator
    0                    -- Default if division by zero
)
```

### Références

```dax
-- Column reference
Sales[Amount]  -- Column 'Amount' in table 'Sales'

-- Table reference
Sales  -- Entire 'Sales' table

-- Measure reference
[Total Sales]  -- Measure named 'Total Sales'
'Measures'[Total Sales]  -- Explicit table reference (optional)

-- Fully qualified
'Sales'[Amount]  -- Explicit table name
```

## Colonnes Calculées vs Mesures

### Colonnes Calculées (Calculated Columns)

```dax
-- Calculated column (row context)
-- Computed once at data refresh
Sales[Profit] = Sales[Revenue] - Sales[Cost]

Sales[Year] = YEAR(Sales[OrderDate])

Sales[Full Name] = Sales[FirstName] & " " & Sales[LastName]

Sales[Profit Margin] =
DIVIDE(
    Sales[Profit],
    Sales[Revenue],
    0
)
```

**Caractéristiques :**
```
✅ Stored in model (increases size)
✅ Computed at refresh time
✅ Can be used in slicers/filters
✅ Row-by-row calculation
❌ Increases model size
❌ Cannot be dynamic
❌ Slower refresh for large tables
```

### Mesures (Measures)

```dax
-- Measure (filter context)
-- Computed on-the-fly at query time
Total Sales = SUM(Sales[Amount])

Average Sale =
AVERAGE(Sales[Amount])

Sales Count = COUNTROWS(Sales)

Total Profit =
SUMX(
    Sales,
    Sales[Revenue] - Sales[Cost]
)
```

**Caractéristiques :**
```
✅ No storage impact (computed on-demand)
✅ Dynamic (context-aware)
✅ Can reference other measures
✅ Efficient for aggregations
❌ Cannot be used in slicers
❌ Slightly slower (recomputed)
❌ Cannot create calculated columns from measures
```

### Quand Utiliser Quoi ?

```
Use Calculated Column when:
  ✅ Need to filter/slice by value
  ✅ Static calculation (doesn't change)
  ✅ Row-level computation
  ✅ Small tables (< 100K rows)

Example: Sales[Year], Product[Category]

Use Measure when:
  ✅ Aggregation (SUM, COUNT, AVG)
  ✅ Dynamic calculation (context-dependent)
  ✅ Complex business logic
  ✅ Performance critical

Example: Total Sales, YoY Growth, Market Share
```

## Variables (VAR)

### Syntaxe

```dax
Sales YoY Growth =
VAR SalesThisYear = [Total Sales]
VAR SalesLastYear =
    CALCULATE(
        [Total Sales],
        DATEADD('Date'[Date], -1, YEAR)
    )
VAR GrowthAmount = SalesThisYear - SalesLastYear
VAR GrowthPct = DIVIDE(GrowthAmount, SalesLastYear, 0)
RETURN
    GrowthPct
```

### Benefits

```
✅ Readability
  • Break complex formulas into steps
  • Self-documenting code
  • Easier to maintain

✅ Performance
  • Compute once, reuse multiple times
  • Avoid redundant calculations
  • Optimize query plan

✅ Debugging
  • Test intermediate results
  • Identify errors faster
  • Comment out sections
```

### Example

```dax
-- ❌ Bad: Repeated calculation
Profit Margin =
DIVIDE(
    SUM(Sales[Revenue]) - SUM(Sales[Cost]),
    SUM(Sales[Revenue]),
    0
)

-- ✅ Good: Use variables
Profit Margin =
VAR Revenue = SUM(Sales[Revenue])
VAR Cost = SUM(Sales[Cost])
VAR Profit = Revenue - Cost
RETURN
    DIVIDE(Profit, Revenue, 0)
```

## Fonctions de Base

### Aggregation Functions

**SUM:**
```dax
Total Sales = SUM(Sales[Amount])

Total Quantity = SUM(Sales[Quantity])
```

**AVERAGE:**
```dax
Average Sale = AVERAGE(Sales[Amount])

Average Order Value =
DIVIDE(
    SUM(Sales[Amount]),
    DISTINCTCOUNT(Sales[OrderID]),
    0
)
```

**COUNT and COUNTROWS:**
```dax
-- COUNT: Count non-blank values in column
Customer Count = COUNT(Sales[CustomerID])

-- COUNTROWS: Count all rows in table
Order Count = COUNTROWS(Sales)

-- DISTINCTCOUNT: Count unique values
Unique Customers = DISTINCTCOUNT(Sales[CustomerID])
```

**MIN and MAX:**
```dax
Earliest Order = MIN(Sales[OrderDate])

Latest Order = MAX(Sales[OrderDate])

Lowest Price = MIN(Product[Price])

Highest Price = MAX(Product[Price])
```

### DIVIDE Function

```dax
-- DIVIDE: Safe division (handles division by zero)
Profit Margin =
DIVIDE(
    [Total Profit],
    [Total Sales],
    0  -- Default value if division by zero
)

-- Without DIVIDE (can error)
Profit Margin = [Total Profit] / [Total Sales]  -- ❌ Error if Total Sales = 0

-- Equivalent IF version (verbose)
Profit Margin =
IF(
    [Total Sales] <> 0,
    [Total Profit] / [Total Sales],
    0
)
```

**Best Practice:**
```
✅ Always use DIVIDE for division
✅ Specify alternate result (default = BLANK())
✅ Avoid division by zero errors
```

### IF Function

```dax
-- Simple IF
Status =
IF(
    Sales[Amount] > 1000,
    "High",
    "Low"
)

-- Nested IF
Segment =
IF(
    [Total Sales] > 10000,
    "VIP",
    IF(
        [Total Sales] > 5000,
        "Premium",
        IF(
            [Total Sales] > 1000,
            "Regular",
            "Basic"
        )
    )
)

-- IF with measures
Sales Performance =
IF(
    [Total Sales] > [Sales Target],
    "Above Target",
    "Below Target"
)
```

### SWITCH Function

```dax
-- SWITCH: Better than nested IF
Segment =
SWITCH(
    TRUE(),
    [Total Sales] > 10000, "VIP",
    [Total Sales] > 5000, "Premium",
    [Total Sales] > 1000, "Regular",
    "Basic"  -- Default
)

-- SWITCH on value
Day Name Short =
SWITCH(
    WEEKDAY('Date'[Date]),
    1, "Sun",
    2, "Mon",
    3, "Tue",
    4, "Wed",
    5, "Thu",
    6, "Fri",
    7, "Sat",
    "Unknown"
)
```

## Date Functions

### Basic Date Functions

```dax
-- YEAR, MONTH, DAY
Year = YEAR('Date'[Date])

Month Number = MONTH('Date'[Date])

Day of Month = DAY('Date'[Date])

Quarter = QUARTER('Date'[Date])

-- WEEKDAY (1=Sunday, 7=Saturday)
Day of Week = WEEKDAY('Date'[Date])

-- FORMAT
Month Name = FORMAT('Date'[Date], "MMMM")  -- January
Month Short = FORMAT('Date'[Date], "MMM")   -- Jan
Date Formatted = FORMAT('Date'[Date], "DD/MM/YYYY")
```

### Date Calculations

```dax
-- DATEDIFF: Difference between dates
Days Since Order =
DATEDIFF(
    Sales[OrderDate],
    TODAY(),
    DAY
)

Months Since Start =
DATEDIFF(
    DATE(2024, 1, 1),
    TODAY(),
    MONTH
)

-- TODAY and NOW
Today = TODAY()  -- Current date
Now = NOW()      -- Current date and time

-- DATE construction
New Year = DATE(2024, 1, 1)

-- EOMONTH: End of month
End of This Month = EOMONTH(TODAY(), 0)
End of Next Month = EOMONTH(TODAY(), 1)
```

## Formatting Measures

### Format Strings

```dax
-- Currency
Total Sales = SUM(Sales[Amount])
-- Format: $#,##0.00

-- Percentage
Growth Rate = DIVIDE([Sales This Year] - [Sales Last Year], [Sales Last Year])
-- Format: 0.00%

-- Number with thousands separator
Total Quantity = SUM(Sales[Quantity])
-- Format: #,##0

-- Custom format (FORMAT function)
Sales Formatted =
FORMAT(
    [Total Sales],
    "$#,##0.00"
)

-- Conditional formatting
Sales with Sign =
VAR Value = [Total Sales]
VAR Sign = IF(Value >= 0, "+", "")
RETURN
    Sign & FORMAT(Value, "$#,##0")
```

### Dynamic Formatting

```dax
-- Format based on magnitude
Sales Smart Format =
VAR Value = [Total Sales]
RETURN
    SWITCH(
        TRUE(),
        Value >= 1000000, FORMAT(Value / 1000000, "$#,##0.0") & "M",
        Value >= 1000, FORMAT(Value / 1000, "$#,##0.0") & "K",
        FORMAT(Value, "$#,##0")
    )

-- Examples:
-- 1,500,000 → $1.5M
-- 50,000 → $50.0K
-- 500 → $500
```

## Exemples Pratiques

### Sales Metrics

```dax
-- Basic metrics
Total Sales = SUM(Sales[Amount])

Total Quantity = SUM(Sales[Quantity])

Order Count = COUNTROWS(Sales)

Unique Customers = DISTINCTCOUNT(Sales[CustomerID])

Average Order Value =
DIVIDE(
    [Total Sales],
    [Order Count],
    0
)

-- Profitability
Total Profit =
SUMX(
    Sales,
    Sales[Quantity] * (Sales[UnitPrice] - Sales[UnitCost])
)

Profit Margin =
DIVIDE(
    [Total Profit],
    [Total Sales],
    0
)
```

### Customer Metrics

```dax
-- Customer analytics
Total Customers = DISTINCTCOUNT(Sales[CustomerID])

New Customers =
CALCULATE(
    DISTINCTCOUNT(Sales[CustomerID]),
    FILTER(
        ALL(Sales),
        Sales[OrderDate] = MIN(Sales[OrderDate])
    )
)

Average Customer Value =
DIVIDE(
    [Total Sales],
    [Total Customers],
    0
)

Customer Lifetime Value =
CALCULATE(
    [Total Sales],
    ALLEXCEPT(Sales, Sales[CustomerID])
)
```

### Inventory Metrics

```dax
-- Inventory analysis
Total Units Sold = SUM(Sales[Quantity])

Days Since Last Sale =
DATEDIFF(
    MAX(Sales[OrderDate]),
    TODAY(),
    DAY
)

Inventory Turnover =
DIVIDE(
    [Total Units Sold],
    AVERAGE(Product[StockLevel]),
    0
)
```

## Best Practices

### ✅ Naming Conventions

```dax
-- ✅ Good: Clear, descriptive names
Total Sales = SUM(Sales[Amount])
Sales Year over Year Growth = ...
Average Order Value = ...

-- ❌ Bad: Abbreviations, unclear
TotSls = SUM(Sales[Amount])
SYOYG = ...
AOV = ...
```

### ✅ Use Variables

```dax
-- ✅ Good: Readable, efficient
Profit Margin =
VAR Revenue = SUM(Sales[Revenue])
VAR Cost = SUM(Sales[Cost])
VAR Profit = Revenue - Cost
RETURN
    DIVIDE(Profit, Revenue, 0)

-- ❌ Bad: Repeated calculations
Profit Margin =
DIVIDE(
    SUM(Sales[Revenue]) - SUM(Sales[Cost]),
    SUM(Sales[Revenue]),
    0
)
```

### ✅ Handle Errors

```dax
-- ✅ Good: Use DIVIDE or IFERROR
Safe Division = DIVIDE([Numerator], [Denominator], 0)

Safe Calculation =
IFERROR(
    [Complex Calculation],
    BLANK()
)

-- ❌ Bad: Direct division
Unsafe = [Numerator] / [Denominator]  -- Can error
```

### ✅ Comment Complex Formulas

```dax
-- ✅ Good: Documented
Sales YoY Growth =
VAR SalesThisYear = [Total Sales]  -- Current year sales
VAR SalesLastYear =
    CALCULATE(
        [Total Sales],
        DATEADD('Date'[Date], -1, YEAR)  -- Previous year
    )
VAR Growth = DIVIDE(SalesThisYear - SalesLastYear, SalesLastYear, 0)
RETURN
    Growth  -- Return as percentage

-- ❌ Bad: No explanation
Sales YoY Growth = DIVIDE([Total Sales] - CALCULATE([Total Sales], DATEADD('Date'[Date], -1, YEAR)), CALCULATE([Total Sales], DATEADD('Date'[Date], -1, YEAR)), 0)
```

### ✅ Organize Measures

```
Create Display Folders:
📁 Sales Measures
   └─ Total Sales
   └─ Sales Last Year
   └─ Sales YoY Growth
📁 Customer Measures
   └─ Total Customers
   └─ New Customers
   └─ Average Customer Value
📁 Product Measures
   └─ Total Products Sold
   └─ Average Unit Price
```

## Points Clés

- DAX = formulas for measures, calculated columns, calculated tables
- Measures = dynamic, computed on-the-fly (preferred)
- Calculated columns = static, stored in model
- Variables (VAR) for readability and performance
- Aggregation functions: SUM, AVERAGE, COUNT, MIN, MAX
- DIVIDE for safe division (handles zero)
- IF for conditions, SWITCH for multiple conditions
- Date functions: YEAR, MONTH, DATEDIFF, TODAY
- Format measures for better readability
- Best practices: clear names, variables, error handling, comments

---

**Prochain fichier :** [06 - DAX CALCULATE & FILTER](./06-dax-calculate-filter.md)

[⬅️ Fichier précédent](./04-modelisation-star-schema.md) | [⬅️ Retour au README du module](./README.md)
