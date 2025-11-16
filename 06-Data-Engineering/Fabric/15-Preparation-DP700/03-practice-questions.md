# Practice Questions for DP-700

## Introduction

Cette section contient des questions de pratique représentatives du format et du niveau de difficulté de l'examen DP-700. Utilisez ces questions pour évaluer votre niveau de préparation et identifier les domaines nécessitant plus d'étude.

## Lakehouse & Data Foundation

### Question 1 - Delta Lake Features

```
You have a Lakehouse in Microsoft Fabric containing a Delta table named
'sales_transactions'. The table was accidentally updated with incorrect data.

You need to restore the table to its state from 2 hours ago.

Which T-SQL statement should you use?

A) ROLLBACK TABLE sales_transactions TO 2 HOURS AGO;

B) RESTORE TABLE sales_transactions TO TIMESTAMP AS OF DATEADD(hour, -2, GETUTCDATE());

C) ALTER TABLE sales_transactions REVERT TO VERSION AS OF 2 HOURS;

D) SELECT * FROM sales_transactions TIMESTAMP AS OF DATEADD(hour, -2, GETUTCDATE());
```

**Answer: B**

**Explanation**: Delta Lake supports Time Travel through the RESTORE TABLE command with TIMESTAMP AS OF syntax. This restores the entire table to its state at the specified time.

---

### Question 2 - OneLake Shortcuts

```
You are designing a data architecture for Contoso. Requirements:
- Data resides in Amazon S3
- Data must be queryable from Fabric without copying
- Maintain single source of truth

What should you implement?

A) Copy data from S3 to OneLake using a scheduled pipeline
B) Create an OneLake shortcut pointing to S3
C) Use PolyBase external tables
D) Configure S3 as a linked service in Data Factory
```

**Answer: B**

**Explanation**: OneLake shortcuts allow querying external data (S3, ADLS Gen2, GCS) without copying. This maintains a single source of truth and avoids data duplication.

---

### Question 3 - Medallion Architecture

```
You are implementing a medallion architecture in Fabric Lakehouse.
Match each layer with its primary purpose:

Bronze Layer  →  [?]
Silver Layer  →  [?]
Gold Layer    →  [?]

Options:
- Raw data as ingested
- Cleaned and validated data
- Business-ready aggregations
- Real-time streaming data
```

**Answer**:
- Bronze → Raw data as ingested
- Silver → Cleaned and validated data
- Gold → Business-ready aggregations

**Explanation**: The medallion architecture follows Bronze (raw), Silver (cleaned), Gold (business-ready) pattern for progressive data refinement.

---

## Data Transformation

### Question 4 - PySpark Optimization

```python
# You have this PySpark code that performs slowly:

df_large = spark.read.table("fact_sales")  # 1 billion rows
df_small = spark.read.table("dim_product")  # 10,000 rows

result = df_large.join(df_small, "product_id")
```

```
How should you optimize this join operation?

A) Use sortMergeJoin hint
B) Repartition df_large by product_id
C) Use broadcast join for df_small
D) Increase shuffle partitions to 1000
```

**Answer: C**

**Explanation**: When joining a large table with a small table, broadcast join eliminates shuffle by broadcasting the small table to all nodes:
```python
from pyspark.sql.functions import broadcast
result = df_large.join(broadcast(df_small), "product_id")
```

---

### Question 5 - Incremental Loading

```
You need to implement incremental data loading from a SQL Server source
to a Fabric Lakehouse. The source table has a 'ModifiedDate' column.

Which approach should you use?

A) Truncate and reload the entire table daily
B) Use watermark-based loading with high watermark tracking
C) Copy all data and deduplicate in Spark
D) Use CDC (Change Data Capture) without watermark
```

**Answer: B**

**Explanation**: Watermark-based loading tracks the last processed ModifiedDate, loading only new/changed records. This is efficient and reduces data transfer.

---

### Question 6 - Pipeline Error Handling

```
Your Data Factory pipeline must:
- Continue processing other files if one file fails
- Log all errors for review
- Retry failed activities up to 3 times

Which pipeline configuration achieves this?

A) Set activity retry policy to 3 and use "Upon Failure" dependency
B) Set ForEach activity to sequential with continue on error
C) Set ForEach activity to parallel with fault tolerance enabled
D) Use Try-Catch pattern with stored procedure error logging
```

**Answer: C**

**Explanation**: ForEach with fault tolerance enabled and parallel execution allows the pipeline to continue processing other items even if some fail, while retry policy handles transient errors.

---

## Data Warehouse

### Question 7 - SCD Type 2 Implementation

```sql
-- You need to implement SCD Type 2 for a customer dimension.
-- Fill in the missing MERGE clause:

MERGE INTO dim_customer AS target
USING staging_customer AS source
ON target.customer_id = source.customer_id
   AND target.is_current = 1

WHEN MATCHED AND (
    target.email <> source.email OR
    target.address <> source.address
) THEN
    UPDATE SET target.is_current = 0,
               target.end_date = GETDATE()

_____ INSERT (customer_id, email, address, is_current, start_date)
VALUES (source.customer_id, source.email, source.address, 1, GETDATE());
```

```
What should replace the blank?

A) WHEN MATCHED THEN
B) WHEN NOT MATCHED THEN
C) WHEN NOT MATCHED BY SOURCE THEN
D) WHEN NOT MATCHED BY TARGET THEN
```

**Answer: B or D (same meaning in MERGE)**

**Explanation**: WHEN NOT MATCHED (or WHEN NOT MATCHED BY TARGET) inserts new records that don't exist in the target dimension table.

---

### Question 8 - Query Optimization

```
You observe that queries against your Fabric Warehouse are slow.
The main query filters on 'sale_date' and 'region_id'.

Which optimization technique is MOST effective?

A) Create a non-clustered index on sale_date
B) Add a clustered columnstore index (default in Fabric)
C) Partition the table by sale_date and apply Z-ORDER on region_id
D) Increase the warehouse capacity to F64
```

**Answer: C**

**Explanation**: For analytical queries with frequent filters on specific columns, partitioning and Z-ORDER optimization provide the best performance by enabling data skipping and co-locating related data.

---

## Semantic Models & DAX

### Question 9 - Direct Lake Configuration

```
You are creating a Direct Lake semantic model in Fabric.
Which requirement must be met for optimal performance?

A) Data must be in Import mode in Power BI Desktop
B) Source tables must be in Delta format with V-Order enabled
C) Source data must be in a SQL Server database
D) Tables must have row count less than 100,000
```

**Answer: B**

**Explanation**: Direct Lake requires Delta Lake format in OneLake, and V-Order optimization ensures the most efficient query performance by pre-sorting data for BI workloads.

---

### Question 10 - DAX Measure

```dax
// You need to calculate Year-over-Year growth percentage.
// Which DAX measure is correct?

// Option A
YoY Growth % =
VAR CurrentYear = SUM(Sales[Amount])
VAR PreviousYear = CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR('Date'[Date]))
RETURN DIVIDE(CurrentYear - PreviousYear, PreviousYear)

// Option B
YoY Growth % =
SUM(Sales[Amount]) / CALCULATE(SUM(Sales[Amount]), DATEADD('Date'[Date], -1, YEAR))

// Option C
YoY Growth % =
(SUM(Sales[Amount]) - CALCULATE(SUM(Sales[Amount]), PREVIOUSYEAR('Date'[Date])))
/ CALCULATE(SUM(Sales[Amount]), PREVIOUSYEAR('Date'[Date]))

// Option D
YoY Growth % =
DIVIDE(
    SUM(Sales[Amount]) - CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR('Date'[Date])),
    CALCULATE(SUM(Sales[Amount]), SAMEPERIODLASTYEAR('Date'[Date]))
)
```

**Answer: D (or A - both are correct)**

**Explanation**: Option D uses DIVIDE (safe division) with SAMEPERIODLASTYEAR for proper time intelligence. Option A is also correct using variables for clarity.

---

### Question 11 - Row-Level Security

```
You need to implement RLS so that salespeople see only their region's data.

Which DAX expression should you use in the security role?

A) [Region] = USERPRINCIPALNAME()

B) LOOKUPVALUE(Users[Region], Users[Email], USERPRINCIPALNAME()) = [Region]

C) FILTER(Sales, Sales[Region] = Users[Region])

D) IF(CONTAINSSTRING(USERPRINCIPALNAME(), [Region]), TRUE(), FALSE())
```

**Answer: B**

**Explanation**: LOOKUPVALUE retrieves the user's region from a Users table based on their email, then filters the data to match that region. This is the standard pattern for dynamic RLS.

---

## Real-Time Analytics

### Question 12 - KQL Query

```kql
// You need to count events per hour for the last 24 hours.
// Which KQL query is correct?

// Option A
SensorEvents
| where Timestamp > ago(24h)
| summarize count() by bin(Timestamp, 1h)

// Option B
SensorEvents
| where Timestamp > now(-24h)
| group by hour(Timestamp)
| count

// Option C
SELECT COUNT(*)
FROM SensorEvents
WHERE Timestamp > DATEADD(hour, -24, GETDATE())
GROUP BY DATEPART(hour, Timestamp)

// Option D
SensorEvents
| filter Timestamp > 24 hours ago
| aggregate count per hour
```

**Answer: A**

**Explanation**: KQL uses `where` for filtering, `ago()` for relative time, `summarize` for aggregation, and `bin()` for time bucketing. Option A is correct KQL syntax.

---

## Architecture & Design

### Question 13 - Case Study Question

```
Scenario:
Contoso has the following requirements:
- Ingest 500GB of data daily from on-premises SQL Server
- Transform data using Spark notebooks
- Store historical data for 7 years
- Enable self-service analytics for business users
- Budget: F8 capacity

Which architecture should you recommend?

A) Lakehouse only with Direct Lake semantic model
B) Data Warehouse only with Import mode dataset
C) Lakehouse (Bronze/Silver) + Warehouse (Gold) + Direct Lake
D) Real-Time Analytics database for all data
```

**Answer: C**

**Explanation**: The hybrid approach leverages Lakehouse for cost-effective storage and Spark transformations (Bronze/Silver), Warehouse for optimized analytical queries (Gold), and Direct Lake for real-time BI with minimal refresh overhead.

---

### Question 14 - Git Integration

```
Your team wants to implement version control for Fabric artifacts.
Which statement is TRUE about Git integration?

A) All artifacts including data are versioned in Git
B) Only metadata and definitions are versioned, not actual data
C) Git integration is only available for Power BI reports
D) Credentials and connection strings are stored in Git for portability
```

**Answer: B**

**Explanation**: Git integration versions metadata and artifact definitions (notebooks, pipelines, report definitions). Actual data, credentials, and runtime configurations are NOT stored in Git for security reasons.

---

## Scoring Your Practice

```python
def evaluate_practice_test(answers, total_questions=14):
    """Évalue vos résultats de test de pratique"""

    score_percentage = (answers['correct'] / total_questions) * 100

    if score_percentage >= 85:
        readiness = "Excellent - Ready for exam"
        recommendation = "Schedule your exam, final review of weak areas"
    elif score_percentage >= 70:
        readiness = "Good - Almost ready"
        recommendation = "Focus on missed questions, more practice needed"
    elif score_percentage >= 55:
        readiness = "Moderate - More study required"
        recommendation = "Review all domains, increase hands-on practice"
    else:
        readiness = "Needs improvement"
        recommendation = "Extend study timeline, focus on fundamentals"

    return {
        'score': f"{answers['correct']}/{total_questions}",
        'percentage': f"{score_percentage:.1f}%",
        'readiness': readiness,
        'recommendation': recommendation
    }
```

## Points Clés

- Pratiquer régulièrement avec des questions de différents domaines
- Analyser les réponses incorrectes pour comprendre les lacunes
- Focus sur les concepts fréquemment testés (Delta Lake, DAX, Architecture)
- Chronométrer vos réponses (2 minutes max par question)
- Réviser les patterns d'implémentation (SCD, Medallion, RLS)
- Comprendre le "pourquoi" derrière chaque réponse
- Refaire les questions difficiles après révision du concept
- Utiliser les erreurs comme opportunités d'apprentissage

---

**Navigation** : [Précédent : Study Guide](./02-study-guide.md) | [Index](../README.md) | [Suivant : Hands-on Labs](./04-hands-on-labs.md)
