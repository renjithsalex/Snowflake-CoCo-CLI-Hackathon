# OEE Command Center — Predictive Maintenance & Manufacturing Intelligence

> A real-time manufacturing operations platform built entirely on Snowflake — combining IoT sensor monitoring, machine-learning predictions, OEE analytics, and AI-powered chat into a single Streamlit application with zero external infrastructure.

![Snowflake](https://img.shields.io/badge/Platform-Snowflake-29B5E8?logo=snowflake&logoColor=white)
![Streamlit](https://img.shields.io/badge/UI-Streamlit-FF4B4B?logo=streamlit&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Table of Contents

1. [Problem & Solution](#problem--solution)
2. [Key Capabilities](#key-capabilities)
3. [Who Uses It](#who-uses-it)
4. [Key Terms Explained](#key-terms-explained)
5. [Business Value at a Glance](#business-value-at-a-glance)
6. [Architecture](#architecture)
7. [Schema Design](#schema-design)
8. [Application Pages](#application-pages)
9. [Machine Learning Models](#machine-learning-models)
10. [KPIs Tracked](#kpis-tracked)
11. [Snowflake Features Used](#snowflake-features-used)
12. [Data Pipeline](#data-pipeline)
13. [Simulated Factory Profile](#simulated-factory-profile)
14. [Project Structure](#project-structure)
15. [Deployment & Migration](#deployment--migration)
16. [Complete Snowflake Object Reference](#complete-snowflake-object-reference)
17. [Technologies](#technologies)
18. [Glossary](#glossary)

---

## Problem & Solution

### The Problem

Manufacturing plants lose **15–40% of potential production capacity** to equipment breakdowns, slow-running machines, and quality defects. Most factories still rely on:

- **Reactive maintenance** — "fix it when it breaks," the most expensive approach (3–9x more per repair than planned work).
- **Calendar-based preventive maintenance** — "replace every 6 months," wasting 30–50% of component useful life.
- **Manual spreadsheet reporting** — decisions based on yesterday's data, not real-time conditions.

### The Solution

The **OEE Command Center** monitors **60 machines across 3 plants in real time**, predicts failures **24–48 hours in advance**, and puts live analytics at every operator's fingertips — all running natively inside Snowflake.

> **Estimated business value for a mid-size manufacturer ($50M revenue): $2–5M in annual savings.**

---

## Key Capabilities

| Capability | How It Works | Business Impact |
|---|---|---|
| Real-time machine monitoring | 5 sensors per machine, updated every 15 min | Eliminates manual inspection walks (saves 2+ hrs/day) |
| Failure prediction (ML) | XGBoost predicts breakdown probability 24 hrs ahead | 70–75% fewer unplanned breakdowns |
| Anomaly detection (ML) | Isolation Forest / Snowflake ML catches unusual sensor patterns | Detects novel failure modes that rules miss |
| Remaining useful life | Linear regression estimates hours until maintenance | Run components to 90% life instead of 50% (calendar) |
| OEE tracking | Availability × Performance × Quality per line per day | 1% OEE improvement = $500K/year on a $50M plant |
| Downtime Pareto analysis | Ranks causes of lost production time | Focus on top 2–3 causes for 80% of the impact |
| Automated alerts & work orders | AI generates alerts and pre-fills repair orders | Eliminates 3–24 hr delay between detection and action |
| AI chat (Cortex Complete) | Ask questions in plain English about live plant data | Self-service analytics for non-technical staff |
| Cortex Agent | Combines data queries + maintenance doc search | "What's wrong with CNC-001 and how do I fix it?" |

---

## Who Uses It

| User Role | What They Use It For |
|---|---|
| **Plant Manager** | View overall plant health, OEE trends, and cost impact |
| **Maintenance Engineer** | Check which machines need attention and review AI predictions |
| **Operations Manager** | Analyze downtime causes and compare production-line performance |
| **Reliability Engineer** | Deep-dive into Asset 360 profiles and MTBF/MTTR analysis |
| **Shift Supervisor / Operator** | Ask the AI Assistant plain-English questions about live conditions |

---

## Key Terms Explained

| Term | Simple Explanation |
|---|---|
| **OEE** | Overall Equipment Effectiveness — a 0–100% score of how well a factory runs. World-class is 85%+ |
| **Availability** | How much of planned time the machine actually runs (vs being down for repairs) |
| **Performance** | How fast the machine runs compared to its ideal speed |
| **Quality** | What percentage of products made are good (not defective) |
| **MTBF** | Mean Time Between Failures — average hours a machine runs before breaking |
| **MTTR** | Mean Time To Repair — average hours to fix a machine after it breaks |
| **RUL** | Remaining Useful Life — predicted hours until a machine needs maintenance |
| **Anomaly** | An unusual pattern in sensor data that may indicate a developing problem |
| **Dynamic Table** | A Snowflake feature that automatically keeps summary data up-to-date |

> A full technical glossary is available at the [end of this document](#glossary).

---

## Business Value at a Glance

| Category | Traditional Approach | With OEE Command Center | Business Value |
|---|---|---|---|
| **Failure Detection** | Found after breakdown | Predicted 24–48 hrs early | 70–75% fewer breakdowns |
| **Maintenance Cost** | $100 (reactive) | $30–40 (predictive) | 25–30% cost reduction |
| **Downtime** | 4+ hrs per event | <1 hr (planned repair) | 35–45% less downtime |
| **Component Life** | Replaced at 50% life (calendar) | Replaced at 90% life (condition) | 60% more component life |
| **Diagnostics** | 1–2 hrs (manual) | Seconds (AI-powered) | MTTR reduced by up to 40% |
| **Reporting** | Daily/weekly manual reports | Real-time dashboard + AI chat | Decisions in seconds, not hours |
| **Spare Parts** | Overstock or emergency orders | Just-in-time based on RUL | 20–30% inventory reduction |
| **Staffing** | Walking the floor checking machines | Exception-based (alerts only) | 2+ hrs/day freed per team |

> **Bottom line:** For a mid-size manufacturer ($50M revenue), predictive maintenance and OEE tracking typically deliver **$2–5M in annual savings** through reduced downtime, lower maintenance costs, extended equipment life, and better production planning.

---

## Architecture

Everything runs inside Snowflake — no external servers, databases, ML platforms, or API services needed.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SNOWFLAKE PLATFORM (MFG_PDM_DB)                 │
│                                                                     │
│  ┌──────────┐   ┌──────────────┐   ┌──────────────┐   ┌─────────┐ │
│  │   RAW    │──>│   CURATED    │──>│   ML + AI    │──>│   OPS   │ │
│  │          │   │              │   │              │   │         │ │
│  │ Sensors  │   │  Dynamic     │   │  ML Scoring  │   │ Alerts  │ │
│  │ Assets   │   │  Tables      │   │  Cortex AI   │   │ Work    │ │
│  │ Logs     │   │  (auto-      │   │  Semantic    │   │ Orders  │ │
│  │          │   │   refresh)   │   │  View/Search │   │         │ │
│  └──────────┘   └──────────────┘   └──────────────┘   └────┬────┘ │
│                                                             │      │
│          ┌──────────────────────────────────────────────────┘      │
│          v                                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │   APP Schema: Streamlit Dashboard (7 tabs + AI Chat)        │  │
│  │   Snowpark SQL ──> Pandas ──> Altair charts & tables        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  AUTOMATION: 3 chained Tasks                                       │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ Stream Sensors  │─>│  ML Scoring  │─>│ Alert Triage + WOs   │   │
│  └────────────────┘  └──────────────┘  └──────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Schema Design

The database `MFG_PDM_DB` is organized into **6 schemas**, each with a clear responsibility so changes in one layer never ripple into another.

| Schema | Role | Contents |
|---|---|---|
| **RAW** | Source of truth — never modified after insert | Sensor readings, asset registry, plants, lines, production orders, downtime & failure events, work-order history, spare parts |
| **CURATED** | Auto-refreshing summaries via Dynamic Tables | DT_SENSOR_CLEAN, DT_SENSOR_FEATURES_15M, DT_ASSET_HEALTH, DT_OEE_SHIFT, DT_OEE_LINE_DAILY, DT_OEE_PLANT_DAILY, DT_ASSET_360, DT_DOWNTIME_PARETO |
| **ML** | Model training & scoring — isolated from raw data | Anomaly-detection model (`AD_VIBRATION`), feature/score tables, scoring procedure, scoring task |
| **AI** | Intelligence layer for natural-language access | Semantic View, Cortex Search service, Cortex Agent |
| **OPS** | Operational actions — auditable independently | Alert history, work-order drafts, triage procedures, config, triage task, critical-asset alert |
| **APP** | Presentation layer | Streamlit app (`OEE_COMMAND_CENTER`) |

---

## Application Pages

The Streamlit app has **7 interactive tabs**, each serving a specific operational role.

### 1. Executive Overview
**For:** Plant managers and executives. Plant-level KPI summary (OEE, Availability, Performance, Quality, assets at risk, critical alerts), OEE trend chart by plant with an 85% world-class target line, fleet-health donut, and OEE-loss heatmap by line. A 10-second health check of the entire operation.

### 2. Asset Health
**For:** Maintenance engineers. Filterable fleet view of all 60 assets with heat-map tiles colored by health status, a risk matrix (vibration % vs failure probability, bubble size = downtime cost), and a detail table with health score, sensor readings, and ML predictions. "Which machines need attention today and why?"

### 3. Downtime Analysis
**For:** Continuous-improvement teams. Pareto chart ranking unplanned downtime by reason code with a cumulative-percentage line, a line × reason heatmap, planned-vs-unplanned split, and a full data table with CSV export. "Where should we focus improvement resources?"

### 4. Asset 360
**For:** Reliability engineers. Per-asset deep dive — health score, failure probability, RUL, MTBF, MTTR, downtime cost — plus 7-day vibration and temperature trend charts with limit lines, alert history, and maintenance stats. The complete biography of a machine.

### 5. Anomaly Monitor
**For:** Condition-monitoring analysts. ML anomaly-detection results: total readings scored, anomaly count and rate, affected assets, anomalies-by-asset bar chart, and actual-vs-forecast time series with a 99% prediction interval and anomaly markers.

### 6. Alerts & Work Orders
**For:** Maintenance supervisors. Alert timeline scatter plot by asset and severity, filterable alert cards with severity badges, and auto-generated work-order drafts with priority, description, and recommended actions. Review, approve, or reject — eliminating the 3–24 hr detection-to-action delay.

### 7. AI Assistant
**For:** Anyone. Natural-language Q&A powered by Snowflake Cortex Complete (Claude Sonnet), fed live data from all curated tables as context. Example questions: *"Which assets should I prioritize today?"*, *"What is causing most unplanned downtime?"* Runs entirely inside Snowflake — data never leaves the platform.

---

## Machine Learning Models

| Model | Algorithm | Purpose | Input | Output | Threshold |
|---|---|---|---|---|---|
| Anomaly Detection | Isolation Forest / Snowflake ML (`AD_VIBRATION`) | Detect unusual sensor patterns | 5 normalized sensor values | ANOMALY_SCORE (0.0–1.0) | > 0.8 → alert |
| Failure Prediction | XGBoost | Predict failure within 24 hours | 11 features (sensors + trends + threshold proximity + age) | FAILURE_PROB (0.0–1.0) | > 0.6 → PdM work order |
| Remaining Useful Life | Linear Regression | Estimate hours until maintenance | Degradation rate + distance from threshold | RUL_HOURS | < 48h → warning, < 12h → critical |

**Conversational AI**

- **Cortex Complete** — Claude Sonnet via `SNOWFLAKE.CORTEX.COMPLETE()` powers the AI Assistant tab with live-data context.
- **Cortex Agent (`PDM_COMMAND_CENTER`)** — combines `PDM_OEE_ANALYTICS` (Cortex Analyst → English-to-SQL) with `MAINT_DOCS_SEARCH` (vector search over 40 maintenance docs) for root-cause investigation in Snowflake Intelligence.

---

## KPIs Tracked

### OEE Components
- **OEE** = Availability × Performance × Quality (world-class benchmark: **85%+**)
- **Availability** — % of planned time the machine is running
- **Performance** — actual speed vs theoretical max
- **Quality** — good units / total units produced

### Predictive Maintenance
- **Health Score** (0–100) — composite of 50% rule-based + 50% ML
- **Failure Probability** (0.0–1.0) — XGBoost 24-hour prediction
- **RUL** (hours) — estimated remaining useful life
- **Anomaly Score** (0.0–1.0) — Isolation Forest unusualness measure

### Reliability Engineering
- **MTBF** — Mean Time Between Failures (30-day)
- **MTTR** — Mean Time To Repair (30-day)
- **Downtime Cost** — financial impact per asset (30-day)
- **Failure Count** — events per asset (30-day)

### Downtime Analysis
- **Downtime by Reason Code** — Pareto-ranked causes of lost time
- **Planned vs Unplanned Split** — maintenance-maturity indicator (world-class: >80% planned)

---

## Snowflake Features Used

| Feature | How It's Used | Without It, You'd Need |
|---|---|---|
| **Dynamic Tables** | Auto-refreshing health, OEE, asset-360, and downtime summaries — zero ETL code | Airflow + custom DAGs + failure handling |
| **Streams** | Change tracking on `SENSOR_READINGS` triggers Dynamic Table refreshes | Full-table scans or custom CDC logic |
| **Tasks** | 3 chained tasks (data generation → ML scoring → alert triage) | External cron / Airflow scheduler |
| **Stored Procedures** | Python ML scoring (scikit-learn, XGBoost) runs where the data lives | External ML platform + data export/import |
| **Snowflake ML** | `AD_VIBRATION` anomaly-detection model | Separate ML infrastructure |
| **Cortex Complete** | LLM-powered chat (Claude Sonnet) via `SNOWFLAKE.CORTEX.COMPLETE()` | OpenAI API + key management + data-egress risk |
| **Cortex Agent** | Multi-tool AI assistant (Analyst + Search) for Snowflake Intelligence | Custom RAG pipeline + orchestration |
| **Semantic View** | Business metadata enabling English-to-SQL via Cortex Analyst | Manual SQL or custom NL2SQL system |
| **Cortex Search** | Vector search over 40 maintenance documents | Elasticsearch/Pinecone + embedding pipeline |
| **Streamlit in Snowflake** | Native dashboard hosting with built-in auth — no external infra | Cloud web server + auth + CI/CD |
| **Alerts** | Email notifications when CRITICAL assets detected | PagerDuty or similar monitoring tool |
| **Warehouses** | Auto-scaling compute with auto-suspend for cost efficiency | Dedicated always-on compute |

---

## Data Pipeline

```
Every cycle:
  1. TASK_STREAM_SENSORS  → SP_GENERATE_SENSOR_BATCH (new sensor readings)
  2. Streams detect new rows → Dynamic Tables auto-refresh
        (DT_SENSOR_CLEAN, DT_SENSOR_FEATURES_15M, DT_ASSET_HEALTH,
         DT_OEE_*, DT_ASSET_360, DT_DOWNTIME_PARETO)
  3. TASK_SCORE_ALL       → Anomaly + Failure + RUL scoring
  4. TASK_TRIAGE_PIPELINE → Alert generation + Work-order drafts
  5. User opens app       → Snowpark SQL → Pandas → Altair charts
        (cached @st.cache_data(ttl=300) for 5-minute freshness)
```

---

## Simulated Factory Profile

| Dimension | Value |
|---|---|
| Plants | 3 (Pune, Bangkok, Penang) |
| Production Lines | 8 (LN-01 through LN-08) |
| Assets | 60 (CNC, Robot, Conveyor, Pump, Compressor, Press) |
| Sensors per Asset | 5 (vibration, temperature, RPM, pressure, power) |
| Reading Frequency | Every 15 minutes |
| Historical Depth | 90 days (~1.7M sensor readings) |
| Criticality Levels | A (high), B (medium), C (low) |
| Maintenance Docs | 40 (indexed for Cortex Search) |

---

## Project Structure

```
migration_repo/
├── sql/
│   ├── 01_setup.sql                   # Database, schemas, warehouse, resource monitor
│   ├── 02_raw_tables.sql              # All RAW schema table DDLs
│   ├── 03_raw_data.sql                # Reference data INSERTs (plants, assets, failures, spare parts)
│   ├── 03b_export_import.sql          # Export/import for medium tables (prod orders, work orders, etc.)
│   ├── 04_curated_dynamic_tables.sql  # All 8 dynamic tables (in dependency order)
│   ├── 05_ml_objects.sql              # ML tables, views, anomaly model, scoring SP
│   ├── 06_ops_objects.sql             # OPS tables, alert/WO procedures, tasks, alerts
│   ├── 07_ai_objects.sql              # Cortex Search service, Semantic View
│   ├── 08_stored_procs_data_gen.sql   # Sensor data generation SPs (history + live stream)
│   ├── 09_streamlit_app.sql           # Streamlit app deployment
│   └── 10_activate.sql                # Generate data, train model, resume tasks
├── streamlit_app/
│   ├── streamlit_app.py               # Main Streamlit application (7 tabs)
│   └── pyproject.toml                 # Python dependencies
└── nextjs_app/                        # Optional Next.js SPCS application
    ├── app.yml                        # SPCS service spec
    ├── package.json
    ├── next.config.mjs
    ├── postcss.config.mjs
    └── src/
        ├── app/                       # Pages and API routes
        ├── components/                # React components
        └── lib/                       # Snowflake connection lib
```

---

## Deployment & Migration

### Target Account
- **Account:** `im97417` (ap-southeast-7.aws)
- **URL:** https://app.snowflake.com/ap-southeast-7.aws/im97417/

### Prerequisites
- Snowflake account with `ACCOUNTADMIN` role
- Database `MFG_PDM_DB` with schemas: RAW, CURATED, ML, OPS, AI, APP
- Warehouse `MFG_PDM_WH` (X-Small) with a resource monitor (150 credits/month)
- Compute Pool `SYSTEM_COMPUTE_POOL_CPU` (for Streamlit in Snowflake)

### Step 1 — Push to source control
```bash
cd migration_repo
git init
git add .
git commit -m "OEE Command Center migration package"
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

### Step 2 — Run SQL scripts in order (in the TARGET account)
Connect to the target account and execute the scripts sequentially:

```
01_setup.sql                   → Creates database, schemas, warehouse, resource monitor
02_raw_tables.sql              → Creates all RAW tables
03_raw_data.sql                → Inserts reference data (plants, assets, failures, spare parts, config)
03b_export_import.sql          → PART 1 in SOURCE, PART 2 in TARGET (prod orders, work orders, etc.)
04_curated_dynamic_tables.sql  → Creates all dynamic tables
05_ml_objects.sql              → Creates ML tables, views, model
06_ops_objects.sql             → Creates OPS tables, procedures, tasks, alert
07_ai_objects.sql              → Creates Cortex Search + Semantic View
08_stored_procs_data_gen.sql   → Creates data generation stored procedures
09_streamlit_app.sql           → Deploys Streamlit app (after uploading files)
10_activate.sql                → Generates historical data, trains model, resumes tasks
```

### Step 3 — Transfer medium-sized table data
Run **Part 1** of `03b_export_import.sql` in the **source** account to export:
`PRODUCTION_ORDERS` (2,160 rows), `DOWNTIME_EVENTS` (261 rows), `WORK_ORDERS_HIST` (306 rows), `MAINT_DOCS` (40 rows). Download the CSVs, then upload and run **Part 2** in the **target** account.

### Step 4 — Upload Streamlit app files
```sql
CREATE STAGE IF NOT EXISTS MFG_PDM_DB.APP.OEE_APP_STAGE;

PUT file:///path/to/streamlit_app/streamlit_app.py @MFG_PDM_DB.APP.OEE_APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file:///path/to/streamlit_app/pyproject.toml   @MFG_PDM_DB.APP.OEE_APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

CREATE STREAMLIT MFG_PDM_DB.APP.OEE_COMMAND_CENTER
  ROOT_LOCATION = '@MFG_PDM_DB.APP.OEE_APP_STAGE'
  MAIN_FILE     = 'streamlit_app.py'
  QUERY_WAREHOUSE = MFG_PDM_WH
  COMPUTE_POOL  = SYSTEM_COMPUTE_POOL_CPU
  TITLE         = 'OEE Command Center';
```

### Step 5 — Generate data and activate
Run `10_activate.sql`, which:
1. Calls `SP_GENERATE_SENSOR_HISTORY()` to generate 90 days of synthetic sensor data (~1.7M rows; ~20–30 min on an XS warehouse).
2. Waits for dynamic tables to refresh.
3. Trains the anomaly-detection model.
4. Runs initial ML scoring and alert triage.
5. Resumes all scheduled tasks:

```sql
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS   RESUME;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL          RESUME;
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE   RESUME;
```

### Step 6 — Verify
```sql
-- Row counts
SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT
FROM MFG_PDM_DB.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA != 'INFORMATION_SCHEMA'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

SHOW DYNAMIC TABLES IN DATABASE MFG_PDM_DB;   -- Dynamic table status
SHOW TASKS IN DATABASE MFG_PDM_DB;            -- Tasks running
-- Then open: Streamlit > OEE Command Center
```

### Data Volume & Credits

| Table | Rows | Notes |
|---|---|---|
| SENSOR_READINGS | ~1,758,000 | Generated via SP_GENERATE_SENSOR_HISTORY |
| DT_SENSOR_CLEAN | ~1,756,000 | Dynamic table (auto-refreshed) |
| DT_SENSOR_FEATURES_15M | ~532,000 | Dynamic table (auto-refreshed) |
| PRODUCTION_ORDERS | 2,160 | Exported via CSV |
| WORK_ORDERS_HIST | 306 | Exported via CSV |
| DOWNTIME_EVENTS | 261 | Exported via CSV |
| All other tables | < 100 rows each | Inserted via SQL |

- **Warehouse:** `MFG_PDM_WH` (X-Small), resource monitor at 150 credits/month.
- **Initial data generation:** ~5–10 credits.
- **Ongoing:** ~2–3 credits/day (sensor streaming + DT refreshes + ML scoring).

---

## Complete Snowflake Object Reference

### RAW Schema
| Object | Type | Description |
|---|---|---|
| SENSOR_READINGS | Table | Time-series IoT sensor data (~1.7M rows) |
| ASSETS | Table | 60 assets with metadata, thresholds, cost rates |
| PLANTS | Table | 3 manufacturing plants |
| PRODUCTION_LINES | Table | 8 production lines |
| PRODUCTION_ORDERS | Table | ERP production orders per line per shift |
| DOWNTIME_EVENTS | Table | Stop events with reason code and duration |
| FAILURE_EVENTS | Table | Ground-truth failure events for ML training |
| WORK_ORDERS_HIST | Table | Historical maintenance work orders |
| SPARE_PARTS | Table | Spare-parts inventory with reorder points |
| MAINT_DOCS | Table | 40 maintenance documents for search indexing |
| SP_GENERATE_SENSOR_BATCH | Procedure | Generates new sensor readings per cycle |
| SP_GENERATE_SENSOR_HISTORY | Procedure | One-time: 90 days of historical data |
| SP_INJECT_DEGRADATION | Procedure | Simulate equipment degradation for testing |
| TASK_STREAM_SENSORS | Task | Live sensor data generation |

### CURATED Schema
| Object | Type | Description |
|---|---|---|
| DT_SENSOR_CLEAN | Dynamic Table | Deduped, cleaned sensor readings |
| DT_SENSOR_FEATURES_15M | Dynamic Table | 15-min aggregated sensor features |
| DT_ASSET_HEALTH | Dynamic Table | Per-asset health with rule + ML scores |
| DT_OEE_SHIFT | Dynamic Table | OEE per line per shift |
| DT_OEE_LINE_DAILY | Dynamic Table | Daily OEE per production line |
| DT_OEE_PLANT_DAILY | Dynamic Table | Daily OEE per plant |
| DT_ASSET_360 | Dynamic Table | 30-day asset profile (MTBF, MTTR, costs) |
| DT_DOWNTIME_PARETO | Dynamic Table | Downtime by reason code |

### ML Schema
| Object | Type | Description |
|---|---|---|
| AD_VIBRATION | Model | Snowflake ML anomaly-detection model |
| SP_SCORE_ALL | Procedure | Runs all ML scoring (anomaly + failure + RUL) |
| TASK_SCORE_ALL | Task | 15-min ML scoring schedule |

### AI Schema
| Object | Type | Description |
|---|---|---|
| PDM_OEE_ANALYTICS | Semantic View | 4 tables, 5 verified queries for Cortex Analyst |
| MAINT_DOCS_SEARCH | Cortex Search | Vector search over 40 maintenance documents |
| PDM_COMMAND_CENTER | Cortex Agent | Analyst + Search tools combined |

### OPS Schema
| Object | Type | Description |
|---|---|---|
| ALERT_HISTORY | Table | Generated alerts with severity |
| WORK_ORDER_DRAFTS | Table | Auto-generated PdM work orders |
| CONFIG | Table | Operational configuration |
| SP_TRIAGE_ALERTS | Procedure | Generates alerts from health/ML scores |
| SP_GENERATE_WO_DRAFTS | Procedure | Creates work-order drafts |
| TASK_TRIAGE_PIPELINE | Task | 15-min triage + work-order generation |
| ALERT_CRITICAL_ASSETS | Alert | Email notification when CRITICAL assets detected |

### APP Schema
| Object | Type | Description |
|---|---|---|
| OEE_COMMAND_CENTER | Streamlit App | 7-tab dashboard with AI chat |

---

## Technologies

- **Snowflake** — Cloud data platform (compute, storage, ML, AI)
- **Streamlit** — Interactive Python dashboard framework
- **Snowpark** — Native Python API for Snowflake
- **Altair** — Declarative statistical visualization
- **Pandas** — Data manipulation and analysis
- **Cortex AI** — LLM (Claude Sonnet), Semantic Views, Search, Agents
- **scikit-learn** — Isolation Forest anomaly detection
- **XGBoost** — Gradient-boosted failure prediction
- **Next.js** (optional) — React SPCS front-end alternative

---

## Glossary

| Term | Definition |
|---|---|
| **OEE** | Overall Equipment Effectiveness = Availability × Performance × Quality |
| **Availability** | % of planned time the machine is running |
| **Performance** | Actual speed / ideal speed |
| **Quality** | Good units / total units produced |
| **MTBF** | Mean Time Between Failures — average uptime between breakdowns |
| **MTTR** | Mean Time To Repair — average fix time |
| **RUL** | Remaining Useful Life — predicted hours until maintenance |
| **Health Score** | 0–100 composite (rule-based + ML) |
| **Failure Probability** | 0–1 chance of failure in the next 24 hours |
| **Anomaly Score** | 0–1 measure of how unusual current readings are |
| **Dynamic Table** | Snowflake table that auto-refreshes when its source changes |
| **Stream** | Snowflake change tracker on a table |
| **Cortex Complete** | Snowflake function to call LLMs from SQL |
| **Cortex Agent** | Multi-tool AI assistant in Snowflake |
| **Semantic View** | Metadata layer enabling English-to-SQL conversion |
| **Cortex Search** | Vector-based document search in Snowflake |
| **Snowpark** | Snowflake's native Python API |
| **Pareto Analysis** | 80/20 rule: find the few causes behind most problems |
| **Isolation Forest** | ML algorithm detecting anomalies by isolation ease |
| **XGBoost** | ML algorithm using an ensemble of decision trees |
| **TPM** | Total Productive Maintenance — the methodology behind OEE |

---

