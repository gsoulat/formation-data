# Modélisation Star Schema

## Introduction

Le **Star Schema** (schéma en étoile) est le modèle dimensionnel standard pour les data warehouses et modèles sémantiques Power BI, optimisant les performances et la simplicité.

```
Star Schema Visualization:
                 Dim_Date
                    │
                    │ 1
                    ▼
    Dim_Customer ← (*) Fact_Sales (*) → Dim_Product
                    ▲
                  1 │
                    │
                 Dim_Store

Center = Fact table (Sales)
Points = Dimension tables (Date, Customer, Product, Store)
Shape = Star ⭐
```

## Principes du Star Schema

### Architecture

```
Components:
┌─────────────────────────────────────┐
│  Fact Table (CENTER)                │
│  ├─ Measures/metrics (Amount, Qty)  │
│  ├─ Foreign keys (IDs)              │
│  ├─ Granularity (transaction level) │
│  └─ Large row count (millions+)     │
├─────────────────────────────────────┤
│  Dimension Tables (POINTS)          │
│  ├─ Descriptive attributes          │
│  ├─ Primary keys (IDs)              │
│  ├─ Hierarchies (Year→Month→Day)    │
│  └─ Smaller row count (thousands)   │
└─────────────────────────────────────┘

Relationships:
  Fact (*) ──→ (1) Dimension
  Many-to-One from Fact to each Dimension
```

### Benefits

```
✅ Advantages:
  1. Simple to understand
     • Business users grasp easily
     • Clear separation (facts vs dimensions)

  2. Query performance
     • Optimized for BI queries
     • Minimal joins (1 hop max)
     • Aggregation-friendly

  3. Flexibility
     • Easy to add dimensions
     • Slice-and-dice by any dimension
     • Support for drill-down

  4. Scalability
     • Billions of fact rows
     • Millions of dimensions rows
     • Fast queries with proper indexing

❌ Drawbacks:
  • Data redundancy (denormalized dimensions)
  • Storage overhead (repeated attributes)
  • Update complexity (SCD management)
```

## Tables de Dimension

### Caractéristiques

```
Dimension Table Structure:
┌────────────────────────────────────┐
│  Dim_Customer                      │
├────────────────────────────────────┤
│  CustomerKey (PK) │ INT IDENTITY   │ ← Surrogate key
│  CustomerID       │ VARCHAR(50)    │ ← Business key
│  FirstName        │ VARCHAR(100)   │ ← Attributes
│  LastName         │ VARCHAR(100)   │
│  Email            │ VARCHAR(200)   │
│  City             │ VARCHAR(100)   │
│  State            │ VARCHAR(50)    │
│  Country          │ VARCHAR(50)    │
│  CustomerSegment  │ VARCHAR(20)    │
│  CreatedDate      │ DATE           │
│  IsActive         │ BIT            │
└────────────────────────────────────┘

Properties:
  • Denormalized (flat structure)
  • Descriptive attributes
  • Relatively small (<1M rows typically)
  • Slow changing (updates rare)
```

### Types de Dimensions

**1. Date Dimension (Calendar Table):**
```sql
-- Create Date dimension
CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY,        -- 20240115
    Date DATE NOT NULL,              -- 2024-01-15
    Year INT,                        -- 2024
    Quarter INT,                     -- 1
    QuarterName VARCHAR(10),         -- Q1 2024
    Month INT,                       -- 1
    MonthName VARCHAR(20),           -- January
    MonthShort VARCHAR(10),          -- Jan
    Week INT,                        -- 3
    DayOfMonth INT,                  -- 15
    DayOfWeek INT,                   -- 2 (Monday)
    DayName VARCHAR(20),             -- Monday
    IsWeekend BIT,                   -- 0
    IsHoliday BIT,                   -- 0
    FiscalYear INT,                  -- 2024
    FiscalQuarter INT                -- 3
);

-- DAX alternative
Date = CALENDAR(DATE(2020, 1, 1), DATE(2030, 12, 31))
```

**2. Customer Dimension:**
```
Dim_Customer:
  • Demographics (age, gender, income)
  • Geographic (city, state, country)
  • Segmentation (VIP, Premium, Regular)
  • Contact info (email, phone)
  • Status (active, inactive)
```

**3. Product Dimension:**
```
Dim_Product:
  • Product hierarchy (Category → Subcategory → Product)
  • Attributes (color, size, weight)
  • Pricing (list price, cost)
  • Status (active, discontinued)
  • Supplier info
```

**4. Geography Dimension:**
```
Dim_Geography:
  • Country
  • Region
  • State/Province
  • City
  • Postal Code
  • Coordinates (lat/lon)
```

## Tables de Fait

### Caractéristiques

```
Fact Table Structure:
┌────────────────────────────────────┐
│  Fact_Sales                        │
├────────────────────────────────────┤
│  SalesKey (PK)    │ BIGINT         │ ← Surrogate key
│  DateKey (FK)     │ INT            │ ← Foreign keys
│  CustomerKey (FK) │ INT            │
│  ProductKey (FK)  │ INT            │
│  StoreKey (FK)    │ INT            │
│  Quantity         │ INT            │ ← Measures
│  UnitPrice        │ DECIMAL(10,2)  │
│  SalesAmount      │ DECIMAL(10,2)  │
│  Cost             │ DECIMAL(10,2)  │
│  Profit           │ DECIMAL(10,2)  │
└────────────────────────────────────┘

Properties:
  • Foreign keys to dimensions
  • Numeric measures (additive)
  • Granularity (one row per transaction)
  • Very large (millions/billions of rows)
  • Partitioned by date
```

### Types de Measures

**Additive Measures:**
```
Can be summed across all dimensions:
  ✅ SalesAmount: SUM works for all dimensions
  ✅ Quantity: SUM works for all dimensions
  ✅ Cost: SUM works for all dimensions
```

**Semi-Additive Measures:**
```
Can be summed across some dimensions, not all:
  ⚠️ Account Balance: SUM across customers, NOT across time
  ⚠️ Inventory: SUM across products, NOT across time
  → Use LASTNONBLANK or snapshot tables
```

**Non-Additive Measures:**
```
Cannot be summed:
  ❌ Unit Price: Use AVERAGE, not SUM
  ❌ Ratios: Calculate at query time
  ❌ Percentages: Calculate dynamically
```

## Clés Surrogate

### Définition

```
Surrogate Key = Artificial key (not from source)

Business Key (Natural):
  • CustomerID: "CUST-12345"
  • ProductCode: "PROD-ABC-001"
  • From source system
  • Can change
  • Not optimized for joins

Surrogate Key:
  • CustomerKey: 1, 2, 3, 4...
  • ProductKey: 1, 2, 3, 4...
  • Generated by warehouse
  • Integer (4 bytes)
  • Never changes
  • Optimized for joins
```

### Why Use Surrogate Keys?

```
✅ Benefits:
1. Performance
   • Integer joins faster than string joins
   • Smaller index size
   • Better compression

2. Stability
   • Source system ID can change
   • Surrogate key never changes
   • Maintains referential integrity

3. SCD Support
   • Multiple versions of same entity
   • CustomerKey: 1, 2 (same customer, different versions)
   • Tracks history

4. Integration
   • Merge data from multiple sources
   • Same customer in Source A and B
   • Single CustomerKey in warehouse

Example:
  Source A: CustomerID = "A123"
  Source B: CustomerID = "B456"
  → Warehouse: CustomerKey = 1 (same person)
```

### Implementation

```sql
-- Dimension with surrogate key
CREATE TABLE Dim_Customer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate
    CustomerID VARCHAR(50) NOT NULL,            -- Business key
    SourceSystem VARCHAR(20),                   -- Which source
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    ...
);

-- Fact table references surrogate key
CREATE TABLE Fact_Sales (
    SalesKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    CustomerKey INT FOREIGN KEY REFERENCES Dim_Customer(CustomerKey),
    ...
);
```

## Slowly Changing Dimensions (SCD)

### SCD Type 1: Overwrite

```
Behavior: Update existing record (no history)

Example:
  Customer moved:
    BEFORE: CustomerKey=1, City="Paris"
    AFTER:  CustomerKey=1, City="Lyon"

  History is lost ❌

Use when:
  • History not important
  • Corrections only
  • Storage constrained

SQL:
  UPDATE Dim_Customer
  SET City = 'Lyon'
  WHERE CustomerKey = 1;
```

### SCD Type 2: Add New Row

```
Behavior: Insert new record (preserve history)

Example:
  Customer moved:
    Row 1: CustomerKey=1, CustomerID="C123", City="Paris",
           ValidFrom=2023-01-01, ValidTo=2024-01-14, IsCurrent=0
    Row 2: CustomerKey=2, CustomerID="C123", City="Lyon",
           ValidFrom=2024-01-15, ValidTo=NULL, IsCurrent=1

  Full history preserved ✅

Use when:
  • History critical
  • Audit requirements
  • Trend analysis

Columns needed:
  • ValidFrom (start date)
  • ValidTo (end date)
  • IsCurrent (flag for active record)
```

**SCD Type 2 Implementation:**
```sql
-- Update existing record
UPDATE Dim_Customer
SET ValidTo = '2024-01-14',
    IsCurrent = 0
WHERE CustomerKey = 1;

-- Insert new record
INSERT INTO Dim_Customer (CustomerID, City, ValidFrom, ValidTo, IsCurrent)
VALUES ('C123', 'Lyon', '2024-01-15', NULL, 1);
```

**DAX for SCD Type 2:**
```dax
-- Get current version only
Current Customers = FILTER(Dim_Customer, Dim_Customer[IsCurrent] = 1)

-- Point-in-time analysis
Customers At Date =
FILTER(
    Dim_Customer,
    Dim_Customer[ValidFrom] <= SELECTEDVALUE('Date'[Date]) &&
    (Dim_Customer[ValidTo] >= SELECTEDVALUE('Date'[Date]) || ISBLANK(Dim_Customer[ValidTo]))
)
```

### SCD Type 3: Add New Column

```
Behavior: Add column for previous value

Example:
  Customer moved:
    CustomerKey=1, CurrentCity="Lyon", PreviousCity="Paris"

  Limited history (1-2 versions) ⚠️

Use when:
  • Only need current + previous
  • Simple reporting
  • Avoid table bloat

SQL:
  ALTER TABLE Dim_Customer ADD PreviousCity VARCHAR(100);

  UPDATE Dim_Customer
  SET PreviousCity = CurrentCity,
      CurrentCity = 'Lyon'
  WHERE CustomerKey = 1;
```

## Snowflake Schema

### Structure

```
Snowflake = Normalized Star Schema

Star Schema:
  Fact_Sales (*) ──→ (1) Dim_Product
                          (denormalized, all attributes)

Snowflake Schema:
  Fact_Sales (*) ──→ (1) Dim_Product (*) ──→ (1) Dim_Category
                                         (*) ──→ (1) Dim_Subcategory

  Product dimension is normalized into multiple tables
```

### Comparison

```
Star Schema:
  ✅ Simpler queries (fewer joins)
  ✅ Faster queries
  ✅ Easier to understand
  ❌ Data redundancy
  ❌ Larger storage

Snowflake Schema:
  ✅ Less data redundancy
  ✅ Smaller storage
  ✅ Easier dimension updates
  ❌ More complex queries
  ❌ Slower queries (more joins)
  ❌ Harder to understand

Recommendation:
  🚀 Use Star Schema for Power BI
  ❌ Avoid Snowflake (performance penalty)
  ✅ Denormalize dimensions for BI
```

## Role-Playing Dimensions

### Concept

```
Role-Playing Dimension = Same dimension, multiple roles

Example: Date dimension used 3 times in Sales
  • OrderDate
  • ShipDate
  • DueDate

Single physical table (Dim_Date)
Multiple logical relationships
```

### Implementation

```
Power BI Model:
┌──────────────────────────────────────┐
│  Fact_Sales                          │
│  ├─ OrderDateKey (FK)                │
│  ├─ ShipDateKey (FK)                 │
│  └─ DueDateKey (FK)                  │
└──────────────────────────────────────┘
          │         │         │
          ▼         ▼         ▼
     ┌────────────────────┐
     │  Dim_Date          │
     │  (single table)    │
     └────────────────────┘

Relationships:
  • Sales[OrderDateKey] → Date[DateKey] (Active)
  • Sales[ShipDateKey] → Date[DateKey] (Inactive)
  • Sales[DueDateKey] → Date[DateKey] (Inactive)
```

**DAX with Inactive Relationships:**
```dax
-- Uses active relationship (OrderDate)
Sales Amount = SUM(Sales[Amount])

-- Uses inactive relationship (ShipDate)
Sales by Ship Date =
CALCULATE(
    [Sales Amount],
    USERELATIONSHIP(Sales[ShipDateKey], 'Date'[DateKey])
)

-- Uses inactive relationship (DueDate)
Sales by Due Date =
CALCULATE(
    [Sales Amount],
    USERELATIONSHIP(Sales[DueDateKey], 'Date'[DateKey])
)
```

## Degenerate Dimensions

### Definition

```
Degenerate Dimension = Dimension attribute in fact table

Example:
  Invoice Number, Order Number, Transaction ID

Characteristics:
  • No separate dimension table
  • Stored in fact table
  • Used for grouping/filtering
  • No descriptive attributes

Fact_Sales:
  ├─ SalesKey (PK)
  ├─ DateKey (FK) → Dim_Date
  ├─ CustomerKey (FK) → Dim_Customer
  ├─ InvoiceNumber  ← Degenerate dimension (no FK)
  ├─ Amount
  └─ Quantity
```

### When to Use

```
✅ Use degenerate dimension when:
  • Dimension has no attributes (just ID)
  • Used only for filtering/grouping
  • Would create empty dimension table

❌ Create proper dimension when:
  • Has descriptive attributes
  • Needs hierarchies
  • Used for drill-down
```

## Best Practices

### ✅ Design Principles

```
1. Keep dimensions denormalized
   • Flat structure (no snowflaking)
   • All attributes in one table
   • Easier queries, faster joins

2. Use surrogate keys
   • Integer keys for all relationships
   • Never use business keys for joins
   • Maintains stability

3. One fact, one grain
   • Each fact table = single granularity
   • Don't mix grain levels
   • Create separate facts if needed

4. Minimize dimension count
   • 5-15 dimensions optimal
   • Combine related attributes
   • Avoid dimension proliferation

5. Use SCD Type 2 for critical dimensions
   • Preserve history when needed
   • Customer, Product dimensions
   • Audit and compliance
```

### ✅ Naming Conventions

```
Tables:
  ✅ Fact_Sales, Fact_Orders
  ✅ Dim_Customer, Dim_Product, Dim_Date

Keys:
  ✅ CustomerKey (surrogate)
  ✅ CustomerID (business key)
  ❌ Customer_Key (underscore inconsistent)

Attributes:
  ✅ FirstName, LastName, EmailAddress
  ✅ OrderDate, ShipDate
  ❌ FName, LName (abbreviations unclear)
```

### ✅ Performance Optimization

```
1. Partition fact tables
   • By date (most common filter)
   • Monthly or yearly partitions

2. Index foreign keys
   • All FK columns in fact table
   • Clustered index on DateKey

3. Compression
   • Columnstore index for fact tables
   • Page compression for dimensions

4. Statistics
   • Keep statistics updated
   • Especially on join columns
```

## Example: Complete Star Schema

```
E-Commerce Star Schema:
┌──────────────────────────────────────┐
│  Fact_Sales                          │
│  ├─ SalesKey (PK)                    │
│  ├─ DateKey (FK) ──────────┐         │
│  ├─ CustomerKey (FK) ───┐  │         │
│  ├─ ProductKey (FK) ──┐ │  │         │
│  ├─ StoreKey (FK) ──┐ │ │  │         │
│  ├─ Quantity        │ │ │  │         │
│  ├─ UnitPrice       │ │ │  │         │
│  ├─ SalesAmount     │ │ │  │         │
│  ├─ Cost            │ │ │  │         │
│  └─ Profit          │ │ │  │         │
└─────────────────────┼─┼─┼──┼─────────┘
                      │ │ │  │
           ┌──────────┘ │ │  │
           ▼            │ │  │
      Dim_Store        │ │  │
      ├─ StoreKey      │ │  │
      ├─ StoreName     │ │  │
      ├─ City          │ │  │
      └─ Country       │ │  │
                       │ │  │
           ┌───────────┘ │  │
           ▼             │  │
      Dim_Product       │  │
      ├─ ProductKey     │  │
      ├─ ProductName    │  │
      ├─ Category       │  │
      └─ Subcategory    │  │
                        │  │
           ┌────────────┘  │
           ▼               │
      Dim_Customer        │
      ├─ CustomerKey      │
      ├─ FirstName        │
      ├─ LastName         │
      ├─ City             │
      └─ Segment          │
                          │
           ┌──────────────┘
           ▼
      Dim_Date
      ├─ DateKey
      ├─ Date
      ├─ Year
      ├─ Month
      └─ DayName
```

## Points Clés

- Star Schema = central fact + surrounding dimensions
- Fact = measures + foreign keys (large, millions of rows)
- Dimension = attributes + primary key (small, thousands of rows)
- Surrogate keys (integers) for performance and stability
- SCD Type 1 (overwrite), Type 2 (new row), Type 3 (new column)
- Denormalize dimensions (avoid snowflake in Power BI)
- Role-playing dimensions (same table, multiple roles, USERELATIONSHIP)
- Degenerate dimensions (IDs in fact table without dimension)
- One fact, one grain principle
- Optimize with partitioning, indexing, compression

---

**Prochain fichier :** [05 - DAX Basics](./05-dax-basics.md)

[⬅️ Fichier précédent](./03-import-vs-directquery.md) | [⬅️ Retour au README du module](./README.md)
