# Projet 3 : Data Warehouse Analytics

## Vue d'ensemble

Dans ce projet, vous allez construire un **Data Warehouse complet** avec star schema pour une chaîne de retail "GlobalMart". Vous créerez des modèles sémantiques Direct Lake et des rapports Power BI pour fournir des insights business actionables.

**Durée estimée :** 10-12 heures
**Niveau :** Intermédiaire à Avancé
**Modules prérequis :** 03, 07

## Contexte Business

### L'entreprise : GlobalMart

GlobalMart est une chaîne de retail internationale avec :
- Présence dans 5 régions mondiales
- 100,000+ transactions mensuelles
- 10,000+ clients actifs
- 500+ produits dans le catalogue
- Équipes sales, marketing et finance nécessitant des analyses

### Problématique

L'équipe de direction a besoin de :
- **Visibilité temps réel** sur les performances de ventes
- **Analyses comparatives** (YoY, MoM, par région)
- **Segmentation client** pour optimiser le marketing
- **Analyse produits** pour la gestion des stocks
- **Contrôle d'accès** : chaque région voit uniquement ses données

**Objectif :** Créer un Data Warehouse analytique avec reporting self-service.

## Objectifs d'Apprentissage

À la fin de ce projet, vous serez capable de :

- ✅ Concevoir un star schema optimisé (dimensions, facts)
- ✅ Créer et charger un Fabric Warehouse avec T-SQL
- ✅ Configurer un semantic model Direct Lake
- ✅ Écrire des mesures DAX avancées (time intelligence, CALCULATE)
- ✅ Construire des rapports Power BI interactifs
- ✅ Implémenter Row-Level Security
- ✅ Optimiser les performances (V-Order, DAX)
- ✅ Documenter un modèle de données

## 📦 Données Fournies

**IMPORTANT : Les données pour ce projet sont disponibles dans `../../Ressources/datasets/`**

| Fichier | Description | Usage dans ce projet |
|---------|-------------|---------------------|
| **`retail_sales.csv`** (15 MB, 100K lignes) | Ventes avec dates, montants, régions, catégories | → Fact_Sales |
| **`customers.csv`** (1.6 MB, 10K clients) | Clients avec pays, ville, segments | → Dim_Customer |
| **`products.csv`** (63 KB, 500 produits) | Catalogue avec catégories, prix, coûts | → Dim_Product |

### Chargement des Données

1. **Uploadez les fichiers** dans votre Lakehouse `Files/raw/`
2. **Créez les tables Bronze** :

```python
# Dans un notebook Fabric
df_sales = spark.read.csv("Files/raw/retail_sales.csv", header=True, inferSchema=True)
df_customers = spark.read.csv("Files/raw/customers.csv", header=True, inferSchema=True)
df_products = spark.read.csv("Files/raw/products.csv", header=True, inferSchema=True)

# Sauvegarder comme tables Delta (Bronze)
df_sales.write.mode("overwrite").saveAsTable("bronze_sales")
df_customers.write.mode("overwrite").saveAsTable("bronze_customers")
df_products.write.mode("overwrite").saveAsTable("bronze_products")
```

3. **Générer Dim_Date** : Script T-SQL fourni dans la section "Star Schema"
4. **Transformer en Star Schema** : Scripts de création des dimensions et facts fournis

### Structure Star Schema

```
                    ┌─────────────┐
                    │  Dim_Date   │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴───────┐    ┌─────────────┐
│ Dim_Customer├────┤  Fact_Sales   ├────┤ Dim_Product │
└─────────────┘    └───────┬───────┘    └─────────────┘
                           │
                    ┌──────┴──────┐
                    │Dim_Geography│
                    └─────────────┘
```

## Architecture Cible

```
┌─────────────────────────────────────────────────────────────┐
│                    SOURCE DATA (Lakehouse)                   │
├──────────────┬──────────────┬──────────────────────────────┤
│ retail_sales │ customers    │ products                      │
│ (100K rows)  │ (10K rows)   │ (500 rows)                   │
└──────┬───────┴──────┬───────┴──────────┬───────────────────┘
       │              │                  │
       └──────────────┴──────────────────┘
                      │
                      ▼
        ┌──────────────────────────┐
        │    FABRIC WAREHOUSE      │
        │    (Star Schema)         │
        ├──────────────────────────┤
        │ ┌─────────────────────┐  │
        │ │    Dim_Date         │  │
        │ │    Dim_Customer     │  │
        │ │    Dim_Product      │  │
        │ │    Dim_Geography    │  │
        │ └─────────────────────┘  │
        │           │              │
        │           ▼              │
        │ ┌─────────────────────┐  │
        │ │    Fact_Sales       │  │
        │ │    (100K+ rows)     │  │
        │ └─────────────────────┘  │
        └──────────────────────────┘
                      │
                      ▼
        ┌──────────────────────────┐
        │   SEMANTIC MODEL         │
        │   (Direct Lake)          │
        ├──────────────────────────┤
        │ • Relationships          │
        │ • DAX Measures           │
        │ • Row-Level Security     │
        │ • Hierarchies            │
        └──────────────────────────┘
                      │
                      ▼
        ┌──────────────────────────┐
        │   POWER BI REPORTS       │
        ├──────────────────────────┤
        │ • Executive Dashboard    │
        │ • Customer Analysis      │
        │ • Product Performance    │
        │ • Financial Insights     │
        └──────────────────────────┘
```

## Données Source

Utilisez les datasets générés :
- `retail_sales.csv` (14.6 MB, 100K transactions)
- `customers.csv` (1.5 MB, 10K clients)
- `products.csv` (500 produits)

**Emplacement :** `/Ressources/datasets/`

## Phase 1: Chargement des Données Sources (1h)

### 1.1 Upload vers Lakehouse

1. Créer un Lakehouse "GlobalMart_Raw"
2. Upload les fichiers CSV dans Files/raw/
3. Créer des tables Delta :

```python
# Notebook: Load Raw Data

# Load retail sales
df_sales = spark.read.csv(
    "Files/raw/retail_sales.csv",
    header=True,
    inferSchema=True
)
df_sales.write.format("delta").saveAsTable("raw_sales")
print(f"Sales: {df_sales.count()} rows")

# Load customers
df_customers = spark.read.csv(
    "Files/raw/customers.csv",
    header=True,
    inferSchema=True
)
df_customers.write.format("delta").saveAsTable("raw_customers")
print(f"Customers: {df_customers.count()} rows")

# Load products
df_products = spark.read.csv(
    "Files/raw/products.csv",
    header=True,
    inferSchema=True
)
df_products.write.format("delta").saveAsTable("raw_products")
print(f"Products: {df_products.count()} rows")

# Validate
spark.sql("SHOW TABLES").show()
```

## Phase 2: Création du Warehouse (2h)

### 2.1 Créer le Fabric Warehouse

1. Fabric Workspace → New → Warehouse
2. Nom : "GlobalMart_DW"
3. Description : "Analytical Data Warehouse for GlobalMart"

### 2.2 Création de la Dimension Date

```sql
-- Date dimension generator (for 2020-2025)
CREATE TABLE Dim_Date (
    DateKey INT NOT NULL,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    MonthShort VARCHAR(3) NOT NULL,
    Week INT NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    DayShort VARCHAR(3) NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,

    CONSTRAINT PK_DimDate PRIMARY KEY NONCLUSTERED (DateKey) NOT ENFORCED
);

-- Populate date dimension using CTE
WITH DateRange AS (
    SELECT CAST('2020-01-01' AS DATE) AS Date
    UNION ALL
    SELECT DATEADD(DAY, 1, Date)
    FROM DateRange
    WHERE Date < '2025-12-31'
)
INSERT INTO Dim_Date
SELECT
    CAST(FORMAT(Date, 'yyyyMMdd') AS INT) AS DateKey,
    Date,
    YEAR(Date) AS Year,
    DATEPART(QUARTER, Date) AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, Date) AS VARCHAR) AS QuarterName,
    MONTH(Date) AS Month,
    DATENAME(MONTH, Date) AS MonthName,
    LEFT(DATENAME(MONTH, Date), 3) AS MonthShort,
    DATEPART(WEEK, Date) AS Week,
    DAY(Date) AS DayOfMonth,
    DATEPART(WEEKDAY, Date) AS DayOfWeek,
    DATENAME(WEEKDAY, Date) AS DayName,
    LEFT(DATENAME(WEEKDAY, Date), 3) AS DayShort,
    CASE WHEN DATEPART(WEEKDAY, Date) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    0 AS IsHoliday,  -- Mark manually or via lookup
    CASE WHEN MONTH(Date) >= 7 THEN YEAR(Date) + 1 ELSE YEAR(Date) END AS FiscalYear,
    CASE
        WHEN MONTH(Date) IN (7,8,9) THEN 1
        WHEN MONTH(Date) IN (10,11,12) THEN 2
        WHEN MONTH(Date) IN (1,2,3) THEN 3
        ELSE 4
    END AS FiscalQuarter
FROM DateRange
OPTION (MAXRECURSION 2500);

-- Verify
SELECT COUNT(*) AS TotalDays FROM Dim_Date;
-- Expected: ~2192 days (6 years)
```

### 2.3 Création de la Dimension Customer

```sql
CREATE TABLE Dim_Customer (
    CustomerKey INT IDENTITY(1,1) NOT NULL,
    CustomerID VARCHAR(20) NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Segment VARCHAR(50) NOT NULL,
    Industry VARCHAR(50) NOT NULL,
    CompanySize VARCHAR(20) NOT NULL,
    RegistrationDate DATE NOT NULL,
    TotalPurchases INT NOT NULL,
    TotalSpend DECIMAL(12,2) NOT NULL,
    LifetimeValue DECIMAL(12,2) NOT NULL,
    SatisfactionScore DECIMAL(3,1) NOT NULL,
    IsChurned BIT NOT NULL,

    CONSTRAINT PK_DimCustomer PRIMARY KEY NONCLUSTERED (CustomerKey) NOT ENFORCED
);

-- Load from Lakehouse via shortcut or INSERT SELECT
INSERT INTO Dim_Customer (
    CustomerID, FirstName, LastName, FullName, Email, Segment, Industry,
    CompanySize, RegistrationDate, TotalPurchases, TotalSpend, LifetimeValue,
    SatisfactionScore, IsChurned
)
SELECT
    customer_id,
    first_name,
    last_name,
    first_name + ' ' + last_name,
    email,
    segment,
    industry,
    company_size,
    CAST(registration_date AS DATE),
    total_purchases,
    total_spend,
    lifetime_value,
    satisfaction_score,
    CAST(is_churned AS BIT)
FROM lakehouse.dbo.raw_customers;

-- Create index for lookups
CREATE INDEX IX_DimCustomer_CustomerID ON Dim_Customer(CustomerID);
```

### 2.4 Création de la Dimension Product

```sql
CREATE TABLE Dim_Product (
    ProductKey INT IDENTITY(1,1) NOT NULL,
    ProductID VARCHAR(20) NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    SubCategory VARCHAR(50) NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    UnitCost DECIMAL(10,2) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    MarginPercent DECIMAL(5,1) NOT NULL,
    IsActive BIT NOT NULL,

    CONSTRAINT PK_DimProduct PRIMARY KEY NONCLUSTERED (ProductKey) NOT ENFORCED
);

INSERT INTO Dim_Product (
    ProductID, ProductName, Category, SubCategory, Brand,
    UnitCost, UnitPrice, MarginPercent, IsActive
)
SELECT
    product_id,
    product_name,
    category,
    subcategory,
    brand,
    unit_cost,
    unit_price,
    margin_percent,
    CAST(is_active AS BIT)
FROM lakehouse.dbo.raw_products;

CREATE INDEX IX_DimProduct_ProductID ON Dim_Product(ProductID);
```

### 2.5 Création de la Dimension Geography

```sql
CREATE TABLE Dim_Geography (
    GeographyKey INT IDENTITY(1,1) NOT NULL,
    Region VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Continent VARCHAR(50) NOT NULL,

    CONSTRAINT PK_DimGeography PRIMARY KEY NONCLUSTERED (GeographyKey) NOT ENFORCED
);

-- Extract unique geographies from sales
INSERT INTO Dim_Geography (Region, Country, Continent)
SELECT DISTINCT
    region,
    country,
    CASE
        WHEN region = 'North America' THEN 'Americas'
        WHEN region = 'Latin America' THEN 'Americas'
        WHEN region = 'Europe' THEN 'Europe'
        WHEN region = 'Asia Pacific' THEN 'Asia'
        WHEN region = 'Middle East' THEN 'Asia'
        ELSE 'Other'
    END AS Continent
FROM lakehouse.dbo.raw_sales;
```

### 2.6 Création de la Fact Table

```sql
CREATE TABLE Fact_Sales (
    SalesKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    TransactionID VARCHAR(20) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    GrossAmount DECIMAL(12,2) NOT NULL,
    DiscountPercent DECIMAL(5,2) NOT NULL,
    DiscountAmount DECIMAL(12,2) NOT NULL,
    NetAmount DECIMAL(12,2) NOT NULL,
    Cost DECIMAL(12,2) NOT NULL,
    Profit DECIMAL(12,2) NOT NULL,
    Channel VARCHAR(50) NOT NULL,
    PaymentMethod VARCHAR(50) NOT NULL,

    CONSTRAINT PK_FactSales PRIMARY KEY NONCLUSTERED (SalesKey) NOT ENFORCED,
    CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey)
        REFERENCES Dim_Date(DateKey) NOT ENFORCED,
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey)
        REFERENCES Dim_Customer(CustomerKey) NOT ENFORCED,
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey)
        REFERENCES Dim_Product(ProductKey) NOT ENFORCED,
    CONSTRAINT FK_FactSales_DimGeography FOREIGN KEY (GeographyKey)
        REFERENCES Dim_Geography(GeographyKey) NOT ENFORCED
);

-- Load fact data with dimension lookups
INSERT INTO Fact_Sales (
    DateKey, CustomerKey, ProductKey, GeographyKey, TransactionID,
    Quantity, UnitPrice, GrossAmount, DiscountPercent, DiscountAmount,
    NetAmount, Cost, Profit, Channel, PaymentMethod
)
SELECT
    CAST(FORMAT(CAST(s.date AS DATE), 'yyyyMMdd') AS INT) AS DateKey,
    c.CustomerKey,
    p.ProductKey,
    g.GeographyKey,
    s.transaction_id,
    s.quantity,
    s.unit_price,
    s.gross_amount,
    s.discount_percent,
    s.discount_amount,
    s.net_amount,
    s.cost,
    s.profit,
    s.channel,
    s.payment_method
FROM lakehouse.dbo.raw_sales s
INNER JOIN Dim_Customer c ON s.customer_id = c.CustomerID
INNER JOIN Dim_Product p ON s.product_id = p.ProductID
INNER JOIN Dim_Geography g ON s.region = g.Region AND s.country = g.Country;

-- Verify row count
SELECT COUNT(*) AS TotalSales FROM Fact_Sales;
-- Expected: ~100,000 rows
```

## Phase 3: Semantic Model Direct Lake (2h)

### 3.1 Créer le Semantic Model

1. Fabric Workspace → New → Semantic Model
2. Type : Direct Lake
3. Source : GlobalMart_DW (Warehouse)
4. Sélectionner toutes les tables (Dim_*, Fact_Sales)

### 3.2 Définir les Relations

```
Relationships (Star Schema):
┌─────────────────┐     ┌───────────────┐
│   Dim_Date      │     │  Dim_Customer │
│   (DateKey)     │     │  (CustomerKey)│
└────────┬────────┘     └───────┬───────┘
         │ 1:*                  │ 1:*
         ▼                      ▼
┌─────────────────────────────────────────┐
│              Fact_Sales                  │
│  (DateKey, CustomerKey, ProductKey,     │
│   GeographyKey)                         │
└─────────────────────────────────────────┘
         ▲                      ▲
         │ *:1                  │ *:1
┌────────┴────────┐     ┌───────┴───────┐
│  Dim_Product    │     │ Dim_Geography │
│  (ProductKey)   │     │ (GeographyKey)│
└─────────────────┘     └───────────────┘

Configuration:
- All relationships: Single direction
- Cross-filter: Single
- Cardinality: Many-to-One (Fact to Dim)
- Active: Yes
```

### 3.3 Créer les Mesures DAX

```dax
// ===========================================
// BASE MEASURES
// ===========================================

Total Sales =
SUM(Fact_Sales[NetAmount])

Total Quantity =
SUM(Fact_Sales[Quantity])

Total Cost =
SUM(Fact_Sales[Cost])

Total Profit =
SUM(Fact_Sales[Profit])

Transaction Count =
COUNTROWS(Fact_Sales)

Average Order Value =
DIVIDE([Total Sales], [Transaction Count], 0)

Profit Margin % =
DIVIDE([Total Profit], [Total Sales], 0)

// ===========================================
// TIME INTELLIGENCE
// ===========================================

Sales MTD =
TOTALMTD([Total Sales], Dim_Date[Date])

Sales QTD =
TOTALQTD([Total Sales], Dim_Date[Date])

Sales YTD =
TOTALYTD([Total Sales], Dim_Date[Date])

Sales Previous Month =
CALCULATE([Total Sales], PREVIOUSMONTH(Dim_Date[Date]))

Sales Previous Year =
CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Dim_Date[Date]))

Sales YoY Growth % =
VAR CurrentPeriod = [Total Sales]
VAR PriorPeriod = [Sales Previous Year]
RETURN
    DIVIDE(CurrentPeriod - PriorPeriod, PriorPeriod, BLANK())

Sales MoM Growth % =
VAR CurrentMonth = [Total Sales]
VAR PriorMonth = [Sales Previous Month]
RETURN
    DIVIDE(CurrentMonth - PriorMonth, PriorMonth, BLANK())

// ===========================================
// CUSTOMER ANALYTICS
// ===========================================

Active Customers =
DISTINCTCOUNT(Fact_Sales[CustomerKey])

Average Customer Spend =
DIVIDE([Total Sales], [Active Customers], 0)

New Customers =
VAR CurrentPeriodCustomers = VALUES(Fact_Sales[CustomerKey])
VAR PriorPeriodCustomers =
    CALCULATETABLE(
        VALUES(Fact_Sales[CustomerKey]),
        PREVIOUSMONTH(Dim_Date[Date])
    )
RETURN
    COUNTROWS(EXCEPT(CurrentPeriodCustomers, PriorPeriodCustomers))

Customer Retention Rate =
VAR TotalCustomers = [Active Customers]
VAR NewCust = [New Customers]
VAR RetainedCustomers = TotalCustomers - NewCust
RETURN
    DIVIDE(RetainedCustomers, TotalCustomers, 0)

// ===========================================
// PRODUCT ANALYTICS
// ===========================================

Products Sold =
DISTINCTCOUNT(Fact_Sales[ProductKey])

Top Product Sales =
VAR ProductRank =
    RANKX(ALL(Dim_Product), [Total Sales], , DESC)
RETURN
    IF(ProductRank <= 10, [Total Sales], BLANK())

Category Contribution % =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(Dim_Product[Category])),
    0
)

// ===========================================
// GEOGRAPHIC ANALYTICS
// ===========================================

Regional Sales Distribution % =
DIVIDE(
    [Total Sales],
    CALCULATE([Total Sales], ALL(Dim_Geography)),
    0
)

// ===========================================
// KPI STATUS
// ===========================================

Sales Target =
2000000  // $2M monthly target (customize)

Sales vs Target % =
DIVIDE([Total Sales], [Sales Target], 0)

Target Status =
VAR Achievement = [Sales vs Target %]
RETURN
    SWITCH(
        TRUE(),
        Achievement >= 1.1, "Exceeding",
        Achievement >= 1.0, "On Target",
        Achievement >= 0.9, "Slightly Below",
        "Below Target"
    )
```

### 3.4 Configurer Row-Level Security

1. Dans le semantic model → Manage Roles
2. Créer un rôle "Regional_Access"

```dax
// Role: Regional_Access
// Table: Dim_Geography
[Region] IN {
    LOOKUPVALUE(
        UserRegionMapping[Region],
        UserRegionMapping[UserEmail],
        USERPRINCIPALNAME()
    )
}

// Alternative avec table de mapping
VAR CurrentUser = USERPRINCIPALNAME()
RETURN
    [Region] IN
    CALCULATETABLE(
        VALUES(SecurityMapping[AllowedRegion]),
        SecurityMapping[UserEmail] = CurrentUser
    )
```

3. Assigner les utilisateurs aux rôles

## Phase 4: Power BI Reports (3h)

### 4.1 Page 1: Executive Dashboard

**Layout:**
```
┌─────────┬─────────┬─────────┬─────────┐
│ Total   │ YoY     │ Profit  │ Trans.  │
│ Sales   │ Growth  │ Margin  │ Count   │
│ (Card)  │ (Card)  │ (Card)  │ (Card)  │
├─────────┴─────────┴─────────┴─────────┤
│                                        │
│    Sales Trend (Line Chart)            │
│    X: Date (Month)                     │
│    Y: Total Sales, Sales Previous Year │
│                                        │
├────────────────────┬───────────────────┤
│                    │                   │
│ Sales by Category  │ Sales by Region   │
│ (Bar Chart)        │ (Donut Chart)     │
│                    │                   │
└────────────────────┴───────────────────┘
```

**Visual Configurations:**

Card - Total Sales:
- Value: [Total Sales]
- Format: Currency, 0 decimals
- Conditional formatting: Color scale

Line Chart - Sales Trend:
```
X-Axis: Dim_Date[MonthName]
Y-Axis: [Total Sales], [Sales Previous Year]
Legend: "Current Year", "Prior Year"
Title: "Monthly Sales Trend"
```

### 4.2 Page 2: Customer Analysis

**Visuals:**

1. **Customer Segmentation (Pie Chart)**
   - Values: [Active Customers]
   - Legend: Dim_Customer[Segment]

2. **Top 10 Customers (Table)**
```
Columns:
- Dim_Customer[FullName]
- [Total Sales]
- [Transaction Count]
- [Average Order Value]

Sort: [Total Sales] DESC
Top N filter: 10
```

3. **Customer Lifetime Value Distribution (Histogram)**
   - X-Axis: Dim_Customer[LifetimeValue] (bins)
   - Y-Axis: Count of customers

4. **Geographic Sales (Map)**
   - Location: Dim_Geography[Country]
   - Size: [Total Sales]
   - Color: [Profit Margin %]

5. **New vs Returning Customers (Clustered Column)**
   - X-Axis: Dim_Date[Month]
   - Y-Axis: [New Customers], [Active Customers] - [New Customers]

### 4.3 Page 3: Product Performance

**Visuals:**

1. **Category Performance (Treemap)**
   - Group: Dim_Product[Category]
   - Values: [Total Sales]
   - Color: [Profit Margin %]

2. **Brand Analysis (Matrix)**
```
Rows: Dim_Product[Brand]
Columns: Dim_Product[Category]
Values: [Total Sales], [Profit Margin %]

Conditional formatting:
- [Total Sales]: Data bars
- [Profit Margin %]: Color scale (Red < 30%, Yellow 30-50%, Green > 50%)
```

3. **Product Ranking (Table)**
   - Dim_Product[ProductName]
   - [Total Sales]
   - [Total Quantity]
   - [Category Contribution %]
   - Sparkline: Sales over time

4. **Sales by Channel (Stacked Bar)**
   - X-Axis: Dim_Product[Category]
   - Y-Axis: [Total Sales]
   - Legend: Fact_Sales[Channel]

### 4.4 Page 4: Financial Insights

**Visuals:**

1. **Profit Waterfall**
   - Category: "Revenue", "Cost", "Gross Profit", "Operating Expenses", "Net Profit"
   - Show: Breakdown of profit components

2. **Discount Analysis (Scatter)**
   - X-Axis: [DiscountPercent] (average)
   - Y-Axis: [Profit Margin %]
   - Size: [Total Sales]
   - Details: Dim_Product[Category]

3. **Payment Method Distribution (Donut)**
   - Values: [Transaction Count]
   - Legend: Fact_Sales[PaymentMethod]

### 4.5 Slicers et Filters

Add to all pages:
- Date Range (Slicer - Slider)
- Region (Slicer - Dropdown)
- Category (Slicer - List)
- Channel (Slicer - Buttons)

Enable:
- Sync slicers across pages
- Clear all filters button

## Phase 5: Optimisation et Tests (1h)

### 5.1 Performance Optimization

**V-Order (Warehouse):**
```sql
-- Tables are automatically V-Order optimized in Fabric
-- Verify optimization status
SELECT
    table_name,
    column_name,
    is_v_ordered
FROM sys.dm_column_store_row_groups
WHERE table_name LIKE 'Fact%' OR table_name LIKE 'Dim%';
```

**DAX Optimization:**
```dax
// BEFORE (Slow)
Total Sales Slow =
SUMX(Fact_Sales, Fact_Sales[Quantity] * Fact_Sales[UnitPrice])

// AFTER (Fast - pre-calculated column)
Total Sales Fast =
SUM(Fact_Sales[NetAmount])

// Use Variables
Profit Margin Optimized =
VAR TotalProfit = [Total Profit]
VAR TotalSales = [Total Sales]
RETURN
    DIVIDE(TotalProfit, TotalSales, 0)
```

### 5.2 Testing

**Performance Tests:**
```
Use Power BI Performance Analyzer:
1. View → Performance Analyzer
2. Start Recording
3. Refresh all visuals
4. Analyze results

Targets:
- DAX query < 1 second
- Visual rendering < 500ms
- Total page load < 3 seconds
```

**Data Validation:**
```sql
-- Validate referential integrity
SELECT 'Orphan Sales (No Customer)' AS Check,
       COUNT(*) AS Count
FROM Fact_Sales f
LEFT JOIN Dim_Customer c ON f.CustomerKey = c.CustomerKey
WHERE c.CustomerKey IS NULL

UNION ALL

SELECT 'Total Sales Amount Match',
       CASE WHEN ABS(SUM(f.NetAmount) - (SELECT SUM(net_amount) FROM lakehouse.dbo.raw_sales)) < 1
            THEN 0 ELSE 1 END
FROM Fact_Sales f;
```

## Livrables

### Checklist Technique
- [ ] Lakehouse avec données source (3 tables)
- [ ] Warehouse avec star schema (4 dimensions, 1 fact)
- [ ] Données chargées et validées (100K+ transactions)
- [ ] Semantic model Direct Lake configuré
- [ ] 15+ mesures DAX (base, time intelligence, analytics)
- [ ] Row-Level Security par région
- [ ] 4 pages de rapport Power BI
- [ ] Slicers synchronisés
- [ ] Performance < 3s par page
- [ ] Documentation complète

### Documentation Requise
- [ ] Diagramme star schema
- [ ] Dictionnaire de données
- [ ] Catalogue des mesures DAX
- [ ] Guide utilisateur des rapports
- [ ] Configuration RLS
- [ ] Rapport de performance

### Métriques de Succès
```
Data Quality:
  ✓ 100% referential integrity
  ✓ 0 orphan records
  ✓ Data matches source

Performance:
  ✓ Page load < 3 seconds
  ✓ DAX queries < 1 second
  ✓ Direct Lake mode active

Security:
  ✓ RLS filters data correctly
  ✓ Users see only allowed regions
  ✓ No data leakage

Business Value:
  ✓ Executives can see KPIs
  ✓ Self-service analytics enabled
  ✓ Insights are actionable
```

## Critères d'Évaluation

- Star schema design quality (25%)
- DAX measures correctness et performance (30%)
- Report UX et business insights (25%)
- Performance optimization (10%)
- Documentation (10%)

## Extensions Possibles

1. **SCD Type 2** : Historisation des dimensions
2. **Incremental Refresh** : Mise à jour incrémentale
3. **Composite Model** : Mélange Direct Lake + Import
4. **AI Insights** : Q&A, Key Influencers, Smart Narratives
5. **Mobile Layout** : Rapports optimisés mobile
6. **Alertes** : Data-driven alerts sur KPIs

---

**Durée estimée: 10-12 heures**

**Données requises :** `retail_sales.csv`, `customers.csv`, `products.csv` dans `/Ressources/datasets/`

[⬅️ Retour aux projets](../README.md)
