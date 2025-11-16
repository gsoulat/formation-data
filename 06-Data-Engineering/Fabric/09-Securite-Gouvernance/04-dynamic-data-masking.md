# Dynamic Data Masking

## Introduction

**Dynamic Data Masking (DDM)** masque automatiquement les données sensibles pour les utilisateurs non autorisés, sans modifier les données sous-jacentes.

```
DDM Concept:
┌──────────────────────────────────────────┐
│  Actual Data          │  Masked View     │
│  Email: john@co.com   │  Email: jXXX@XXX │
│  Phone: 555-123-4567  │  Phone: XXX-XXX-4567 │
│  Card: 4532-1234-5678 │  Card: XXXX-XXXX-5678 │
└──────────────────────────────────────────┘

Data unchanged in database, masked at query time
```

## DDM vs CLS

### Comparison

```
Column-Level Security (CLS):
  • Column completely hidden
  • Query fails if trying to access
  • All or nothing access
  • Cannot see any value

Dynamic Data Masking (DDM):
  • Column visible but values masked
  • Query returns masked values
  • Partial visibility
  • See format, not actual value

Use case distinction:
  CLS: "This column doesn't exist for you"
  DDM: "You can see there's data, but not the actual values"
```

### When to Use DDM

```
Use DDM when:
  ✅ Users need to see data exists (not hidden)
  ✅ Format validation needed (email looks like email)
  ✅ Partial information sufficient
  ✅ Call center scenarios (last 4 digits of phone)
  ✅ Development/testing environments

Use CLS when:
  ✅ Column must be completely invisible
  ✅ Even masked values are too sensitive
  ✅ Compliance requires total restriction
  ✅ No business need to see the column exists
```

## Types de Masquage

### Default (Full Mask)

```sql
-- Completely hides the value

CREATE TABLE Customers (
    CustomerID INT,
    SecretCode VARCHAR(50) MASKED WITH (FUNCTION = 'default()')
);

Result:
  Actual: "ABC123XYZ"
  Masked: "XXXX"

  Actual: 12345
  Masked: 0

  Actual: 2024-01-15
  Masked: 1900-01-01

Use case:
  Completely obscure sensitive codes
  Default for any data type
```

### Partial Mask

```sql
-- Show some characters, hide others

Email MASKED WITH (FUNCTION = 'partial(1,"XXX",0)')
-- Shows first 1 char, replaces middle with XXX, shows last 0 chars
-- "john.doe@company.com" → "jXXX"

Phone MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)')
-- Shows first 0 chars, adds XXX-XXX-, shows last 4 chars
-- "555-123-4567" → "XXX-XXX-4567"

CreditCard MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)')
-- "4532-1234-5678-9012" → "XXXX-XXXX-XXXX-9012"

SSN MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)')
-- "123-45-6789" → "XXX-XX-6789"

Syntax:
  partial(prefix_chars, replacement_string, suffix_chars)
  Prefix: Number of starting characters to show
  Replacement: String to insert in middle
  Suffix: Number of ending characters to show
```

### Email Mask

```sql
-- Specialized for email addresses

Email MASKED WITH (FUNCTION = 'email()')

Result:
  "john.doe@company.com" → "jXXX@XXXX.com"
  "alice@startup.io" → "aXXX@XXXX.com"

Behavior:
  First character visible
  Followed by XXX
  @ symbol visible
  Domain masked to XXXX.com

Use case:
  Verify email exists
  See first initial
  Maintain email format appearance
```

### Random Mask

```sql
-- Random number within range

Salary MASKED WITH (FUNCTION = 'random(10000, 100000)')

Result:
  Actual: 75000
  Masked: 45823 (random each query)

Behavior:
  Returns random number in specified range
  Different each time queried
  Original value completely hidden

Use case:
  Numeric fields where range matters
  Hide exact value but show it's numeric
  Testing scenarios
```

## Implementation

### Creating Masked Table

```sql
CREATE TABLE SensitiveCustomers (
    CustomerID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    Phone NVARCHAR(20) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)'),
    SSN NVARCHAR(11) MASKED WITH (FUNCTION = 'default()'),
    CreditCard NVARCHAR(19) MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)'),
    DateOfBirth DATE MASKED WITH (FUNCTION = 'default()'),
    Salary DECIMAL(10,2) MASKED WITH (FUNCTION = 'random(30000, 200000)')
);

-- Insert actual data
INSERT INTO SensitiveCustomers VALUES
(1, 'John', 'Doe', 'john.doe@email.com', '555-123-4567', '123-45-6789', '4532-1234-5678-9012', '1985-03-15', 85000.00);

-- Query as privileged user: See actual data
-- Query as regular user: See masked data
```

### Adding Mask to Existing Column

```sql
-- Modify existing column to add mask
ALTER TABLE Employees
ALTER COLUMN Salary ADD MASKED WITH (FUNCTION = 'random(40000, 150000)');

ALTER TABLE Customers
ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-",7)');

-- Verify mask applied
SELECT
    c.name AS ColumnName,
    c.is_masked,
    c.masking_function
FROM sys.masked_columns mc
JOIN sys.columns c ON mc.object_id = c.object_id AND mc.column_id = c.column_id
WHERE mc.object_id = OBJECT_ID('Customers');
```

### Removing Mask

```sql
-- Drop mask from column
ALTER TABLE Employees
ALTER COLUMN Salary DROP MASKED;

ALTER TABLE Customers
ALTER COLUMN Phone DROP MASKED;

-- Column now shows actual values to everyone
```

## UNMASK Permission

### Granting UNMASK

```sql
-- Allow user to see actual values

-- Specific user
GRANT UNMASK TO [privileged_user@company.com];

-- Specific role
GRANT UNMASK TO HRAdmin;

-- Check who has UNMASK
SELECT
    dp.name AS PrincipalName,
    dp.type_desc
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE p.permission_name = 'UNMASK';
```

### Behavior with UNMASK

```
User WITHOUT UNMASK:
SELECT * FROM SensitiveCustomers;
-- Email: jXXX@XXXX.com
-- Phone: XXX-XXX-4567
-- SSN: XXXX
-- CreditCard: XXXX-XXXX-XXXX-9012

User WITH UNMASK:
SELECT * FROM SensitiveCustomers;
-- Email: john.doe@email.com
-- Phone: 555-123-4567
-- SSN: 123-45-6789
-- CreditCard: 4532-1234-5678-9012

Transparent to queries:
  Same SQL, different results based on permission
  No code changes needed
```

### Revoking UNMASK

```sql
-- Remove UNMASK permission
REVOKE UNMASK FROM [user@company.com];

-- User now sees masked values again
```

## Column-Level UNMASK (Granular)

### Selective Unmasking

```sql
-- SQL Server 2022+ / Fabric SQL
-- Grant UNMASK on specific columns only

GRANT UNMASK ON SensitiveCustomers(Phone) TO CustomerService;

Result:
  CustomerService sees:
    ✅ Phone: 555-123-4567 (unmasked)
    ❌ Email: jXXX@XXXX.com (masked)
    ❌ SSN: XXXX (masked)

Use case:
  Call center needs phone but not SSN
  Partial access to sensitive data
```

### Multiple Column UNMASK

```sql
-- Different permissions per role

GRANT UNMASK ON SensitiveCustomers(Phone, Email) TO SalesTeam;
GRANT UNMASK ON SensitiveCustomers(SSN, DateOfBirth) TO Compliance;
GRANT UNMASK ON SensitiveCustomers TO HRAdmin; -- All columns

Result:
  SalesTeam: See Phone, Email unmasked
  Compliance: See SSN, DOB unmasked
  HRAdmin: See everything unmasked
  Others: See everything masked
```

## Use Cases

### Call Center

```sql
-- Support agents need partial info

CREATE TABLE CustomerSupport (
    TicketID INT,
    CustomerName NVARCHAR(100),
    Phone NVARCHAR(20) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)'),
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    Issue NVARCHAR(MAX),
    CreditCardLast4 NVARCHAR(4) -- Store only last 4, no masking needed
);

Support agent sees:
  Phone: XXX-XXX-4567 (verify customer)
  Email: jXXX@XXXX.com (see domain)
  CreditCardLast4: 9012 (confirm card)

Workflow:
  1. Customer calls
  2. Agent asks for last 4 of phone
  3. Matches masked display
  4. Verifies identity with last 4 of card
  5. Never sees full sensitive data
```

### Development/Testing

```sql
-- Realistic data without exposure

Production:
  Email: john.doe@company.com
  SSN: 123-45-6789

Development (via masking):
  Email: jXXX@XXXX.com
  SSN: XXXX

Benefits:
  ✅ Real data distribution (for testing)
  ✅ No sensitive data exposure
  ✅ Same queries work
  ✅ Realistic test scenarios

Alternative to:
  Synthetic data generation
  Data anonymization ETL
  Test data subsets
```

### Analytics

```sql
-- Aggregate without seeing individual values

Masked query:
SELECT
    Region,
    COUNT(*) AS CustomerCount,
    -- Can't see individual salaries but can count
FROM Customers
GROUP BY Region;

-- Even with masking, aggregation works on real values
-- User sees masked individual rows
-- But aggregates compute on actual data

Important note:
  Masking hides display, not computation
  User can potentially infer values through aggregates
  Not suitable for high-security scenarios
```

## Limitations

### Security Limitations

```
DDM is NOT foolproof security:

1. Inference attacks
   Query: SELECT * WHERE Salary > 50000
   Masked result shows which rows match
   Can narrow down actual values

2. Aggregate functions
   SELECT AVG(Salary), MIN(Salary), MAX(Salary)
   Returns actual aggregated values
   Even to users seeing masked individual rows

3. Export/copy
   User with SELECT permission
   Can export data (still masked)
   But has access to structure

Best for:
  ✅ Casual protection
  ✅ Display masking
  ✅ First line of defense

Not suitable for:
  ❌ Highly sensitive data (use CLS)
  ❌ Compliance requirements (HIPAA, etc.)
  ❌ Preventing determined attackers
```

### Functional Limitations

```
DDM restrictions:
  ❌ Cannot mask computed columns
  ❌ Cannot mask encrypted columns
  ❌ FILESTREAM columns not supported
  ❌ Memory-optimized tables limited support

Query limitations:
  ❌ Full-text search sees masked values
  ❌ CASE expressions might expose values
  ❌ User-defined functions can bypass

Example bypass:
  -- User creates function that reveals masked value
  -- Should restrict CREATE FUNCTION permission
```

### Workaround for Aggregates

```sql
-- If aggregates are concern, combine with permissions

Option 1: Restrict aggregate functions
CREATE PROCEDURE GetRegionalStats
AS
BEGIN
    -- Procedure runs with elevated permissions
    -- Returns only aggregates, no individual rows
    SELECT Region, AVG(Salary) AS AvgSalary
    FROM Employees
    GROUP BY Region;
END
GO

GRANT EXECUTE ON GetRegionalStats TO Analyst;
-- Analyst can run proc, cannot write own aggregate queries

Option 2: Pre-computed aggregates
CREATE VIEW SafeEmployeeStats AS
SELECT
    Department,
    COUNT(*) AS EmpCount,
    -- Deliberately obscured aggregates
    CASE
        WHEN AVG(Salary) < 50000 THEN 'Low'
        WHEN AVG(Salary) < 80000 THEN 'Medium'
        ELSE 'High'
    END AS SalaryBand
FROM Employees
GROUP BY Department;

GRANT SELECT ON SafeEmployeeStats TO Analyst;
```

## Combining DDM with Other Security

### DDM + RLS

```sql
-- Layer masking with row filtering

-- RLS: Sales reps see only their customers
CREATE FUNCTION fn_CustomerFilter(@SalesRep NVARCHAR(50))
RETURNS TABLE AS
RETURN SELECT 1 WHERE @SalesRep = CURRENT_USER;

CREATE SECURITY POLICY CustomerPolicy
ADD FILTER PREDICATE fn_CustomerFilter(AssignedSalesRep) ON Customers;

-- DDM: Mask sensitive columns
ALTER TABLE Customers
ALTER COLUMN CreditCard ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX-",4)');

Result:
  Sales rep sees only their customers (RLS)
  Credit card numbers are masked (DDM)
  Double protection
```

### DDM + CLS

```sql
-- Some columns hidden, others masked

-- CLS: Hide SSN completely
CREATE ROLE BasicUser;
GRANT SELECT ON Customers(ID, Name, Email, Phone) TO BasicUser;
-- No SSN column access

-- DDM: Mask Email and Phone for BasicUser
ALTER TABLE Customers ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
ALTER TABLE Customers ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-",4)');

Result:
  BasicUser sees:
    ✅ ID, Name (unmasked)
    ✅ Email: jXXX@XXXX.com (masked)
    ✅ Phone: XXX-4567 (masked)
    ❌ SSN (completely hidden by CLS)

Defense in depth:
  SSN: Not even visible
  Email/Phone: Visible but masked
  ID/Name: Fully visible
```

## Best Practices

### Design Guidelines

```
1. Choose appropriate mask type
   Email → email() function
   Phone → partial() showing last digits
   SSN → default() or partial last 4
   Numbers → random() or default()

2. Document masked columns
   Why masked
   Who can unmask
   Business justification

3. Test with actual users
   Verify masking applies correctly
   Check no unintended exposure
   Validate user experience

4. Regular review
   Are masks still appropriate?
   Should some columns use CLS instead?
   New columns need masking?

5. Combine with other security
   DDM alone is insufficient
   Use with RLS, CLS, permissions
   Defense in depth approach
```

### Common Mistakes

```
❌ Relying solely on DDM for security
  Users can infer values
  Aggregates expose real data
  Use CLS for truly sensitive data

❌ Forgetting UNMASK inheritance
  UNMASK on database = all tables
  Be specific with permissions

❌ Inconsistent masking
  Same data type, different masks
  Confuses users
  Standardize approach

❌ Not testing queries
  Application queries might fail
  WHERE clauses on masked columns
  Joins might not work as expected

❌ Production vs Dev mismatch
  Dev has UNMASK, prod doesn't
  Code works in dev, fails in prod
  Test with actual permissions
```

### Audit and Monitoring

```sql
-- Track who has UNMASK
SELECT
    'Database Level' AS Scope,
    dp.name AS Principal,
    p.permission_name
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE p.permission_name = 'UNMASK'

UNION

SELECT
    'Column: ' + OBJECT_NAME(p.major_id) + '.' + COL_NAME(p.major_id, p.minor_id),
    dp.name,
    p.permission_name
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE p.permission_name = 'UNMASK' AND p.class = 1;

-- Review quarterly
-- Remove unnecessary UNMASK grants
-- Document justifications
```

## Points Clés

- DDM masks data at query time without changing stored values
- Mask types: default (full), partial, email, random
- UNMASK permission allows seeing actual values
- Granular UNMASK: Column-specific unmasking (SQL 2022+)
- Use cases: Call centers, dev/test, casual protection
- Limitations: Not bulletproof (inference attacks, aggregates)
- Combine with RLS/CLS for layered security
- Best for display masking, not high-security requirements
- Document and audit UNMASK permissions regularly
- Test thoroughly with actual user permissions

---

**Prochain fichier :** [05 - Microsoft Purview Integration](./05-purview-integration.md)

[⬅️ Fichier précédent](./03-column-level-security.md) | [⬅️ Retour au README du module](./README.md)
