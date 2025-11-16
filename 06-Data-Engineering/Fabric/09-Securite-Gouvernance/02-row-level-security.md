# Row-Level Security (RLS)

## Introduction

**Row-Level Security (RLS)** restreint l'accès aux données au niveau des lignes, permettant aux utilisateurs de voir uniquement les données autorisées.

```
RLS Concept:
┌──────────────────────────────────────┐
│  Database: Sales                      │
│  ├─ Total rows: 1,000,000            │
│  └─ User A sees: 250,000 (France)    │
│      User B sees: 350,000 (Germany)  │
│      Admin sees: 1,000,000 (All)     │
└──────────────────────────────────────┘

Single dataset, different views per user
```

## Pourquoi RLS ?

### Use Cases

```
1. Regional data restriction
   Sales reps see only their territory
   France → France data only
   Germany → Germany data only

2. Multi-tenant SaaS
   Customer A sees their data only
   Customer B sees their data only
   Complete data isolation

3. Hierarchical access
   CEO sees entire company
   VP sees their division
   Manager sees their team

4. Confidentiality
   HR sees salary data
   Others see employee info without salary

5. Regulatory compliance
   GDPR: Restrict personal data access
   HIPAA: Patient data isolation
```

### Benefits

```
✅ Single dataset (no duplication)
✅ Centralized security logic
✅ Automatic enforcement (no user action)
✅ Audit-compliant
✅ Scales with data
✅ Works across reports

Without RLS:
  Create separate datasets per region
  Maintain multiple copies
  Risk of data leakage
  Difficult to manage

With RLS:
  Single source of truth
  Security applied at query time
  Consistent across all reports
```

## Creating RLS Roles

### Power BI Desktop

```
Setup process:
1. Open Power BI Desktop
2. Modeling tab → Manage roles
3. Click "Create"
4. Name role: "France Sales"
5. Select table: Sales
6. Write DAX filter: [Country] = "France"
7. Save

Role definition:
┌──────────────────────────────┐
│  Role: France Sales          │
│  Table: Sales                │
│  Filter: [Country] = "France"│
└──────────────────────────────┘

Effect:
  Users in this role see only France rows
  Automatically applied to all queries
```

### DAX Filter Expressions

```dax
// Simple equality
[Country] = "France"

// Multiple values
[Region] IN {"North", "South", "East"}

// Numeric comparison
[Salary] <= 50000

// String pattern
CONTAINSSTRING([Email], "@sales.company.com")

// Date range
[OrderDate] >= DATE(2024, 1, 1)

// Boolean
[IsActive] = TRUE()

// Combined conditions (AND)
[Country] = "France" && [Department] = "Sales"

// Combined conditions (OR)
[Region] = "Europe" || [Region] = "Asia"

// Complex logic
SWITCH(
    TRUE(),
    [Country] = "France", TRUE(),
    [Country] = "Belgium", TRUE(),
    FALSE()
)
```

### Multiple Tables

```dax
// When filtering dimension table, facts automatically filtered via relationship

Role: Europe Region
Table: Dim_Geography
Filter: [Continent] = "Europe"

Automatic propagation:
  Dim_Geography filtered → Fact_Sales filtered
  Only sales in Europe shown
  Relationship does the work

Best practice:
  Apply RLS to dimension tables
  Cleaner logic
  Better performance
  Easier maintenance
```

## Static vs Dynamic RLS

### Static RLS

```dax
// Fixed filter in role definition

Role: France Sales
Filter: [Country] = "France"

Role: Germany Sales
Filter: [Country] = "Germany"

Role: UK Sales
Filter: [Country] = "UK"

Characteristics:
  • One role per security group
  • Filter values hardcoded
  • Easy to understand
  • Potentially many roles needed

Maintenance:
  Add new country → Create new role
  Change logic → Edit each role
```

### Dynamic RLS

```dax
// Filter based on logged-in user

Role: Regional Sales (single role for all)
Filter: [SalesRepEmail] = USERPRINCIPALNAME()

How it works:
  1. User logs in (alice@company.com)
  2. USERPRINCIPALNAME() returns "alice@company.com"
  3. Filter: Show rows where SalesRepEmail = "alice@company.com"
  4. Each user sees their own data automatically

Benefits:
  ✅ Single role for all users
  ✅ Scalable (new users auto-filtered)
  ✅ Self-maintaining
  ✅ Less role management
```

### Dynamic RLS with Mapping Table

```dax
// Security mapping table approach

UserSecurity table:
| UserEmail              | AllowedRegion |
|------------------------|---------------|
| alice@company.com      | France        |
| bob@company.com        | Germany       |
| carol@company.com      | UK            |
| dave@company.com       | France        |

Role: Regional Access
Table: Dim_Geography
Filter:
[Region] IN
CALCULATETABLE(
    VALUES(UserSecurity[AllowedRegion]),
    UserSecurity[UserEmail] = USERPRINCIPALNAME()
)

Result:
  Alice sees France data
  Bob sees Germany data
  Carol sees UK data
  Dave sees France data
  All through single role!

Management:
  Add user access → Add row to UserSecurity table
  No DAX changes needed
  Data-driven security
```

### Multiple Regions per User

```dax
// User can access multiple regions

UserSecurity table:
| UserEmail           | AllowedRegion |
|---------------------|---------------|
| manager@company.com | France        |
| manager@company.com | Germany       |
| manager@company.com | UK            |

Role filter (same as before):
[Region] IN
CALCULATETABLE(
    VALUES(UserSecurity[AllowedRegion]),
    UserSecurity[UserEmail] = USERPRINCIPALNAME()
)

Result:
  Manager sees France + Germany + UK data
  Flexible access patterns
  One user, multiple permissions
```

## Testing RLS

### "View as" in Power BI Desktop

```
Testing process:
1. Modeling tab → View as
2. Select role to test
3. Optionally add "Other user" email
4. Click "OK"
5. See data as that role would

Example:
  Test "France Sales" role
  Report shows only France data
  All visuals filtered automatically

Important:
  Test every role before publishing
  Verify no data leakage
  Check edge cases (null values, new data)
```

### Service-Side Testing

```
After publishing to Fabric:

1. Dataset settings → Security
2. Test as specific user
3. Enter user email
4. See what they would see

Additional checks:
  • Test with actual users
  • Verify group memberships work
  • Check cross-report behavior
  • Validate performance
```

### Common Testing Scenarios

```
Test cases:
1. Basic access
   User in role → Sees filtered data ✓
   User not in role → Sees all data ✗ (needs fixing)

2. No data scenario
   User with no matching rows → Sees blank report ✓

3. Admin override
   Admin should see all → No filter applied ✓

4. Multi-role membership
   User in multiple roles → Union of filters ✓

5. New data
   New country added → Properly filtered ✓

6. NULL values
   Rows with NULL country → Visible or hidden? Check logic

Document results:
  | Scenario | Expected | Actual | Pass/Fail |
```

## RLS in Direct Lake

### Considerations

```
Direct Lake + RLS:

Behavior:
  RLS applied at query time
  Same as Import mode
  No special configuration

Performance:
  Filter pushdown to Parquet files
  V-Order optimization helps
  May fallback to DirectQuery if complex

Limitations:
  Some DAX functions limited
  Complex row-level calculations slower
  Monitor for DirectQuery fallback

Best practice:
  Keep RLS filters simple
  Use column comparisons (not calculations)
  Test performance with realistic data volumes
```

### Supported Patterns

```
✅ Works well in Direct Lake:
  [Country] = "France"
  [Region] IN {"North", "South"}
  [IsActive] = TRUE()
  USERPRINCIPALNAME() comparisons

⚠️ May cause fallback:
  Complex CALCULATE expressions
  Nested table filters
  Dynamic calculations at row level

Monitor:
  DAX Studio to check if Direct Lake maintained
  Performance Analyzer for query times
```

## Advanced Scenarios

### Hierarchical Security

```dax
// Manager sees team's data

OrgHierarchy table:
| EmployeeEmail        | ManagerEmail          |
|---------------------|-----------------------|
| alice@company.com   | manager@company.com   |
| bob@company.com     | manager@company.com   |
| carol@company.com   | manager@company.com   |
| manager@company.com | vp@company.com        |

// Recursive PATH (pre-calculate in data prep)
Employees[HierarchyPath] = "vp > manager > alice"

Role filter:
PATHCONTAINS(
    Employees[HierarchyPath],
    USERPRINCIPALNAME()
)

Result:
  Alice sees her data
  Manager sees Alice + Bob + Carol + self
  VP sees everyone
```

### Time-Based Access

```dax
// Users see only recent data

Role: Recent Data Access
Filter:
[OrderDate] >= TODAY() - 365

Result:
  All users in role see last 365 days only
  Older data automatically hidden
  No historical access

Advanced:
// Based on user access date in security table
[OrderDate] >=
LOOKUPVALUE(
    UserSecurity[AccessStartDate],
    UserSecurity[UserEmail],
    USERPRINCIPALNAME()
)
```

### Emergency Override

```dax
// Admin bypass for troubleshooting

Role: Standard User
Filter:
[Country] IN
CALCULATETABLE(
    VALUES(UserSecurity[AllowedCountry]),
    UserSecurity[UserEmail] = USERPRINCIPALNAME()
)
||
USERPRINCIPALNAME() = "admin@company.com"

Result:
  Standard users → Filtered view
  Admin → Sees all data (bypass)

Use sparingly:
  Only for break-glass scenarios
  Document all overrides
  Audit usage
```

## Limitations

### DAX Limitations in RLS

```
Not allowed in RLS filters:
  ❌ Measures (only table references)
  ❌ CALCULATE with context modification
  ❌ Some row context functions

Example:
  // This won't work
  [Total Sales] > 1000  // Measure not allowed

  // Use this instead
  [SalesAmount] > 1000  // Column reference OK
```

### Performance Considerations

```
RLS impact on performance:
  • Filter applied to every query
  • Complex filters = slower queries
  • Large security tables = more processing

Optimization:
  ✅ Simple column comparisons
  ✅ Index security tables properly
  ✅ Pre-compute hierarchies
  ✅ Use integers over strings where possible

Monitor:
  Query times before/after RLS
  Memory usage
  DirectQuery vs cached responses
```

### Inheritance Limitations

```
RLS doesn't inherit automatically:
  • Report shared → RLS applies
  • Dataset shared → RLS applies
  • Embedded analytics → Requires additional config

Special cases:
  • Composite models → Each source needs RLS
  • Dataflows → No RLS (transform layer)
  • Notebooks → Access via workspace role, not RLS
```

## Best Practices

### Design Principles

```
1. Keep filters simple
   ❌ Complex nested DAX
   ✅ Column = Value comparisons

2. Use dimension tables
   Apply RLS to dimensions, not facts
   Relationships propagate filters

3. Create security table
   Manage access via data, not DAX code
   Easier updates

4. Document everything
   Role purposes
   Filter logic
   User assignments

5. Test extensively
   Every role
   Edge cases
   Performance impact
```

### Common Mistakes

```
❌ Forgetting to publish roles
  RLS defined in Desktop but not deployed
  Users see all data

❌ Complex filter logic
  Hard to maintain
  Performance issues
  Difficult to audit

❌ Not testing with real users
  Works in "View as" but not production
  Group membership issues

❌ Ignoring NULL values
  Rows with NULL country
  Might slip through filters

❌ Too many static roles
  One role per user = maintenance nightmare
  Use dynamic RLS instead
```

### Security Audit Checklist

```
Regular reviews:
[ ] All roles have clear purpose
[ ] Users assigned to correct roles
[ ] Filter logic verified correct
[ ] No unauthorized data access
[ ] Performance acceptable
[ ] New data properly filtered
[ ] Documentation up to date
[ ] Test results documented
```

## Points Clés

- RLS filters data at row level based on user identity
- Static RLS: Fixed filters per role (simple but many roles)
- Dynamic RLS: USERPRINCIPALNAME() for automatic filtering (scalable)
- Security mapping tables enable data-driven permissions
- Test with "View as" in Desktop and Service
- Apply RLS to dimension tables for cleaner logic
- Direct Lake supports RLS with simple filters
- Keep filters simple for performance
- Document roles and test regularly
- Best practice: Dynamic RLS with security mapping table

---

**Prochain fichier :** [03 - Column-Level Security (CLS)](./03-column-level-security.md)

[⬅️ Fichier précédent](./01-workspace-security.md) | [⬅️ Retour au README du module](./README.md)
