# Sensitivity Labels

## Introduction

**Sensitivity Labels** sont des marqueurs de classification appliqués aux données pour indiquer leur niveau de confidentialité et appliquer automatiquement des protections.

```
Label Hierarchy:
┌─────────────────────────────┐
│  Highly Confidential        │  ← Most restricted
├─────────────────────────────┤
│  Confidential               │
├─────────────────────────────┤
│  Internal                   │
├─────────────────────────────┤
│  Public                     │  ← Least restricted
└─────────────────────────────┘
```

## Microsoft Information Protection

### Framework Overview

```
Microsoft Information Protection (MIP):
  • Unified labeling across Microsoft 365
  • Automatic protection based on label
  • Consistent across Word, Excel, Power BI, Fabric
  • Integrated with Azure AD

Components:
  1. Labels (classification)
  2. Policies (who can apply which labels)
  3. Protection (encryption, restrictions)
  4. Analytics (label usage tracking)
```

### Integration with Fabric

```
Flow:
  MIP Label → Fabric Asset → Downstream Reports

Example:
  Lakehouse table: Customer PII
  Label: "Confidential"

  Semantic model built on table:
  Inherits "Confidential" label

  Report built on dataset:
  Inherits "Confidential" label

  Export to PDF:
  PDF marked "Confidential"

Protection travels with data
```

## Creating Labels

### Label Structure

```
Label configuration:

Name: Confidential
  Sub-labels:
    - Confidential\HR Data
    - Confidential\Financial
    - Confidential\PII

Properties:
  • Display name (user sees)
  • Description (guidance for users)
  • Color (visual indicator)
  • Priority (determines hierarchy)
  • Protection settings
```

### Typical Label Scheme

```
Public:
  • Marketing materials
  • Public announcements
  • Non-sensitive documentation
  • No restrictions on sharing
  • Color: Green

Internal:
  • Employee directory
  • Internal procedures
  • Non-confidential business data
  • Share within organization only
  • Color: Yellow

Confidential:
  • Customer data
  • Financial reports
  • Strategic plans
  • Restricted sharing
  • Color: Orange

Highly Confidential:
  • Trade secrets
  • M&A information
  • Executive compensation
  • Very restricted, encrypted
  • Color: Red
```

### Protection Actions

```
What labels can enforce:

1. Visual marking
   Header: "CONFIDENTIAL"
   Footer: "Internal Use Only"
   Watermark: Company logo

2. Encryption
   Only authorized users can open
   Azure Rights Management (RMS)
   Key managed by organization

3. Access restrictions
   Prevent copy/paste
   Disable printing
   Block screenshots
   Restrict forwarding

4. Expiration
   Access expires after date
   Re-authentication required
   Content auto-deletes

Configuration varies by label
Higher labels = more restrictions
```

## Applying Labels

### Manual Application

```
User applies label:

Power BI Desktop:
1. File menu → Sensitivity
2. Select label
3. Apply

Fabric portal:
1. Asset settings
2. Sensitivity section
3. Choose label

Use cases:
  • User knows data sensitivity
  • Override automatic suggestion
  • Special circumstances

Requirements:
  • User has permission to apply label
  • Label available in policy
  • Business justification (optional)
```

### Automatic Labeling

```
System applies label based on content:

Rules:
  IF contains SSN pattern THEN apply "Confidential\PII"
  IF contains credit card THEN apply "Confidential\Financial"
  IF from HR system THEN apply "Confidential\HR Data"

Configuration:
  Admin creates auto-label policies
  Defines conditions (content inspection)
  Specifies label to apply
  Optionally: Recommend vs Force

Power BI behavior:
  Dataset contains PII → Auto-labeled Confidential
  No user action needed
  Consistent application

Benefits:
  ✅ Consistent classification
  ✅ No user burden
  ✅ Reduces human error
  ✅ Scales across organization
```

### Recommended vs Required

```
Policy options:

Recommended:
  System suggests label
  User can accept or change
  Prompt: "This content appears confidential. Apply Confidential label?"
  User training opportunity

Required:
  System forces label
  User cannot change (without special permission)
  Higher security but less flexibility
  Use for highly sensitive data

Configuration:
  Admins set policy:
    Label: Highly Confidential
    Application: Required for exec data
    Justification: Always required
```

## Label Inheritance

### Parent to Child

```
Inheritance in Fabric:

Lakehouse (Confidential)
  ↓
Tables inherit (Confidential)
  ↓
Semantic model inherits (Confidential)
  ↓
Reports inherit (Confidential)
  ↓
Dashboards inherit (Confidential)
  ↓
Exports inherit (Confidential)

Automatic propagation:
  Parent labeled → Children inherit
  No manual re-labeling needed
  Consistent protection

Exception:
  Child can have higher label (upgrade allowed)
  Child cannot have lower label (downgrade blocked)
```

### Cross-Object Inheritance

```
When combining labeled sources:

Scenario:
  Dataset A: Confidential
  Dataset B: Internal

Composite model:
  Most restrictive wins
  Result: Confidential

Report using both:
  Labeled: Confidential (highest of inputs)

Merge scenarios:
  Public + Internal = Internal
  Internal + Confidential = Confidential
  Confidential + Highly Confidential = Highly Confidential

Always escalate to most sensitive
```

## Downgrade Protection

### Preventing Downgrade

```
Why protect downgrades:

Problem:
  Malicious user relabels "Highly Confidential" to "Public"
  Shares externally
  Data breach

Solution:
  Downgrade requires justification
  Audit trail maintained
  Approval workflow (optional)

Configuration:
  Policy: Downgrade requires justification
  User must provide reason
  Logged for audit
```

### Justification Requirements

```
When downgrading label:

User action:
1. Attempt to change Confidential → Internal
2. System prompts for justification
3. Options:
   - "Previous label was incorrect"
   - "Data no longer sensitive"
   - "Manager approved"
   - "Other (specify)"
4. User selects and confirms
5. Change logged with justification

Audit log:
  User: alice@company.com
  Asset: SalesReport
  Old label: Confidential
  New label: Internal
  Justification: "Data aggregated, no PII"
  Timestamp: 2024-01-15 10:30:00
```

### Approval Workflows

```
Advanced downgrade control:

Workflow:
1. User requests downgrade
2. Request sent to data owner
3. Owner reviews:
   - Asset contents
   - Justification provided
   - Compliance implications
4. Owner approves/denies
5. If approved, label changed
6. Full audit trail maintained

Configuration:
  Power Automate flow
  Approval via Teams/Email
  SLA for response
  Escalation if no response

Use for:
  Highly sensitive data
  Regulatory requirements
  High-risk changes
```

## Label Policies

### Policy Scope

```
Define who gets which labels:

Policy: Standard Users
  Labels available:
    - Public
    - Internal
    - Confidential
  Applied to: All users
  Default: Internal

Policy: Executive Access
  Labels available:
    - All standard labels
    - Highly Confidential
  Applied to: Executive group
  Default: Confidential

Policy: Data Stewards
  Labels available:
    - All labels
    - Can downgrade with justification
    - Can remove labels (special cases)
  Applied to: Governance team

Multiple policies:
  User gets union of all applicable policies
  Most permissive wins for availability
```

### Default Labels

```
Automatic labeling for new content:

Policy setting:
  Default label: Internal

Behavior:
  New dataset created → Auto-labeled Internal
  New report created → Auto-labeled Internal
  Unless user specifies otherwise

Benefits:
  ✅ No unlabeled content
  ✅ Baseline protection
  ✅ User convenience

Override:
  User can change from default
  Must be allowed label
  Logged if changed
```

### Mandatory Labeling

```
Require labels on all content:

Policy:
  Mandatory: Yes
  Assets must have label before sharing

Enforcement:
  User tries to share unlabeled report
  Error: "Label required before sharing"
  User must apply label first

Benefits:
  ✅ No gaps in classification
  ✅ Forced consideration
  ✅ Complete audit trail

User experience:
  Slight friction (must label)
  Training important
  Clear guidance needed
```

## Sensitivity Labels in Fabric

### Supported Assets

```
Fabric items with label support:

✅ Lakehouses
✅ Warehouses
✅ Semantic models (datasets)
✅ Reports
✅ Dashboards
✅ Dataflows Gen2
✅ Pipelines

Limited support:
⚠️ KQL Databases (metadata only)
⚠️ Notebooks (file level)

Not labeled:
❌ Individual tables (inherit from container)
❌ Connections
❌ Parameters
```

### Visual Indicators

```
How labels appear:

Workspace view:
  Dataset name [🔒 Confidential]
  Report name [🟡 Internal]

Asset settings:
  Sensitivity: Confidential (orange badge)

Export files:
  Header: "CONFIDENTIAL"
  Footer: "Company Name - Internal Use Only"

Report viewer:
  Top banner: "This report is labeled Confidential"

Clear visual cues
Users aware of sensitivity
```

### Export Behavior

```
Labels persist during export:

Scenario:
  Power BI report labeled "Confidential"
  User exports to PDF

Result:
  PDF has watermark
  File metadata includes label
  Encryption applied (if configured)
  Cannot be opened without permission

Export formats:
  PDF: Visual marking + metadata
  Excel: Rights Management protection
  PowerPoint: Slide watermarks
  Image: Watermark overlay

Protection travels with data
Even outside Fabric environment
```

## Audit and Monitoring

### Label Usage Reports

```
Track label application:

Metrics:
  • Assets by label (distribution)
  • Label changes over time
  • Downgrade frequency
  • Unlabeled assets count

Report example:
  Public: 50 assets (15%)
  Internal: 180 assets (55%)
  Confidential: 85 assets (26%)
  Highly Confidential: 12 assets (4%)
  Unlabeled: 0 assets (0%) ✓

Trend analysis:
  Confidential labels increasing
  Indicates more sensitive data being added
  Adjust controls accordingly
```

### Compliance Alerts

```
Monitor for issues:

Alert: Highly Confidential asset shared externally
  Trigger: External sharing detected
  Action: Notify compliance team
  Severity: High

Alert: Mass downgrade detected
  Trigger: >10 downgrades in 1 hour
  Action: Investigate user activity
  Severity: Medium

Alert: Unlabeled assets published
  Trigger: Asset without label shared
  Action: Auto-apply default label
  Severity: Low (if default applied)

Proactive monitoring
Catch issues early
Maintain compliance posture
```

### Activity Logs

```
Detailed audit trail:

Event: Label applied
  User: bob@company.com
  Asset: CustomerAnalysis report
  Label: Confidential
  Time: 2024-01-15 14:30:00
  Source: Manual

Event: Label downgraded
  User: carol@company.com
  Asset: SalesReport
  Old: Confidential
  New: Internal
  Justification: "Aggregated data only"
  Time: 2024-01-15 15:45:00
  Approved by: Data Steward

Event: Protected content accessed
  User: dave@company.com
  Asset: ExecutiveReport (Highly Confidential)
  Access: Granted
  Location: Redmond office
  Time: 2024-01-15 16:00:00

Complete visibility
Regulatory evidence
Security investigation support
```

## Best Practices

### Label Strategy

```
1. Keep labels simple
   3-5 labels sufficient
   Too many confuses users
   Clear distinctions

2. Provide guidance
   When to use each label
   Examples for each category
   Quick reference card

3. Start with defaults
   Most content gets baseline protection
   Users upgrade when needed
   Reduces burden

4. Align with data classification
   Labels match data sensitivity
   Purview classifications → Labels
   Consistent approach

5. Involve stakeholders
   Legal: Compliance requirements
   Security: Protection needs
   Business: Usability concerns
```

### Common Mistakes

```
❌ Too many labels
  Users confused
  Inconsistent application
  Keep it simple

❌ No user training
  Users don't understand
  Incorrect labels applied
  Invest in education

❌ Labels without protection
  Visual marking only
  No actual enforcement
  False sense of security

❌ Ignoring inheritance
  Child assets unlabeled
  Gaps in protection
  Configure policies correctly

❌ Not monitoring usage
  Don't know if working
  Can't prove compliance
  Set up reporting
```

### Implementation Checklist

```
Before rollout:
[ ] Define label hierarchy
[ ] Configure protection actions
[ ] Create label policies
[ ] Test inheritance behavior
[ ] Set default labels
[ ] Configure mandatory labeling
[ ] Train users
[ ] Communicate policies
[ ] Set up monitoring
[ ] Document everything

After rollout:
[ ] Monitor adoption
[ ] Review downgrade requests
[ ] Analyze label distribution
[ ] Gather user feedback
[ ] Adjust policies as needed
[ ] Regular compliance audits
```

## Points Clés

- Sensitivity labels classify data by confidentiality level
- Microsoft Information Protection provides unified framework
- Labels can enforce protection: marking, encryption, restrictions
- Manual vs automatic labeling (recommend vs require)
- Inheritance: Parent labels flow to child assets
- Downgrade protection prevents unauthorized relabeling
- Label policies control who applies which labels
- Fabric supports labels on most asset types
- Visual indicators make sensitivity clear to users
- Audit trails track all label activities
- Best practices: Simple scheme, user training, monitoring

---

**Prochain fichier :** [08 - Compliance & Audit](./08-compliance-audit.md)

[⬅️ Fichier précédent](./06-data-lineage.md) | [⬅️ Retour au README du module](./README.md)
