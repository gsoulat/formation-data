# Best Practices Dataflows

## Introduction

Les **best practices** pour Dataflows Gen2 couvrent la performance, la maintenabilité, la qualité des données, et la gouvernance.

```
Best Practices Categories:
├── Performance & Optimization
├── Query Design & Folding
├── Error Handling & Resilience
├── Documentation & Naming
├── Security & Governance
└── Testing & Validation
```

## Performance & Optimization

### ✅ Query Folding

**Maximize Folding :**
```powerquery
// ✅ GOOD: Operations fold to source
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // These operations fold (pushed to SQL):
    Filtered = Table.SelectRows(sales, each
        [year] = 2024                    // WHERE year = 2024
        and [amount] > 100               // AND amount > 100
    ),
    Selected = Table.SelectColumns(Filtered,
        {"id", "customer_id", "amount"}), // SELECT id, customer_id, amount
    Sorted = Table.Sort(Selected,
        {{"amount", Order.Descending}})  // ORDER BY amount DESC
in
    Sorted

// Native query generated (efficient!):
-- SELECT id, customer_id, amount
-- FROM sales
-- WHERE year = 2024 AND amount > 100
-- ORDER BY amount DESC

// ❌ BAD: Breaks folding
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // Custom function breaks folding
    WithUpper = Table.AddColumn(sales, "name_upper",
        each Text.Upper([customer_name])),  // ← Breaks folding

    // Now filter doesn't fold (all data loaded first!)
    Filtered = Table.SelectRows(WithUpper, each [year] = 2024)
in
    Filtered

// All 100M rows loaded, then filtered in Power Query!
```

**Check Folding :**
```
Right-click step → View Native Query

✅ Shows SQL → Folding works
❌ Error message → Folding broken
```

### ✅ Filter Early, Select Columns Early

```powerquery
// ✅ GOOD: Filter and select early
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // 1. Filter first (reduce rows)
    Filtered = Table.SelectRows(sales, each [year] = 2024),
    // → 100M rows → 5M rows

    // 2. Select columns (reduce columns)
    Selected = Table.SelectColumns(Filtered, {"id", "amount", "date"}),
    // → 50 columns → 3 columns

    // 3. Now transform (on 5M rows x 3 columns)
    Transformed = Table.TransformColumns(Selected, ...)
in
    Transformed

// ❌ BAD: Transform all data first
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // 1. Transform on 100M rows x 50 columns
    Transformed = Table.TransformColumns(sales, ...),

    // 2. Then filter (too late!)
    Filtered = Table.SelectRows(Transformed, each [year] = 2024)
in
    Filtered
```

### ✅ Buffer Lookup Tables

```powerquery
// ✅ GOOD: Buffer small lookup table
let
    Sales = /* 10M rows */,
    Products = /* 1000 rows */,

    // Load products in memory once
    BufferedProducts = Table.Buffer(Products),

    // Lookup from memory (fast!)
    Enriched = Table.AddColumn(Sales, "product_name",
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
    Enriched

// ❌ BAD: No buffering
let
    Sales = /* 10M rows */,
    Products = /* 1000 rows */,

    // Lookup scans Products table 10M times!
    Enriched = Table.AddColumn(Sales, "product_name",
        each
            let
                match = Table.SelectRows(Products,  // ← Re-scans every time
                    (p) => p[product_id] = [product_id])
            in
                ...
    )
in
    Enriched
```

### ✅ Use Native Joins (Merge) When Possible

```powerquery
// ✅ GOOD: Native merge (can fold)
let
    Sales = Sql.Database("server", "db"){[Item="sales"]}[Data],
    Customers = Sql.Database("server", "db"){[Item="customers"]}[Data],

    // Merge folds to SQL JOIN
    Merged = Table.NestedJoin(
        Sales, {"customer_id"},
        Customers, {"customer_id"},
        "customer",
        JoinKind.LeftOuter
    ),

    Expanded = Table.ExpandTableColumn(Merged, "customer",
        {"name", "country"})
in
    Expanded

// Native query:
-- SELECT s.*, c.name, c.country
-- FROM sales s
-- LEFT JOIN customers c ON s.customer_id = c.customer_id

// ❌ BAD: Manual lookup (doesn't fold)
WithCustomer = Table.AddColumn(Sales, "customer_name",
    each
        let
            match = Table.SelectRows(Customers,
                (c) => c[customer_id] = [customer_id])
        in
            match{0}[name]
)
```

## Query Design

### ✅ Descriptive Naming

```powerquery
// ✅ GOOD: Clear names
let
    Source_SQL_SalesDB = Sql.Database("sql-prod.company.com", "SalesDB"),
    RawSalesTable = Source_SQL_SalesDB{[Schema="dbo",Item="sales"]}[Data],
    FilterCurrentYear = Table.SelectRows(RawSalesTable, each [year] = 2024),
    ActiveCustomersOnly = Table.SelectRows(FilterCurrentYear, each [is_active] = true),
    SelectedColumns = Table.SelectColumns(ActiveCustomersOnly, {"id", "amount"}),
    FinalCleanedData = Table.RenameColumns(SelectedColumns, {{"id", "sale_id"}})
in
    FinalCleanedData

// ❌ BAD: Generic names
let
    Source = Sql.Database("server", "db"),
    Table1 = Source{[Item="sales"]}[Data],
    Step1 = Table.SelectRows(Table1, each [year] = 2024),
    Step2 = Table.SelectRows(Step1, each [is_active] = true),
    Result = Step2
in
    Result
```

### ✅ One Responsibility Per Query

```powerquery
// ✅ GOOD: Separate concerns

// Query 1: Source_Customers
let
    Source = Sql.Database("server", "db"),
    customers = Source{[Item="customers"]}[Data]
in
    customers

// Query 2: Cleaned_Customers (references Query 1)
let
    Source = Source_Customers,
    Filtered = Table.SelectRows(Source, each [is_active] = true),
    Cleaned = Table.TransformColumns(Filtered, ...)
in
    Cleaned

// Query 3: Final_Customers (references Query 2)
let
    Source = Cleaned_Customers,
    Enriched = Table.AddColumn(Source, ...),
    Final = Table.SelectColumns(Enriched, ...)
in
    Final

// ❌ BAD: Everything in one query (monolithic)
let
    Source = Sql.Database("server", "db"),
    customers = Source{[Item="customers"]}[Data],
    Filtered = Table.SelectRows(customers, each [is_active] = true),
    Cleaned = Table.TransformColumns(Filtered, ...),
    Enriched = Table.AddColumn(Cleaned, ...),
    Final = Table.SelectColumns(Enriched, ...)
in
    Final
```

### ✅ Use Parameters for Flexibility

```powerquery
// Create parameters
Environment = "prod" meta [IsParameterQuery=true],
BatchSize = 1000 meta [IsParameterQuery=true],
StartDate = #date(2024, 1, 1) meta [IsParameterQuery=true]

// Use in queries
let
    Server = if Environment = "prod" then "sql-prod.com" else "sql-dev.com",
    Source = Sql.Database(Server, "SalesDB"),
    sales = Source{[Item="sales"]}[Data],

    Filtered = Table.SelectRows(sales, each
        [sale_date] >= StartDate
    ),

    Batched = Table.FirstN(Filtered, BatchSize)
in
    Batched
```

## Error Handling

### ✅ Robust Error Handling

```powerquery
let
    // Safe source connection
    Source = try
        Sql.Database("server", "db")
    otherwise
        #table({"Error"}, {{"Cannot connect to database"}}),

    // Safe table access
    customers = try
        Source{[Schema="dbo",Item="customers"]}[Data]
    otherwise
        #table({"Error"}, {{"Table not found"}}),

    // Safe type conversions
    WithAmount = Table.TransformColumns(customers, {
        {"amount", each try Number.From(_) otherwise 0, type number}
    }),

    // Safe date parsing
    WithDate = Table.TransformColumns(WithAmount, {
        {"order_date", each
            try Date.From(_)
            otherwise #date(1900, 1, 1),
            type date}
    }),

    // Remove errors
    ValidRows = Table.SelectRows(WithDate, each
        [customer_id] <> null
        and [amount] <> null
    )
in
    ValidRows
```

### ✅ Null Handling

```powerquery
// ✅ GOOD: Explicit null handling
let
    Source = /* data */,

    // Replace nulls
    WithDefaults = Table.ReplaceValue(
        Source,
        null,
        "Unknown",
        Replacer.ReplaceValue,
        {"country"}
    ),

    // Coalesce columns
    WithFallback = Table.AddColumn(Source, "final_value",
        each [primary_value] ?? [secondary_value] ?? [default_value] ?? 0
    ),

    // Filter out nulls
    NoNulls = Table.SelectRows(Source, each
        [customer_id] <> null
        and [amount] <> null
    )
in
    NoNulls

// ❌ BAD: Assume no nulls
Calculated = Table.AddColumn(Source, "ratio",
    each [value1] / [value2]  // ← Crash si null!
)
```

## Data Quality

### ✅ Validation Columns

```powerquery
let
    Source = /* raw data */,

    // Add validation flags
    WithValidation = Table.AddColumn(Source, "is_valid",
        each
            [customer_id] <> null
            and [email] <> null
            and Text.Contains([email], "@")
            and [amount] > 0
            and [sale_date] <= Date.From(DateTime.LocalNow())
    ),

    // Add error descriptions
    WithErrors = Table.AddColumn(WithValidation, "validation_errors",
        each
            if [customer_id] = null then "Missing customer ID"
            else if [email] = null then "Missing email"
            else if not Text.Contains([email], "@") then "Invalid email format"
            else if [amount] <= 0 then "Invalid amount"
            else if [sale_date] > Date.From(DateTime.LocalNow()) then "Future date"
            else "OK"
    ),

    // Split valid/invalid
    ValidData = Table.SelectRows(WithErrors, each [is_valid] = true),
    InvalidData = Table.SelectRows(WithErrors, each [is_valid] = false)
in
    ValidData  // Load valid to destination
    // InvalidData can be sent to error log
```

### ✅ Deduplication Strategy

```powerquery
// ✅ GOOD: Keep latest based on timestamp
let
    Source = /* data with duplicates */,

    // Sort by timestamp descending
    Sorted = Table.Sort(Source, {
        {"customer_id", Order.Ascending},
        {"updated_at", Order.Descending}
    }),

    // Keep first occurrence (latest due to sort)
    Deduplicated = Table.Distinct(Sorted, {"customer_id"}),

    // Remove sort column if temporary
    Final = Table.RemoveColumns(Deduplicated, {"updated_at"})
in
    Final

// ❌ BAD: Arbitrary deduplication
Deduplicated = Table.Distinct(Source, {"customer_id"})
// Which row kept? Unknown!
```

## Documentation

### ✅ Comments and Metadata

```powerquery
let
    /*
     * Source: SQL Server Production Database
     * Purpose: Extract customer data for analytics
     * Owner: Data Team
     * Last modified: 2024-01-15
     */

    // Connection to production SQL Server
    Source = Sql.Database("sql-prod.company.com", "SalesDB"),

    // Get customers table
    customers_table = Source{[Schema="dbo",Item="customers"]}[Data],

    /*
     * Filter to active customers only to reduce data volume.
     * Active = customer with activity in last 12 months.
     */
    ActiveCustomers = Table.SelectRows(customers_table, each
        [is_active] = true
        and [last_activity_date] >= Date.AddMonths(Date.From(DateTime.LocalNow()), -12)
    ),

    // Transform columns to standard format
    StandardizedData = Table.TransformColumns(ActiveCustomers, {
        {"first_name", Text.Proper, type text},
        {"last_name", Text.Proper, type text},
        {"email", Text.Lower, type text}
    }),

    /*
     * Add calculated age column based on birth_date.
     * Age = (Today - birth_date) / 365.25 to account for leap years.
     */
    WithAge = Table.AddColumn(StandardizedData, "age",
        each Duration.Days(DateTime.LocalNow() - DateTime.From([birth_date])) / 365.25,
        Int64.Type
    )
in
    WithAge
```

### ✅ Query Organization

```
Query Groups (folders):
├── 📁 Parameters
│   ├── Environment
│   ├── RangeStart
│   └── RangeEnd
├── 📁 Sources
│   ├── Source_SQL_Customers
│   ├── Source_SQL_Orders
│   └── Source_API_Products
├── 📁 Transformations
│   ├── Cleaned_Customers
│   ├── Enriched_Orders
│   └── Joined_Customer_Orders
├── 📁 Functions
│   ├── fn_CalculateTax
│   └── fn_CleanPhone
└── 📁 Outputs (Destinations)
    ├── Final_Customers
    └── Final_Orders
```

## Security & Governance

### ✅ Credentials Management

```
❌ DON'T hardcode credentials:
  Source = Sql.Database("server", "db", [User="admin", Password="pass123"])

✅ DO use stored credentials:
  Source = Sql.Database("server", "db")
  // Credentials stored securely in workspace

✅ DO use service principals:
  // Configured at workspace level
  // Automatic authentication
```

### ✅ Row-Level Security

```powerquery
// Apply RLS in dataflow (if source doesn't support)
let
    Source = /* all data */,

    // Get current user
    CurrentUser = "user@company.com",  // Or from parameter

    // Filter based on user
    FilteredByUser = Table.SelectRows(Source, each
        [sales_rep_email] = CurrentUser
        or List.Contains({"admin@company.com", "manager@company.com"}, CurrentUser)
    )
in
    FilteredByUser

// Better: Use source RLS if available (query folding)
```

### ✅ PII Handling

```powerquery
// Mask sensitive data
let
    Source = /* customer data with PII */,

    // Hash email
    MaskedEmail = Table.TransformColumns(Source, {
        {"email", each Text.Start(_, 3) & "***@" & Text.AfterDelimiter(_, "@"), type text}
    }),

    // Mask phone
    MaskedPhone = Table.TransformColumns(MaskedEmail, {
        {"phone", each "***-***-" & Text.End(_, 4), type text}
    }),

    // Remove SSN column entirely
    Final = Table.RemoveColumns(MaskedPhone, {"ssn"})
in
    Final
```

## Testing & Validation

### ✅ Test Queries

```powerquery
// Create test query with sample data
TestData = #table(
    {"customer_id", "name", "email", "amount"},
    {
        {1, "John Doe", "john@example.com", 100},
        {2, "Jane Smith", null, 200},  // Test null handling
        {3, "Bob Invalid", "not-an-email", -50},  // Test validation
        {1, "John Duplicate", "john2@example.com", 150}  // Test deduplication
    }
)

// Apply transformations
TestResult = /* your transformation logic on TestData */

// Verify:
// - Null handling works
// - Validation catches invalid email
// - Deduplication removes duplicate customer_id
```

### ✅ Assertions

```powerquery
let
    Source = /* data */,
    Transformed = /* transformations */,

    // Assertions
    RowCount = Table.RowCount(Transformed),
    AssertNotEmpty = if RowCount = 0 then
        error "No rows returned! Check filters."
        else Transformed,

    // Check required columns exist
    ColumnNames = Table.ColumnNames(AssertNotEmpty),
    RequiredColumns = {"customer_id", "name", "email"},
    AssertColumns = if List.ContainsAll(ColumnNames, RequiredColumns) then
        AssertNotEmpty
        else error "Missing required columns",

    // Check no nulls in key column
    NullCount = Table.RowCount(Table.SelectRows(AssertColumns,
        each [customer_id] = null)),
    AssertNoNulls = if NullCount > 0 then
        error "Found " & Text.From(NullCount) & " null customer IDs"
        else AssertColumns
in
    AssertNoNulls
```

## Performance Monitoring

### ✅ Query Diagnostics

```
Tools → Query Diagnostics → Start Diagnostics
... perform operations ...
Tools → Query Diagnostics → Stop Diagnostics

Review:
  ├─ Which steps took longest?
  ├─ Which steps folded to source?
  ├─ Memory usage per step
  └─ Data source queries generated

Optimize based on findings.
```

### ✅ Profiling

```
View → Column quality
View → Column distribution
View → Column profile

Check:
  • Errors per column
  • Null count
  • Distinct values (cardinality)
  • Min/Max/Average

Optimize:
  • Remove error-prone columns
  • Handle nulls early
  • Use high-cardinality columns for joins
```

## Deployment

### ✅ Environment Strategy

```
Development Dataflow:
  • Parameters: Environment = "dev"
  • Source: dev databases
  • Destination: dev lakehouse
  • Refresh: Manual

Production Dataflow:
  • Parameters: Environment = "prod"
  • Source: prod databases
  • Destination: prod lakehouse
  • Refresh: Scheduled (daily 8 AM)

Use parameters to switch between environments!
```

### ✅ Change Management

```
1. Version control (if using Git integration)
2. Test in DEV workspace first
3. Document changes in comments
4. Deploy to PROD during maintenance window
5. Monitor first refresh closely
6. Validate row counts match expectations
```

## Checklist

### Before Publishing

```
✅ Query folding verified (View Native Query)
✅ No hardcoded credentials
✅ Parameters used for environments
✅ Error handling on all risky operations
✅ Null handling explicit
✅ Comments added to complex logic
✅ Query names descriptive
✅ Test with sample data
✅ Destination configured correctly
✅ Refresh schedule set (if needed)
✅ Failure alerts configured
✅ Documentation updated
```

### After Publishing

```
✅ First refresh successful
✅ Row counts validated
✅ Data quality checks pass
✅ Downstream consumers notified
✅ Performance monitored
✅ Error logs reviewed
✅ Incremental refresh working (if enabled)
```

## Points Clés

- Query folding = priorité #1 pour performance
- Filter early, select columns early
- Buffer lookup tables
- Descriptive naming pour maintenabilité
- Robust error handling (try-otherwise)
- Explicit null handling
- Data validation columns
- Comments et documentation
- Parameters pour flexibility
- Test avant déploiement
- Monitor performance avec diagnostics
- Security: pas de credentials hardcodés
- Environment-specific parameters

---

**Module 05 COMPLET** ✅

[⬅️ Fichier précédent](./05-incremental-refresh.md) | [➡️ Module suivant : Notebooks & Spark](../../06-Notebooks-Spark/) | [⬅️ Retour au README du module](./README.md)
