# Semantic Model DAX Measures Template
# =====================================
# Standard DAX measures for Fabric semantic models
# Copy and customize for your specific model

## Base Measures

```dax
// ═══════════════════════════════════════════════════════
// SALES METRICS
// ═══════════════════════════════════════════════════════

Total Sales =
SUM(Fact_Sales[SalesAmount])

Total Quantity =
SUM(Fact_Sales[Quantity])

Total Transactions =
COUNTROWS(Fact_Sales)

Average Order Value =
DIVIDE([Total Sales], [Total Transactions], 0)

// ═══════════════════════════════════════════════════════
// COST & PROFIT
// ═══════════════════════════════════════════════════════

Total Cost =
SUMX(
    Fact_Sales,
    Fact_Sales[Quantity] * RELATED(Dim_Product[UnitCost])
)

Gross Profit =
[Total Sales] - [Total Cost]

Gross Margin % =
DIVIDE([Gross Profit], [Total Sales], 0)

Net Profit =
[Gross Profit] - [Total Operating Expenses]

Net Margin % =
DIVIDE([Net Profit], [Total Sales], 0)
```

## Time Intelligence

```dax
// ═══════════════════════════════════════════════════════
// PERIOD-TO-DATE
// ═══════════════════════════════════════════════════════

Sales MTD =
TOTALMTD([Total Sales], Dim_Date[Date])

Sales QTD =
TOTALQTD([Total Sales], Dim_Date[Date])

Sales YTD =
TOTALYTD([Total Sales], Dim_Date[Date])

// ═══════════════════════════════════════════════════════
// PREVIOUS PERIOD COMPARISONS
// ═══════════════════════════════════════════════════════

Sales Previous Month =
CALCULATE(
    [Total Sales],
    PREVIOUSMONTH(Dim_Date[Date])
)

Sales Previous Quarter =
CALCULATE(
    [Total Sales],
    PREVIOUSQUARTER(Dim_Date[Date])
)

Sales Previous Year =
CALCULATE(
    [Total Sales],
    PREVIOUSYEAR(Dim_Date[Date])
)

Sales Same Period Last Year =
CALCULATE(
    [Total Sales],
    SAMEPERIODLASTYEAR(Dim_Date[Date])
)

// ═══════════════════════════════════════════════════════
// GROWTH CALCULATIONS
// ═══════════════════════════════════════════════════════

Sales MoM Growth =
VAR CurrentMonth = [Total Sales]
VAR PreviousMonth = [Sales Previous Month]
RETURN
    DIVIDE(CurrentMonth - PreviousMonth, PreviousMonth, 0)

Sales MoM Growth % =
FORMAT([Sales MoM Growth], "0.00%")

Sales YoY Growth =
VAR CurrentPeriod = [Total Sales]
VAR LastYear = [Sales Same Period Last Year]
RETURN
    DIVIDE(CurrentPeriod - LastYear, LastYear, 0)

Sales YoY Growth % =
FORMAT([Sales YoY Growth], "0.00%")

Sales YoY Absolute Change =
[Total Sales] - [Sales Same Period Last Year]

// ═══════════════════════════════════════════════════════
// RUNNING TOTALS
// ═══════════════════════════════════════════════════════

Running Total Sales =
CALCULATE(
    [Total Sales],
    FILTER(
        ALL(Dim_Date[Date]),
        Dim_Date[Date] <= MAX(Dim_Date[Date])
    )
)

Running Total YTD =
VAR MaxDate = MAX(Dim_Date[Date])
VAR YearStart = DATE(YEAR(MaxDate), 1, 1)
RETURN
    CALCULATE(
        [Total Sales],
        Dim_Date[Date] >= YearStart && Dim_Date[Date] <= MaxDate
    )

// ═══════════════════════════════════════════════════════
// MOVING AVERAGES
// ═══════════════════════════════════════════════════════

Sales 3M Moving Average =
AVERAGEX(
    DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -3, MONTH),
    [Total Sales]
)

Sales 12M Moving Average =
AVERAGEX(
    DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -12, MONTH),
    [Total Sales]
)
```

## Customer Analytics

```dax
// ═══════════════════════════════════════════════════════
// CUSTOMER COUNTS
// ═══════════════════════════════════════════════════════

Total Customers =
DISTINCTCOUNT(Fact_Sales[CustomerKey])

New Customers =
VAR CurrentPeriodCustomers = VALUES(Fact_Sales[CustomerKey])
VAR PreviousPeriodCustomers =
    CALCULATETABLE(
        VALUES(Fact_Sales[CustomerKey]),
        PREVIOUSMONTH(Dim_Date[Date])
    )
RETURN
    COUNTROWS(
        EXCEPT(CurrentPeriodCustomers, PreviousPeriodCustomers)
    )

Lost Customers =
VAR CurrentPeriodCustomers = VALUES(Fact_Sales[CustomerKey])
VAR PreviousPeriodCustomers =
    CALCULATETABLE(
        VALUES(Fact_Sales[CustomerKey]),
        PREVIOUSMONTH(Dim_Date[Date])
    )
RETURN
    COUNTROWS(
        EXCEPT(PreviousPeriodCustomers, CurrentPeriodCustomers)
    )

Customer Retention Rate =
VAR TotalCustomers = [Total Customers]
VAR LostCust = [Lost Customers]
RETURN
    DIVIDE(TotalCustomers - LostCust, TotalCustomers, 0)

// ═══════════════════════════════════════════════════════
// CUSTOMER VALUE
// ═══════════════════════════════════════════════════════

Average Revenue Per Customer =
DIVIDE([Total Sales], [Total Customers], 0)

Customer Lifetime Value =
VAR AvgOrderValue = [Average Order Value]
VAR AvgPurchaseFrequency =
    DIVIDE([Total Transactions], [Total Customers], 0)
VAR CustomerLifespanYears = 3  // Assumption
RETURN
    AvgOrderValue * AvgPurchaseFrequency * CustomerLifespanYears

Top 20% Customers Revenue =
VAR TopCustomers =
    TOPN(
        ROUNDUP([Total Customers] * 0.2, 0),
        ALL(Dim_Customer),
        CALCULATE([Total Sales])
    )
RETURN
    CALCULATE(
        [Total Sales],
        KEEPFILTERS(TopCustomers)
    )

Pareto Percentage =
DIVIDE([Top 20% Customers Revenue], [Total Sales], 0)
```

## Product Analytics

```dax
// ═══════════════════════════════════════════════════════
// PRODUCT PERFORMANCE
// ═══════════════════════════════════════════════════════

Products Sold =
DISTINCTCOUNT(Fact_Sales[ProductKey])

Average Selling Price =
DIVIDE([Total Sales], [Total Quantity], 0)

Units Per Transaction =
DIVIDE([Total Quantity], [Total Transactions], 0)

Product Contribution % =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(Dim_Product)),
    0
)

// ═══════════════════════════════════════════════════════
// RANKING
// ═══════════════════════════════════════════════════════

Product Rank by Sales =
RANKX(
    ALL(Dim_Product[ProductName]),
    [Total Sales],
    ,
    DESC,
    DENSE
)

Category Rank by Revenue =
RANKX(
    ALL(Dim_Product[Category]),
    [Total Sales],
    ,
    DESC,
    DENSE
)

Top N Products =
VAR ProductRank = [Product Rank by Sales]
VAR N = 10  // Top 10
RETURN
    IF(ProductRank <= N, [Total Sales], BLANK())

// ═══════════════════════════════════════════════════════
// ABC ANALYSIS
// ═══════════════════════════════════════════════════════

Product ABC Class =
VAR CurrentProductSales = [Total Sales]
VAR CumulativePercentage =
    DIVIDE(
        CALCULATE(
            [Total Sales],
            FILTER(
                ALL(Dim_Product),
                [Total Sales] >= CurrentProductSales
            )
        ),
        CALCULATE([Total Sales], ALL(Dim_Product)),
        0
    )
RETURN
    SWITCH(
        TRUE(),
        CumulativePercentage <= 0.7, "A",
        CumulativePercentage <= 0.9, "B",
        "C"
    )
```

## KPIs and Targets

```dax
// ═══════════════════════════════════════════════════════
// TARGET COMPARISONS
// ═══════════════════════════════════════════════════════

Sales Target =
SUM(Targets[SalesTarget])

Sales vs Target =
[Total Sales] - [Sales Target]

Sales vs Target % =
DIVIDE([Total Sales], [Sales Target], 0) - 1

Sales Target Achievement =
DIVIDE([Total Sales], [Sales Target], 0)

Sales Target Status =
VAR Achievement = [Sales Target Achievement]
RETURN
    SWITCH(
        TRUE(),
        Achievement >= 1.1, "Exceeding",
        Achievement >= 1.0, "On Target",
        Achievement >= 0.9, "Slightly Below",
        "Below Target"
    )

// ═══════════════════════════════════════════════════════
// FORECASTING
// ═══════════════════════════════════════════════════════

Sales Forecast =
VAR DaysElapsed =
    DATEDIFF(
        MIN(Dim_Date[Date]),
        TODAY(),
        DAY
    )
VAR TotalDays =
    DATEDIFF(
        MIN(Dim_Date[Date]),
        MAX(Dim_Date[Date]),
        DAY
    )
VAR CurrentSales = [Total Sales]
RETURN
    DIVIDE(CurrentSales, DaysElapsed, 0) * TotalDays

Days to Target =
VAR DailyRunRate =
    DIVIDE([Total Sales], COUNTROWS(Dim_Date), 0)
VAR RemainingTarget = [Sales Target] - [Total Sales]
RETURN
    IF(
        RemainingTarget > 0,
        ROUNDUP(DIVIDE(RemainingTarget, DailyRunRate, 0), 0),
        0
    )
```

## Dynamic Measures

```dax
// ═══════════════════════════════════════════════════════
// DYNAMIC MEASURE SELECTION
// ═══════════════════════════════════════════════════════

// Create a disconnected table for measure selection
// MeasureSelector = {"Sales", "Quantity", "Profit", "Margin"}

Selected Measure =
VAR SelectedMetric = SELECTEDVALUE(MeasureSelector[Metric], "Sales")
RETURN
    SWITCH(
        SelectedMetric,
        "Sales", [Total Sales],
        "Quantity", [Total Quantity],
        "Profit", [Gross Profit],
        "Margin", [Gross Margin %],
        [Total Sales]
    )

// ═══════════════════════════════════════════════════════
// DYNAMIC PERIOD SELECTION
// ═══════════════════════════════════════════════════════

// PeriodSelector = {"MTD", "QTD", "YTD", "Last 12 Months"}

Selected Period Sales =
VAR Period = SELECTEDVALUE(PeriodSelector[Period], "YTD")
RETURN
    SWITCH(
        Period,
        "MTD", [Sales MTD],
        "QTD", [Sales QTD],
        "YTD", [Sales YTD],
        "Last 12 Months",
            CALCULATE(
                [Total Sales],
                DATESINPERIOD(Dim_Date[Date], MAX(Dim_Date[Date]), -12, MONTH)
            ),
        [Total Sales]
    )

// ═══════════════════════════════════════════════════════
// CONDITIONAL FORMATTING VALUES
// ═══════════════════════════════════════════════════════

Growth Color =
VAR GrowthValue = [Sales YoY Growth]
RETURN
    SWITCH(
        TRUE(),
        GrowthValue > 0.1, "#2E7D32",   // Dark Green
        GrowthValue > 0, "#4CAF50",      // Green
        GrowthValue > -0.1, "#FFA726",   // Orange
        "#D32F2F"                         // Red
    )

KPI Status Icon =
VAR Achievement = [Sales Target Achievement]
RETURN
    SWITCH(
        TRUE(),
        Achievement >= 1.0, "✓",
        Achievement >= 0.9, "⚠",
        "✗"
    )
```

## Performance Optimization Tips

```dax
// ═══════════════════════════════════════════════════════
// BEST PRACTICES
// ═══════════════════════════════════════════════════════

// 1. Use variables to avoid recalculation
OptimizedMeasure =
VAR TotalSales = SUM(Fact_Sales[SalesAmount])
VAR TotalCost = SUM(Fact_Sales[Cost])
VAR Profit = TotalSales - TotalCost
RETURN
    DIVIDE(Profit, TotalSales, 0)

// 2. Use SUMMARIZE for complex aggregations
ComplexAggregation =
VAR SummaryTable =
    SUMMARIZE(
        Fact_Sales,
        Dim_Customer[Segment],
        "TotalSales", SUM(Fact_Sales[SalesAmount]),
        "AvgOrder", AVERAGE(Fact_Sales[SalesAmount])
    )
RETURN
    COUNTROWS(FILTER(SummaryTable, [TotalSales] > 10000))

// 3. Avoid nested CALCULATE when possible
// BAD:
// CALCULATE(CALCULATE([Total Sales], Filter1), Filter2)
// GOOD:
// CALCULATE([Total Sales], Filter1, Filter2)

// 4. Use KEEPFILTERS to preserve context
FilteredWithContext =
CALCULATE(
    [Total Sales],
    KEEPFILTERS(Dim_Product[Category] = "Electronics")
)

// 5. Avoid FILTER with large tables
// BAD:
// CALCULATE([Total Sales], FILTER(ALL(Fact_Sales), Fact_Sales[Amount] > 100))
// GOOD:
// CALCULATE([Total Sales], Fact_Sales[Amount] > 100)
```

---

## Setup Instructions

1. **Create semantic model** in Fabric workspace
2. **Import tables** from Lakehouse/Warehouse
3. **Define relationships** (star schema)
4. **Create measures** from this template
5. **Customize** for your specific business needs
6. **Test** with Power BI reports
7. **Optimize** based on performance analyzer

---

[⬅️ Retour aux templates](../README.md)
