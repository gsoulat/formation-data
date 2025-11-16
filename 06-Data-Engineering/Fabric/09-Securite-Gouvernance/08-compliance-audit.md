# Compliance & Audit

## Introduction

**Compliance et Audit** assurent que l'utilisation des données respecte les réglementations et politiques, avec traçabilité complète pour les vérifications.

```
Compliance Framework:
┌─────────────────────────────────────────┐
│  Regulatory Requirements                 │
│  (GDPR, HIPAA, SOC 2, PCI DSS)          │
├─────────────────────────────────────────┤
│  Organizational Policies                 │
│  (Data retention, access controls)       │
├─────────────────────────────────────────┤
│  Technical Controls                      │
│  (Audit logs, encryption, RLS)          │
├─────────────────────────────────────────┤
│  Monitoring & Reporting                  │
│  (Activity tracking, compliance reports) │
└─────────────────────────────────────────┘
```

## Audit Logs dans Fabric

### What is Logged

```
Fabric captures:

User activities:
  • Report views
  • Data exports
  • Dataset refreshes
  • Sharing actions
  • Permission changes

Admin activities:
  • Workspace creation
  • Capacity management
  • Tenant settings changes
  • User provisioning

System events:
  • Refresh successes/failures
  • Gateway connections
  • API calls
  • Security events

Retention:
  • 30 days default
  • Exportable for longer retention
  • Integration with SIEM systems
```

### Accessing Logs

```
Methods:

1. Fabric Admin Portal
   Admin portal → Audit logs
   Filter by user, action, date
   Export to CSV

2. Microsoft 365 Compliance Center
   Unified audit log
   Cross-service view
   Advanced search

3. PowerShell
   Search-UnifiedAuditLog -RecordType PowerBI
   Programmatic access
   Automation friendly

4. REST API
   Activity events API
   Custom integrations
   Dashboard building
```

### Common Queries

```powershell
# PowerShell examples

# All Power BI activities in last 7 days
Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -RecordType PowerBI `
    -ResultSize 5000

# Specific user activities
Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-30) `
    -EndDate (Get-Date) `
    -UserIds "user@company.com" `
    -RecordType PowerBI

# Export activities (data exfiltration check)
Search-UnifiedAuditLog `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -Operations "ExportReport","DownloadReport" `
    -RecordType PowerBI
```

### Event Types

```
Key events to monitor:

Access events:
  ViewReport - User viewed report
  ViewDataset - User accessed dataset
  GetDatasource - Connection accessed

Modification events:
  CreateReport - New report created
  UpdateDataset - Dataset modified
  DeleteWorkspace - Workspace removed

Sharing events:
  ShareReport - Report shared
  AddWorkspaceUser - User added
  ExportReport - Data exported

Security events:
  ChangeGatewayDatasourceCredentials
  UpdateWorkspaceAccess
  ApplySensitivityLabel
```

## Activity Monitoring

### Real-Time Monitoring

```
Set up real-time alerts:

Scenario: Unusual data export
  Monitor: ExportReport events
  Threshold: >10 exports per user per day
  Alert: Email security team

Scenario: After-hours access
  Monitor: ViewReport events
  Time: Outside 7 AM - 9 PM
  Alert: Log for review

Scenario: Large data refresh failure
  Monitor: RefreshDataset events
  Status: Failed
  Alert: Notify data engineering team

Tools:
  • Azure Monitor
  • Logic Apps
  • Power Automate
  • Custom dashboards
```

### User Behavior Analytics

```
Detect anomalies:

Normal pattern:
  User A: 10 reports viewed daily
  User A: 2 exports weekly
  Access: Business hours

Anomaly detected:
  User A: 50 reports viewed (5x normal)
  User A: 15 exports (7x normal)
  Access: 2 AM (unusual time)

Investigation:
  • Is this legitimate business need?
  • Possible data exfiltration?
  • Compromised account?

Response:
  Alert generated
  Security review initiated
  User contacted for verification
```

## Compliance Standards

### GDPR (Data Protection)

```
General Data Protection Regulation (EU)

Requirements:
  1. Consent for personal data processing
  2. Right to access (data subject requests)
  3. Right to be forgotten (deletion)
  4. Data portability
  5. Breach notification (72 hours)

Fabric implementation:
  • Audit logs prove processing activities
  • RLS restricts unauthorized access
  • Sensitivity labels mark PII
  • Data lineage shows data flow
  • Export functionality for portability

Documentation needed:
  • Record of processing activities
  • Data protection impact assessment
  • Privacy policy
  • Consent records
```

### HIPAA (Healthcare)

```
Health Insurance Portability and Accountability Act

Requirements:
  1. Protected Health Information (PHI) safeguards
  2. Access controls
  3. Audit trail
  4. Data integrity
  5. Breach notification

Fabric implementation:
  • Encryption at rest and in transit
  • RLS for minimum necessary access
  • CLS for PHI column restriction
  • Activity logs for audit trail
  • Sensitivity labels for PHI

Key controls:
  • No PHI in shared datasets without controls
  • Masking for non-privileged users
  • BAA (Business Associate Agreement) with Microsoft
  • Regular access reviews
```

### SOC 2 (Security)

```
Service Organization Control Type 2

Trust Service Criteria:
  1. Security - Protection against unauthorized access
  2. Availability - System available for operation
  3. Processing Integrity - Processing is complete and accurate
  4. Confidentiality - Information designated confidential
  5. Privacy - Personal information protected

Fabric alignment:
  Security: Azure AD, MFA, workspace roles
  Availability: Fabric SLA, redundancy
  Processing Integrity: Data validation, testing
  Confidentiality: RLS, CLS, encryption
  Privacy: Sensitivity labels, data masking

Evidence collection:
  • Access control reports
  • Audit log exports
  • Configuration screenshots
  • Policy documentation
```

### PCI DSS (Payment Cards)

```
Payment Card Industry Data Security Standard

Requirements:
  1. Protect cardholder data
  2. Maintain vulnerability management
  3. Implement access control
  4. Monitor networks
  5. Maintain information security policy

Fabric implementation:
  • CLS for credit card columns
  • Dynamic masking for card numbers
  • No full card numbers in reports
  • Encrypted storage
  • Limited access to payment data

Best practice:
  • Don't store full card numbers
  • Use tokens or last 4 digits
  • Minimize payment data in analytics
  • Regular security assessments
```

## Data Retention Policies

### Defining Retention

```
Retention policy components:

1. What data is covered
   • Raw data (Lakehouse)
   • Processed data (Warehouse)
   • Reports and dashboards
   • Audit logs

2. How long to keep
   • Legal requirements (7 years for financial)
   • Business needs (historical trends)
   • Storage costs (balance retention)

3. What happens after retention
   • Archive (move to cold storage)
   • Delete (permanent removal)
   • Anonymize (remove PII, keep aggregates)

Example policy:
  Transaction data: 7 years (legal)
  Customer PII: 3 years (GDPR)
  Audit logs: 10 years (compliance)
  Temporary data: 30 days (operational)
```

### Implementation

```
Fabric retention setup:

Lakehouse:
  Use Delta Lake retention features
  VACUUM command for cleanup
  Automated via pipeline

VACUUM sales_table RETAIN 7 DAYS;
-- Removes files older than 7 days

Warehouse:
  Table partitioning by date
  Drop old partitions
  Scheduled cleanup jobs

Reports:
  Workspace lifecycle
  Archive unused reports
  Delete after review period

Automation:
  Pipeline runs monthly
  Identifies data past retention
  Deletes or archives
  Logs actions for audit
```

### Legal Hold

```
Preserving data for legal matters:

Scenario:
  Legal department notifies: "Preserve all data for Project X"
  Data cannot be deleted during investigation
  May last months or years

Implementation:
1. Identify relevant data
   • All Project X files
   • Related emails
   • Database records

2. Apply legal hold
   • Suspend retention policies
   • Mark as preserved
   • Notify data owners

3. Maintain hold
   • Regular verification
   • Prevent accidental deletion
   • Track custodians

4. Release hold
   • Legal clears hold
   • Resume normal retention
   • Document release

Fabric approach:
  • Tag assets under hold
  • Exclude from cleanup jobs
  • Audit access during hold
  • Report on held data
```

## eDiscovery

### What is eDiscovery

```
Electronic Discovery = Legal process of finding electronic information

Use cases:
  • Litigation (lawsuit)
  • Regulatory investigation
  • Internal investigation
  • Compliance audit

Process:
  1. Identification (what data exists)
  2. Preservation (prevent deletion)
  3. Collection (gather relevant data)
  4. Processing (prepare for review)
  5. Review (attorneys examine)
  6. Production (provide to other party)
```

### Fabric and eDiscovery

```
Microsoft 365 eDiscovery integration:

Searchable content:
  • Power BI reports
  • Dataset metadata
  • Sharing information
  • Activity logs

Search queries:
  Find all reports about "Project Alpha"
  Data modified by specific user
  Content labeled "Confidential"

Export capabilities:
  • Report metadata
  • Activity logs
  • User access history
  • Configuration details

Limitations:
  • Actual data not directly searchable (in rows)
  • Metadata and activities are primary
  • May need to query databases separately
```

## Compliance Manager

### Overview

```
Microsoft Compliance Manager:
  • Assessment of compliance posture
  • Recommendations for improvement
  • Score based on controls implemented
  • Pre-built templates for regulations

Dashboard shows:
  Compliance score: 78/100
  Areas needing improvement
  Recommended actions
  Assessment history
```

### Pre-Built Assessments

```
Available assessments:

GDPR Assessment:
  • 150+ controls mapped
  • Microsoft responsibilities
  • Your responsibilities
  • Implementation guidance

SOC 2 Assessment:
  • Security controls
  • Availability metrics
  • Processing integrity checks

HIPAA Assessment:
  • PHI protection controls
  • Access management
  • Audit requirements

Custom Assessment:
  • Create for organization policies
  • Map internal controls
  • Track progress
```

### Improvement Actions

```
Compliance Manager recommendations:

Action: Enable Multi-Factor Authentication
  Impact: High (+5 points)
  Status: Not started
  Guidance: Configure Azure AD MFA
  Deadline: Q1 2024

Action: Implement Data Classification
  Impact: Medium (+3 points)
  Status: In progress
  Guidance: Apply sensitivity labels
  Deadline: Q2 2024

Action: Review Access Permissions
  Impact: Medium (+3 points)
  Status: Completed
  Evidence: Attached access review report

Track progress over time
Demonstrate compliance improvement
```

## Reporting for Compliance

### Executive Dashboard

```
Compliance status summary:

Key metrics:
  • Overall compliance score: 82%
  • Open findings: 5
  • Overdue actions: 2
  • Last audit date: 2024-01-15

Risk areas:
  • Data access reviews: Behind schedule
  • Encryption: Not all datasets encrypted
  • Audit log retention: Only 30 days

Recommendations:
  1. Complete Q1 access reviews
  2. Enable encryption for all Lakehouses
  3. Extend audit log retention to 1 year
```

### Audit Evidence Package

```
For auditors/regulators:

Package includes:
  1. Access control evidence
     • User permission exports
     • Role assignments
     • Group memberships

  2. Activity evidence
     • Audit log exports
     • Login history
     • Data access patterns

  3. Security configuration
     • Encryption settings
     • MFA status
     • Conditional access policies

  4. Data governance
     • Sensitivity label usage
     • Data classification reports
     • Retention policy documentation

  5. Incident records
     • Security incidents
     • Breach notifications
     • Remediation actions

Organized by control
Easy for auditor review
Demonstrates compliance
```

### Automated Reporting

```
Schedule compliance reports:

Power Automate flow:
1. Trigger: Monthly (1st day)
2. Actions:
   • Query audit logs
   • Calculate metrics
   • Generate report
   • Email to compliance team
   • Store in SharePoint

Report contents:
  • User access summary
  • Label usage statistics
  • Policy violations
  • Risk indicators
  • Trend analysis

Benefits:
  • Consistent reporting
  • No manual effort
  • Historical tracking
  • Early warning system
```

## Best Practices

### Compliance Program

```
1. Know your regulations
   • Which apply to your industry
   • Specific requirements
   • Penalties for non-compliance

2. Map controls to data
   • Which data affected
   • What controls needed
   • Implementation plan

3. Automate where possible
   • Audit log collection
   • Policy enforcement
   • Reporting

4. Regular assessments
   • Internal audits
   • Third-party reviews
   • Penetration testing

5. Continuous improvement
   • Learn from findings
   • Update controls
   • Train employees
```

### Common Mistakes

```
❌ Ignoring audit logs
  No review of activities
  Miss security incidents
  Can't prove compliance

❌ Manual compliance
  Inconsistent application
  Resource intensive
  Error prone

❌ No retention policy
  Data grows indefinitely
  Legal liability
  Storage costs

❌ Reactive approach
  Fix issues after audit finds them
  More costly
  Reputation risk

❌ Siloed compliance
  IT doesn't talk to Legal
  Business ignores requirements
  Gaps in coverage
```

### Audit Preparation Checklist

```
Before audit:
[ ] Review scope of audit
[ ] Gather required evidence
[ ] Verify controls are functioning
[ ] Document any exceptions
[ ] Prepare key personnel
[ ] Test evidence retrieval
[ ] Update compliance documentation

During audit:
[ ] Provide requested evidence promptly
[ ] Answer questions accurately
[ ] Document auditor requests
[ ] Track findings as they arise
[ ] Maintain professional communication

After audit:
[ ] Review final report
[ ] Create remediation plan
[ ] Assign owners for findings
[ ] Set deadlines for fixes
[ ] Schedule follow-up audit
[ ] Update controls based on learnings
```

## Points Clés

- Audit logs capture all user and system activities in Fabric
- Activity monitoring detects anomalies and security incidents
- Compliance standards: GDPR, HIPAA, SOC 2, PCI DSS
- Data retention policies balance legal, business, and cost needs
- Legal hold preserves data during investigations
- eDiscovery searches electronic information for legal matters
- Compliance Manager scores and recommends improvements
- Automated reporting reduces manual effort and ensures consistency
- Best practices: Know regulations, automate, assess regularly
- Evidence packages demonstrate compliance to auditors

---

**Module 09 complet!** Vous maîtrisez maintenant la sécurité et la gouvernance dans Fabric: workspace security, RLS/CLS, data masking, Purview integration, lineage, sensitivity labels, et compliance.

[⬅️ Fichier précédent](./07-sensitivity-labels.md) | [⬅️ Retour au README du module](./README.md)
