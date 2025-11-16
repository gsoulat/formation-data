# Microsoft Purview Integration

## Introduction

**Microsoft Purview** est la plateforme unifiée de gouvernance des données de Microsoft, intégrée avec Fabric pour le catalogage, la classification, et la découverte des données.

```
Purview + Fabric Architecture:
┌──────────────────────────────────────────┐
│  Microsoft Purview                        │
│  ├─ Data Catalog                          │
│  ├─ Data Map                              │
│  ├─ Data Estate Insights                  │
│  └─ Data Policy                           │
├──────────────────────────────────────────┤
│  Fabric Assets                            │
│  ├─ Lakehouses                            │
│  ├─ Warehouses                            │
│  ├─ Datasets                              │
│  └─ Pipelines                             │
└──────────────────────────────────────────┘
```

## Vue d'ensemble de Purview

### Composants Principaux

```
1. Data Catalog
   • Central inventory of data assets
   • Searchable metadata
   • Business glossary

2. Data Map
   • Automated scanning
   • Data classification
   • Lineage tracking

3. Data Estate Insights
   • Analytics on your data estate
   • Sensitive data reports
   • Classification coverage

4. Data Policy
   • Access policies
   • Governance rules
   • Compliance controls
```

### Benefits

```
✅ Single pane of glass for data governance
✅ Automated discovery and classification
✅ Business-friendly data descriptions
✅ Compliance and audit support
✅ Cross-platform visibility (Azure, Fabric, on-prem)
✅ Data lineage tracking
```

## Enregistrement de Sources Fabric

### Connect Fabric to Purview

```
Setup process:
1. Microsoft Purview portal → Data Map
2. Register sources → Microsoft Fabric
3. Configure connection:
   • Tenant information
   • Authentication (managed identity)
   • Workspace selection
4. Verify connectivity

Requirements:
  • Purview account created
  • Fabric capacity available
  • Proper permissions (Data Source Admin)
  • Network connectivity
```

### Source Types

```
Registerable Fabric assets:
  • Lakehouse (Delta tables)
  • Data Warehouse (SQL tables)
  • Semantic Models (datasets)
  • Pipelines (orchestration)
  • Dataflows Gen2

Metadata captured:
  • Schema information
  • Column details
  • Relationships
  • Last modified dates
  • Owners
```

## Scanning et Cataloging

### Creating Scans

```
Scan configuration:
1. Select registered source
2. Create new scan
3. Configure:
   • Scan scope (all or specific assets)
   • Credential (managed identity)
   • Classification rules
   • Scan trigger (manual or scheduled)

Example:
  Source: Fabric Lakehouse (Sales)
  Scope: All tables
  Classification: Enabled (PII detection)
  Schedule: Weekly on Sunday 2 AM
  Credential: Managed identity
```

### Scan Results

```
After scan completes:

Assets discovered:
  • 25 tables
  • 350 columns
  • 15 pipelines

Classifications applied:
  • 12 columns marked as PII
  • 5 columns marked as Financial
  • 3 columns marked as Confidential

Metadata captured:
  • Column names and types
  • Sample data patterns
  • Table sizes
  • Last update timestamps

Searchable in catalog:
  "Find all tables with customer email"
  "Show assets classified as PII"
  "List financial data sources"
```

### Incremental Scanning

```
Full scan vs Incremental:

Full scan:
  • Scans everything
  • Longer duration
  • Higher resource usage
  • Use initially or after major changes

Incremental scan:
  • Only changed assets
  • Faster
  • Less resource intensive
  • Use for regular updates

Configuration:
  Schedule: Incremental weekly
  Retain: Full scan monthly
```

## Data Classification

### Built-in Classifications

```
Pre-configured patterns:

Personal Information:
  • Email addresses
  • Phone numbers
  • Names
  • Addresses

Government IDs:
  • Social Security Number (SSN)
  • Driver's license
  • Passport number
  • National ID

Financial:
  • Credit card numbers
  • Bank account numbers
  • IBAN/SWIFT codes
  • Tax IDs

Healthcare (HIPAA):
  • Medical record numbers
  • Health insurance IDs
  • Patient names
  • Diagnoses

Pattern matching:
  Email: regex for *@*.com/org/net
  SSN: 3-2-4 digit pattern
  Credit Card: Luhn algorithm validation
```

### Custom Classifications

```
Create organization-specific patterns:

Example: Employee ID
  Pattern: EMP-[0-9]{6}
  Matches: EMP-123456, EMP-000001

Example: Internal Project Code
  Pattern: PRJ-[A-Z]{3}-[0-9]{4}
  Matches: PRJ-ABC-2024, PRJ-XYZ-1234

Configuration:
1. Purview → Data Map → Classifications
2. Create custom classification
3. Define pattern (regex)
4. Add description
5. Apply to scans

Use cases:
  • Internal codes
  • Proprietary identifiers
  • Industry-specific data
```

### Classification Accuracy

```
Review and adjust:

False positives:
  Column "CustomerPhoneModel" classified as Phone Number
  Reason: Pattern matches "model numbers with digits"
  Fix: Add exclusion rule or adjust pattern

False negatives:
  Column "EmergencyContact" not classified as PII
  Reason: Free-form text, no pattern detected
  Fix: Add custom rule for column name patterns

Best practice:
  • Review scan results
  • Adjust classifications
  • Document exceptions
  • Re-scan affected assets
```

## Business Glossary

### Creating Terms

```
Business glossary = Shared vocabulary

Term: "Customer Churn"
  Definition: Customer who canceled subscription in last 30 days
  Synonyms: Attrition, Lost Customer
  Related terms: Retention, Lifetime Value
  Owner: Marketing Analytics Team
  Status: Approved

Term: "Net Revenue"
  Definition: Gross revenue minus discounts, returns, and taxes
  Formula: Gross Revenue - Discounts - Returns - Taxes
  Different from: Gross Revenue
  Data Steward: Finance Team

Benefits:
  ✅ Consistent understanding
  ✅ Self-service discovery
  ✅ Reduced ambiguity
  ✅ Business-IT alignment
```

### Linking Terms to Assets

```
Connect glossary to data:

Scenario:
  Glossary term: "Customer Lifetime Value (CLV)"
  Related column: Customers.LifetimeValue

Linking process:
1. Asset: Customers table
2. Column: LifetimeValue
3. Assign glossary term: Customer Lifetime Value
4. Link established

Result:
  When user searches "CLV"
  → Finds glossary term
  → Sees linked Customers.LifetimeValue column
  → Understands business context

Discovery:
  "What data do we have about customer churn?"
  → Glossary term "Churn"
  → Linked tables: CustomerRetention, SubscriptionCancellations
  → User finds relevant data sources
```

### Governance Workflows

```
Term approval process:

1. Draft term submitted
   Submitted by: Data Analyst
   Term: "Active User"
   Definition: User with login in last 30 days

2. Review by data steward
   Reviewer: Analytics Manager
   Comments: "Should we use 7 days instead?"

3. Revision
   Updated definition: User with login in last 7 days

4. Approval
   Approved by: Data Governance Board
   Status: Approved
   Effective date: 2024-02-01

5. Publication
   Available in catalog
   Linked to relevant assets
   Used across organization
```

## Data Discovery

### Searching the Catalog

```
Search capabilities:

Keyword search:
  "customer email"
  → Returns assets with customer and email in metadata

Filtered search:
  Source type: Fabric Lakehouse
  Classification: PII
  Owner: DataTeam@company.com

Advanced queries:
  "tables modified in last 30 days"
  "columns classified as financial"
  "assets without owner assigned"

Results display:
  Asset name
  Type (table, column, pipeline)
  Classifications
  Description
  Glossary terms
  Lineage information
```

### Browse by Collection

```
Organize assets into collections:

Collection: Sales Analytics
  ├─ Lakehouse: Sales_DW
  │   ├─ Table: FactSales
  │   ├─ Table: DimCustomer
  │   └─ Table: DimProduct
  ├─ Semantic Model: SalesReport
  └─ Pipeline: DailySalesLoad

Collection: Marketing
  ├─ Lakehouse: Marketing_Analytics
  ├─ Dataset: CampaignPerformance
  └─ Dataflow: CustomerSegmentation

Benefits:
  • Logical grouping
  • Team-based organization
  • Access control per collection
  • Easier navigation
```

### Data Asset Details

```
Asset page shows:

Overview:
  • Name, type, source
  • Owner, last modified
  • Description
  • Classification summary

Schema:
  • All columns with types
  • Column classifications
  • Glossary term links

Lineage:
  • Where data comes from
  • Where data goes to
  • Transformation steps

Related:
  • Similar assets
  • Related glossary terms
  • Dependent reports/pipelines
```

## Endorsement

### Certified vs Promoted

```
Endorsement levels:

Promoted:
  • "Good quality, verified by owner"
  • Self-service endorsement
  • Indicates recommended dataset
  • Green badge in Fabric

Certified:
  • "Highest quality, organization approved"
  • Requires special permission
  • Organizational standard
  • Gold badge in Fabric

No endorsement:
  • Default state
  • May be work in progress
  • Not officially recommended

Process:
  1. Data owner promotes asset (self-service)
  2. Data steward reviews
  3. If criteria met, certifies (elevated privilege)
```

### Certification Criteria

```
Before certifying:

Data quality checks:
  [ ] No NULL values in key columns
  [ ] Data refreshes successfully
  [ ] Accurate calculations
  [ ] Documented lineage

Documentation:
  [ ] Clear description
  [ ] Column descriptions
  [ ] Glossary terms linked
  [ ] Owner assigned

Security:
  [ ] Appropriate RLS/CLS
  [ ] Sensitivity labels applied
  [ ] Access permissions reviewed

Maintenance:
  [ ] Refresh schedule set
  [ ] Monitoring configured
  [ ] Support contact defined

Only certify when all criteria met
```

### Impact of Endorsement

```
User experience:

Fabric workspace:
  Datasets with certification badge
  Users prefer certified sources
  Reduces duplicate datasets

Search results:
  Certified assets ranked higher
  Visual indicators (badges)
  Trust signals for users

Governance:
  Track certified vs uncertified
  Measure adoption of quality data
  Identify gaps in certification
```

## Sensitivity Labels in Purview

### Label Inheritance

```
Flow:
  Purview classification → Fabric asset → Power BI report

Example:
  Purview scans Lakehouse
  Detects PII (Email, SSN)
  Recommends "Confidential" label

  Fabric asset receives label
  Power BI report built on asset
  Report inherits "Confidential" label

  User exports report to PDF
  PDF retains "Confidential" marking

Chain:
  Source data labeled → All downstream artifacts inherit
  Consistent protection across lifecycle
```

### Automatic vs Manual

```
Automatic labeling:
  Based on classification results
  PII detected → Apply "Confidential"
  Financial data → Apply "Internal"
  No intervention needed

Manual override:
  User believes label should be higher
  Can upgrade but not downgrade
  Requires justification

Policy:
  Automatic: Default classification rules
  Manual: User escalation when needed
  Downgrade: Requires special permission
```

## Best Practices

### Governance Program

```
1. Define ownership
   • Data owners (business)
   • Data stewards (technical)
   • Data custodians (operational)

2. Establish processes
   • Asset registration workflow
   • Classification review cadence
   • Glossary term approval
   • Certification criteria

3. Enable self-service
   • Searchable catalog
   • Clear documentation
   • Business glossary
   • Training materials

4. Monitor and improve
   • Track usage metrics
   • Measure classification coverage
   • Review false positives
   • Update rules regularly
```

### Common Mistakes

```
❌ Not scanning regularly
  Metadata becomes stale
  New assets not cataloged
  Classifications outdated

❌ Ignoring false positives
  Trust in system decreases
  Users ignore classifications
  Security gaps

❌ No business glossary
  Inconsistent terminology
  Misunderstanding of metrics
  Poor data literacy

❌ Not linking assets to terms
  Glossary exists but not used
  Discovery still difficult
  Business-IT disconnect

❌ Skipping certification
  All assets look equal
  Users can't identify quality
  Proliferation of duplicates
```

### Metrics to Track

```
Governance health dashboard:

Coverage:
  % of assets scanned
  % of assets with descriptions
  % of assets with owners

Classification:
  # of classified columns
  # of PII columns identified
  False positive rate

Quality:
  # of certified datasets
  # of promoted datasets
  Certification adoption rate

Usage:
  Catalog search volume
  Glossary term hits
  Asset discovery time
```

## Points Clés

- Purview = unified data governance platform
- Register Fabric sources for automated cataloging
- Scanning discovers and classifies assets
- Built-in classifications: PII, financial, healthcare
- Custom classifications for organization-specific patterns
- Business glossary provides shared vocabulary
- Endorsement: Promoted (owner) vs Certified (org approved)
- Data discovery via search and browse
- Sensitivity labels flow from Purview to Fabric
- Best practices: regular scanning, glossary maintenance, certification criteria

---

**Prochain fichier :** [06 - Data Lineage](./06-data-lineage.md)

[⬅️ Fichier précédent](./04-dynamic-data-masking.md) | [⬅️ Retour au README du module](./README.md)
