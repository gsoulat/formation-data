# Real-Time Dashboards

## Introduction

**Real-Time Dashboards** dans Microsoft Fabric permettent de visualiser des données en temps réel avec rafraîchissement automatique, idéal pour le monitoring opérationnel.

```
Real-Time Dashboard Architecture:
┌─────────────┐   ┌──────────────┐   ┌──────────────┐
│ KQL Database│ → │ KQL Queries  │ → │  Dashboard   │
│  (Data)     │   │ (Analytics)  │   │  (Visual)    │
└─────────────┘   └──────────────┘   └──────────────┘
       ↑                                     ↓
  Streaming               Auto-refresh (seconds to minutes)
  Ingestion                   Live metrics
```

## Création de Dashboard

### Via Fabric Portal

```
Step-by-step:
1. Workspace → + New → Real-Time Dashboard
2. Name: "IoT Monitoring Dashboard"
3. Add tiles (visuals)
4. Write KQL queries
5. Configure refresh
6. Share with team

Dashboard canvas:
  ┌─────────────────────────────────────────┐
  │  [+ Add tile]  [Settings]  [Share]      │
  ├─────────────────────────────────────────┤
  │  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
  │  │ Tile 1  │  │ Tile 2  │  │ Tile 3  │ │
  │  │ (Card)  │  │ (Chart) │  │ (Table) │ │
  │  └─────────┘  └─────────┘  └─────────┘ │
  │  ┌──────────────────────┐  ┌─────────┐ │
  │  │     Tile 4           │  │ Tile 5  │ │
  │  │   (Time Chart)       │  │  (Map)  │ │
  │  └──────────────────────┘  └─────────┘ │
  └─────────────────────────────────────────┘
```

### Tile Configuration

```
Add new tile:
1. Click "+ Add tile"
2. Select data source (KQL Database)
3. Write KQL query
4. Choose visualization type
5. Format appearance
6. Set refresh interval

Tile properties:
  • Title: "Active Devices"
  • Query: KQL expression
  • Visual: Card, Chart, Table, Map
  • Size: Resizable on canvas
  • Refresh: 10 seconds - 1 hour
```

## Types de Visualisations

### Cards (KPIs)

```kql
// Single value card
Telemetry
| where Timestamp > ago(5m)
| summarize ActiveDevices = dcount(DeviceId)
| project ActiveDevices

// Result: 1,234
// Displayed as large number with label

// With trend indicator
Telemetry
| summarize
    Current = countif(Timestamp > ago(5m)),
    Previous = countif(Timestamp between (ago(10m) .. ago(5m)))
| extend Trend = Current - Previous
| project Current, Trend

// Shows: 1,234 (↑ 45)
```

### Time Charts

```kql
// Line chart over time
Telemetry
| where Timestamp > ago(1h)
| summarize AvgTemp = avg(Temperature) by bin(Timestamp, 1m)
| render timechart

// Configuration:
// X-axis: Timestamp
// Y-axis: AvgTemp
// Auto-refresh: Every minute
// Shows rolling 1-hour window

// Multi-series
Telemetry
| where Timestamp > ago(1h)
| summarize AvgTemp = avg(Temperature) by bin(Timestamp, 1m), Location
| render timechart

// Separate line per Location
// Legend: Factory_A, Factory_B, etc.
```

### Bar/Column Charts

```kql
// Top devices by temperature
Telemetry
| where Timestamp > ago(15m)
| summarize MaxTemp = max(Temperature) by DeviceId
| top 10 by MaxTemp desc
| render barchart

// Displays: Horizontal bars
// Sorted by temperature
// Quick identification of hot spots

// Stacked column chart
Logs
| where Timestamp > ago(1h)
| summarize Count = count() by Level, bin(Timestamp, 5m)
| render columnchart with (kind=stacked)

// Stack: Error, Warning, Info
// By time bucket
// Shows error distribution
```

### Tables

```kql
// Recent events table
Logs
| where Level == "Error"
| top 20 by Timestamp desc
| project Timestamp, Service, Message
| render table

// Interactive table:
// • Sortable columns
// • Scrollable
// • Click to drill down
// • Export to CSV

// Conditional formatting (via tile settings)
// Red: Level == "Error"
// Yellow: Level == "Warning"
// Green: Level == "Info"
```

### Maps

```kql
// Geographic visualization
Telemetry
| where Timestamp > ago(1h)
| summarize AvgTemp = avg(Temperature) by Location, Latitude, Longitude
| render scatterchart with (kind=map)

// Map features:
// • Bubble size: Value magnitude
// • Color: Heat map
// • Hover: Details
// • Zoom/Pan: Interactive

// Use case: Global IoT deployment monitoring
```

### Gauges

```kql
// Progress toward target
Metrics
| where MetricName == "CPU"
| summarize CurrentCPU = avg(Value)
| extend Target = 80, Min = 0, Max = 100
| project CurrentCPU, Target, Min, Max

// Gauge display:
// • Needle at CurrentCPU
// • Green zone: 0-60%
// • Yellow zone: 60-80%
// • Red zone: 80-100%
// • Target marker
```

## Parameters et Filtres

### Dashboard Parameters

```
Parameters = Global filters for entire dashboard

Example: Time range parameter
  Name: TimeRange
  Type: dropdown
  Values: [1h, 4h, 12h, 24h, 7d]
  Default: 1h

Usage in queries:
Telemetry
| where Timestamp > ago(TimeRange)
| summarize Count = count()

User interaction:
  • Select "24h" from dropdown
  • All tiles refresh with 24h data
  • Single control for whole dashboard
```

### Multiple Parameters

```
Complex filtering:

Parameter 1: TimeRange (dropdown)
  Values: 1h, 4h, 12h, 24h

Parameter 2: Location (multi-select)
  Values: Factory_A, Factory_B, Factory_C
  Default: All selected

Parameter 3: DeviceType (text)
  Free text input
  Filter by device pattern

Query using parameters:
Telemetry
| where Timestamp > ago(TimeRange)
| where Location in (Location_param)  // Multi-select
| where DeviceId contains DeviceType_param
| summarize AvgTemp = avg(Temperature) by Location
```

### Cross-Filtering

```
Click on one visual → Filter others

Example:
  1. Click "Factory_A" on bar chart
  2. Time chart filters to Factory_A only
  3. Table shows Factory_A events
  4. KPIs recalculate for Factory_A

Configuration:
  Enable cross-filter in dashboard settings
  Define which tiles interact
  Set filter behavior (include/exclude)

Benefits:
  ✅ Interactive exploration
  ✅ Drill-down capability
  ✅ Context-aware analysis
```

## Auto-Refresh Configuration

### Refresh Intervals

```
Per-tile refresh settings:

Options:
  • 10 seconds (near real-time)
  • 30 seconds
  • 1 minute
  • 5 minutes
  • 15 minutes
  • 30 minutes
  • 1 hour
  • Manual only

Considerations:
  • 10 seconds: High load on KQL Database
  • 1 minute: Good balance for monitoring
  • 5+ minutes: Cost-effective, less fresh

Recommendation:
  Critical KPIs: 10-30 seconds
  Trend charts: 1-5 minutes
  Historical tables: 15+ minutes
```

### Streaming Tiles

```
True streaming visualization:

Configuration:
  Tile type: Streaming
  Query: Continuous KQL
  Update: As data arrives (not polling)

Benefits:
  ✅ Sub-second latency
  ✅ No polling overhead
  ✅ True real-time

Limitations:
  ⚠️ Limited visual types
  ⚠️ Higher resource consumption
  ⚠️ Not all queries supported

Use for:
  • Critical alerts
  • Live counters
  • Heartbeat monitoring
```

### Performance Impact

```
Dashboard query load:

Example dashboard:
  • 10 tiles
  • 30-second refresh each
  • 100 users viewing

Queries per minute:
  10 tiles × 2 refreshes × 100 users = 2,000 queries/minute

Optimization:
  1. Increase refresh interval (60s instead of 30s)
     → 1,000 queries/minute (50% reduction)

  2. Cache common queries
     → Shared results for identical queries

  3. Stagger refresh times
     → Avoid thundering herd

  4. Optimize KQL queries
     → Faster execution, less load
```

## Design Best Practices

### Layout Principles

```
1. Most important metrics at top
   ┌──────────────────────────────┐
   │  KPI Cards (critical stats)  │
   ├──────────────────────────────┤
   │  Trend charts (patterns)     │
   ├──────────────────────────────┤
   │  Detail tables (drill-down)  │
   └──────────────────────────────┘

2. Left-to-right reading pattern
   ┌─────────┬─────────┬─────────┐
   │ Summary │ Details │ Actions │
   └─────────┴─────────┴─────────┘

3. Group related metrics
   ┌─────────────┬─────────────┐
   │   Device    │   Network   │
   │   Health    │   Status    │
   └─────────────┴─────────────┘
```

### Color Conventions

```
Semantic colors:
  ✅ Green: Good, normal, success
  ⚠️ Yellow/Orange: Warning, attention needed
  ❌ Red: Error, critical, failure
  🔵 Blue: Information, neutral

Consistency:
  • Same meaning across dashboard
  • Match organizational standards
  • Consider color blindness (use shapes too)

Example:
  Temperature normal: Green
  Temperature elevated: Yellow
  Temperature critical: Red
  Each also has icon: ✓, ⚠, ✗
```

### Tile Sizing

```
Size based on importance:

Critical KPI:
  ┌────────────────────┐
  │  ACTIVE DEVICES    │  Large tile
  │      1,234         │  Easy to see from distance
  └────────────────────┘

Supporting metric:
  ┌──────────┐
  │ Avg Temp │  Medium tile
  │  25.3°C  │  Secondary information
  └──────────┘

Detail data:
  ┌──────┐
  │ ...  │  Small tile
  └──────┘  For experts only

Grid alignment:
  Use dashboard grid system
  Consistent spacing
  Balanced layout
```

## Use Cases

### Operations Monitoring

```
Dashboard: Factory Operations

Tiles:
1. Active Machines (card)
   Count of devices reporting in last 5m

2. Average Temperature (gauge)
   Current vs threshold

3. Temperature by Zone (heatmap)
   Visual factory layout

4. Recent Alerts (table)
   Last 20 critical events

5. Hourly Production (line chart)
   Units produced over time

6. Equipment Health (stacked bar)
   Status distribution

Refresh: 30 seconds
Users: Operations team, floor managers
Purpose: Real-time factory monitoring
```

### Security Operations Center

```
Dashboard: SOC Monitoring

Tiles:
1. Threat Level (gauge)
   Overall security posture

2. Events by Severity (pie chart)
   Critical, High, Medium, Low

3. Geographic Attack Map (map)
   Source of suspicious activity

4. Top Attackers (bar chart)
   IP addresses with most attempts

5. Event Timeline (line chart)
   Security events over time

6. Recent Incidents (table)
   Actionable security events

Refresh: 10 seconds (critical)
Users: Security analysts
Purpose: Threat detection and response
```

### Business Analytics

```
Dashboard: Sales Performance

Tiles:
1. Revenue Today (card)
   Real-time sales total

2. Orders per Hour (line chart)
   Transaction velocity

3. Top Products (bar chart)
   Best sellers

4. Geographic Sales (map)
   Revenue by region

5. Customer Segment (donut chart)
   Enterprise vs SMB vs Consumer

6. Recent Large Orders (table)
   High-value transactions

Refresh: 1 minute
Users: Sales leadership
Purpose: Revenue monitoring
```

## Sharing et Collaboration

### Access Control

```
Permission levels:

1. Viewer
   • View dashboard
   • Interact with filters
   • Cannot edit

2. Contributor
   • View and edit tiles
   • Modify queries
   • Cannot share

3. Admin
   • Full control
   • Share with others
   • Delete dashboard

Assignment:
  Dashboard → Share → Add users/groups
  Select permission level
  Optionally add message
```

### Embedding

```
Embed dashboard in:
  • SharePoint pages
  • Teams channels
  • Web applications
  • Internal portals

Configuration:
1. Dashboard settings → Embed
2. Copy embed code (iframe)
3. Paste in target application
4. Configure size and permissions

Security:
  • Users must authenticate
  • Respects RLS (Row-Level Security)
  • Audit trail maintained
```

### Alerts Integration

```
Connect dashboard to alerts:

Workflow:
  Dashboard visual
    ↓
  Monitor condition (value > threshold)
    ↓
  Trigger alert (Data Activator)
    ↓
  Notify (Teams, Email, Power Automate)

Example:
  Card showing "Error Rate"
  When > 5%: Send Teams message to ops channel
  Include link to dashboard for investigation

Benefits:
  ✅ Proactive monitoring
  ✅ Reduce dashboard watching
  ✅ Automated escalation
```

## Advanced Features

### Drillthrough

```
Click tile → Open detailed view

Configuration:
  1. Create detail dashboard/page
  2. Enable drillthrough on source tile
  3. Pass context (DeviceId, TimeRange)
  4. Detail view filters automatically

Example:
  Main dashboard: All devices overview
  Click device row
  Drillthrough: Single device details
    • Device history
    • Sensor readings
    • Maintenance log
    • Anomaly timeline
```

### Annotations

```
Add context to dashboards:

Types:
  • Text boxes: Explain metrics
  • Thresholds: Visual markers
  • Goals: Target lines
  • Notes: Important information

Example:
  Revenue chart with:
    • Target line at $100K
    • Annotation: "New product launch"
    • Note: "Data refresh at 8 AM UTC"

Benefits:
  ✅ Self-documenting
  ✅ Context for viewers
  ✅ Historical markers
```

### Mobile View

```
Responsive dashboard design:

Desktop view:
  ┌─────┬─────┬─────┐
  │  A  │  B  │  C  │
  ├─────┴─────┴─────┤
  │       D         │
  └─────────────────┘

Mobile view (auto-adjusted):
  ┌─────┐
  │  A  │
  ├─────┤
  │  B  │
  ├─────┤
  │  C  │
  ├─────┤
  │  D  │
  └─────┘

Configuration:
  Dashboard settings → Mobile layout
  Prioritize important tiles
  Simplify complex visuals
  Test on actual device
```

## Troubleshooting

### Common Issues

```
1. Slow tile refresh
   Cause: Complex KQL query
   Solution: Optimize query, add aggregations

2. No data displayed
   Cause: Time range mismatch
   Solution: Check TimeRange parameter vs data availability

3. High database load
   Cause: Too many tiles, fast refresh
   Solution: Increase intervals, cache queries

4. Permissions error
   Cause: RLS blocking data
   Solution: Verify user roles, check RLS rules

5. Stale data
   Cause: Ingestion pipeline issue
   Solution: Check EventStream, verify ingestion
```

### Performance Monitoring

```
Dashboard health metrics:

Track:
  • Query execution time
  • Tile render time
  • User interaction latency
  • Error rate

Analysis:
  View dashboard performance tab
  Identify slowest tiles
  Optimize queries
  Consider caching

Target:
  • Tile load: < 3 seconds
  • Full dashboard: < 10 seconds
  • Interaction response: < 500ms
```

## Points Clés

- Real-Time Dashboards visualize live data with automatic refresh
- Tile types: Cards (KPIs), charts, tables, maps, gauges
- Parameters enable global filtering across all tiles
- Auto-refresh: Balance freshness vs query load (10s to 1hr)
- Design: Important metrics at top, semantic colors, proper sizing
- Sharing: Viewer/Contributor/Admin permissions, embedding options
- Advanced: Drillthrough, annotations, mobile-responsive
- Use cases: Operations monitoring, security SOC, business analytics
- Performance: Optimize queries, stagger refresh, monitor load
- Best practice: Right-size refresh intervals per tile importance

---

**Prochain fichier :** [06 - Data Activator & Alerts](./06-activator-alerts.md)

[⬅️ Fichier précédent](./04-streaming-ingestion.md) | [⬅️ Retour au README du module](./README.md)
