# Column-Level Security (CLS)

## Introduction

**Column-Level Security (CLS)** restreint l'accès à des colonnes spécifiques, masquant les données sensibles aux utilisateurs non autorisés.

```
CLS Concept:
┌────────────────────────────────────────────┐
│  Table: Employees                          │
│  ├─ EmployeeID (visible to all)           │
│  ├─ Name (visible to all)                 │
│  ├─ Department (visible to all)           │
│  ├─ Salary ❌ (HR only)                   │
│  ├─ SSN ❌ (HR only)                      │
│  └─ PerformanceRating ❌ (Managers only)  │
└────────────────────────────────────────────┘

Same table, different columns visible per user
```

## CLS vs RLS

### Comparison

```
Row-Level Security (RLS):
  Filter: Which ROWS user can see
  Example: France sales rep sees France rows only
  All columns visible, but limited rows

Column-Level Security (CLS):
  Filter: Which COLUMNS user can see
  Example: HR sees Salary, others don't
  All rows visible, but limited columns

Combined RLS + CLS:
  User sees subset of rows AND columns
  Most restrictive security model
  Example: France HR sees France employees with Salary
```

### When to Use CLS

```
Use CLS for:
  ✅ Sensitive columns (Salary, SSN, Credit Card)
  ✅ PII data (Personal Identifiable Information)
  ✅ Confidential business data (Cost, Margin)
  ✅ Regulated data (HIPAA, GDPR)

Don't use CLS for:
  ❌ Row-level filtering (use RLS)
  ❌ Aggregated summaries (use measures with RLS)
  ❌ Temporary hiding (use report design)
```

## Implementing CLS in Fabric

### SQL Database (T-SQL)

```sql
-- Create table with sensitive columns
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100),
    Department NVARCHAR(50),
    Salary DECIMAL(10,2),      -- Sensitive
    SSN NVARCHAR(11),          -- Sensitive
    PerformanceRating INT      -- Sensitive
);

-- Create role
CREATE ROLE HRDataViewer;

-- Revoke all SELECT on table
REVOKE SELECT ON Employees FROM HRDataViewer;

-- Grant SELECT on non-sensitive columns only
GRANT SELECT ON Employees(EmployeeID, Name, Department) TO HRDataViewer;

-- Users in HRDataViewer cannot see Salary, SSN, PerformanceRating
```

### Adding Full Access Role

```sql
-- Role with access to all columns
CREATE ROLE HRAdmin;

-- Grant all columns
GRANT SELECT ON Employees TO HRAdmin;

-- Now:
-- HRDataViewer: EmployeeID, Name, Department
-- HRAdmin: All columns including Salary, SSN
```

### Adding Users to Roles

```sql
-- Add user to role
ALTER ROLE HRDataViewer ADD MEMBER [analyst@company.com];
ALTER ROLE HRAdmin ADD MEMBER [hr_manager@company.com];

-- Remove user from role
ALTER ROLE HRDataViewer DROP MEMBER [analyst@company.com];

-- Check role membership
SELECT
    dp.name AS RoleName,
    mp.name AS MemberName
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
JOIN sys.database_principals mp ON drm.member_principal_id = mp.principal_id;
```

## Object-Level Security (OLS)

### What is OLS?

```
OLS = CLS at the object level in semantic models

Hide entire tables/columns from:
  • Model view in Power BI
  • Report field list
  • Data exploration tools

Similar to CLS but enforced in semantic model layer
```

### Implementing OLS

```
Power BI Desktop / Tabular Editor:

1. Table-level OLS
   Table: SensitiveData
   Property: Visible = False for specific roles

2. Column-level OLS
   Column: Employees.Salary
   Property: Visible = False for role "Standard Users"

Result:
  Standard Users → Don't see Salary in field list
  HR Users → See Salary in field list

XMLA endpoint:
{
  "name": "Salary",
  "column": {
    "objectPermissions": [
      {
        "role": "StandardUsers",
        "permission": "None"
      }
    ]
  }
}
```

### OLS vs CLS

```
OLS (Object-Level Security):
  Location: Semantic model layer
  Enforcement: Hides from UI, prevents queries
  Scope: Tables, columns, measures
  Tool: Power BI/Tabular Editor

CLS (Column-Level Security):
  Location: Database layer (SQL)
  Enforcement: SQL permission system
  Scope: Columns only
  Tool: T-SQL commands

Which to use:
  OLS: Power BI semantic models, self-service BI
  CLS: SQL databases, direct queries
  Both: Defense in depth (layered security)
```

## Combining CLS with RLS

### Layered Security

```sql
-- Table: EmployeeSales
-- Columns: EmployeeID, Name, Region, Sales, Salary, CommissionRate

-- CLS: Restrict Salary column
CREATE ROLE SalesAnalyst;
GRANT SELECT ON EmployeeSales(EmployeeID, Name, Region, Sales) TO SalesAnalyst;
-- No access to Salary, CommissionRate

-- RLS: Restrict rows by region
CREATE FUNCTION fn_SalesRegionFilter (@Region NVARCHAR(50))
RETURNS TABLE
AS
RETURN
    SELECT 1 WHERE @Region = CURRENT_USER; -- Simplified

CREATE SECURITY POLICY SalesRegionPolicy
ADD FILTER PREDICATE dbo.fn_SalesRegionFilter(Region)
ON dbo.EmployeeSales;

-- Result:
-- SalesAnalyst sees:
--   ✅ Rows for their region only (RLS)
--   ✅ Columns: EmployeeID, Name, Region, Sales (CLS)
--   ❌ No Salary, CommissionRate columns
--   ❌ No other regions' rows
```

### Power BI Implementation

```dax
// RLS Role: RegionalSales
// Table: Sales
// Filter: [Region] = USERPRINCIPALNAME()

// OLS: Hide Salary measure from non-HR users
// Tabular Editor:
// Measure: [Total Salary]
// Set: Visible = false for role "RegionalSales"

// Combined effect:
// Regional manager sees:
//   ✅ Their region's sales data (RLS)
//   ❌ Salary column hidden (OLS)
//   ✅ All other metrics visible
```

## Use Cases

### PII Protection

```sql
-- Protect Personal Identifiable Information

Table: Customers
Columns:
  CustomerID (public)
  Name (PII)
  Email (PII)
  Phone (PII)
  Address (PII)
  Country (public)
  TotalPurchases (public)

CREATE ROLE CustomerAnalyst;
-- Can see aggregate patterns, not PII
GRANT SELECT ON Customers(CustomerID, Country, TotalPurchases) TO CustomerAnalyst;

CREATE ROLE CustomerService;
-- Needs PII for support
GRANT SELECT ON Customers TO CustomerService;

Result:
  Analyst: Analyze trends without seeing personal data
  Support: Full access for customer service
  GDPR compliance maintained
```

### Financial Data

```sql
-- Protect cost/margin data

Table: Products
Columns:
  ProductID
  ProductName
  Category
  Price (public)
  Cost (confidential)
  Margin (confidential)

CREATE ROLE SalesTeam;
GRANT SELECT ON Products(ProductID, ProductName, Category, Price) TO SalesTeam;
-- Sales sees products and prices

CREATE ROLE FinanceTeam;
GRANT SELECT ON Products TO FinanceTeam;
-- Finance sees cost and margins

Business reason:
  Sales shouldn't negotiate based on internal margins
  Finance needs full picture for pricing strategy
```

### HR Data

```sql
-- Multi-level HR access

Table: EmployeeRecords
Columns:
  EmployeeID, Name, Department (all users)
  Email, Phone (managers)
  Salary, Benefits (HR only)
  SSN, TaxInfo (HR-Payroll only)

CREATE ROLE AllEmployees;
GRANT SELECT ON EmployeeRecords(EmployeeID, Name, Department) TO AllEmployees;

CREATE ROLE Managers;
GRANT SELECT ON EmployeeRecords(EmployeeID, Name, Department, Email, Phone) TO Managers;

CREATE ROLE HR;
GRANT SELECT ON EmployeeRecords(EmployeeID, Name, Department, Email, Phone, Salary, Benefits) TO HR;

CREATE ROLE HRPayroll;
GRANT SELECT ON EmployeeRecords TO HRPayroll;

Hierarchy:
  AllEmployees ⊂ Managers ⊂ HR ⊂ HRPayroll
  Progressive access based on need
```

## Performance Impact

### Query Execution

```
How CLS affects queries:

Query: SELECT * FROM Employees
User Role: HRDataViewer (no Salary access)

Execution:
1. User submits query
2. Database checks permissions
3. Rewrites query to exclude restricted columns
4. Returns: EmployeeID, Name, Department only

Performance impact:
  • Permission check adds minimal overhead
  • Fewer columns = potentially faster (less data)
  • No significant performance penalty
```

### Index Considerations

```
CLS and indexes:

Scenario:
  Index on Salary column
  User cannot access Salary

Effect:
  Index still exists (metadata level)
  User queries don't use Salary index
  No security breach through index

Best practice:
  Don't rely on column invisibility for security
  Users might infer data from query plans
  Always use proper permission enforcement
```

## Testing CLS

### Verification Steps

```sql
-- Test column visibility

-- As admin, verify setup
EXECUTE AS USER = 'analyst@company.com';
SELECT * FROM Employees;
-- Should see only permitted columns
REVERT;

-- Check effective permissions
SELECT
    OBJECT_NAME(major_id) AS TableName,
    COL_NAME(major_id, minor_id) AS ColumnName,
    permission_name,
    state_desc
FROM sys.database_permissions
WHERE class = 1 -- Column
AND grantee_principal_id = DATABASE_PRINCIPAL_ID('HRDataViewer');
```

### Error Handling

```sql
-- What users see when blocked

User query:
SELECT EmployeeID, Name, Salary FROM Employees;

If user lacks Salary permission:
Error: The SELECT permission was denied on the column 'Salary'

Better UX:
SELECT
    EmployeeID,
    Name,
    CASE
        WHEN HAS_PERMS_BY_NAME('Employees', 'OBJECT', 'SELECT') = 1
        THEN Salary
        ELSE NULL
    END AS Salary
FROM Employees;

// Handle gracefully in application layer
```

## Limitations

### Known Limitations

```
CLS limitations:
  ❌ Cannot filter on hidden column (query fails)
  ❌ Aggregates on hidden columns fail
  ❌ Schema information still visible (column exists)
  ❌ Computed columns may expose restricted data

Example:
  User cannot see Salary
  Query: SELECT * FROM Employees WHERE Salary > 50000
  Result: Error (cannot filter on inaccessible column)

  Query: SELECT SUM(Salary) FROM Employees
  Result: Error (cannot aggregate inaccessible column)
```

### Workarounds

```sql
-- Pre-aggregate in views

CREATE VIEW EmployeeSummary AS
SELECT
    Department,
    COUNT(*) AS EmployeeCount,
    AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department;

-- Grant view access (shows aggregate, not individual)
GRANT SELECT ON EmployeeSummary TO SalesAnalyst;

-- Or create calculated columns
ALTER TABLE Employees ADD
    SalaryBand AS (
        CASE
            WHEN Salary < 50000 THEN 'Low'
            WHEN Salary < 100000 THEN 'Medium'
            ELSE 'High'
        END
    );

-- Grant SalaryBand but not Salary
-- Users see bands, not exact values
```

## Best Practices

### Design Guidelines

```
1. Identify sensitive data upfront
   • PII: Names, SSN, addresses
   • Financial: Salary, cost, margins
   • Health: Medical records (HIPAA)
   • Legal: Contracts, negotiations

2. Principle of least privilege
   Grant minimum required columns
   Default deny, explicit allow

3. Use roles, not individual users
   CREATE ROLE for groups of users
   Easier management
   Consistent application

4. Document everything
   Which columns are restricted
   Which roles have access
   Business justification

5. Regular audits
   Review role memberships
   Verify restrictions still appropriate
   Remove unnecessary access
```

### Common Mistakes

```
❌ Forgetting computed columns
  Computed column uses restricted data
  User can infer restricted values

❌ Views exposing restricted columns
  View created by admin includes Salary
  User with view access sees Salary indirectly

❌ Inconsistent restrictions
  Table A restricts SSN
  Table B doesn't (same SSN, different table)
  Data exposed through Table B

❌ Not testing edge cases
  JOINs with restricted columns
  Aggregations
  Subqueries
```

### Security Audit

```
Regular checks:
[ ] All sensitive columns identified
[ ] Proper roles created
[ ] Correct permissions granted
[ ] No unintended exposure through views
[ ] Computed columns reviewed
[ ] Documentation updated
[ ] Compliance verified (GDPR, HIPAA)
[ ] Access logs reviewed
```

## Points Clés

- CLS restricts access to specific columns (not rows)
- Complement to RLS (rows + columns = complete security)
- T-SQL: GRANT SELECT on specific columns only
- OLS: Object-Level Security in semantic models
- Use for PII, financial, HR sensitive data
- Minimal performance impact
- Test thoroughly (hidden columns cause query errors)
- Limitations: Cannot filter/aggregate on hidden columns
- Best practices: Roles, least privilege, documentation
- Regular audits ensure continued compliance

---

**Prochain fichier :** [04 - Dynamic Data Masking](./04-dynamic-data-masking.md)

[⬅️ Fichier précédent](./02-row-level-security.md) | [⬅️ Retour au README du module](./README.md)
