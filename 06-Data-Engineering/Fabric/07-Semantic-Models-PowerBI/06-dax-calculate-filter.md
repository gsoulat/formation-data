# DAX CALCULATE & FILTER

## Introduction

**CALCULATE** est la fonction DAX la plus puissante et la plus importante. Elle modifie le contexte de filtre dans lequel une expression est évaluée.

```
CALCULATE = Game Changer in DAX
┌──────────────────────────────────────┐
│  90% of advanced DAX uses CALCULATE  │
│  Master CALCULATE = Master DAX       │
└──────────────────────────────────────┘
```

## CALCULATE: La Fonction Centrale

### Syntaxe

```dax
CALCULATE(
    <expression>,
    <filter1>,
    <filter2>,
    ...
)

-- Example
Sales France =
CALCULATE(
    SUM(Sales[Amount]),
    Sales[Country] = "France"
)
```

### Comportement

```
CALCULATE does 3 things:
1. Evaluates filters (filter arguments)
2. Modifies filter context
3. Evaluates expression in new context

Without CALCULATE:
  Total Sales = SUM(Sales[Amount])
  → Uses existing filter context
  → If France selected, returns France sales

With CALCULATE:
  All Sales = CALCULATE(SUM(Sales[Amount]), ALL(Sales))
  → Ignores existing filters on Sales
  → Always returns ALL sales (even if France selected)
```

## Filter Context Modification

### Adding Filters

```dax
-- Add filter to existing context
Sales France =
CALCULATE(
    [Total Sales],
    Sales[Country] = "France"
)

-- Multiple filters (AND logic)
Sales France Premium =
CALCULATE(
    [Total Sales],
    Sales[Country] = "France",
    Product[Category] = "Premium"
)

-- Same as:
Sales France Premium =
CALCULATE(
    [Total Sales],
    Sales[Country] = "France" && Product[Category] = "Premium"
)
```

### Removing Filters

```dax
-- Remove all filters from Sales table
All Sales =
CALCULATE(
    [Total Sales],
    ALL(Sales)
)

-- Remove filter from specific column
Sales All Countries =
CALCULATE(
    [Total Sales],
    ALL(Sales[Country])
)

-- Remove all filters except some columns
Sales By Country =
CALCULATE(
    [Total Sales],
    ALLEXCEPT(Sales, Sales[Country])
)
```

### Replacing Filters

```dax
-- CALCULATE replaces filter on same column
-- User selects France, but measure shows US:
Sales US =
CALCULATE(
    [Total Sales],
    Sales[Country] = "US"  -- Replaces France filter
)

-- KEEPFILTERS preserves existing filter (AND logic)
Sales US if Selected =
CALCULATE(
    [Total Sales],
    KEEPFILTERS(Sales[Country] = "US")
)
-- Returns BLANK if France selected (no intersection)
```

## FILTER Function

### Syntaxe

```dax
FILTER(
    <table>,
    <filter_expression>
)

-- Returns a table with rows that match filter
-- Used inside CALCULATE
```

### Basic FILTER

```dax
-- Filter table
High Value Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        Sales,
        Sales[Amount] > 1000
    )
)

-- Equivalent to (simpler):
High Value Sales =
CALCULATE(
    [Total Sales],
    Sales[Amount] > 1000
)
```

### When to Use FILTER

```
Use FILTER when:
  ✅ Complex conditions
  ✅ Comparing to measures
  ✅ Row-by-row evaluation needed
  ✅ Multiple columns from same table

Use simple filter when:
  ✅ Single column
  ✅ Simple comparison
  ✅ Better performance
```

### FILTER with Measures

```dax
-- Filter based on measure value
High Spending Customers =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Customer),
        [Total Sales] > 10000
    )
)

-- For each customer:
-- 1. Calculate Total Sales
-- 2. Keep only if > 10000
-- 3. Sum sales for kept customers
```

### FILTER Performance

```dax
-- ❌ Bad: FILTER on large table
Sales High Value =
CALCULATE(
    [Total Sales],
    FILTER(
        Sales,  -- 10M rows!
        Sales[Amount] > 1000
    )
)

-- ✅ Good: Simple filter (optimized)
Sales High Value =
CALCULATE(
    [Total Sales],
    Sales[Amount] > 1000  -- Faster
)

-- FILTER is slower because:
-- • Row-by-row iteration
-- • Cannot leverage indexes
-- • No query folding
```

## ALL Function Family

### ALL

```dax
-- Remove ALL filters from table
Total Sales All =
CALCULATE(
    [Total Sales],
    ALL(Sales)
)

-- Remove filters from column(s)
Sales All Countries =
CALCULATE(
    [Total Sales],
    ALL(Sales[Country])
)

-- Multiple columns
Sales All Locations =
CALCULATE(
    [Total Sales],
    ALL(Sales[Country], Sales[City])
)
```

### ALLEXCEPT

```dax
-- Remove all filters EXCEPT specified columns
Sales by Country Only =
CALCULATE(
    [Total Sales],
    ALLEXCEPT(Sales, Sales[Country])
)

-- Equivalent to:
Sales by Country Only =
CALCULATE(
    [Total Sales],
    ALL(Sales),  -- Remove all filters
    VALUES(Sales[Country])  -- Re-apply Country filter
)

-- Example:
-- User filters: Country=France, Year=2024, Category=Electronics
-- ALLEXCEPT(Sales, Sales[Country]) →
--   Removes Year and Category filters
--   Keeps Country=France filter
```

### ALLSELECTED

```dax
-- Removes filters inside visual, keeps filters outside
Sales % of Visual Total =
DIVIDE(
    [Total Sales],
    CALCULATE(
        [Total Sales],
        ALLSELECTED(Sales)
    )
)

-- Example:
-- Page filter: Year=2024
-- Visual: Country slicer showing France, US, UK
-- ALLSELECTED(Sales):
--   Removes Country filter (inside visual)
--   Keeps Year=2024 filter (outside visual)
--   → Total for 2024 across all countries IN THE VISUAL
```

### Comparison

```
ALL:
  • Removes all filters on table/column
  • Ignores all user selections
  • Returns absolute total

ALLEXCEPT:
  • Removes all filters except specified
  • Keeps some user selections
  • Partial filter removal

ALLSELECTED:
  • Removes filters inside visual only
  • Respects filters from slicers/pages
  • Context-aware total
```

## REMOVEFILTERS

```dax
-- Modern alternative to ALL (clearer intent)
Sales Total =
CALCULATE(
    [Total Sales],
    REMOVEFILTERS(Sales)
)

-- Remove from specific columns
Sales All Years =
CALCULATE(
    [Total Sales],
    REMOVEFILTERS('Date'[Year])
)

-- REMOVEFILTERS vs ALL:
-- Same functionality, REMOVEFILTERS is clearer
CALCULATE([Total Sales], ALL(Sales))           -- Old
CALCULATE([Total Sales], REMOVEFILTERS(Sales)) -- New ✅
```

## KEEPFILTERS

```dax
-- Preserve existing filter (AND logic instead of replace)
-- Without KEEPFILTERS:
Sales France =
CALCULATE(
    [Total Sales],
    Sales[Country] = "France"
)
-- If user selects "US", measure shows France anyway (replaces filter)

-- With KEEPFILTERS:
Sales France if Relevant =
CALCULATE(
    [Total Sales],
    KEEPFILTERS(Sales[Country] = "France")
)
-- If user selects "US", measure shows BLANK (no intersection)
-- If user selects "France", measure shows France
```

## Combinaisons Avancées

### Percentage of Total

```dax
-- % of Grand Total
Sales % of Total =
DIVIDE(
    [Total Sales],
    CALCULATE(
        [Total Sales],
        ALL(Sales)  -- Grand total
    )
)

-- % of Country Total
Sales % of Country =
DIVIDE(
    [Total Sales],
    CALCULATE(
        [Total Sales],
        ALLEXCEPT(Sales, Sales[Country])  -- Country total
    )
)

-- % of Selected Total
Sales % of Selection =
DIVIDE(
    [Total Sales],
    CALCULATE(
        [Total Sales],
        ALLSELECTED(Sales)  -- Total in current visual
    )
)
```

### Top N

```dax
-- Sales for Top 5 Products
Sales Top 5 Products =
CALCULATE(
    [Total Sales],
    TOPN(
        5,
        ALL(Product[Name]),
        [Total Sales],
        DESC
    )
)

-- Is this product in Top 5?
Is Top 5 Product =
VAR CurrentProduct = SELECTEDVALUE(Product[Name])
VAR Top5 = TOPN(5, ALL(Product[Name]), [Total Sales], DESC)
VAR Rank = RANKX(Top5, [Total Sales], , DESC)
RETURN
    IF(ISBLANK(CurrentProduct), BLANK(), Rank <= 5)
```

### Filtering on Multiple Tables

```dax
-- Filter across relationships
Sales France Premium =
CALCULATE(
    [Total Sales],
    Sales[Country] = "France",
    Product[Category] = "Premium"
)

-- Equivalent with FILTER:
Sales France Premium =
CALCULATE(
    [Total Sales],
    FILTER(
        Sales,
        RELATED(Customer[Country]) = "France" &&
        RELATED(Product[Category]) = "Premium"
    )
)
```

### Cumulative Total

```dax
-- Sales Year-to-Date
Sales YTD =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL('Date'),
        'Date'[Date] <= MAX('Date'[Date]) &&
        'Date'[Year] = MAX('Date'[Year])
    )
)

-- Or using DATESYTD (simpler):
Sales YTD = TOTALYTD([Total Sales], 'Date'[Date])
```

### Running Total

```dax
-- Running Total (cumulative)
Sales Running Total =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL('Date'[Date]),
        'Date'[Date] <= MAX('Date'[Date])
    )
)

-- Shows cumulative sales up to selected date
```

## Time Intelligence avec CALCULATE

### Previous Period

```dax
-- Sales Last Year
Sales LY =
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR('Date'[Date])
)

-- Sales Last Month
Sales PM =
CALCULATE(
    [Total Sales],
    PREVIOUSMONTH('Date'[Date])
)

-- Sales Last Quarter
Sales PQ =
CALCULATE(
    [Total Sales],
    PREVIOUSQUARTER('Date'[Date])
)
```

### Year-over-Year Growth

```dax
-- YoY Growth Amount
YoY Growth =
[Total Sales] - [Sales LY]

-- YoY Growth %
YoY Growth % =
DIVIDE(
    [YoY Growth],
    [Sales LY],
    0
)

-- Formatted
YoY Growth Formatted =
VAR Growth = [YoY Growth %]
VAR Sign = IF(Growth >= 0, "+", "")
RETURN
    Sign & FORMAT(Growth, "0.0%")
```

### Moving Average

```dax
-- 3-Month Moving Average
Sales 3M Avg =
CALCULATE(
    [Total Sales],
    DATESINPERIOD(
        'Date'[Date],
        MAX('Date'[Date]),
        -3,
        MONTH
    )
) / 3

-- 12-Month Moving Average
Sales 12M Avg =
CALCULATE(
    AVERAGE(Sales[Amount]),
    DATESINPERIOD(
        'Date'[Date],
        LASTDATE('Date'[Date]),
        -12,
        MONTH
    )
)
```

## Exemples Complexes

### Market Share

```dax
-- Market Share (% of total market)
Market Share =
VAR MyCompanySales = [Total Sales]
VAR TotalMarketSales =
    CALCULATE(
        [Total Sales],
        ALL(Sales[Company])
    )
RETURN
    DIVIDE(MyCompanySales, TotalMarketSales, 0)
```

### Same Period Last Year

```dax
-- Sales for same period last year
Sales SPLY =
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR('Date'[Date])
)

-- Works for any date selection:
-- - Single day → Same day last year
-- - Month → Same month last year
-- - Quarter → Same quarter last year
-- - Custom period → Same period last year
```

### Pareto Analysis (80/20)

```dax
-- Cumulative % of Total
Cumulative % =
VAR CurrentSales = [Total Sales]
VAR RunningTotal =
    CALCULATE(
        [Total Sales],
        FILTER(
            ALLSELECTED(Product[Name]),
            [Total Sales] >= CurrentSales
        )
    )
VAR GrandTotal =
    CALCULATE(
        [Total Sales],
        ALLSELECTED(Product[Name])
    )
RETURN
    DIVIDE(RunningTotal, GrandTotal, 0)

-- Is in top 80%?
Is Top 80% =
[Cumulative %] <= 0.8
```

### Customer Segmentation

```dax
-- RFM Analysis (Recency, Frequency, Monetary)
Customer Segment =
VAR Recency =
    DATEDIFF(
        CALCULATE(MAX(Sales[OrderDate]), ALLEXCEPT(Sales, Sales[CustomerID])),
        TODAY(),
        DAY
    )
VAR Frequency =
    CALCULATE(COUNTROWS(Sales), ALLEXCEPT(Sales, Sales[CustomerID]))
VAR Monetary =
    CALCULATE([Total Sales], ALLEXCEPT(Sales, Sales[CustomerID]))
RETURN
    SWITCH(
        TRUE(),
        Recency < 30 && Frequency > 10 && Monetary > 10000, "Champions",
        Recency < 90 && Frequency > 5 && Monetary > 5000, "Loyal",
        Recency < 180 && Frequency > 2, "Potential",
        Recency >= 365, "Lost",
        "Regular"
    )
```

## Performance Optimization

### ✅ Use Simple Filters

```dax
-- ✅ Good: Simple filter (fastest)
Sales France =
CALCULATE(
    [Total Sales],
    Sales[Country] = "France"
)

-- ❌ Bad: FILTER function (slower)
Sales France =
CALCULATE(
    [Total Sales],
    FILTER(Sales, Sales[Country] = "France")
)
```

### ✅ Filter Early

```dax
-- ✅ Good: Filter first, then calculate
High Value Customers Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        VALUES(Customer[CustomerID]),  -- Small table
        [Customer Lifetime Value] > 10000
    )
)

-- ❌ Bad: Iterate large table
High Value Customers Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Sales),  -- Huge table!
        [Customer Lifetime Value] > 10000
    )
)
```

### ✅ Use Variables

```dax
-- ✅ Good: Calculate once
Sales % Growth =
VAR SalesThisYear = [Total Sales]
VAR SalesLastYear = [Sales LY]
RETURN
    DIVIDE(SalesThisYear - SalesLastYear, SalesLastYear, 0)

-- ❌ Bad: Repeated calculations
Sales % Growth =
DIVIDE([Total Sales] - [Sales LY], [Sales LY], 0)
-- [Sales LY] computed twice!
```

## Best Practices

### ✅ CALCULATE Patterns

```dax
-- ✅ Use CALCULATE for:
-- 1. Percentage calculations
% of Total = DIVIDE([Sales], CALCULATE([Sales], ALL(Sales)))

-- 2. Time intelligence
Sales LY = CALCULATE([Sales], SAMEPERIODLASTYEAR('Date'[Date]))

-- 3. Custom filters
Sales Premium = CALCULATE([Sales], Product[Category] = "Premium")

-- 4. Removing filters
Total All = CALCULATE([Sales], ALL(Sales))

-- 5. Context transition
Customer Total = CALCULATE([Sales])  -- Forces context transition
```

### ✅ Avoid Common Mistakes

```dax
-- ❌ Bad: Unnecessary FILTER
Sales > 100 =
CALCULATE(
    [Total Sales],
    FILTER(Sales, Sales[Amount] > 100)  -- Slow
)

-- ✅ Good: Simple filter
Sales > 100 =
CALCULATE(
    [Total Sales],
    Sales[Amount] > 100  -- Fast
)

-- ❌ Bad: ALL without CALCULATE
Total = [Sales] / ALL(Sales)  -- Error! ALL needs CALCULATE

-- ✅ Good: ALL with CALCULATE
% of Total = DIVIDE([Sales], CALCULATE([Sales], ALL(Sales)))
```

### ✅ Testing Strategy

```dax
-- Test with simple data first
-- Create test measure:
Test CALCULATE =
VAR WithFilter = CALCULATE([Total Sales], Sales[Country] = "France")
VAR WithoutFilter = [Total Sales]
RETURN
    "With Filter: " & WithFilter & " | Without: " & WithoutFilter

-- Verify filter behavior
-- Expected: Different values if France filter working
```

## Points Clés

- CALCULATE = most important DAX function (modifies filter context)
- Use for: percentages, time intelligence, custom filters
- FILTER = table function for complex row-by-row filtering
- ALL = remove all filters on table/column
- ALLEXCEPT = remove all filters except specified columns
- ALLSELECTED = remove filters inside visual, keep outside
- REMOVEFILTERS = modern alternative to ALL (clearer)
- KEEPFILTERS = preserve existing filter (AND logic)
- Avoid FILTER on large tables (use simple filters instead)
- Use variables to avoid repeated calculations
- Master CALCULATE = Master 90% of advanced DAX

---

**Prochain fichier :** [07 - Measures & Calculated Columns](./07-measures-calculated-columns.md)

[⬅️ Fichier précédent](./05-dax-basics.md) | [⬅️ Retour au README du module](./README.md)
