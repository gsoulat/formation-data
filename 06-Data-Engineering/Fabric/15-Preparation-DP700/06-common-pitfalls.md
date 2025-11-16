# Common Pitfalls to Avoid on DP-700

## Introduction

L'examen DP-700 contient de nombreuses questions pièges et des concepts qui peuvent prêter à confusion. Cette section identifie les erreurs courantes des candidats et explique comment les éviter pour maximiser vos chances de succès.

## Architecture & Design Pitfalls

### Piège 1: Confusion Lakehouse vs Warehouse

```python
common_confusion = {
    'misconception': 'Lakehouse and Warehouse are interchangeable',
    'reality': {
        'Lakehouse': {
            'storage': 'Delta Lake files',
            'query_engine': 'Spark (primary) + SQL Endpoint',
            'use_case': 'Data engineering, ML, flexible schema',
            'performance': 'Optimized for large-scale processing'
        },
        'Warehouse': {
            'storage': 'Proprietary columnar format',
            'query_engine': 'T-SQL only',
            'use_case': 'SQL analytics, BI workloads',
            'performance': 'Optimized for SQL queries'
        }
    },
    'exam_tip': 'Choose based on primary workload: Spark → Lakehouse, SQL → Warehouse'
}
```

**Question piège typique**:
> "You need to run complex T-SQL queries with stored procedures. Which should you use?"
> - Answer: **Data Warehouse**, not Lakehouse (même si Lakehouse a un SQL Endpoint)

### Piège 2: OneLake Shortcuts Limitations

```python
shortcuts_pitfalls = {
    'common_mistake': 'Assuming shortcuts copy data',
    'reality': 'Shortcuts are pointers, no data movement',

    'gotchas': [
        {
            'issue': 'Cannot create shortcut to secured data without access',
            'solution': 'Ensure proper permissions on source'
        },
        {
            'issue': 'Cross-tenant shortcuts have limitations',
            'solution': 'Check tenant settings and permissions'
        },
        {
            'issue': 'Performance depends on source location',
            'solution': 'Consider network latency for distant sources'
        },
        {
            'issue': 'Not all file formats supported equally',
            'solution': 'Delta Lake format performs best'
        }
    ],

    'exam_tip': 'Remember: Shortcut = reference, NOT a copy'
}
```

### Piège 3: Direct Lake Fallback Behavior

```python
direct_lake_gotchas = {
    'common_mistake': 'Assuming Direct Lake always stays in DL mode',

    'fallback_triggers': [
        'Very complex DAX queries',
        'Tables without V-Order',
        'High cardinality columns in filters',
        'Non-optimized Delta tables',
        'Composite models mixing Direct Lake with other sources'
    ],

    'impact': 'Switches to DirectQuery = slower performance',

    'how_to_avoid': [
        'Apply V-ORDER to all tables',
        'OPTIMIZE tables regularly',
        'Monitor fallback events',
        'Simplify DAX where possible',
        'Test with realistic workloads'
    ],

    'exam_tip': 'Direct Lake ≠ always fast; needs proper optimization'
}
```

## Data Transformation Pitfalls

### Piège 4: PySpark vs SQL Performance

```python
# WRONG: Using Python loops for large datasets
def process_wrong(df):
    results = []
    for row in df.collect():  # NEVER DO THIS!
        processed = some_function(row)
        results.append(processed)
    return spark.createDataFrame(results)

# RIGHT: Use DataFrame operations
def process_right(df):
    return df.withColumn(
        "processed",
        some_spark_function(col("input"))
    )

performance_pitfall = {
    'mistake': 'Using Python loops instead of Spark operations',
    'why_bad': 'Loses distributed processing benefits',
    'exam_tip': 'Always prefer DataFrame API over collect() + loops'
}
```

### Piège 5: Delta Lake VACUUM Timing

```sql
-- DANGEROUS: Immediate vacuum after writes
OPTIMIZE my_table;
VACUUM my_table RETAIN 0 HOURS;  -- TOO AGGRESSIVE!

-- SAFE: Respect retention period
OPTIMIZE my_table;
VACUUM my_table RETAIN 168 HOURS;  -- 7 days default
```

```python
vacuum_pitfalls = {
    'mistake': 'Vacuuming with too short retention',
    'consequences': [
        'Break Time Travel queries',
        'Lose audit trail',
        'Cannot rollback to recent versions',
        'Active queries may fail'
    ],
    'best_practice': 'Keep at least 7 days retention',
    'exam_tip': 'VACUUM removes history permanently - be cautious!'
}
```

### Piège 6: Incremental Load Without Watermark

```python
# WRONG: No tracking of what was already loaded
def load_data_wrong():
    df = spark.read.table("source")
    df.write.mode("append").saveAsTable("target")
    # Will cause duplicates on next run!

# RIGHT: Track watermark
def load_data_right():
    last_watermark = get_last_watermark("target_table")

    df = spark.read.table("source") \
        .filter(col("modified_date") > last_watermark)

    if df.count() > 0:
        df.write.mode("append").saveAsTable("target")
        update_watermark("target_table", df.agg(max("modified_date")).collect()[0][0])

incremental_pitfall = {
    'mistake': 'Not implementing watermark tracking',
    'result': 'Duplicate data or missing records',
    'exam_tip': 'Always track last processed timestamp or version'
}
```

## DAX & Semantic Model Pitfalls

### Piège 7: Incorrect Filter Context

```dax
// WRONG: This measure is problematic
Total Sales Wrong =
SUMX(
    FILTER(Sales, Sales[Date] = TODAY()),  -- Static filter
    Sales[Amount]
)
// Problem: Ignores slicer selections!

// RIGHT: Respect filter context
Total Sales Right =
CALCULATE(
    SUM(Sales[Amount]),
    'Date'[Date] = TODAY()
)

// EVEN BETTER: Let context flow
Total Sales Best = SUM(Sales[Amount])
// Filter context comes from report filters/slicers
```

```python
dax_context_pitfall = {
    'mistake': 'Overriding filter context unintentionally',
    'impact': 'Measures ignore user selections',
    'fix': 'Understand CALCULATE and filter propagation',
    'exam_tip': 'ALL() removes filters, be explicit about intent'
}
```

### Piège 8: RLS With USERPRINCIPALNAME()

```dax
// WRONG: Hardcoded values
[Region] = "North"  // Only works for specific region

// PARTIAL: Direct comparison
[Email] = USERPRINCIPALNAME()  // Only if email column exists

// CORRECT: With lookup table
LOOKUPVALUE(
    UserAccess[Region],
    UserAccess[UserEmail],
    USERPRINCIPALNAME()
) = [Region]
// Works with security mapping table

// IMPORTANT: Test in Fabric, not Desktop!
// USERPRINCIPALNAME() returns different values in different contexts
```

```python
rls_pitfall = {
    'mistake': 'Testing RLS only in Power BI Desktop',
    'issue': 'USERPRINCIPALNAME() may return empty or different value',
    'solution': 'Test with "View as" role feature in Fabric Service',
    'exam_tip': 'RLS must be tested in the Service, not just Desktop'
}
```

### Piège 9: Calculated Columns vs Measures

```python
calc_column_vs_measure = {
    'calculated_column': {
        'when_to_use': [
            'Static values needed for slicing',
            'Foreign key creation',
            'Simple text categorizations'
        ],
        'impact': 'Increases model size, computed at refresh'
    },
    'measure': {
        'when_to_use': [
            'Aggregations (SUM, COUNT, AVG)',
            'Ratios and percentages',
            'Time intelligence',
            'Any context-aware calculation'
        ],
        'impact': 'Computed at query time, no storage overhead'
    },
    'common_mistake': 'Using calculated column for aggregations',
    'exam_tip': 'If it needs to aggregate, it should be a MEASURE'
}
```

## Pipeline & Orchestration Pitfalls

### Piège 10: Pipeline Parameter Scope

```json
// WRONG: Expecting variable to persist across runs
{
  "activity": "SetVariable",
  "typeProperties": {
    "variableName": "LastRunTime",
    "value": "@utcnow()"
  }
}
// Variable resets with each pipeline run!

// RIGHT: Use external storage for persistence
{
  "activity": "LookupLastRun",
  "typeProperties": {
    "source": {
      "query": "SELECT MAX(LastRunTime) FROM Watermarks"
    }
  }
}
```

```python
pipeline_variable_pitfall = {
    'mistake': 'Assuming pipeline variables persist between runs',
    'reality': 'Variables are scoped to single pipeline execution',
    'solution': 'Store state in database/table between runs',
    'exam_tip': 'Pipeline variables ≠ persistent storage'
}
```

### Piège 11: ForEach Parallelism Issues

```python
foreach_pitfalls = {
    'sequential_when_parallel_needed': {
        'symptom': 'Pipeline runs very slow',
        'cause': 'ForEach set to isSequential=true unnecessarily',
        'fix': 'Enable parallel execution, set batchCount'
    },
    'parallel_with_dependencies': {
        'symptom': 'Race conditions, data corruption',
        'cause': 'Items depend on each other but run in parallel',
        'fix': 'Use sequential for dependent operations'
    },
    'no_fault_tolerance': {
        'symptom': 'One failure stops everything',
        'cause': 'failureCondition not configured',
        'fix': 'Enable fault tolerance for independent items'
    },
    'exam_tip': 'Match parallel/sequential to data dependencies'
}
```

## Real-Time Analytics Pitfalls

### Piège 12: KQL vs T-SQL Syntax

```kql
// KQL syntax - CORRECT for KQL Database
SensorEvents
| where Temperature > 30
| summarize count() by Device
| order by count_ desc

-- T-SQL syntax - WRONG in KQL Database
SELECT COUNT(*), Device
FROM SensorEvents
WHERE Temperature > 30
GROUP BY Device
ORDER BY COUNT(*) DESC
-- This will FAIL in KQL Database!
```

```python
kql_syntax_pitfall = {
    'mistake': 'Using T-SQL syntax in KQL database queries',
    'reality': 'KQL and T-SQL are different languages',
    'key_differences': {
        'filtering': 'where (KQL) vs WHERE (SQL)',
        'aggregation': 'summarize (KQL) vs GROUP BY (SQL)',
        'ordering': 'order by / sort (KQL) vs ORDER BY (SQL)',
        'pipe_operator': '| used in KQL, not in SQL'
    },
    'exam_tip': 'Know which query language for which database type'
}
```

## Security & Governance Pitfalls

### Piège 13: Workspace Roles Confusion

```python
role_confusion = {
    'common_mistakes': [
        {
            'scenario': 'Giving Viewer role to report developer',
            'problem': 'Cannot create or modify content',
            'correct_role': 'Contributor'
        },
        {
            'scenario': 'Giving Member role for read-only access',
            'problem': 'Can share items and add members',
            'correct_role': 'Viewer'
        },
        {
            'scenario': 'Multiple Admins needed but giving everyone Admin',
            'problem': 'Over-privileged, security risk',
            'correct_approach': '1-2 Admins, others as Members/Contributors'
        }
    ],
    'exam_tip': 'Match role to MINIMUM required permissions'
}
```

### Piège 14: Tenant Settings Impact

```python
tenant_settings_pitfalls = {
    'publish_to_web': {
        'danger': 'Makes reports publicly accessible',
        'recommendation': 'DISABLE in production tenants',
        'exam_relevance': 'Security question favorite'
    },
    'external_sharing': {
        'danger': 'Data can leave organization',
        'recommendation': 'Restrict to specific security groups',
        'exam_relevance': 'Common scenario question'
    },
    'export_data': {
        'danger': 'Users can export sensitive data',
        'recommendation': 'Limit based on data sensitivity',
        'exam_relevance': 'Data protection scenarios'
    },
    'exam_tip': 'Tenant settings affect ALL users - be conservative'
}
```

## Exam Strategy Pitfalls

### Piège 15: Time Management

```python
time_management_mistakes = {
    'spending_too_long_on_one_question': {
        'symptom': 'Run out of time for later questions',
        'rule': 'Max 2-3 minutes per question',
        'strategy': 'Mark difficult questions, return later'
    },
    'not_reading_case_studies_first': {
        'symptom': 'Re-reading scenario for each question',
        'rule': 'Read full case study before questions',
        'strategy': 'Take notes on key requirements'
    },
    'changing_answers_without_reason': {
        'symptom': 'Second-guessing correct answers',
        'rule': 'First instinct often correct',
        'strategy': 'Only change if you find concrete reason'
    },
    'leaving_questions_blank': {
        'symptom': 'Lost points for no reason',
        'rule': 'No penalty for wrong answers',
        'strategy': 'Always guess if unsure'
    }
}
```

### Piège 16: Misreading Requirements

```python
requirement_keywords = {
    'must': 'Absolute requirement, no flexibility',
    'should': 'Recommended but not mandatory',
    'may': 'Optional capability',
    'minimize': 'Cost/effort optimization priority',
    'maximize': 'Performance/availability priority',
    'least': 'Choose simplest solution',
    'most': 'Choose most comprehensive solution',

    'trap_phrases': [
        'with minimum administrative effort',
        'while minimizing cost',
        'in the shortest time possible',
        'with the least amount of configuration'
    ],

    'exam_tip': 'Underline key requirements before answering'
}
```

## Points Clés

- Lakehouse ≠ Warehouse: Know when to use each
- Direct Lake requires optimization (V-Order, OPTIMIZE)
- VACUUM removes Time Travel history permanently
- DAX filter context is crucial for correct measures
- RLS must be tested in Fabric Service, not Desktop
- Pipeline variables don't persist between runs
- KQL syntax ≠ T-SQL syntax
- Tenant settings affect the entire organization
- Read all requirements carefully before answering
- Manage your time: don't get stuck on difficult questions

---

**Navigation** : [Précédent : Key Concepts Review](./05-key-concepts-review.md) | [Index](../README.md) | [Suivant : Exam Day Tips](./07-exam-day-tips.md)
