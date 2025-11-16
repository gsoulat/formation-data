# Power Query et Langage M

## Introduction

**Power Query** est l'interface de transformation de données dans les Dataflows Gen2. Le langage **M** (aussi appelé "Power Query Formula Language") est le langage fonctionnel sous-jacent.

```
Power Query Interface:
┌────────────────────────────────────────┐
│  Get Data → Transform → Load            │
├────────────────────────────────────────┤
│  • Visual transformations (UI)         │
│  • M code (Advanced Editor)            │
│  • Query folding (push to source)      │
└────────────────────────────────────────┘
```

## Langage M - Fondamentaux

### Structure de Base

```powerquery
let
    // Step 1: Source
    Source = Sql.Database("server.database.windows.net", "SalesDB"),

    // Step 2: Get table
    dbo_customers = Source{[Schema="dbo",Item="customers"]}[Data],

    // Step 3: Filter
    FilteredRows = Table.SelectRows(dbo_customers, each [country] = "FR"),

    // Step 4: Select columns
    SelectedColumns = Table.SelectColumns(FilteredRows, {"customer_id", "name", "email"}),

    // Step 5: Rename
    RenamedColumns = Table.RenameColumns(SelectedColumns, {{"name", "customer_name"}})
in
    RenamedColumns
```

**Syntaxe :**
```
let
    variable1 = expression1,
    variable2 = expression2,
    ...
    finalVariable = finalExpression
in
    finalVariable
```

### Types de Données

```powerquery
// Text
TextValue = "Hello World"

// Number
IntValue = 42
FloatValue = 3.14

// Boolean
BoolValue = true

// Date/Time
DateValue = #date(2024, 1, 15)
TimeValue = #time(14, 30, 0)
DateTimeValue = #datetime(2024, 1, 15, 14, 30, 0)
DateTimeZoneValue = #datetimezone(2024, 1, 15, 14, 30, 0, 1, 0)

// Duration
DurationValue = #duration(1, 2, 3, 4)  // 1 day, 2 hours, 3 min, 4 sec

// List
ListValue = {1, 2, 3, 4, 5}
MixedList = {1, "text", true, null}

// Record
RecordValue = [Name = "John", Age = 30, City = "Paris"]

// Table
TableValue = #table(
    {"ID", "Name"},
    {
        {1, "Alice"},
        {2, "Bob"}
    }
)

// Null
NullValue = null

// Function
FunctionValue = (x) => x * 2
```

### Opérateurs

```powerquery
// Arithmetic
10 + 5      // 15
10 - 5      // 5
10 * 5      // 50
10 / 5      // 2
10 / 3      // 3.333...
5 ^ 2       // 25 (power)

// Comparison
10 = 10     // true
10 <> 5     // true (not equal)
10 > 5      // true
10 >= 10    // true
10 < 20     // true
10 <= 10    // true

// Logical
true and false      // false
true or false       // true
not true           // false

// Text
"Hello" & " " & "World"  // "Hello World"

// Null coalescing
null ?? "default"   // "default"
"value" ?? "default"  // "value"

// Membership
"a" in {"a", "b", "c"}  // true
```

### Commentaires

```powerquery
// Single-line comment

/*
   Multi-line
   comment
*/

let
    Source = Sql.Database("server", "db"),  // Inline comment
    /*
       This step filters the data
       to only include active records
    */
    Filtered = Table.SelectRows(Source, each [is_active] = true)
in
    Filtered
```

## Fonctions M Essentielles

### Text Functions

```powerquery
// Upper / Lower / Proper
Text.Upper("hello")          // "HELLO"
Text.Lower("WORLD")          // "world"
Text.Proper("john doe")      // "John Doe"

// Length
Text.Length("Hello")         // 5

// Substring
Text.Middle("Hello World", 6, 5)  // "World"
Text.Start("Hello", 3)       // "Hel"
Text.End("Hello", 2)         // "lo"

// Find / Replace
Text.Contains("Hello World", "World")  // true
Text.PositionOf("Hello World", "World")  // 6
Text.Replace("Hello World", "World", "M")  // "Hello M"

// Trim
Text.Trim("  spaces  ")      // "spaces"
Text.TrimStart("  left")     // "left"
Text.TrimEnd("right  ")      // "right"

// Split / Combine
Text.Split("a,b,c", ",")     // {"a", "b", "c"}
Text.Combine({"a", "b", "c"}, ",")  // "a,b,c"

// Padding
Text.PadStart("5", 3, "0")   // "005"
Text.PadEnd("5", 3, "0")     // "500"

// Extract
Text.AfterDelimiter("name:john", ":")  // "john"
Text.BeforeDelimiter("john@email.com", "@")  // "john"
```

### Number Functions

```powerquery
// Rounding
Number.Round(3.7)            // 4
Number.RoundDown(3.7)        // 3
Number.RoundUp(3.2)          // 4
Number.Round(3.14159, 2)     // 3.14

// Absolute / Sign
Number.Abs(-5)               // 5
Number.Sign(-5)              // -1
Number.Sign(5)               // 1
Number.Sign(0)               // 0

// Power / Sqrt
Number.Power(2, 3)           // 8
Number.Sqrt(16)              // 4

// Min / Max
Number.Min({1, 5, 3})        // 1
Number.Max({1, 5, 3})        // 5

// Mod
Number.Mod(10, 3)            // 1

// Integer / From
Number.IntegerDivide(10, 3)  // 3
Number.From("123")           // 123
Number.ToText(123)           // "123"

// Random
Number.Random()              // 0.xxx (between 0 and 1)
Number.RandomBetween(1, 100) // Random int between 1 and 100
```

### Date/Time Functions

```powerquery
// Current
DateTime.LocalNow()          // Current local datetime
DateTime.FixedLocalNow()     // Fixed at query start
Date.From(DateTime.LocalNow())  // Current date only

// Parts
Date.Year(#date(2024, 1, 15))     // 2024
Date.Month(#date(2024, 1, 15))    // 1
Date.Day(#date(2024, 1, 15))      // 15
Date.DayOfWeek(#date(2024, 1, 15))  // 0 (Sunday=0, Saturday=6)
Date.DayOfYear(#date(2024, 1, 15))  // 15

// Add / Subtract
Date.AddDays(#date(2024, 1, 15), 7)       // 2024-01-22
Date.AddMonths(#date(2024, 1, 15), 1)     // 2024-02-15
Date.AddYears(#date(2024, 1, 15), 1)      // 2025-01-15

// Start / End of period
Date.StartOfMonth(#date(2024, 1, 15))     // 2024-01-01
Date.EndOfMonth(#date(2024, 1, 15))       // 2024-01-31
Date.StartOfWeek(#date(2024, 1, 15))      // 2024-01-14 (Sunday)
Date.StartOfYear(#date(2024, 1, 15))      // 2024-01-01

// Difference
Duration.Days(#date(2024, 1, 20) - #date(2024, 1, 15))  // 5

// From / To
Date.FromText("2024-01-15")   // #date(2024, 1, 15)
Date.ToText(#date(2024, 1, 15), "yyyy-MM-dd")  // "2024-01-15"
```

### List Functions

```powerquery
// Count / IsEmpty
List.Count({1, 2, 3})        // 3
List.IsEmpty({})             // true

// First / Last
List.First({1, 2, 3})        // 1
List.Last({1, 2, 3})         // 3

// Range
List.Range({1, 2, 3, 4, 5}, 1, 3)  // {2, 3, 4}
List.FirstN({1, 2, 3, 4}, 2)       // {1, 2}
List.LastN({1, 2, 3, 4}, 2)        // {3, 4}

// Contains / Position
List.Contains({1, 2, 3}, 2)        // true
List.PositionOf({1, 2, 3}, 2)      // 1 (0-indexed)

// Sum / Average / Min / Max
List.Sum({1, 2, 3, 4})       // 10
List.Average({1, 2, 3, 4})   // 2.5
List.Min({1, 2, 3})          // 1
List.Max({1, 2, 3})          // 3

// Transform
List.Transform({1, 2, 3}, each _ * 2)  // {2, 4, 6}

// Select
List.Select({1, 2, 3, 4}, each _ > 2)  // {3, 4}

// Accumulate
List.Accumulate({1, 2, 3}, 0, (state, current) => state + current)  // 6

// Combine
List.Combine({{1, 2}, {3, 4}})  // {1, 2, 3, 4}

// Distinct / Sort
List.Distinct({1, 2, 2, 3})     // {1, 2, 3}
List.Sort({3, 1, 2})            // {1, 2, 3}
```

## Table Functions

### Table.SelectRows (Filter)

```powerquery
// Simple filter
Filtered = Table.SelectRows(Source, each [amount] > 100)

// Multiple conditions (AND)
Filtered = Table.SelectRows(Source, each [amount] > 100 and [country] = "FR")

// Multiple conditions (OR)
Filtered = Table.SelectRows(Source, each [amount] > 1000 or [is_vip] = true)

// Complex conditions
Filtered = Table.SelectRows(Source, each
    [amount] > 100
    and [country] <> null
    and List.Contains({"FR", "BE", "CH"}, [country])
)

// Date filtering
Filtered = Table.SelectRows(Source, each
    [order_date] >= #date(2024, 1, 1)
    and [order_date] < #date(2024, 2, 1)
)
```

### Table.SelectColumns

```powerquery
// Select specific columns
Selected = Table.SelectColumns(Source, {"customer_id", "name", "email"})

// Remove columns (keep all except)
Removed = Table.RemoveColumns(Source, {"internal_id", "temp_flag"})
```

### Table.RenameColumns

```powerquery
// Rename columns
Renamed = Table.RenameColumns(Source, {
    {"old_name1", "new_name1"},
    {"old_name2", "new_name2"}
})

// Example
Renamed = Table.RenameColumns(Source, {
    {"CustomerID", "customer_id"},
    {"CustomerName", "customer_name"}
})
```

### Table.TransformColumns

```powerquery
// Transform single column
Transformed = Table.TransformColumns(Source, {
    {"name", Text.Upper}
})

// Transform multiple columns
Transformed = Table.TransformColumns(Source, {
    {"name", Text.Proper},
    {"email", Text.Lower},
    {"amount", each _ * 1.2}
})

// With type
Transformed = Table.TransformColumns(Source, {
    {"amount", each Number.Round(_, 2), type number}
})
```

### Table.AddColumn

```powerquery
// Add simple column
WithColumn = Table.AddColumn(Source, "full_name",
    each [first_name] & " " & [last_name]
)

// Add calculated column
WithColumn = Table.AddColumn(Source, "total_with_tax",
    each [amount] * 1.2,
    type number
)

// Add conditional column
WithColumn = Table.AddColumn(Source, "category",
    each if [amount] > 1000 then "High" else "Low"
)

// Add complex column
WithColumn = Table.AddColumn(Source, "age",
    each Duration.Days(DateTime.LocalNow() - [birth_date]) / 365,
    Int64.Type
)
```

### Table.Group (Aggregation)

```powerquery
// Simple group
Grouped = Table.Group(Source, {"country"}, {
    {"total_sales", each List.Sum([amount]), type number}
})

// Multiple aggregations
Grouped = Table.Group(Source, {"country", "year"}, {
    {"total_sales", each List.Sum([amount]), type number},
    {"order_count", each Table.RowCount(_), type number},
    {"avg_order", each List.Average([amount]), type number}
})

// Group all rows
Grouped = Table.Group(Source, {}, {
    {"all_rows", each _, type table}
})
```

### Table.Join

```powerquery
// Inner join
Joined = Table.NestedJoin(
    customers, {"customer_id"},
    orders, {"customer_id"},
    "orders",
    JoinKind.Inner
)

// Expand joined table
Expanded = Table.ExpandTableColumn(Joined, "orders",
    {"order_id", "amount"},
    {"order_id", "amount"}
)

// Join types
JoinKind.Inner       // Inner join
JoinKind.LeftOuter   // Left outer join
JoinKind.RightOuter  // Right outer join
JoinKind.FullOuter   // Full outer join
JoinKind.LeftAnti    // Left anti join (rows in left not in right)
JoinKind.RightAnti   // Right anti join
```

### Table.Distinct

```powerquery
// Remove duplicate rows (all columns)
Distinct = Table.Distinct(Source)

// Remove duplicates based on specific columns
Distinct = Table.Distinct(Source, {"email"})
```

### Table.Sort

```powerquery
// Sort ascending
Sorted = Table.Sort(Source, {{"amount", Order.Ascending}})

// Sort descending
Sorted = Table.Sort(Source, {{"amount", Order.Descending}})

// Multiple sort columns
Sorted = Table.Sort(Source, {
    {"country", Order.Ascending},
    {"amount", Order.Descending}
})
```

## Conditional Logic

### if-then-else

```powerquery
// Simple if
Category = if [amount] > 1000 then "High" else "Low"

// Nested if
Category = if [amount] > 10000 then "Premium"
           else if [amount] > 1000 then "High"
           else if [amount] > 100 then "Medium"
           else "Low"

// if with null check
SafeValue = if [value] = null then 0 else [value]
```

### try-otherwise

```powerquery
// Handle errors
SafeConversion = try Number.From([text_field]) otherwise 0

// Try with error details
Result = try
    Number.From([text_field])
otherwise
    [ErrorMessage = "Invalid number format", Value = null]

// Check if error
HasError = try Number.From([text_field]) otherwise null is error
```

## Fonctions Custom

### Function Definition

```powerquery
// Simple function
Double = (x) => x * 2

// Multi-parameter function
Add = (x, y) => x + y

// Function with type
Multiply = (x as number, y as number) as number => x * y

// Complex function
CalculateTax = (amount as number, country as text) as number =>
    if country = "FR" then amount * 0.20
    else if country = "BE" then amount * 0.21
    else if country = "CH" then amount * 0.077
    else amount * 0.20  // Default

// Use in query
let
    Source = ...,
    WithTax = Table.AddColumn(Source, "tax",
        each CalculateTax([amount], [country])
    )
in
    WithTax
```

### Recursive Functions

```powerquery
// Factorial
Factorial = (n as number) as number =>
    if n <= 1 then 1
    else n * @Factorial(n - 1)

// Fibonacci
Fibonacci = (n as number) as number =>
    if n <= 1 then n
    else @Fibonacci(n - 1) + @Fibonacci(n - 2)
```

## Best Practices

### ✅ Naming Conventions

```powerquery
// Clear, descriptive names
let
    Source = Sql.Database("server", "db"),
    CustomersTable = Source{[Schema="dbo",Item="customers"]}[Data],
    ActiveCustomers = Table.SelectRows(CustomersTable, each [is_active] = true),
    FrenchCustomers = Table.SelectRows(ActiveCustomers, each [country] = "FR"),
    SelectedColumns = Table.SelectColumns(FrenchCustomers, {"id", "name", "email"}),
    FinalResult = Table.RenameColumns(SelectedColumns, {{"id", "customer_id"}})
in
    FinalResult
```

### ✅ Performance

```powerquery
// ✅ Good: Filter early
let
    Source = Sql.Database("server", "db"),
    Table = Source{[Schema="dbo",Item="sales"]}[Data],
    FilteredEarly = Table.SelectRows(Table, each [year] = 2024),  // Query folding
    Transformed = Table.TransformColumns(FilteredEarly, ...)
in
    Transformed

// ❌ Bad: Filter late
let
    Source = Sql.Database("server", "db"),
    Table = Source{[Schema="dbo",Item="sales"]}[Data],
    Transformed = Table.TransformColumns(Table, ...),  // All data loaded
    FilteredLate = Table.SelectRows(Transformed, each [year] = 2024)  // After transform
in
    FilteredLate
```

### ✅ Error Handling

```powerquery
let
    Source = try Sql.Database("server", "db") otherwise null,

    Result = if Source = null then
        #table({"Error"}, {{"Cannot connect to database"}})
    else
        Source{[Schema="dbo",Item="customers"]}[Data]
in
    Result
```

## Points Clés

- M = langage fonctionnel pour Power Query
- Structure let-in pour définir transformations
- Types: text, number, date, list, table, record
- Rich library de fonctions (Text, Number, Date, List, Table)
- Query folding = push transformations to source
- Custom functions pour réutilisabilité
- Error handling avec try-otherwise
- Performance: filtrer tôt, limiter colonnes
- Clear naming pour lisibilité

---

**Prochain fichier :** [02 - Création de Dataflows](./02-dataflow-creation.md)

[⬅️ Retour au README du module](./README.md)
