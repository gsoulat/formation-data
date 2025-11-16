# Projet 5 : Gouvernance et Sécurité

## Objectif
Implémenter une architecture sécurisée complète pour un environnement multi-tenant avec RLS, audit trail, et conformité GDPR.

## Architecture
```
Tenant Configuration → Workspace Security → RLS/CLS Implementation → Audit Logging
                                                    ↓
                            Purview Integration ← Sensitivity Labels ← Data Masking
                                    ↓
                              Compliance Dashboard
```

## Compétences
- Row-Level Security (RLS) dynamique
- Column-Level Security (CLS)
- Dynamic Data Masking
- Microsoft Purview integration
- Audit logging et compliance
- Sensitivity labels (MIP)

## 📦 Données Fournies

**IMPORTANT : Les données pour ce projet sont disponibles dans `../../Ressources/datasets/`**

| Fichier | Description | Usage dans ce projet |
|---------|-------------|---------------------|
| **`customers.csv`** (1.6 MB, 10K clients) | Clients avec données personnelles (email, adresse) | → Tester RLS par région, masquage email |
| **`retail_sales.csv`** (15 MB, 100K ventes) | Transactions par région/département | → RLS par équipe de vente |

### Scénarios de Sécurité avec ces Données

**1. Row-Level Security (RLS)** :
```sql
-- Filtrer les ventes par région pour chaque utilisateur
CREATE FUNCTION fn_region_filter(@Region VARCHAR(50))
RETURNS TABLE
AS RETURN
  SELECT 1 AS result WHERE @Region = USER_NAME()
  OR USER_NAME() = 'admin@company.com';
```

**2. Dynamic Data Masking** :
```sql
-- Masquer les emails clients
ALTER TABLE Customers
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

-- Masquer les montants pour non-managers
ALTER TABLE Sales
ALTER COLUMN Amount ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX",0)');
```

**3. GDPR Compliance** :
- `customers.csv` contient des données personnelles pour tester :
  - Suppression d'un client (DSAR request)
  - Anonymisation des données
  - Export des données client

### Chargement

```python
df_customers = spark.read.csv("Files/raw/customers.csv", header=True)
df_sales = spark.read.csv("Files/raw/retail_sales.csv", header=True)

# Ajouter colonne tenant pour multi-tenant
df_customers = df_customers.withColumn("TenantID", F.lit("CORP_001"))
df_sales = df_sales.withColumn("TenantID", F.lit("CORP_001"))
```

## Instructions

### Phase 1: Architecture Multi-Tenant (2h)
1. Créer workspace structure:
```
Corporate_Fabric/
├── Shared_Data_Lake/      (données centralisées)
├── Sales_Analytics/       (équipe ventes)
├── Finance_Reporting/     (équipe finance)
├── HR_Insights/           (équipe RH - données sensibles)
└── Admin_Governance/      (monitoring et audit)
```

2. Configurer workspace roles:
```
Sales_Analytics:
  - Admin: data_platform_team@company.com
  - Members: sales_managers@company.com
  - Contributors: sales_analysts@company.com
  - Viewers: sales_reps@company.com
```

3. Créer service principals pour automatisation:
```powershell
# Azure AD App Registration
$sp = New-AzADServicePrincipal -DisplayName "Fabric-ETL-Service"

# Grant Fabric permissions
Add-FabricWorkspaceMember -WorkspaceId $wsId -PrincipalId $sp.Id -Role "Contributor"
```

### Phase 2: Row-Level Security (3h)
1. Créer table de mapping sécurité:
```sql
CREATE TABLE Security.UserRegionMapping (
    UserEmail NVARCHAR(255),
    AllowedRegion NVARCHAR(50),
    AccessLevel NVARCHAR(20),  -- 'Full', 'Restricted', 'ReadOnly'
    EffectiveDate DATE,
    ExpirationDate DATE
);

INSERT INTO Security.UserRegionMapping VALUES
('alice@company.com', 'North America', 'Full', '2024-01-01', '2025-12-31'),
('bob@company.com', 'Europe', 'Full', '2024-01-01', '2025-12-31'),
('carol@company.com', 'North America', 'ReadOnly', '2024-01-01', '2025-12-31'),
('manager@company.com', 'ALL', 'Full', '2024-01-01', '2025-12-31');
```

2. Implémenter RLS dynamique dans semantic model:
```dax
// Role: RegionalAccess
VAR CurrentUser = USERPRINCIPALNAME()
VAR UserRegions =
    CALCULATETABLE(
        VALUES(UserRegionMapping[AllowedRegion]),
        UserRegionMapping[UserEmail] = CurrentUser,
        UserRegionMapping[EffectiveDate] <= TODAY(),
        UserRegionMapping[ExpirationDate] >= TODAY()
    )
VAR HasAllAccess = "ALL" IN UserRegions

RETURN
    HasAllAccess ||
    [Region] IN UserRegions
```

3. Tester RLS avec différents utilisateurs:
```dax
-- Test as specific user
EVALUATE
    CALCULATETABLE(
        Sales,
        USERPRINCIPALNAME() = "alice@company.com"
    )
```

4. Créer multiple security roles:
   - **Regional_Sales**: Accès par région
   - **Product_Line_Manager**: Accès par ligne de produit
   - **Executive**: Accès complet (données agrégées uniquement)

### Phase 3: Column-Level Security & Masking (2h)
1. Implémenter CLS sur données sensibles:
```sql
-- Table avec données sensibles
CREATE TABLE HR.EmployeeData (
    EmployeeID INT,
    Name NVARCHAR(100),
    Email NVARCHAR(255),
    Salary DECIMAL(12,2),       -- SENSITIVE
    SSN NVARCHAR(20),           -- HIGHLY SENSITIVE
    Department NVARCHAR(50),
    PerformanceScore INT        -- RESTRICTED
);

-- Grant column permissions
GRANT SELECT ON HR.EmployeeData(EmployeeID, Name, Email, Department) TO HR_Viewers;
GRANT SELECT ON HR.EmployeeData TO HR_Managers;
```

2. Configurer Dynamic Data Masking:
```sql
-- Mask sensitive columns
ALTER TABLE HR.EmployeeData
ALTER COLUMN SSN ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XX-",4)');

ALTER TABLE HR.EmployeeData
ALTER COLUMN Salary ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE HR.EmployeeData
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

-- Grant UNMASK to specific roles
GRANT UNMASK TO HR_Managers;
```

3. Tester le masking:
```sql
-- As HR_Viewer (masked)
SELECT Name, Email, SSN, Salary FROM HR.EmployeeData;
-- Result: John Doe, jXXX@XXXX.com, XXX-XX-1234, 0

-- As HR_Manager (unmasked)
EXECUTE AS USER = 'hr_manager@company.com';
SELECT Name, Email, SSN, Salary FROM HR.EmployeeData;
-- Result: John Doe, john@company.com, 123-45-1234, 75000.00
```

### Phase 4: Purview Integration (2h)
1. Configurer scanning Fabric workspace:
```
Microsoft Purview Studio:
  1. Data Map → Register source → Microsoft Fabric
  2. Configure managed identity
  3. Set up scan schedule (weekly)
  4. Define classification rules
```

2. Créer business glossary:
```
Terms:
  - Customer Lifetime Value (CLV)
    Definition: Predicted net profit from entire relationship
    Steward: analytics_team@company.com
    Related: Revenue, Churn Rate

  - Personally Identifiable Information (PII)
    Definition: Data that can identify an individual
    Steward: compliance@company.com
    Classification: Sensitive
    Handling: Must be masked/encrypted
```

3. Appliquer sensitivity labels:
```
Label Hierarchy:
  Public
  └── Internal
      └── Confidential
          └── Highly Confidential
              └── Restricted - PII
              └── Restricted - Financial

Fabric Assets:
  Sales_Data → Confidential
  HR_Employee_Info → Highly Confidential (PII)
  Public_Reports → Internal
  Customer_SSN → Restricted - PII
```

4. Configurer label inheritance:
```python
# When loading data, inherit labels
df = spark.table("sensitive_customer_data")
# Label automatically applied: Confidential

# Export restrictions enforced
# Cannot export to non-labeled destinations
```

### Phase 5: Audit et Compliance (2h)
1. Activer comprehensive audit logging:
```python
# Query audit logs via API
import requests

def get_fabric_audit_logs(start_date, end_date, activity_type=None):
    """Retrieve Fabric audit logs for compliance reporting"""

    url = "https://api.fabric.microsoft.com/v1/admin/auditLogs"
    headers = {"Authorization": f"Bearer {token}"}

    params = {
        "startDateTime": start_date,
        "endDateTime": end_date,
        "activityType": activity_type  # e.g., "ViewReport", "ExportData"
    }

    response = requests.get(url, headers=headers, params=params)
    return response.json()

# Example: Get all data access events
access_logs = get_fabric_audit_logs(
    "2024-01-01T00:00:00Z",
    "2024-01-31T23:59:59Z",
    "ViewReport"
)
```

2. Créer compliance dashboard:
```python
# Aggregate audit data for compliance
audit_summary = spark.sql("""
    SELECT
        DATE(timestamp) as audit_date,
        user_email,
        activity_type,
        COUNT(*) as event_count,
        COUNT(DISTINCT item_id) as unique_items_accessed
    FROM audit_logs
    WHERE timestamp >= DATE_SUB(CURRENT_DATE, 30)
    GROUP BY DATE(timestamp), user_email, activity_type
    ORDER BY audit_date DESC, event_count DESC
""")

# Identify potential violations
violations = spark.sql("""
    SELECT *
    FROM audit_logs
    WHERE
        -- Unusual access patterns
        (activity_type = 'ExportData' AND item_sensitivity = 'HighlyConfidential')
        OR
        -- After hours access to sensitive data
        (HOUR(timestamp) NOT BETWEEN 8 AND 18 AND item_sensitivity IN ('Confidential', 'HighlyConfidential'))
        OR
        -- Bulk data access
        (activity_type = 'ViewReport' AND records_accessed > 10000)
""")
```

3. Implémenter GDPR compliance checks:
```python
# Data Subject Access Request (DSAR) handler
def handle_dsar_request(user_email):
    """Generate report of all data held for a specific user"""

    user_data = {}

    # Check all relevant tables
    tables_with_pii = ["customers", "orders", "support_tickets", "marketing_preferences"]

    for table in tables_with_pii:
        df = spark.table(table).filter(f"email = '{user_email}'")
        if df.count() > 0:
            user_data[table] = df.toPandas().to_dict('records')

    return user_data

# Right to be forgotten
def anonymize_user_data(user_email):
    """Anonymize user data across all tables (GDPR Article 17)"""

    # Log the request
    log_gdpr_action("erasure_request", user_email)

    # Anonymize in each table
    spark.sql(f"""
        UPDATE customers
        SET
            email = 'anonymized@deleted.com',
            name = 'DELETED_USER',
            phone = NULL,
            address = NULL
        WHERE email = '{user_email}'
    """)

    # Maintain audit trail
    log_gdpr_action("erasure_completed", user_email)
```

4. Générer compliance reports:
```python
# Monthly compliance report
def generate_compliance_report():
    report = {
        "report_date": datetime.now().isoformat(),
        "period": "Monthly",
        "metrics": {
            "total_users": get_active_users_count(),
            "sensitive_data_accesses": count_sensitive_accesses(),
            "rls_violations_blocked": count_rls_blocks(),
            "masking_applications": count_masked_queries(),
            "dsar_requests_handled": count_dsar_requests(),
            "data_retention_compliance": check_retention_policies()
        },
        "audit_summary": generate_audit_summary(),
        "risk_indicators": identify_risks()
    }

    # Save to compliance lakehouse
    spark.createDataFrame([report]).write.mode("append").saveAsTable("compliance.monthly_reports")

    return report
```

### Phase 6: Documentation et Formation (1h)
1. Créer documentation sécurité:
   - Architecture de sécurité (diagrammes)
   - Matrice des rôles et permissions
   - Procédures d'onboarding/offboarding
   - Guide de classification des données

2. Préparer formation équipe:
   - Best practices sécurité Fabric
   - Comment demander accès
   - Responsabilités utilisateurs
   - Signalement incidents

## Livrables
- [ ] Architecture multi-tenant documentée
- [ ] RLS dynamique avec 3+ rôles
- [ ] CLS sur colonnes sensibles
- [ ] Data masking configuré
- [ ] Purview integration fonctionnelle
- [ ] Sensitivity labels appliqués
- [ ] Audit dashboard avec métriques clés
- [ ] GDPR compliance features
- [ ] Documentation complète
- [ ] Formation sécurité

## Critères d'évaluation
- RLS/CLS implementation correctness (30%)
- Audit trail completeness (25%)
- Purview integration depth (20%)
- Compliance documentation (15%)
- Security best practices (10%)

## Tests de validation
```
1. RLS Test:
   ✓ User A sees only Region A data
   ✓ User B sees only Region B data
   ✓ Manager sees all regions
   ✓ No data leakage between tenants

2. Masking Test:
   ✓ SSN shows XXX-XX-1234 for viewers
   ✓ Email shows jXXX@XXXX.com
   ✓ Authorized users see full data
   ✓ Masking persists in exports

3. Audit Test:
   ✓ All data accesses logged
   ✓ Sensitive data access highlighted
   ✓ Unusual patterns detected
   ✓ Reports generate correctly
```

---

**Durée estimée: 10-12 heures**

[⬅️ Retour aux projets](../README.md)
