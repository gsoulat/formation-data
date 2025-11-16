# Création de Dataflows

## Introduction

Les **Dataflows Gen2** permettent de créer des transformations de données **no-code** ou **low-code** dans Fabric, accessibles aux analysts sans compétences de programmation.

```
Dataflow Workflow:
┌────────────────────────────────────────┐
│  1. Get Data (Sources)                 │
│  2. Transform (Power Query)            │
│  3. Configure Destination              │
│  4. Publish & Refresh                  │
└────────────────────────────────────────┘
```

## Création d'un Dataflow

### Via UI

```
1. Workspace → + New item
2. Dataflow Gen2
3. Nom: "Transform_Customer_Data"
4. Get data → Choose connector
```

**Interface Dataflow :**
```
┌────────────────────────────────────────┐
│  Queries Pane (left)                   │
│  ├─ Source_Customers                   │
│  ├─ Source_Orders                      │
│  └─ Transformed_Data                   │
├────────────────────────────────────────┤
│  Preview Pane (center)                 │
│  [Data preview with sample rows]       │
├────────────────────────────────────────┤
│  Applied Steps (right)                 │
│  ├─ Source                             │
│  ├─ Changed Type                       │
│  ├─ Filtered Rows                      │
│  └─ Removed Columns                    │
└────────────────────────────────────────┘
```

## Data Sources (Get Data)

### SQL Database

```
1. Get data → SQL Server
2. Server: sql.company.com
3. Database: SalesDB
4. Connection credentials:
   ├─ Windows
   ├─ Database (SQL auth)
   ├─ Microsoft account
   └─ Service principal
5. Navigator → Select tables
6. Transform data
```

**Connection String :**
```
Server: sql-prod.company.com
Database: SalesDB
Authentication: SQL Server Authentication
Username: dataflow_user
Password: ••••••••

Advanced options:
  ├─ Command timeout: 600 seconds
  ├─ SQL statement: SELECT * FROM sales WHERE year = 2024
  └─ Connection string parameters
```

### Azure Blob Storage

```
1. Get data → Azure Blob Storage
2. Account name: storageaccount.blob.core.windows.net
3. Container: raw-data
4. Authentication:
   ├─ Account key
   ├─ SAS token
   └─ Organizational account
5. Navigate to folder/file
6. Transform
```

**File Formats Supported :**
```
• CSV
• JSON
• Parquet
• Excel (.xlsx, .xls)
• XML
• Text
• Binary
```

### REST API

```
1. Get data → Web → From Web
2. URL: https://api.company.com/data
3. Advanced:
   ├─ HTTP request headers
   │  ├─ Authorization: Bearer {token}
   │  └─ Content-Type: application/json
   ├─ HTTP method: GET/POST
   └─ Body (pour POST)
4. Parse JSON response
5. Transform
```

**Example API Call :**
```powerquery
let
    url = "https://api.company.com/customers",
    headers = [
        #"Authorization" = "Bearer " & ApiToken,
        #"Content-Type" = "application/json"
    ],
    response = Web.Contents(url, [Headers=headers]),
    json = Json.Document(response),
    table = Table.FromRecords(json[data])
in
    table
```

### Lakehouse/Warehouse

```
1. Get data → OneLake data hub
2. Select Lakehouse ou Warehouse
3. Browse:
   ├─ Lakehouse: Tables/ ou Files/
   └─ Warehouse: Schemas/Tables
4. Select table
5. Transform
```

**Direct Query :**
```powerquery
let
    Source = Lakehouse.Contents("workspace-id", "lakehouse-id"),
    Navigation = Source{[workspaceId="...", lakehouseId="...", itemKind="Table"]}[Data],
    dbo_sales = Navigation{[Schema="dbo", Item="sales"]}[Data]
in
    dbo_sales
```

### Excel File

```
1. Get data → Excel workbook
2. Upload ou browse OneLake
3. Select sheets/tables
4. Transform
```

**Excel Options :**
```
• First row as headers: Yes/No
• Data type detection: Automatic/None
• Range: A1:Z1000
• Sheet name: Sheet1
```

### SharePoint List

```
1. Get data → SharePoint Online List
2. Site URL: https://company.sharepoint.com/sites/sales
3. List name: Customer Feedback
4. Authentication: Organizational account
5. Transform
```

## Transformations

### UI Transformations (No-Code)

**Column Operations :**
```
Right-click column → Transform:
├─ Change type (Text, Number, Date)
├─ Remove
├─ Duplicate
├─ Rename
├─ Replace values
├─ Fill (Up/Down)
├─ Split column (by delimiter, positions)
└─ Extract (First/Last/Range characters)
```

**Row Operations :**
```
Home tab → Reduce Rows:
├─ Remove Top Rows
├─ Remove Bottom Rows
├─ Keep Top Rows
├─ Keep Bottom Rows
├─ Remove Duplicates
├─ Remove Blanks
└─ Remove Errors
```

**Filter Operations :**
```
Column dropdown → Filter:
├─ Text Filters (Contains, Equals, Begins with, Ends with)
├─ Number Filters (Greater than, Less than, Between)
├─ Date Filters (Before, After, Between)
└─ Advanced Filter (custom conditions)
```

**Add Column Operations :**
```
Add Column tab:
├─ Custom Column (M formula)
├─ Conditional Column (if-then-else UI)
├─ Index Column
├─ Duplicate Column
└─ Column From Examples (AI-powered)
```

### Example: Clean Customer Data

```
Steps:
1. Get Data: SQL Server → customers table
2. Remove Columns: internal_id, temp_flag
3. Filter Rows: is_active = true
4. Remove Duplicates: by email
5. Transform Columns:
   ├─ first_name → Proper Case
   ├─ last_name → Proper Case
   └─ email → Lowercase
6. Trim Whitespace: all text columns
7. Add Column: full_name = first_name & " " & last_name
8. Change Type: birth_date → Date
9. Add Column: age = (Today - birth_date) / 365
10. Rename Columns: snake_case convention
```

**Resulting M Code :**
```powerquery
let
    Source = Sql.Database("sql.company.com", "SalesDB"),
    dbo_customers = Source{[Schema="dbo",Item="customers"]}[Data],
    RemovedColumns = Table.RemoveColumns(dbo_customers, {"internal_id", "temp_flag"}),
    FilteredRows = Table.SelectRows(RemovedColumns, each [is_active] = true),
    RemovedDuplicates = Table.Distinct(FilteredRows, {"email"}),
    TransformedText = Table.TransformColumns(RemovedDuplicates, {
        {"first_name", Text.Proper, type text},
        {"last_name", Text.Proper, type text},
        {"email", Text.Lower, type text}
    }),
    TrimmedText = Table.TransformColumns(TransformedText, {
        {"first_name", Text.Trim, type text},
        {"last_name", Text.Trim, type text}
    }),
    AddedFullName = Table.AddColumn(TrimmedText, "full_name",
        each [first_name] & " " & [last_name], type text),
    ChangedType = Table.TransformColumnTypes(AddedFullName, {
        {"birth_date", type date}
    }),
    AddedAge = Table.AddColumn(ChangedType, "age",
        each Duration.Days(DateTime.LocalNow() - DateTime.From([birth_date])) / 365,
        Int64.Type),
    RenamedColumns = Table.RenameColumns(AddedAge, {
        {"CustomerID", "customer_id"},
        {"FirstName", "first_name"}
    })
in
    RenamedColumns
```

## Advanced Editor

### Accès

```
Home tab → Advanced Editor

ou

View → Advanced Editor
```

**Interface :**
```
┌────────────────────────────────────────┐
│  [M Code Editor]                       │
│                                        │
│  let                                   │
│      Source = ...,                     │
│      Step1 = ...,                      │
│      ...                               │
│  in                                    │
│      FinalStep                         │
│                                        │
├────────────────────────────────────────┤
│  [Syntax Check] [Done] [Cancel]        │
└────────────────────────────────────────┘
```

### Editing M Code

```powerquery
let
    // 1. Source - editable
    Source = Sql.Database("sql.company.com", "SalesDB"),

    // 2. Get table - editable
    sales_table = Source{[Schema="dbo",Item="sales"]}[Data],

    // 3. Add custom logic
    FilteredData = Table.SelectRows(sales_table, each
        [sale_date] >= #date(2024, 1, 1)
        and [amount] > 0
        and [country] <> null
    ),

    // 4. Complex transformation
    EnrichedData = Table.AddColumn(FilteredData, "quarter",
        each "Q" & Number.ToText(Number.RoundUp(Date.Month([sale_date]) / 3)),
        type text
    ),

    // 5. Aggregation
    Grouped = Table.Group(EnrichedData, {"country", "quarter"}, {
        {"total_sales", each List.Sum([amount]), type number},
        {"order_count", each Table.RowCount(_), type number}
    })
in
    Grouped
```

## Query Dependencies

### Referencing Queries

```powerquery
// Query 1: Base data
let
    Source = Sql.Database("server", "db"),
    customers = Source{[Schema="dbo",Item="customers"]}[Data]
in
    customers

// Query 2: References Query 1
let
    Source = Query1,  // Reference to "Query 1"
    FilteredCustomers = Table.SelectRows(Source, each [country] = "FR")
in
    FilteredCustomers

// Query 3: Merge Query 1 and Query 2
let
    AllCustomers = Query1,
    FrenchCustomers = Query2,
    Merged = Table.NestedJoin(
        AllCustomers, {"customer_id"},
        FrenchCustomers, {"customer_id"},
        "french_data",
        JoinKind.LeftOuter
    )
in
    Merged
```

### Query Parameters

```
Créer Parameter:
1. Home → Manage Parameters → New Parameter
2. Name: StartDate
3. Type: Date/Time
4. Current Value: 2024-01-01
5. Suggested Values: Any value / List of values
```

**Use Parameter :**
```powerquery
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],
    Filtered = Table.SelectRows(sales, each
        [sale_date] >= StartDate  // Parameter reference
    )
in
    Filtered
```

**Parameter Types :**
```
• Text: "value"
• Number: 123
• True/False: true
• Date: #date(2024,1,15)
• Date/Time: #datetime(2024,1,15,10,0,0)
• Duration: #duration(1,0,0,0)
• List: {"A", "B", "C"}
• Record: [field1="value", field2=123]
• Any (dynamic)
```

## Query Diagnostics

### Enable Diagnostics

```
Tools → Query Diagnostics → Start Diagnostics
... perform operations ...
Tools → Query Diagnostics → Stop Diagnostics
```

**Diagnostic Output :**
```
Diagnostics generates:
├─ Query execution time
├─ Data source queries
├─ Query folding details
├─ Memory usage
└─ Bottlenecks identified
```

**Example Output :**
```
Step: Filtered Rows
  Duration: 0.2s
  Query folded: Yes
  Native query: SELECT * FROM sales WHERE year = 2024

Step: Transform Columns
  Duration: 2.5s
  Query folded: No
  Rows processed: 1,000,000
  Memory: 120 MB
```

## Data Preview Settings

### Sample Rows

```
View → Data Preview → First 1000 rows (default)
View → Data Preview → Column profile (statistics)
View → Data Preview → Column distribution (histogram)
View → Data Preview → Column quality (errors, empties)
```

**Column Profile :**
```
Column: amount
  Count: 1000
  Error: 5 (0.5%)
  Empty: 10 (1%)
  Distinct: 850
  Unique: 800
  Min: 0
  Max: 10000
  Average: 325.50
  Std Deviation: 145.23
```

**Column Distribution :**
```
[Histogram showing frequency distribution]

Bins:
  0-100: ████████ (200 values)
  100-500: ████████████ (350 values)
  500-1000: ██████ (250 values)
  1000+: ████ (200 values)
```

**Column Quality :**
```
✅ Valid: 985 (98.5%)
❌ Error: 5 (0.5%)
⚠️ Empty: 10 (1%)
```

## Performance Optimization

### Query Folding

**Check Folding :**
```
Right-click step → View Native Query

If enabled:
  Shows SQL/native query pushed to source

If disabled:
  "This step doesn't support query folding"
```

**Optimize for Folding :**
```powerquery
// ✅ Good: Operations fold
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],
    Filtered = Table.SelectRows(sales, each [year] = 2024),  // Folds
    Selected = Table.SelectColumns(Filtered, {"id", "amount"}),  // Folds
    Sorted = Table.Sort(Selected, {{"amount", Order.Descending}})  // Folds
in
    Sorted

// Native query generated:
// SELECT id, amount
// FROM sales
// WHERE year = 2024
// ORDER BY amount DESC

// ❌ Bad: Breaks folding
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],
    Custom = Table.AddColumn(sales, "custom", each Text.Upper([name])),  // Breaks
    Filtered = Table.SelectRows(Custom, each [year] = 2024)
in
    Filtered

// All data loaded, then transformed in Power Query
```

### Reduce Data Volume

```powerquery
// 1. Filter early
Filtered = Table.SelectRows(Source, each [year] = 2024)

// 2. Select only needed columns
Selected = Table.SelectColumns(Filtered, {"id", "name", "amount"})

// 3. Limit rows (for testing)
Top1000 = Table.FirstN(Selected, 1000)
```

## Best Practices

### ✅ Organization

```
Query Naming:
  ✅ Source_Customers
  ✅ Transform_Customers
  ✅ Final_Customer_Data

  ❌ Query1
  ❌ Table1
  ❌ Step3

Query Groups:
  • Sources (raw data)
  • Transformations (intermediate)
  • Outputs (final queries)
  • Parameters
  • Functions
```

### ✅ Documentation

```powerquery
// Add comments to complex steps
let
    Source = Sql.Database("server", "db"),
    sales = Source{[Schema="dbo",Item="sales"]}[Data],

    // Filter to current year only to reduce data volume
    CurrentYear = Table.SelectRows(sales, each Date.Year([sale_date]) = 2024),

    // Calculate tax based on country-specific rates
    WithTax = Table.AddColumn(CurrentYear, "tax", each
        if [country] = "FR" then [amount] * 0.20
        else if [country] = "BE" then [amount] * 0.21
        else [amount] * 0.20  // Default rate
    )
in
    WithTax
```

### ✅ Error Handling

```powerquery
let
    // Try to connect, fallback to empty table
    Source = try
        Sql.Database("server", "db")
    otherwise
        #table({"Error"}, {{"Cannot connect to database"}}),

    // Safe type conversion
    WithNumber = Table.TransformColumns(Source, {
        {"amount", each try Number.From(_) otherwise 0, type number}
    }),

    // Handle null values
    CleanData = Table.SelectRows(WithNumber, each
        [customer_id] <> null and [amount] <> null
    )
in
    CleanData
```

## Points Clés

- Dataflows Gen2 = transformations Power Query no-code
- Get Data: 100+ connectors (SQL, Blob, API, Lakehouse, Excel)
- UI transformations accessibles aux analysts
- Advanced Editor pour M code custom
- Query parameters pour dynamicité
- Query folding critique pour performance
- Diagnostics pour identifier bottlenecks
- Column profile/distribution pour data quality
- Best practices: naming, documentation, error handling

---

**Prochain fichier :** [03 - Transformations Avancées](./03-transformations.md)

[⬅️ Fichier précédent](./01-power-query-m.md) | [⬅️ Retour au README du module](./README.md)
