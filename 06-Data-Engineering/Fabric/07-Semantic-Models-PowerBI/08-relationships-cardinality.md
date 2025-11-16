# Relationships & Cardinality

## Introduction

Les **relationships** (relations) définissent comment les tables sont connectées dans un modèle sémantique Power BI, permettant le filtrage croisé et les calculs DAX.

```
Relationship Basics:
┌─────────────────────────────────────┐
│  Sales (*) ────→ (1) Customer       │
│                                     │
│  Many-to-One relationship           │
│  Sales table (many)                 │
│  Customer table (one)               │
│  Direction: Customer filters Sales  │
└─────────────────────────────────────┘
```

## Types de Relations

### One-to-Many (1:*)

```
Most common relationship type

Example:
  Customer (1) ←──── (*) Sales

Structure:
  • Customer: CustomerKey (PK, unique)
  • Sales: CustomerKey (FK, many duplicates)

Behavior:
  • Filter from Customer to Sales
  • One customer → many sales
  • Each sale → one customer

Visualization:
  Customer[CustomerKey] ← Sales[CustomerKey]
        (1)                      (*)
```

**DAX Example:**
```dax
-- This works because of relationship:
Total Sales by Customer =
CALCULATE(
    SUM(Sales[Amount]),
    Customer[CustomerID] = "CUST123"
)

-- Filter on Customer table automatically filters Sales table
```

### Many-to-One (*:1)

```
Same as One-to-Many, just viewed from other side

Example:
  Sales (*) ────→ (1) Customer

Structure:
  • Sales: CustomerKey (FK, many)
  • Customer: CustomerKey (PK, one)

Behavior:
  • Filter from Customer to Sales
  • Same as 1:* (perspective different only)

Power BI shows: (*:1) in model view
```

### One-to-One (1:1)

```
Rare, usually indicates denormalization opportunity

Example:
  Customer (1) ←──── (1) Customer_Extended

Structure:
  • Customer: CustomerKey (PK, unique)
  • Customer_Extended: CustomerKey (PK, unique)

Use cases:
  ✅ Security (separate sensitive data)
  ✅ Performance (split large table)
  ⚠️ Usually better to merge tables

Recommendation:
  Avoid unless specific reason
  Merge tables if possible
```

### Many-to-Many (*:*)

```
Complex, use bridge table if possible

Example (without bridge):
  Student (*) ←──── (*) Course

Problem:
  • Ambiguous relationships
  • Performance issues
  • Hard to control filter direction

Solution: Bridge table
  Student (1) ← (*) Enrollment (*) → (1) Course

Structure:
  • Student: StudentID (PK)
  • Course: CourseID (PK)
  • Enrollment: StudentID (FK), CourseID (FK)

Benefits:
  ✅ Clear relationships (two 1:*)
  ✅ Better performance
  ✅ Can store additional info (enrollment date, grade)
```

**Many-to-Many in Power BI:**
```
Power BI supports many-to-many relationships:
  Sales (*) ←──── (*) Budget

Configuration:
  • Set cardinality to Many-to-Many
  • Choose cross-filter direction

Caution:
  ⚠️ Can cause ambiguous results
  ⚠️ Performance overhead
  ⚠️ Use only when necessary
  ✅ Prefer bridge table approach
```

## Cardinality

### Définition

```
Cardinality = Number of unique values in a column

Examples:
  Customer[CustomerKey]:
    • Cardinality = 10,000 (10K unique customers)
    • One-side of relationship

  Sales[CustomerKey]:
    • Cardinality = 10,000 (same unique values)
    • But appears 1,000,000 times in Sales table
    • Many-side of relationship

Power BI auto-detects cardinality based on data
```

### Cardinality Types

```
One (1):
  • Column is unique (or nearly unique)
  • Primary key column
  • Example: Customer[CustomerKey]

Many (*):
  • Column has duplicates
  • Foreign key column
  • Example: Sales[CustomerKey]

Detection:
  Power BI samples data to determine cardinality
  Can be overridden manually if needed
```

## Cross-Filter Direction

### Single Direction

```
Default: One-to-Many with Single direction

Example:
  Customer (1) ────→ Sales (*)
  Direction: Single →

Behavior:
  ✅ Customer filters Sales
  ❌ Sales does NOT filter Customer

Use case:
  • Standard star schema
  • Dimension filters fact
  • Fact does not filter dimension

Visualization:
  Customer → Sales (arrow points to Sales)
```

**DAX Example:**
```dax
-- This works (Customer → Sales):
Sales for Customer X =
CALCULATE(
    [Total Sales],
    Customer[Name] = "Customer X"
)

-- This doesn't work (Sales ↛ Customer):
Customers with $0 Sales =
CALCULATE(
    COUNTROWS(Customer),
    Sales[Amount] = 0
)
-- Returns all customers (filter doesn't propagate back)
```

### Both Directions

```
Bidirectional filtering

Example:
  Customer (1) ←───→ Sales (*)
  Direction: Both ←→

Behavior:
  ✅ Customer filters Sales
  ✅ Sales filters Customer

Use case:
  • Many-to-many relationships
  • Complex filtering requirements
  • Specific business logic

Caution:
  ⚠️ Can cause ambiguous filter paths
  ⚠️ Performance overhead
  ⚠️ Circular dependencies risk
```

**When to Use Both:**
```
✅ Use bidirectional when:
  • Many-to-many relationship needed
  • Need to filter dimension from fact
  • Specific business requirement

Example:
  Show only customers who made purchases:
    Customers with Sales =
    CALCULATE(
        COUNTROWS(Customer),
        Sales[Amount] > 0
    )
  → Requires bidirectional relationship
```

### Caution with Both

```
❌ Problems with bidirectional:

1. Ambiguous filter paths
   Product → Sales ← Customer
           ↑     ↓
       Region ←┘

   Multiple paths create confusion

2. Performance
   • More complex filter propagation
   • Slower query execution
   • Materialization overhead

3. Circular dependencies
   Can create infinite filter loops

Recommendation:
  ✅ Use single direction by default
  ⚠️ Use both only when necessary
  ✅ Test thoroughly
  ✅ Document reason
```

## Active vs Inactive Relationships

### Active Relationships

```
Active = Used by default in DAX calculations

Example:
  Sales[OrderDateKey] ────→ Date[DateKey] (Active)
  Sales[ShipDateKey] - - → Date[DateKey] (Inactive)

Behavior:
  • Only one active relationship between two tables
  • Used automatically in measures
  • No USERELATIONSHIP needed

DAX Example:
  Total Sales = SUM(Sales[Amount])
  → Automatically uses OrderDate relationship
```

### Inactive Relationships

```
Inactive = Not used by default, must activate explicitly

Example:
  Sales[ShipDateKey] - - → Date[DateKey] (Inactive)

Visual: Dashed line in model view

Reason:
  • Cannot have 2+ active relationships to same table
  • Sales → Date via OrderDate (active)
  • Sales → Date via ShipDate (inactive)

Usage: Must activate with USERELATIONSHIP
```

### USERELATIONSHIP Function

```dax
-- Use inactive relationship
Sales by Ship Date =
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(Sales[ShipDateKey], 'Date'[DateKey])
)

-- Multiple inactive relationships
Sales by Due Date =
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(Sales[DueDateKey], 'Date'[DateKey])
)

-- Without USERELATIONSHIP:
Total Sales = SUM(Sales[Amount])
→ Uses active OrderDate relationship only
```

## Role-Playing Dimensions

### Concept

```
Role-Playing = Same dimension table used multiple times

Example: Date dimension with 3 roles
  • OrderDate
  • ShipDate
  • DueDate

Single physical table: Date
Multiple logical uses

Implementation:
  Sales[OrderDateKey] → Date[DateKey] (Active)
  Sales[ShipDateKey] → Date[DateKey] (Inactive)
  Sales[DueDateKey] → Date[DateKey] (Inactive)
```

### Best Practices

```dax
-- Create dedicated measures for each role

-- Order Date (uses active relationship)
Sales by Order Date = [Total Sales]

-- Ship Date (uses inactive relationship)
Sales by Ship Date =
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(Sales[ShipDateKey], 'Date'[DateKey])
)

-- Due Date (uses inactive relationship)
Sales by Due Date =
CALCULATE(
    [Total Sales],
    USERELATIONSHIP(Sales[DueDateKey], 'Date'[DateKey])
)

-- Clear naming prevents confusion
```

### Alternative: Multiple Date Tables

```
Instead of inactive relationships, create separate date tables:

Tables:
  • Date_Order
  • Date_Ship
  • Date_Due

Relationships:
  Sales[OrderDateKey] → Date_Order[DateKey] (Active)
  Sales[ShipDateKey] → Date_Ship[DateKey] (Active)
  Sales[DueDateKey] → Date_Due[DateKey] (Active)

Pros:
  ✅ All relationships active (simpler DAX)
  ✅ No USERELATIONSHIP needed
  ✅ Clearer for end users

Cons:
  ❌ Larger model (3x date tables)
  ❌ More maintenance (sync changes)
  ❌ More complex model view

Recommendation:
  Use inactive relationships (smaller, cleaner)
```

## Relations Circulaires

### Définition

```
Circular Relationship = Filter path forms a loop

Example:
  Sales → Customer → Region → Sales (LOOP!)

Structure:
  Sales[CustomerID] → Customer[CustomerID]
  Customer[RegionID] → Region[RegionID]
  Region[RegionID] → Sales[RegionID]

Problem:
  Power BI cannot determine filter direction
  Ambiguous filter propagation
```

### Detection

```
Power BI automatically detects circular relationships:

Error message:
  "Circular dependency detected in the model.
   The following relationships create a cycle:
   Sales → Customer → Region → Sales"

Model view:
  One relationship will be marked as inactive (dashed)
  To break the circle
```

### Solutions

```
Solution 1: Remove redundant relationship
  If Sales has CustomerID, don't need RegionID
  Customer already has RegionID
  Sales → Customer → Region (no loop)

Solution 2: Use inactive relationship
  Keep structure but mark one as inactive
  Activate manually with USERELATIONSHIP when needed

Solution 3: Restructure model
  Create bridge table or denormalize
  Ensure single filter path

Recommendation:
  ✅ Redesign to avoid circular relationships
  ✅ Follow star schema principles
  ❌ Don't rely on inactive relationships as fix
```

## Bidirectional Filtering

### Pros and Cons

```
✅ Pros:
  • Enables complex filtering scenarios
  • Useful for many-to-many
  • Can simplify some DAX

❌ Cons:
  • Ambiguous filter paths
  • Performance overhead
  • Risk of circular dependencies
  • Harder to debug
  • Unexpected results

Recommendation:
  Use sparingly and with caution
```

### When to Use

```
✅ Use bidirectional when:

1. Many-to-many relationship
   Student ← Enrollment → Course
   Need to filter both ways

2. Filter dimension from fact
   Show only customers who made purchases
   Customer ← Sales (bidirectional needed)

3. Security (RLS)
   User table filtering fact table
   Fact table filtering dimension

❌ Avoid when:
  • Standard star schema (use single)
  • Performance critical
  • Can achieve with DAX instead
```

### Alternatives to Bidirectional

```dax
-- Instead of bidirectional relationship
-- Use DAX to achieve same result

-- Show only customers with sales (no bidirectional):
Customers with Sales =
CALCULATE(
    COUNTROWS(Customer),
    FILTER(
        Customer,
        CALCULATE(COUNTROWS(Sales)) > 0
    )
)

-- Show products sold in selected period (no bidirectional):
Products Sold =
CALCULATE(
    COUNTROWS(Product),
    FILTER(
        Product,
        CALCULATE(COUNTROWS(Sales)) > 0
    )
)

Benefits:
  ✅ Explicit logic (clearer)
  ✅ No relationship complexity
  ✅ Better performance in some cases
```

## Best Practices

### ✅ Relationship Design

```
1. Follow star schema
   • Fact tables at center
   • Dimension tables around
   • One-to-many relationships

2. Single active relationship
   • Only one active between two tables
   • Use inactive for additional roles
   • USERELATIONSHIP for inactive

3. Avoid circular relationships
   • Redesign model if circular detected
   • Don't rely on inactive to break circle

4. Single filter direction (default)
   • Customer → Sales (not ←→)
   • Use bidirectional sparingly

5. Use surrogate keys
   • Integer keys (not strings)
   • Better performance
   • Smaller indexes
```

### ✅ Naming Conventions

```
Keys:
  ✅ Customer[CustomerKey] (PK)
  ✅ Sales[CustomerKey] (FK)
  ❌ Customer[ID], Sales[CustID] (inconsistent)

Clarity:
  ✅ Sales[OrderDateKey] → Date[DateKey]
  ✅ Sales[ShipDateKey] → Date[DateKey]
  ❌ Sales[Date1], Sales[Date2] (unclear purpose)
```

### ✅ Testing Relationships

```dax
-- Test relationship works
Test Customer Filter =
VAR CustomerName = "Test Customer"
VAR DirectSum = SUM(Sales[Amount])
VAR FilteredSum =
    CALCULATE(
        SUM(Sales[Amount]),
        Customer[CustomerName] = CustomerName
    )
RETURN
    "Direct: " & DirectSum & " | Filtered: " & FilteredSum

-- Should show different values if relationship works
```

### ✅ Documentation

```
Document relationship purpose:

Example:
  Sales → Customer (Active)
    Purpose: Filter sales by customer attributes
    Direction: Single (Customer filters Sales)

  Sales → Date via OrderDateKey (Active)
    Purpose: Time-based analysis of orders
    Direction: Single (Date filters Sales)

  Sales → Date via ShipDateKey (Inactive)
    Purpose: Ship date analysis
    Usage: Use USERELATIONSHIP in measures
    Measure: Sales by Ship Date
```

## Common Patterns

### Star Schema

```
Standard pattern:

       Dim_Date
          │ 1
          ▼
Dim_Customer ← (*) Fact_Sales (*) → Dim_Product
          │ 1              1 │
          ▼                  ▼
     Dim_Geography      Dim_Category

All relationships:
  • One-to-Many
  • Single direction
  • Active
```

### Snowflake (Avoid)

```
Normalized pattern (avoid in Power BI):

Dim_Customer ← Fact_Sales → Dim_Product → Dim_Category → Dim_Subcategory
                                                1           │ 1
                                                            ▼
                                                      Dim_Brand

Problems:
  ❌ Multiple hops (slower)
  ❌ More complex DAX
  ❌ Harder to maintain

Solution:
  ✅ Denormalize dimensions
  ✅ Flatten into single tables
```

## Points Clés

- Relationships: One-to-Many (most common), Many-to-Many (use bridge table)
- Cardinality: Auto-detected, can override manually
- Cross-filter direction: Single (default), Both (use sparingly)
- Active relationship: Used by default in DAX
- Inactive relationship: Use USERELATIONSHIP to activate
- Role-playing dimensions: Same table, multiple relationships, most inactive
- Avoid circular relationships: Redesign model
- Bidirectional filtering: Use cautiously, performance overhead
- Follow star schema: One-to-Many, single direction
- Use surrogate integer keys for performance

---

**Prochain fichier :** [09 - Performance Analyzer](./09-performance-analyzer.md)

[⬅️ Fichier précédent](./07-measures-calculated-columns.md) | [⬅️ Retour au README du module](./README.md)
