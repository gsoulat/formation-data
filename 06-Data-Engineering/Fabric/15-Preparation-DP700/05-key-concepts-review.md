# Key Concepts Review for DP-700

## Introduction

Cette section consolide les concepts clés que vous devez maîtriser pour l'examen DP-700. Utilisez-la comme référence rapide et pour vos révisions finales avant l'examen.

## OneLake & Data Foundation

### OneLake Architecture

```python
onelake_concepts = {
    'definition': 'Single unified data lake for entire organization',
    'key_features': [
        'Single copy of data (no duplication)',
        'Automatic Delta Lake format',
        'Cross-workspace data sharing',
        'Unified security model',
        'ADLS Gen2 compatible APIs'
    ],
    'hierarchy': {
        'Tenant': 'Top level (organization)',
        'Workspace': 'Logical container for items',
        'Item': 'Lakehouse, Warehouse, etc.',
        'Folder': 'Files or Tables within items'
    },
    'shortcuts': {
        'purpose': 'Reference external data without copying',
        'sources': ['ADLS Gen2', 'S3', 'GCS', 'Other OneLake locations'],
        'use_cases': [
            'Multi-cloud integration',
            'Cross-workspace sharing',
            'Data virtualization'
        ]
    }
}
```

### Delta Lake Essentials

```python
delta_lake_features = {
    'ACID_transactions': {
        'Atomicity': 'All or nothing operations',
        'Consistency': 'Data always valid state',
        'Isolation': 'Concurrent operations isolated',
        'Durability': 'Changes persisted permanently'
    },
    'time_travel': {
        'syntax': 'VERSION AS OF or TIMESTAMP AS OF',
        'use_cases': [
            'Audit and compliance',
            'Rollback mistakes',
            'Reproduce historical analysis',
            'Debug data issues'
        ],
        'default_retention': '30 days (configurable)'
    },
    'schema_evolution': {
        'types': ['Add columns', 'Rename columns', 'Change types'],
        'merge_schema': 'option("mergeSchema", "true")',
        'overwrite_schema': 'option("overwriteSchema", "true")'
    },
    'optimization': {
        'OPTIMIZE': 'Compacts small files',
        'VACUUM': 'Removes old versions',
        'Z-ORDER': 'Co-locates related data',
        'V-ORDER': 'Fabric-specific for BI queries'
    }
}
```

## Medallion Architecture

```python
medallion_layers = {
    'bronze': {
        'other_names': ['Raw', 'Landing'],
        'characteristics': [
            'Data as-is from source',
            'Schema on read',
            'Minimal transformations',
            'Append-only ingestion',
            'Full historical audit trail'
        ],
        'typical_operations': [
            'COPY INTO',
            'Streaming ingestion',
            'File-based loading'
        ]
    },
    'silver': {
        'other_names': ['Cleansed', 'Validated', 'Curated'],
        'characteristics': [
            'Cleaned and validated data',
            'Enforced schema',
            'Standardized formats',
            'Deduplicated',
            'Business rules applied'
        ],
        'typical_operations': [
            'Type casting',
            'Null handling',
            'Deduplication',
            'Joins with reference data',
            'Data quality checks'
        ]
    },
    'gold': {
        'other_names': ['Business', 'Consumption', 'Serving'],
        'characteristics': [
            'Business-ready aggregations',
            'Dimensional models',
            'KPI calculations',
            'Optimized for queries',
            'Specific use case focused'
        ],
        'typical_operations': [
            'Aggregations (SUM, COUNT, AVG)',
            'Business logic',
            'Star schema modeling',
            'Performance optimization'
        ]
    }
}
```

## Data Warehouse Concepts

### Dimensional Modeling

```python
dimensional_modeling = {
    'star_schema': {
        'components': {
            'fact_tables': [
                'Contains measures (numeric values)',
                'Foreign keys to dimensions',
                'Usually largest tables',
                'Examples: FactSales, FactInventory'
            ],
            'dimension_tables': [
                'Descriptive attributes',
                'Surrogate keys (identity)',
                'Business keys (natural)',
                'Examples: DimCustomer, DimProduct, DimDate'
            ]
        },
        'advantages': [
            'Simple to understand',
            'Optimized for queries',
            'Supports drill-down analysis',
            'Efficient joins (one level)'
        ]
    },
    'slowly_changing_dimensions': {
        'type_1': {
            'description': 'Overwrite old value',
            'use_case': 'Corrections, non-historical',
            'implementation': 'UPDATE statement'
        },
        'type_2': {
            'description': 'Add new row, track history',
            'use_case': 'Historical tracking required',
            'key_columns': ['is_current', 'effective_date', 'end_date'],
            'implementation': 'MERGE with version management'
        },
        'type_3': {
            'description': 'Add column for previous value',
            'use_case': 'Limited history (current + previous)',
            'implementation': 'Additional columns'
        }
    }
}
```

### Fabric Warehouse Specifics

```sql
-- Key differences from traditional SQL Server

-- 1. Distribution is automatic (no HASH/ROUND_ROBIN)
CREATE TABLE FactSales (
    SalesKey BIGINT,
    Amount DECIMAL(18,2)
    -- No WITH (DISTRIBUTION = ...) needed
);

-- 2. Clustered columnstore is default
-- No need to explicitly create CCI

-- 3. Cross-database queries supported
SELECT * FROM Database1.schema.table1 t1
JOIN Database2.schema.table2 t2 ON t1.id = t2.id;

-- 4. T-SQL compatibility (with some limitations)
-- Supported: Views, Stored Procedures, Functions
-- Limited: Triggers, some system functions
```

## Semantic Models & DAX

### Direct Lake Mode

```python
direct_lake = {
    'definition': 'Query data directly from OneLake without import',
    'prerequisites': [
        'Data in Delta Lake format',
        'V-Order optimization enabled',
        'Fabric capacity (F SKU)',
        'Tables in Lakehouse'
    ],
    'benefits': [
        'No scheduled refresh needed',
        'Always up-to-date data',
        'No data duplication',
        'Near Import-mode performance',
        'Supports large datasets (TB scale)'
    ],
    'fallback_behavior': {
        'when': 'Complex queries or unsupported features',
        'to': 'DirectQuery mode',
        'impact': 'Potential performance decrease'
    },
    'vs_import': {
        'Direct Lake': 'Reads from OneLake, no copy',
        'Import': 'Copies data into model, scheduled refresh'
    },
    'vs_directquery': {
        'Direct Lake': 'Optimized for Delta Lake',
        'DirectQuery': 'Live queries to any source'
    }
}
```

### Essential DAX Patterns

```dax
// Time Intelligence Functions
YTD = TOTALYTD([Measure], 'Date'[Date])
QTD = TOTALQTD([Measure], 'Date'[Date])
MTD = TOTALMTD([Measure], 'Date'[Date])

Previous Year = CALCULATE([Measure], SAMEPERIODLASTYEAR('Date'[Date]))
Previous Month = CALCULATE([Measure], DATEADD('Date'[Date], -1, MONTH))

// Growth Calculations
YoY Growth =
VAR Current = [Measure]
VAR Previous = CALCULATE([Measure], SAMEPERIODLASTYEAR('Date'[Date]))
RETURN DIVIDE(Current - Previous, Previous)

// Running Totals
Running Total =
CALCULATE(
    [Measure],
    FILTER(
        ALLSELECTED('Date'[Date]),
        'Date'[Date] <= MAX('Date'[Date])
    )
)

// CALCULATE with Filters
Filtered Measure =
CALCULATE(
    [Base Measure],
    FILTER(ALL(Table), Table[Column] = "Value")
)

// Safe Division
Safe Divide = DIVIDE([Numerator], [Denominator], 0)

// Iterators
Weighted Avg =
SUMX(
    Table,
    Table[Value] * Table[Weight]
) / SUM(Table[Weight])
```

### Row-Level Security (RLS)

```dax
// Static RLS
[Region] = "North"

// Dynamic RLS
[Email] = USERPRINCIPALNAME()

// With Lookup Table
LOOKUPVALUE(
    Users[Region],
    Users[Email], USERPRINCIPALNAME()
) = [Region]

// Multiple Conditions
[Region] IN CALCULATETABLE(
    VALUES(UserRegions[Region]),
    UserRegions[Email] = USERPRINCIPALNAME()
)
```

## Real-Time Analytics

### KQL Quick Reference

```kql
// Basic Queries
TableName
| where Timestamp > ago(1h)
| where Column == "value"
| project Column1, Column2, Column3
| order by Column1 desc
| take 100

// Aggregations
TableName
| summarize
    Count = count(),
    Sum = sum(NumericColumn),
    Avg = avg(NumericColumn),
    Max = max(NumericColumn)
    by GroupColumn

// Time Bucketing
TableName
| summarize count() by bin(Timestamp, 5m)

// String Operations
TableName
| where Column contains "substring"
| where Column startswith "prefix"
| where Column matches regex "pattern"

// Joins
Table1
| join kind=inner Table2 on $left.Key == $right.Key

// Rendering
TableName
| summarize count() by Category
| render piechart
```

## Data Factory & Pipelines

### Key Activities

```python
pipeline_activities = {
    'Copy': {
        'purpose': 'Move data between sources',
        'key_settings': [
            'Source dataset',
            'Sink dataset',
            'Mapping',
            'Fault tolerance'
        ]
    },
    'Dataflow': {
        'purpose': 'Visual data transformation',
        'tool': 'Power Query',
        'use_case': 'Complex transformations'
    },
    'Notebook': {
        'purpose': 'Run Spark code',
        'parameters': 'Can pass from pipeline',
        'use_case': 'Advanced processing'
    },
    'ForEach': {
        'purpose': 'Iterate over collection',
        'settings': ['Sequential', 'Parallel', 'Batch size'],
        'use_case': 'Process multiple files'
    },
    'If Condition': {
        'purpose': 'Branching logic',
        'expression': '@equals(activity.status, "Succeeded")',
        'use_case': 'Conditional execution'
    },
    'Set Variable': {
        'purpose': 'Store values for later use',
        'scope': 'Pipeline level',
        'use_case': 'Dynamic parameters'
    }
}
```

### Triggers

```python
trigger_types = {
    'Schedule': {
        'description': 'Run at specific times',
        'example': 'Every day at 6 AM'
    },
    'Tumbling Window': {
        'description': 'Non-overlapping time windows',
        'example': 'Process hourly batches',
        'features': ['Retry', 'Dependencies', 'Backfill']
    },
    'Event': {
        'description': 'Triggered by events',
        'example': 'File arrives in storage'
    },
    'Manual': {
        'description': 'On-demand execution',
        'example': 'Debug or ad-hoc runs'
    }
}
```

## Security Model

```python
fabric_security = {
    'workspace_roles': {
        'Admin': 'Full control, manage members',
        'Member': 'Create content, share items',
        'Contributor': 'Create/edit content, no share',
        'Viewer': 'View content only'
    },
    'item_permissions': {
        'Build': 'Create new content using item',
        'Read': 'View item',
        'Write': 'Modify item',
        'Reshare': 'Share with others'
    },
    'data_security': {
        'RLS': 'Filter rows based on user',
        'OLS': 'Hide columns/objects',
        'CLS': 'Column-level security'
    },
    'tenant_settings': {
        'controlled_by': 'Fabric Admin',
        'examples': [
            'External sharing',
            'Export capabilities',
            'API access',
            'Git integration'
        ]
    }
}
```

## Performance Optimization

```python
optimization_techniques = {
    'lakehouse': [
        'Partition tables by date',
        'Apply Z-ORDER on filter columns',
        'Enable V-ORDER for BI',
        'Regular OPTIMIZE operations',
        'VACUUM old versions',
        'Use appropriate file sizes (128MB-1GB)'
    ],
    'warehouse': [
        'Design proper star schema',
        'Use surrogate keys (INT)',
        'Implement proper indexing',
        'Write efficient SQL (avoid SELECT *)',
        'Use CTEs for complex queries',
        'Monitor query statistics'
    ],
    'semantic_model': [
        'Use Direct Lake when possible',
        'Minimize calculated columns',
        'Optimize DAX measures',
        'Reduce model complexity',
        'Remove unused columns',
        'Test with Performance Analyzer'
    ],
    'pipelines': [
        'Parallel processing where possible',
        'Incremental loading patterns',
        'Proper error handling',
        'Efficient data movement',
        'Right-size compute resources'
    ]
}
```

## Points Clés à Mémoriser

1. **OneLake** = Single storage layer for all Fabric
2. **Delta Lake** = ACID + Time Travel + Schema Evolution
3. **Medallion** = Bronze (raw) > Silver (clean) > Gold (business)
4. **Direct Lake** = Best of Import (performance) + DirectQuery (freshness)
5. **SCD Type 2** = Historical tracking with is_current flag
6. **CALCULATE** = Most important DAX function for filter context
7. **V-ORDER** = Fabric-specific optimization for columnar reads
8. **Shortcuts** = Virtual references to external data
9. **Git Integration** = Version control for metadata only
10. **RLS** = Row-Level Security for data access control

---

**Navigation** : [Précédent : Hands-on Labs](./04-hands-on-labs.md) | [Index](../README.md) | [Suivant : Common Pitfalls](./06-common-pitfalls.md)
