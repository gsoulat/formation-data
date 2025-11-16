# M Language (Power Query) Cheatsheet

## Fundamentals

### Data Types
```m
// Primitive Types
text_value = "Hello World"
number_value = 42
decimal_value = 3.14
boolean_value = true
null_value = null
date_value = #date(2024, 12, 25)
time_value = #time(14, 30, 0)
datetime_value = #datetime(2024, 12, 25, 14, 30, 0)
duration_value = #duration(1, 2, 30, 0)  // 1 day, 2 hours, 30 min

// Complex Types
list_value = {1, 2, 3, 4, 5}
record_value = [Name = "Alice", Age = 30, Active = true]
table_value = #table({"Col1", "Col2"}, {{1, "A"}, {2, "B"}})
```

### Let Expression
```m
let
    Source = Excel.Workbook(File.Contents("data.xlsx")),
    Sheet1 = Source{[Item="Sheet1"]}[Data],
    PromotedHeaders = Table.PromoteHeaders(Sheet1),
    FilteredRows = Table.SelectRows(PromotedHeaders, each [Status] = "Active"),
    Result = FilteredRows
in
    Result
```

### Comments
```m
// Single line comment

/*
   Multi-line
   comment
*/

// Documentation (appears in query description)
let
    // @description: Loads and transforms sales data
    // @author: Data Team
    Source = ...
```

## Data Sources

### Files
```m
// Excel
Excel.Workbook(File.Contents("C:\Data\sales.xlsx"))

// CSV
Csv.Document(File.Contents("data.csv"), [Delimiter=",", Encoding=65001])

// JSON
Json.Document(File.Contents("data.json"))

// Parquet (Fabric native)
Parquet.Document(File.Contents("data.parquet"))

// Folder (multiple files)
Folder.Files("C:\Data\Monthly")
```

### Databases
```m
// SQL Server
Sql.Database("server.database.windows.net", "database_name", [Query="SELECT * FROM Sales"])

// Azure Synapse
AzureSynapse.Database("workspace.sql.azuresynapse.net", "database")

// Fabric Lakehouse
Lakehouse.Tables("workspace_id", "lakehouse_id")

// Fabric Warehouse
FabricWarehouse.Tables("workspace_id", "warehouse_id")
```

### Web & APIs
```m
// Web page
Web.Page(Web.Contents("https://example.com/data"))

// REST API
Web.Contents(
    "https://api.example.com/data",
    [
        Headers = [
            #"Authorization" = "Bearer " & token,
            #"Content-Type" = "application/json"
        ],
        Query = [
            startDate = "2024-01-01",
            endDate = "2024-12-31"
        ]
    ]
)

// OData
OData.Feed("https://services.odata.org/V4/Northwind/Northwind.svc/")
```

## Table Operations

### Select & Remove Columns
```m
// Select specific columns
Table.SelectColumns(Source, {"Name", "Age", "City"})

// Remove columns
Table.RemoveColumns(Source, {"TempColumn", "OldColumn"})

// Reorder columns
Table.ReorderColumns(Source, {"ID", "Name", "Date", "Amount"})

// Rename columns
Table.RenameColumns(Source, {{"OldName", "NewName"}, {"Col2", "RenamedCol2"}})
```

### Filter Rows
```m
// Simple filter
Table.SelectRows(Source, each [Status] = "Active")

// Multiple conditions
Table.SelectRows(Source, each [Amount] > 100 and [Date] >= #date(2024, 1, 1))

// Text contains
Table.SelectRows(Source, each Text.Contains([Name], "Corp"))

// Not null
Table.SelectRows(Source, each [Email] <> null)

// In list
Table.SelectRows(Source, each List.Contains({"USA", "Canada", "Mexico"}, [Country]))

// Top N rows
Table.FirstN(Source, 100)

// Remove duplicates
Table.Distinct(Source, {"CustomerID"})
```

### Add Columns
```m
// Custom column
Table.AddColumn(Source, "FullName", each [FirstName] & " " & [LastName])

// Conditional column
Table.AddColumn(Source, "Status", each
    if [Amount] > 1000 then "High"
    else if [Amount] > 100 then "Medium"
    else "Low"
)

// Index column
Table.AddIndexColumn(Source, "RowIndex", 1, 1)

// Column from examples (UI feature)
// Generates M code automatically based on examples

// Duplicate column
Table.DuplicateColumn(Source, "OriginalColumn", "CopyColumn")
```

### Transform Columns
```m
// Change data type
Table.TransformColumnTypes(Source, {
    {"Date", type date},
    {"Amount", type number},
    {"Active", type logical}
})

// Replace values
Table.ReplaceValue(Source, "Old", "New", Replacer.ReplaceText, {"TextColumn"})

// Replace null
Table.ReplaceValue(Source, null, 0, Replacer.ReplaceValue, {"Amount"})

// Text transformations
Table.TransformColumns(Source, {
    {"Name", Text.Upper},
    {"Email", Text.Lower},
    {"Code", Text.Trim}
})

// Split column
Table.SplitColumn(Source, "FullName", Splitter.SplitTextByDelimiter(" "), {"FirstName", "LastName"})

// Merge columns
Table.CombineColumns(Source, {"FirstName", "LastName"}, Combiner.CombineTextByDelimiter(" "), "FullName")
```

### Group & Aggregate
```m
// Simple grouping
Table.Group(Source, {"Category"}, {
    {"TotalSales", each List.Sum([Amount]), type number},
    {"AvgSales", each List.Average([Amount]), type number},
    {"Count", each Table.RowCount(_), Int64.Type}
})

// Multiple grouping columns
Table.Group(Source, {"Year", "Month", "Region"}, {
    {"Revenue", each List.Sum([Amount]), type number},
    {"Transactions", each Table.RowCount(_), Int64.Type}
})

// All rows (nested table)
Table.Group(Source, {"CustomerID"}, {
    {"AllOrders", each _, type table}
})
```

### Join Tables
```m
// Inner join
Table.NestedJoin(Orders, {"CustomerID"}, Customers, {"ID"}, "CustomerData", JoinKind.Inner)

// Left outer join
Table.NestedJoin(Orders, {"ProductID"}, Products, {"ID"}, "ProductInfo", JoinKind.LeftOuter)

// Expand joined columns
Table.ExpandTableColumn(JoinedTable, "CustomerData", {"Name", "Email"}, {"CustomerName", "CustomerEmail"})

// Full outer join
Table.NestedJoin(Table1, {"Key"}, Table2, {"Key"}, "Merged", JoinKind.FullOuter)

// Anti join (rows not in other table)
Table.NestedJoin(Orders, {"ProductID"}, Discontinued, {"ID"}, "Match", JoinKind.LeftAnti)
```

### Append (Union)
```m
// Append two tables
Table.Combine({Table1, Table2})

// Append multiple tables
Table.Combine({Jan, Feb, Mar, Apr, May, Jun})

// From folder (all files)
let
    Source = Folder.Files("C:\Data\Monthly"),
    FilteredFiles = Table.SelectRows(Source, each Text.EndsWith([Name], ".csv")),
    LoadedFiles = Table.AddColumn(FilteredFiles, "Data", each Csv.Document([Content])),
    Combined = Table.Combine(LoadedFiles[Data])
in
    Combined
```

### Pivot & Unpivot
```m
// Pivot (rows to columns)
Table.Pivot(Source, List.Distinct(Source[Attribute]), "Attribute", "Value")

// Unpivot (columns to rows)
Table.UnpivotOtherColumns(Source, {"ID", "Name"}, "Attribute", "Value")

// Unpivot specific columns
Table.Unpivot(Source, {"Jan", "Feb", "Mar"}, "Month", "Sales")
```

## Text Functions

```m
// Manipulation
Text.Upper("hello")           // "HELLO"
Text.Lower("HELLO")           // "hello"
Text.Proper("hello world")    // "Hello World"
Text.Trim("  spaces  ")       // "spaces"
Text.Clean("text\nwith\ttabs") // Remove non-printable

// Extraction
Text.Start("Hello", 2)        // "He"
Text.End("Hello", 3)          // "llo"
Text.Middle("Hello", 1, 3)    // "ell"
Text.Range("Hello", 2, 2)     // "ll"

// Search
Text.Contains("Hello World", "World")  // true
Text.StartsWith("Hello", "He")         // true
Text.EndsWith("file.csv", ".csv")      // true
Text.PositionOf("Hello", "l")          // 2

// Replace
Text.Replace("Hello", "l", "x")        // "Hexxo"
Text.Remove("A1B2C3", {"1", "2", "3"}) // "ABC"

// Split & Combine
Text.Split("A,B,C", ",")               // {"A", "B", "C"}
Text.Combine({"A", "B", "C"}, "-")     // "A-B-C"

// Format
Text.PadStart("42", 5, "0")            // "00042"
Text.Format("Hello #{0}", {"World"})   // "Hello World"
```

## Number Functions

```m
// Rounding
Number.Round(3.14159, 2)      // 3.14
Number.RoundDown(3.9)         // 3
Number.RoundUp(3.1)           // 4
Number.RoundTowardZero(-3.5)  // -3

// Math
Number.Abs(-42)               // 42
Number.Sign(-5)               // -1
Number.Power(2, 10)           // 1024
Number.Sqrt(16)               // 4
Number.Log10(100)             // 2
Number.Mod(10, 3)             // 1

// Conversion
Number.ToText(42)             // "42"
Number.FromText("42")         // 42
Number.From("3.14")           // 3.14

// Formatting
Number.ToText(1234.5, "C")    // "$1,234.50" (currency)
Number.ToText(0.85, "P")      // "85.00%"
```

## Date & Time Functions

```m
// Current
DateTime.LocalNow()           // Current local datetime
Date.From(DateTime.LocalNow()) // Today's date
Time.From(DateTime.LocalNow()) // Current time

// Extraction
Date.Year(#date(2024, 12, 25))     // 2024
Date.Month(#date(2024, 12, 25))    // 12
Date.Day(#date(2024, 12, 25))      // 25
Date.DayOfWeek(#date(2024, 12, 25)) // 3 (Wednesday)
Date.WeekOfYear(#date(2024, 12, 25)) // 52

// Date arithmetic
Date.AddDays(#date(2024, 1, 1), 30)    // 2024-01-31
Date.AddMonths(#date(2024, 1, 15), 3)  // 2024-04-15
Date.AddYears(#date(2024, 1, 1), 1)    // 2025-01-01

// Difference
Duration.Days(#date(2024, 12, 31) - #date(2024, 1, 1))  // 365

// Start/End of period
Date.StartOfMonth(#date(2024, 6, 15))  // 2024-06-01
Date.EndOfMonth(#date(2024, 6, 15))    // 2024-06-30
Date.StartOfYear(#date(2024, 6, 15))   // 2024-01-01
Date.EndOfWeek(#date(2024, 6, 15))     // 2024-06-16

// Formatting
Date.ToText(#date(2024, 12, 25), "yyyy-MM-dd")  // "2024-12-25"
DateTime.ToText(dt, "MM/dd/yyyy HH:mm:ss")
```

## List Functions

```m
// Creation
{1, 2, 3, 4, 5}
{1..100}                          // Range 1 to 100
List.Generate(() => 1, each _ <= 10, each _ + 1)  // Generate 1-10

// Aggregation
List.Sum({1, 2, 3, 4, 5})         // 15
List.Average({1, 2, 3, 4, 5})     // 3
List.Max({1, 2, 3, 4, 5})         // 5
List.Min({1, 2, 3, 4, 5})         // 1
List.Count({1, 2, 3, 4, 5})       // 5

// Selection
List.First({1, 2, 3})             // 1
List.Last({1, 2, 3})              // 3
List.FirstN({1, 2, 3, 4, 5}, 3)   // {1, 2, 3}
List.LastN({1, 2, 3, 4, 5}, 2)    // {4, 5}
List.Range({1, 2, 3, 4, 5}, 2, 3) // {3, 4, 5}

// Transformation
List.Transform({1, 2, 3}, each _ * 2)  // {2, 4, 6}
List.Select({1, 2, 3, 4, 5}, each _ > 3) // {4, 5}
List.Sort({3, 1, 4, 1, 5})        // {1, 1, 3, 4, 5}
List.Reverse({1, 2, 3})           // {3, 2, 1}
List.Distinct({1, 1, 2, 2, 3})    // {1, 2, 3}

// Membership
List.Contains({1, 2, 3}, 2)       // true
List.ContainsAny({1, 2, 3}, {3, 4}) // true
List.ContainsAll({1, 2, 3}, {1, 2}) // true

// Combination
List.Combine({{1, 2}, {3, 4}})    // {1, 2, 3, 4}
List.Zip({{1, 2}, {"A", "B"}})    // {{1, "A"}, {2, "B"}}
```

## Record Functions

```m
// Access
Record.Field([Name="Alice", Age=30], "Name")  // "Alice"
[Name="Alice", Age=30][Name]                  // "Alice"

// Manipulation
Record.AddField([A=1], "B", 2)                // [A=1, B=2]
Record.RemoveFields([A=1, B=2, C=3], {"B"})   // [A=1, C=3]
Record.RenameFields([Old=1], {{"Old", "New"}}) // [New=1]
Record.TransformFields([A="hello"], {{"A", Text.Upper}}) // [A="HELLO"]

// Information
Record.FieldNames([A=1, B=2])      // {"A", "B"}
Record.FieldValues([A=1, B=2])     // {1, 2}
Record.ToTable([A=1, B=2])         // Table with Name/Value columns
```

## Error Handling

```m
// Try-Otherwise
let
    Result = try Number.FromText("invalid") otherwise 0
in
    Result  // Returns 0

// Try with error details
let
    Attempt = try 1/0,
    Result = if Attempt[HasError] then
        "Error: " & Attempt[Error][Message]
    else
        Attempt[Value]
in
    Result

// Custom errors
if [Amount] < 0 then
    error Error.Record("NegativeAmount", "Amount cannot be negative", [Amount])
else
    [Amount]

// Error in table
Table.AddColumn(Source, "SafeDivision", each
    try [Revenue] / [Costs] otherwise null
)
```

## Custom Functions

```m
// Simple function
let
    MultiplyByTwo = (x) => x * 2
in
    MultiplyByTwo(5)  // Returns 10

// Function with multiple parameters
let
    CalculateTax = (amount as number, rate as number) as number =>
        amount * rate
in
    CalculateTax(100, 0.2)  // Returns 20

// Optional parameters
let
    Greet = (name as text, optional greeting as text) as text =>
        let
            actualGreeting = if greeting = null then "Hello" else greeting
        in
            actualGreeting & ", " & name & "!"
in
    Greet("Alice")  // "Hello, Alice!"

// Function with documentation
let
    // Custom function documentation
    fnCalculateDiscount = (
        originalPrice as number,
        discountPercent as number
    ) as number =>
        let
            discount = originalPrice * (discountPercent / 100),
            finalPrice = originalPrice - discount
        in
            finalPrice,

    // Add documentation metadata
    fnType = type function (
        originalPrice as number,
        discountPercent as number
    ) as number meta [
        Documentation.Name = "Calculate Discount",
        Documentation.Description = "Calculates the final price after applying a discount percentage",
        Documentation.Examples = {[
            Description = "Apply 20% discount to $100",
            Code = "fnCalculateDiscount(100, 20)",
            Result = "80"
        ]}
    ]
in
    Value.ReplaceType(fnCalculateDiscount, fnType)
```

## Performance Tips

```m
// 1. Filter early
let
    Source = Sql.Database("server", "db"),
    // Good: Filter at source
    Filtered = Table.SelectRows(Source, each [Year] = 2024)
in
    Filtered

// 2. Select needed columns only
Table.SelectColumns(Source, {"ID", "Name", "Amount"})

// 3. Use native query folding
Value.NativeQuery(Sql.Database("server", "db"),
    "SELECT * FROM Sales WHERE Amount > 1000")

// 4. Buffer when reusing
let
    BufferedTable = Table.Buffer(ExpensiveQuery),
    Result1 = Table.SelectRows(BufferedTable, each [A] > 10),
    Result2 = Table.SelectRows(BufferedTable, each [B] < 5)
in
    ...

// 5. Avoid row-by-row operations
// Bad: Table.AddColumn(each OtherTable{[ID]})
// Good: Use Table.NestedJoin instead

// 6. Check query folding
// View → Query Dependencies → View Native Query
Table.View(...) // Enables folding
```

## Dataflow Gen2 Specific

```m
// Reference other dataflows
Dataflows.Contents("workspace_id", "dataflow_id")

// Fabric Lakehouse connection
Lakehouse.Tables("workspace_id", "lakehouse_id")
Lakehouse.Files("workspace_id", "lakehouse_id")

// Staging (Write to Lakehouse)
// Configure in Dataflow destination settings

// Parameters
let
    StartDate = #date(2024, 1, 1) meta [IsParameter = true],
    Source = Table.SelectRows(Data, each [Date] >= StartDate)
in
    Source
```

---

**Quick Reference Card**

| Operation | M Code |
|-----------|--------|
| Load Excel | `Excel.Workbook(File.Contents("file.xlsx"))` |
| Filter rows | `Table.SelectRows(tbl, each [Col] > 10)` |
| Add column | `Table.AddColumn(tbl, "New", each [A] + [B])` |
| Group by | `Table.Group(tbl, {"Key"}, {{"Sum", each List.Sum([Val])}})` |
| Join tables | `Table.NestedJoin(t1, {"K"}, t2, {"K"}, "J", JoinKind.Inner)` |
| Remove nulls | `Table.SelectRows(tbl, each [Col] <> null)` |
| Change type | `Table.TransformColumnTypes(tbl, {{"Col", type number}})` |
| Replace value | `Table.ReplaceValue(tbl, "old", "new", Replacer.ReplaceText, {"Col"})` |

---

[⬅️ Retour aux ressources](../README.md)
