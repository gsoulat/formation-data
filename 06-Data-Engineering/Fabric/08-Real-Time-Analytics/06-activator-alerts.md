# Data Activator & Alerts

## Introduction

**Data Activator** est le service de détection et d'action automatique dans Microsoft Fabric, permettant de surveiller les données en temps réel et de déclencher des actions basées sur des conditions.

```
Data Activator Workflow:
┌──────────┐   ┌─────────────┐   ┌──────────┐   ┌──────────┐
│   Data   │ → │   Monitor   │ → │  Detect  │ → │  Action  │
│  Source  │   │  Conditions │   │  Trigger │   │ (Alert)  │
└──────────┘   └─────────────┘   └──────────┘   └──────────┘
     ↓               ↓                ↓              ↓
  KQL DB        Thresholds         Event         Teams/Email
  EventStream   Patterns           Matched       Power Automate
```

## Qu'est-ce que Data Activator ?

### Définition

```
Data Activator = No-code real-time alerting engine

Capabilities:
  ✅ Monitor data streams continuously
  ✅ Detect conditions and patterns
  ✅ Trigger automated actions
  ✅ No coding required
  ✅ Built into Fabric

Use cases:
  • Temperature exceeds threshold → Alert
  • Sales drop below target → Notify manager
  • Error rate spikes → Page on-call team
  • Inventory low → Reorder automatically
```

### Architecture

```
Components:
┌─────────────────────────────────────────┐
│  Reflex (Data Activator item)           │
│  ├─ Data sources (what to monitor)      │
│  ├─ Objects (business entities)         │
│  ├─ Properties (tracked metrics)        │
│  ├─ Triggers (conditions)               │
│  └─ Actions (what to do)                │
└─────────────────────────────────────────┘

Workflow:
  1. Connect to data source (KQL DB, EventStream)
  2. Define objects (Device, Customer, Order)
  3. Track properties (Temperature, Revenue)
  4. Set triggers (when Temperature > 80)
  5. Configure actions (send Teams message)
```

## Création d'un Reflex

### Via Fabric Portal

```
Step-by-step:
1. Workspace → + New → Reflex
2. Name: "IoT Temperature Alerts"
3. Connect data source
4. Define objects and properties
5. Create triggers
6. Configure actions
7. Activate monitoring

Interface:
  ┌─────────────────────────────────────┐
  │  Data  │  Design  │  Triggers       │
  ├─────────────────────────────────────┤
  │  Object: Device                     │
  │  ├─ Property: Temperature           │
  │  ├─ Property: Status                │
  │  └─ Trigger: High Temperature Alert │
  └─────────────────────────────────────┘
```

### From Power BI Report

```
Quick setup from visual:

1. Open Power BI report
2. Right-click on visual
3. Select "Set Alert" or "Create Reflex"
4. Define condition:
   "When Total Sales < 10000"
5. Choose action:
   "Send email to me"
6. Activate

Benefits:
  ✅ Quick setup
  ✅ Leverages existing visuals
  ✅ No separate configuration
  ✅ Business user friendly
```

## Objects et Properties

### Defining Objects

```
Object = Business entity to monitor

Examples:
  • Device (IoT sensor)
  • Customer (business account)
  • Order (transaction)
  • Server (IT infrastructure)
  • Employee (HR tracking)

Object definition:
  Name: Device
  Key: DeviceId (unique identifier)
  Source: KQL Database / Telemetry table

Data source columns:
  DeviceId → Object key
  Temperature → Property
  Humidity → Property
  Status → Property
  Location → Property (static attribute)
```

### Property Types

```
1. Measure (numeric, changes over time)
   • Temperature: 25.3°C
   • Revenue: $45,000
   • Error count: 15

2. State (categorical, current status)
   • Device status: Online/Offline
   • Order status: Pending/Shipped
   • Alert level: Normal/Warning/Critical

3. Dimension (static attribute)
   • Device location: Factory_A
   • Customer region: Europe
   • Product category: Electronics

Configuration:
  Property: Temperature
  Type: Measure
  Source column: Temperature
  Update frequency: Real-time (streaming)
```

## Types de Triggers

### Threshold Triggers

```
Simple value comparison:

Condition examples:
  • Temperature > 80
  • Revenue < 10000
  • ErrorRate >= 0.05
  • Inventory <= ReorderPoint

Configuration:
  Trigger: High Temperature
  When: Temperature becomes greater than 80
  For: Any device
  Action: Send Teams alert

Timeline behavior:
  Temperature = 78 → No alert
  Temperature = 82 → ALERT TRIGGERED
  Temperature = 85 → No new alert (already triggered)
  Temperature = 75 → Alert clears
  Temperature = 82 → ALERT TRIGGERED (new occurrence)
```

### Change Detection

```
Monitor for significant changes:

Conditions:
  • Value changed by more than X%
  • Value increased/decreased
  • Status changed to specific value

Example:
  Trigger: Revenue Drop Alert
  When: Revenue decreases by more than 20% in 1 hour
  Action: Notify sales manager

  Hour 1: Revenue = $50,000
  Hour 2: Revenue = $38,000 (24% drop)
  → ALERT: "Revenue dropped 24% in last hour"
```

### Pattern Detection

```
Complex pattern recognition:

Types:
  • Continuous above/below threshold for duration
  • Oscillation (rapid changes)
  • Trend (consistent increase/decrease)

Example:
  Trigger: Sustained High Temperature
  When: Temperature > 75 for more than 10 minutes
  Action: Create maintenance ticket

  Timeline:
    10:00 - Temperature 76 → Start timer
    10:05 - Temperature 78 → Still high
    10:10 - Temperature 77 → ALERT (10 min sustained)

Benefits:
  ✅ Reduces false positives
  ✅ Catches persistent issues
  ✅ Ignores temporary spikes
```

### Aggregation Triggers

```
Monitor aggregated metrics:

Functions:
  • Count events in time window
  • Average over period
  • Sum of values
  • Distinct count

Example:
  Trigger: High Error Volume
  When: Count of errors in last 15 minutes > 100
  Action: Page on-call engineer

  Aggregation query (background):
    Errors
    | where Timestamp > ago(15m)
    | where Level == "Error"
    | summarize ErrorCount = count()
    | where ErrorCount > 100

  Result: Proactive alerting before system degrades
```

## Actions Disponibles

### Email Notifications

```
Send email when triggered:

Configuration:
  Recipient: ops-team@company.com
  Subject: "High Temperature Alert: {{DeviceId}}"
  Body:
    "Device {{DeviceId}} at {{Location}}
     Current temperature: {{Temperature}}°C
     Threshold: 80°C
     Time: {{TriggerTime}}"

Variables:
  {{DeviceId}} - Object key
  {{Temperature}} - Property value
  {{Location}} - Object attribute
  {{TriggerTime}} - When triggered

Customization:
  ✅ Custom subject line
  ✅ Dynamic body content
  ✅ HTML formatting
  ✅ Include charts/data
```

### Teams Notifications

```
Post to Teams channel:

Configuration:
  Team: Operations
  Channel: Alerts
  Message:
    "🚨 **Alert: High Temperature**
     Device: {{DeviceId}}
     Location: {{Location}}
     Temperature: {{Temperature}}°C
     [View Dashboard](link)"

Features:
  ✅ Channel or DM
  ✅ Rich formatting (markdown)
  ✅ Include links
  ✅ @mention users
  ✅ Adaptive cards

Use case:
  Critical alerts to shared channel
  Team collaboration on issues
  Immediate visibility
```

### Power Automate Flows

```
Trigger complex workflows:

Connection:
  Data Activator trigger → Power Automate flow

Flow examples:

1. Create incident ticket
   Alert → Create ServiceNow incident
   Include: Device details, severity, time

2. Escalation workflow
   Alert → Wait 15 minutes
   If not acknowledged → Escalate to manager

3. Automated remediation
   High CPU → Run Azure Function
   Function restarts service
   Log action taken

4. Multi-channel notification
   Alert → Send email
         → Post to Teams
         → Create task in Planner
         → Log to SharePoint

Benefits:
  ✅ Complex logic
  ✅ Multi-step workflows
  ✅ Integration with 400+ connectors
  ✅ Conditional branching
```

### Custom Webhooks

```
HTTP POST to external service:

Configuration:
  URL: https://api.external.com/alerts
  Method: POST
  Headers:
    Content-Type: application/json
    Authorization: Bearer <token>
  Body:
    {
      "alert_type": "high_temperature",
      "device_id": "{{DeviceId}}",
      "value": {{Temperature}},
      "timestamp": "{{TriggerTime}}",
      "severity": "critical"
    }

Use cases:
  • Custom alert management system
  • Third-party monitoring integration
  • Slack (via webhook)
  • PagerDuty
  • Custom applications
```

## Scénarios d'Utilisation

### IoT Monitoring

```
Scenario: Factory equipment monitoring

Objects:
  Device (Machine)
    Key: MachineId

Properties:
  • Temperature (measure)
  • Vibration (measure)
  • OperationalStatus (state)
  • LastMaintenance (date)

Triggers:
1. High Temperature
   When: Temperature > 85°C
   Action: Teams alert to maintenance

2. High Vibration (possible failure)
   When: Vibration > 2.5 for 5+ minutes
   Action: Create maintenance ticket

3. Device Offline
   When: OperationalStatus = "Offline"
   Action: Email to operations manager

4. Maintenance Overdue
   When: DaysSinceLastMaintenance > 90
   Action: Schedule maintenance task
```

### E-commerce Operations

```
Scenario: Online store monitoring

Objects:
  Order
    Key: OrderId

Properties:
  • Amount (measure)
  • Status (state)
  • PaymentStatus (state)

Triggers:
1. Large Order Alert
   When: Amount > $10,000
   Action: Notify sales manager

2. Payment Failed
   When: PaymentStatus = "Failed"
   Action: Email customer support

3. Order Processing Delay
   When: Status = "Pending" for > 2 hours
   Action: Alert fulfillment team

Results:
  • Proactive customer service
  • Faster issue resolution
  • Revenue protection
```

### Security Monitoring

```
Scenario: Cybersecurity threat detection

Objects:
  SecurityEvent
    Key: EventId

Properties:
  • Severity (state)
  • AttackType (state)
  • SourceIP (dimension)
  • EventCount (measure)

Triggers:
1. Critical Security Event
   When: Severity = "Critical"
   Action: PagerDuty alert (immediate)

2. Brute Force Detection
   When: EventCount > 100 in 5 minutes from same SourceIP
   Action: Block IP + alert SOC

3. Unusual Access Pattern
   When: AccessTime outside normal hours AND Sensitive = true
   Action: Notify security team

4. Data Exfiltration
   When: DataTransferVolume > 1GB in 1 hour
   Action: Lock account + investigate
```

## Best Practices

### Alert Design

```
1. Avoid alert fatigue
   ❌ Too many alerts = ignored alerts
   ✅ Only critical, actionable alerts

2. Set appropriate thresholds
   ❌ Alert on every fluctuation
   ✅ Alert on meaningful deviations
   Use historical data to determine baselines

3. Include context
   ❌ "Temperature high"
   ✅ "Device sensor_001 at Factory_A: 85°C (threshold 80°C)"

4. Prioritize severity
   Critical: Immediate action required
   High: Action needed soon
   Medium: Investigate when possible
   Low: Informational

5. Define escalation paths
   Initial alert → Wait 15 min → Escalate if not acknowledged
```

### Trigger Optimization

```
1. Use sustained conditions
   ❌ Temperature > 80 (single moment)
   ✅ Temperature > 80 for 5+ minutes
   Reduces false positives from spikes

2. Combine conditions (AND/OR)
   Temperature > 80 AND Location = "Critical Zone"
   More specific, fewer unnecessary alerts

3. Set cool-down periods
   After alert triggers, wait X minutes before re-alerting
   Prevents alert flooding

4. Test thoroughly
   Use historical data to simulate triggers
   Verify expected behavior
   Check edge cases
```

### Action Configuration

```
1. Choose appropriate action type
   • Email: Non-urgent, detailed info
   • Teams: Team collaboration needed
   • Power Automate: Complex workflow
   • Webhook: System integration

2. Include actionable information
   What happened
   Where (which object)
   When (timestamp)
   What to do (link to runbook)

3. Route to right people
   Map triggers to responsible teams
   Use distribution lists for redundancy
   Consider time zones

4. Track and measure
   Alert volume over time
   Response times
   False positive rate
   Action effectiveness
```

## Monitoring et Gestion

### Reflex Status

```
Monitor your Reflex health:

Dashboard shows:
  • Active triggers count
  • Alerts sent (last 24h)
  • Data lag (source freshness)
  • Errors (failed actions)

Health indicators:
  ✅ Green: All healthy
  ⚠️ Yellow: Warnings present
  ❌ Red: Issues need attention

Common issues:
  • Data source disconnected
  • Action failed (email bounced)
  • Trigger not firing (check logic)
  • High alert volume (adjust thresholds)
```

### Alert History

```
Review past alerts:

View:
  • Timestamp
  • Trigger name
  • Object affected
  • Action taken
  • Outcome (success/failure)

Analysis:
  1. Alert frequency by trigger
     Which triggers fire most?
     Adjust thresholds if too noisy

  2. Alert patterns
     Time of day trends
     Seasonal patterns
     Root cause identification

  3. Action effectiveness
     Were actions successful?
     Response time improvements
     Business impact metrics
```

### Troubleshooting

```
Common problems and solutions:

1. Trigger not firing
   Check:
   • Data source connectivity
   • Condition logic (threshold values)
   • Object key matching
   • Property data type

2. Too many alerts
   Solution:
   • Increase thresholds
   • Add sustained duration
   • Use cool-down periods
   • Combine conditions

3. Action failing
   Check:
   • Authentication (tokens, credentials)
   • Network connectivity (webhooks)
   • Rate limits (email quotas)
   • Recipient availability

4. Data lag
   Check:
   • Source ingestion pipeline
   • EventStream health
   • KQL Database performance
   • Network issues
```

## Integration avec Fabric

### EventStream Connection

```
Direct connection to streaming data:

Setup:
1. Create Reflex
2. Add data source → EventStream
3. Select stream
4. Map fields to properties

Real-time monitoring:
  EventStream → Reflex → Action
  Latency: Seconds

Use case:
  Monitor streaming IoT data
  Alert on anomalies immediately
  No intermediate storage needed
```

### KQL Database Connection

```
Query-based monitoring:

Setup:
1. Create Reflex
2. Add data source → KQL Database
3. Write KQL query
4. Define objects from query results

Example query:
Telemetry
| where Timestamp > ago(5m)
| summarize AvgTemp = avg(Temperature) by DeviceId
| where AvgTemp > 75

Benefits:
  ✅ Complex aggregations
  ✅ Historical context
  ✅ Flexible queries
  ✅ Pre-computed metrics
```

### Power BI Integration

```
Alerts from report visuals:

Connection:
  Power BI visual → Set Alert → Reflex

Advantages:
  ✅ Business-friendly
  ✅ Leverages existing reports
  ✅ Visual context
  ✅ No query writing

Limitations:
  ⚠️ Tied to report refresh
  ⚠️ Not true real-time
  ⚠️ Limited trigger complexity
```

## Points Clés

- Data Activator = no-code real-time alerting in Fabric
- Reflex: Contains objects, properties, triggers, and actions
- Objects: Business entities with unique keys (Device, Customer, Order)
- Properties: Measures (numeric), states (categorical), dimensions (static)
- Trigger types: Threshold, change detection, patterns, aggregations
- Actions: Email, Teams, Power Automate, webhooks
- Best practices: Avoid alert fatigue, include context, test thoroughly
- Sustained conditions reduce false positives (e.g., > 5 minutes)
- Monitoring: Track alert history, analyze patterns, troubleshoot issues
- Integrations: EventStream (real-time), KQL Database (queries), Power BI (visuals)
- Key goal: Proactive monitoring with automated response

---

**Module 08 complet!** Vous maîtrisez maintenant l'analytics temps réel dans Fabric: EventStream, KQL Database, KQL queries, streaming ingestion, dashboards temps réel, et Data Activator.

[⬅️ Fichier précédent](./05-real-time-dashboards.md) | [⬅️ Retour au README du module](./README.md)
