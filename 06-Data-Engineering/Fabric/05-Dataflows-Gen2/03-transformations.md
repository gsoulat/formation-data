# Transformations Avancées

## Introduction

Les transformations avancées permettent de traiter des cas complexes : pivoting, unpivoting, merges multiples, lookups, et data quality.

```
Transformation Categories:
├── Reshaping (Pivot, Unpivot, Transpose)
├── Combining (Merge, Append, Join)
├── Data Quality (Duplicates, Errors, Nulls)
├── Text Processing (Parse, Extract, Split)
└── Advanced Calculations
```

## Pivot et Unpivot

### Unpivot Columns

**Scenario : Wide to Long**
```
Input (Wide):
ProductID | Jan | Feb | Mar
1         | 100 | 150 | 200
2         | 50  | 75  | 100

Output (Long):
ProductID | Month | Sales
1         | Jan   | 100
1         | Feb   | 150
1         | Mar   | 200
2         | Jan   | 50
2         | Feb   | 75
2         | Mar   | 100
```

**Transformation :**
```powerquery
let
    Source = /* wide table */,
    Unpivoted = Table.UnpivotOtherColumns(
        Source,
        {"ProductID"},  // Columns to keep
        "Month",         // Attribute column name
        "Sales"          // Value column name
    )
in
    Unpivoted
```

**Via UI :**
```
1. Select columns to keep (ProductID)
2. Transform → Unpivot Other Columns
3. Rename Attribute → "Month"
4. Rename Value → "Sales"
```

### Pivot Columns

**Scenario : Long to Wide**
```
Input (Long):
ProductID | Month | Sales
1         | Jan   | 100
1         | Feb   | 150
2         | Jan   | 50

Output (Wide):
ProductID | Jan | Feb
1         | 100 | 150
2         | 50  | null
```

**Transformation :**
```powerquery
let
    Source = /* long table */,
    Pivoted = Table.Pivot(
        Source,
        List.Distinct(Source[Month]),  // Values to pivot
        "Month",                        // Column to pivot
        "Sales",                        // Value column
        List.Sum                        // Aggregation function
    )
in
    Pivoted
```

**Via UI :**
```
1. Select Month column
2. Transform → Pivot Column
3. Values Column: Sales
4. Advanced → Aggregate: Sum
```

### Transpose

```powerquery
// Flip rows and columns
Transposed = Table.Transpose(Source)

// With headers from first row
WithHeaders = Table.PromoteHeaders(Transposed)
```

## Combining Data

### Merge Queries (Joins)

**Inner Join :**
```powerquery
let
    Customers = /* customers table */,
    Orders = /* orders table */,

    Merged = Table.NestedJoin(
        Customers, {"customer_id"},
        Orders, {"customer_id"},
        "Orders",
        JoinKind.Inner
    ),

    Expanded = Table.ExpandTableColumn(
        Merged,
        "Orders",
        {"order_id", "amount", "order_date"},
        {"order_id", "amount", "order_date"}
    )
in
    Expanded
```

**Left Outer Join :**
```powerquery
Merged = Table.NestedJoin(
    Customers, {"customer_id"},
    Orders, {"customer_id"},
    "Orders",
    JoinKind.LeftOuter  // Keep all customers, even without orders
)
```

**Join Types :**
```
JoinKind.Inner       → Only matching rows
JoinKind.LeftOuter   → All left + matching right
JoinKind.RightOuter  → All right + matching left
JoinKind.FullOuter   → All rows from both
JoinKind.LeftAnti    → Left rows NOT in right
JoinKind.RightAnti   → Right rows NOT in left
```

**Multi-Column Join :**
```powerquery
Merged = Table.NestedJoin(
    Table1, {"country", "region"},
    Table2, {"country", "region"},
    "Matched",
    JoinKind.Inner
)
```

**Fuzzy Matching :**
```powerquery
Merged = Table.FuzzyNestedJoin(
    Table1, {"company_name"},
    Table2, {"company_name"},
    "Matches",
    JoinKind.LeftOuter,
    [
        IgnoreCase = true,
        IgnoreSpace = true,
        SimilarityColumnName = "Similarity",
        Threshold = 0.8
    ]
)
```

### Append Queries (Union)

```powerquery
// Combine two tables with same structure
let
    Sales2023 = /* sales 2023 */,
    Sales2024 = /* sales 2024 */,

    Combined = Table.Combine({Sales2023, Sales2024})
in
    Combined

// Multiple tables
AllSales = Table.Combine({
    Sales2021,
    Sales2022,
    Sales2023,
    Sales2024
})
```

**Append with Missing Columns :**
```powerquery
// Add missing columns as null
Table1_WithColumns = Table.AddColumn(Table1, "new_column",
    each null, type text),

Appended = Table.Combine({Table1_WithColumns, Table2})
```

## Lookups et Enrichment

### Simple Lookup

```powerquery
let
    Sales = /* sales table */,
    ProductLookup = /* product reference */,

    // Add product info to sales
    WithProductInfo = Table.AddColumn(Sales, "product_info",
        each Table.SelectRows(ProductLookup,
            (lookup) => lookup[product_id] = [product_id]
        ){0}?
    ),

    Expanded = Table.ExpandRecordColumn(
        WithProductInfo,
        "product_info",
        {"product_name", "category"},
        {"product_name", "category"}
    )
in
    Expanded
```

### Buffered Lookup (Performance)

```powerquery
let
    Sales = /* large sales table */,
    Products = /* product lookup - buffer in memory */,
    BufferedProducts = Table.Buffer(Products),

    WithProduct = Table.AddColumn(Sales, "product_name",
        each
            let
                match = Table.SelectRows(BufferedProducts,
                    (p) => p[product_id] = [product_id])
            in
                if Table.RowCount(match) > 0 then
                    match{0}[product_name]
                else
                    "Unknown"
    )
in
    WithProduct
```

### List.Accumulate for Complex Lookups

```powerquery
let
    Source = /* source data */,
    LookupTable = /* lookup table */,

    Enriched = List.Accumulate(
        Table.ToRecords(Source),
        {},
        (state, current) =>
            let
                lookup = Table.SelectRows(LookupTable,
                    each [id] = current[id]),
                enriched = current & lookup{0}
            in
                state & {enriched}
    ),

    ToTable = Table.FromRecords(Enriched)
in
    ToTable
```

## Data Quality Transformations

### Remove Duplicates

```powerquery
// Remove all duplicate rows
NoDuplicates = Table.Distinct(Source)

// Remove duplicates based on specific columns
NoDuplicates = Table.Distinct(Source, {"email", "phone"})

// Keep first occurrence
FirstOccurrence = Table.Distinct(Source, {"customer_id"})

// Advanced: Keep last occurrence
let
    Sorted = Table.Sort(Source, {{"created_date", Order.Descending}}),
    Deduplicated = Table.Distinct(Sorted, {"customer_id"})
in
    Deduplicated
```

### Handle Errors

```powerquery
// Remove rows with errors
let
    Source = /* data with potential errors */,
    RemovedErrors = Table.RemoveRowsWithErrors(Source)
in
    RemovedErrors

// Replace errors with default values
ReplacedErrors = Table.ReplaceErrorValues(Source, {
    {"amount", 0},
    {"quantity", 1}
})

// Keep errors for analysis
let
    ValidRows = Table.RemoveRowsWithErrors(Source),
    ErrorRows = Table.SelectRowsWithErrors(Source),
    WithErrorFlag = Table.AddColumn(ErrorRows, "error_details",
        each "Error in row")
in
    ErrorRows
```

### Handle Nulls

```powerquery
// Remove rows with null in specific column
NoNulls = Table.SelectRows(Source, each [customer_id] <> null)

// Replace nulls with defaults
Replaced = Table.ReplaceValue(
    Source,
    null,
    "Unknown",
    Replacer.ReplaceValue,
    {"country"}
)

// Fill down (propagate previous value)
Filled = Table.FillDown(Source, {"category"})

// Fill up
Filled = Table.FillUp(Source, {"region"})

// Coalesce multiple columns
WithCoalesce = Table.AddColumn(Source, "final_value",
    each [value1] ?? [value2] ?? [value3] ?? 0
)
```

### Data Validation

```powerquery
let
    Source = /* source data */,

    // Add validation column
    WithValidation = Table.AddColumn(Source, "is_valid",
        each
            [customer_id] <> null
            and [email] <> null
            and Text.Contains([email], "@")
            and [amount] > 0
    ),

    // Split valid vs invalid
    ValidRows = Table.SelectRows(WithValidation, each [is_valid] = true),
    InvalidRows = Table.SelectRows(WithValidation, each [is_valid] = false)
in
    ValidRows  // ou InvalidRows pour audit
```

## Text Processing

### Parse Complex Text

```powerquery
// Extract from pattern
let
    Source = /* data with "Name: John, Age: 30" */,

    ExtractedName = Table.AddColumn(Source, "name",
        each Text.BetweenDelimiters([text], "Name: ", ",")),

    ExtractedAge = Table.AddColumn(ExtractedName, "age",
        each Number.From(Text.BetweenDelimiters([text], "Age: ", "")))
in
    ExtractedAge
```

### Split Column Advanced

```powerquery
// Split by delimiter
SplitByComma = Table.SplitColumn(
    Source,
    "FullAddress",
    Splitter.SplitTextByDelimiter(",", QuoteStyle.Csv),
    {"Street", "City", "PostalCode"}
)

// Split by positions
SplitByPosition = Table.SplitColumn(
    Source,
    "Code",
    Splitter.SplitTextByPositions({0, 2, 5}),
    {"Prefix", "Middle", "Suffix"}
)

// Split by character transition
SplitByCase = Table.SplitColumn(
    Source,
    "CamelCase",
    Splitter.SplitTextByCharacterTransition(
        {"a".."z"},
        {"A".."Z"}
    )
)
```

### Regular Expressions

```powerquery
// Extract with regex
EmailExtracted = Table.AddColumn(Source, "email",
    each
        let
            pattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
            matches = Text.PositionOf([text], pattern, Occurrence.All)
        in
            if List.Count(matches) > 0 then
                Text.Middle([text], matches{0}, Text.Length([text]))
            else
                null
)

// Validate format
WithValidation = Table.AddColumn(Source, "email_valid",
    each
        let
            pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
            text = [email]
        in
            try
                Text.Length(text) > 0
                and Text.Contains(text, "@")
                and Text.Contains(Text.AfterDelimiter(text, "@"), ".")
            otherwise
                false
)
```

## Advanced Calculations

### Running Total

```powerquery
let
    Source = /* ordered sales data */,

    AddIndex = Table.AddIndexColumn(Source, "Index", 0, 1),

    RunningTotal = Table.AddColumn(AddIndex, "running_total",
        each List.Sum(
            List.FirstN(AddIndex[amount], [Index] + 1)
        )
    )
in
    RunningTotal
```

### Moving Average

```powerquery
let
    Source = /* time series data */,
    AddIndex = Table.AddIndexColumn(Source, "Index", 0, 1),

    MovingAvg = Table.AddColumn(AddIndex, "moving_avg_7day",
        each
            let
                startIndex = Number.Max({0, [Index] - 6}),
                values = List.Range(AddIndex[amount], startIndex, [Index] - startIndex + 1)
            in
                List.Average(values)
    )
in
    MovingAvg
```

### Rank / Dense Rank

```powerquery
let
    Source = /* sales by customer */,
    Sorted = Table.Sort(Source, {{"total_sales", Order.Descending}}),
    AddIndex = Table.AddIndexColumn(Sorted, "rank", 1, 1),

    // Dense rank (no gaps)
    WithDenseRank = Table.AddColumn(AddIndex, "dense_rank",
        each
            let
                previousRows = Table.FirstN(Sorted, [Index]),
                distinctValues = List.Count(List.Distinct(previousRows[total_sales]))
            in
                distinctValues
    )
in
    WithDenseRank
```

### Group and Aggregate

```powerquery
// Multiple aggregations
Grouped = Table.Group(
    Source,
    {"country", "product_category"},
    {
        {"total_sales", each List.Sum([amount]), type number},
        {"avg_sale", each List.Average([amount]), type number},
        {"max_sale", each List.Max([amount]), type number},
        {"min_sale", each List.Min([amount]), type number},
        {"order_count", each Table.RowCount(_), type number},
        {"unique_customers", each List.Count(List.Distinct([customer_id])), type number},
        {"first_order_date", each List.Min([order_date]), type date},
        {"last_order_date", each List.Max([order_date]), type date}
    }
)

// Keep all rows as nested table
GroupedWithDetails = Table.Group(
    Source,
    {"country"},
    {
        {"orders", each _, type table},
        {"total", each List.Sum([amount]), type number}
    }
)
```

## Custom Functions

### Reusable Functions

```powerquery
// Function: Calculate tax
CalculateTax = (amount as number, country as text) as number =>
    if country = "FR" then amount * 0.20
    else if country = "BE" then amount * 0.21
    else if country = "CH" then amount * 0.077
    else amount * 0.19  // Default

// Use in query
let
    Source = /* sales data */,
    WithTax = Table.AddColumn(Source, "tax",
        each CalculateTax([amount], [country]),
        type number)
in
    WithTax
```

```powerquery
// Function: Clean phone number
CleanPhone = (phone as text) as text =>
    let
        removed = Text.Remove(phone, {" ", "-", "(", ")", "+"}),
        cleaned = Text.Trim(removed)
    in
        cleaned

// Apply to column
Cleaned = Table.TransformColumns(Source, {
    {"phone", CleanPhone, type text}
})
```

### Function with Error Handling

```powerquery
SafeDivide = (numerator as number, denominator as number) as number =>
    try
        if denominator = 0 then
            0
        else
            numerator / denominator
    otherwise
        null

// Use
Calculated = Table.AddColumn(Source, "ratio",
    each SafeDivide([value1], [value2]),
    type number
)
```

## Performance Patterns

### Buffering

```powerquery
// Buffer small lookup tables
let
    LargeSales = /* 10M rows */,
    SmallProducts = /* 1000 rows */,
    BufferedProducts = Table.Buffer(SmallProducts),  // Load in memory

    WithProduct = Table.AddColumn(LargeSales, "product_name",
        each
            let
                match = Table.SelectRows(BufferedProducts,
                    (p) => p[product_id] = [product_id])
            in
                if Table.RowCount(match) > 0 then
                    match{0}[product_name]
                else
                    null
    )
in
    WithProduct
```

### List.Generate for Efficiency

```powerquery
// Generate date table efficiently
DateTable = List.Generate(
    () => #date(2020, 1, 1),
    each _ <= #date(2024, 12, 31),
    each Date.AddDays(_, 1)
)

// Convert to table with attributes
DateTableExpanded = Table.FromRecords(
    List.Transform(DateTable, each [
        Date = _,
        Year = Date.Year(_),
        Month = Date.Month(_),
        MonthName = Date.MonthName(_),
        Quarter = "Q" & Text.From(Number.RoundUp(Date.Month(_) / 3)),
        DayOfWeek = Date.DayOfWeekName(_),
        IsWeekend = Date.DayOfWeek(_, Day.Monday) >= 5
    ])
)
```

## Best Practices

### ✅ Query Structure

```powerquery
let
    // 1. Source (document where data comes from)
    Source = Sql.Database("server.db.net", "SalesDB"),

    // 2. Navigation (get specific table)
    sales_table = Source{[Schema="dbo",Item="sales"]}[Data],

    // 3. Filter early (query folding)
    FilteredEarly = Table.SelectRows(sales_table,
        each [year] = 2024 and [amount] > 0),

    // 4. Select needed columns only
    SelectedColumns = Table.SelectColumns(FilteredEarly,
        {"sale_id", "customer_id", "amount", "sale_date"}),

    // 5. Transformations (in logical order)
    CleanedData = Table.TransformColumns(SelectedColumns, ...),

    // 6. Enrichment (lookups, calculations)
    EnrichedData = Table.AddColumn(CleanedData, ...),

    // 7. Final cleanup
    FinalData = Table.RemoveColumns(EnrichedData, {"temp_column"})
in
    FinalData
```

### ✅ Error Handling

```powerquery
let
    // Wrap risky operations in try
    Source = try
        Sql.Database("server", "db")
    otherwise
        #table({"Error"}, {{"Connection failed"}}),

    // Safe type conversions
    SafeNumbers = Table.TransformColumns(Source, {
        {"amount", each try Number.From(_) otherwise 0, type number}
    }),

    // Null checks
    ValidData = Table.SelectRows(SafeNumbers,
        each [customer_id] <> null and [amount] <> null)
in
    ValidData
```

### ✅ Performance

```powerquery
// ✅ Good
let
    Source = ...,
    FilteredEarly = Table.SelectRows(Source, each [year] = 2024),  // Folds
    Selected = Table.SelectColumns(FilteredEarly, {"id", "amount"}),  // Folds
    Transformed = Table.TransformColumns(Selected, ...)  // After filtering
in
    Transformed

// ❌ Bad
let
    Source = ...,
    Transformed = Table.TransformColumns(Source, ...),  // All data loaded
    Filtered = Table.SelectRows(Transformed, each [year] = 2024)  // After
in
    Filtered
```

## Points Clés

- Pivot/Unpivot pour reshaping data
- Merge queries = joins (Inner, Left, Right, Full, Anti)
- Append queries = union de tables
- Lookups avec buffering pour performance
- Data quality: duplicates, errors, nulls handling
- Text processing: parse, split, regex
- Advanced calculations: running totals, moving averages, ranking
- Custom functions pour réutilisabilité
- Performance: buffer lookups, filter early, query folding
- Error handling dans transformations critiques

---

**Prochain fichier :** [04 - Destinations](./04-destinations.md)

[⬅️ Fichier précédent](./02-dataflow-creation.md) | [⬅️ Retour au README du module](./README.md)
