# Complete Object Reference & Documentation

Every Snowflake object used by the OEE Command Center, organized by category.

---

## 1. Database & Schemas

| Object | Type | Description |
|---|---|---|
| `MFG_PDM_DB` | Database | Central database for all manufacturing data, ML, and operations |
| `MFG_PDM_DB.RAW` | Schema | Raw ingestion layer: IoT sensors, ERP, CMMS data. Source of truth. |
| `MFG_PDM_DB.CURATED` | Schema | Auto-refreshing summaries via 8 Dynamic Tables |
| `MFG_PDM_DB.AI` | Schema | Cortex Agent, Semantic View, Cortex Search services |
| `MFG_PDM_DB.ML` | Schema | ML scoring tables, training views, scoring procedures |
| `MFG_PDM_DB.OPS` | Schema | Alert history, work order drafts, triage automation |
| `MFG_PDM_DB.APP` | Schema | Streamlit app deployment and stage |

**DDL:** [`ddl/01_database/create_database.sql`](ddl/01_database/create_database.sql)

---

## 2. Tables (RAW Schema — 11 tables)

| Table | Rows | Purpose | Used By |
|---|---|---|---|
| `SENSOR_READINGS` | ~9.3M | IoT time-series: 5 sensors × 60 assets × 90 days | DT_SENSOR_CLEAN, DT_SENSOR_FEATURES_15M |
| `ASSETS` | 60 | Machine master data: type, thresholds, cost rates | All Dynamic Tables, ML scoring |
| `PLANTS` | 3 | Plant master data: name, country, timezone | DT_OEE_SHIFT, DT_OEE_PLANT_DAILY |
| `PRODUCTION_LINES` | 8 | Line master data: name, plant, shift pattern | All DTs with LINE_ID |
| `PRODUCTION_ORDERS` | 2,160 | ERP orders: shift date, counts, cycle time | DT_OEE_SHIFT → OEE pipeline |
| `DOWNTIME_EVENTS` | 350 | Stop events: reason code, duration, planned flag | DT_DOWNTIME_PARETO |
| `FAILURE_EVENTS` | 50 | Ground truth failures for ML training | V_CLASSIFY_TRAIN, DT_ASSET_360 |
| `WORK_ORDERS_HIST` | 300 | Maintenance WO history: type, cost, parts | DT_ASSET_360 |
| `SPARE_PARTS` | 80 | Inventory: stock levels, reorder points, costs | DT_ASSET_360 |
| `MAINT_DOCS` | 40+ | Maintenance procedures for Cortex Search | MAINT_DOCS_SEARCH |
| `DEGRADATION_INJECTIONS` | varies | Demo control: inject live degradation patterns | SP_GENERATE_SENSOR_BATCH |

**DDL:** [`ddl/02_tables/raw_tables.sql`](ddl/02_tables/raw_tables.sql)

## 3. Tables (ML Schema — 3 tables)

| Table | Purpose |
|---|---|
| `ANOMALY_SCORES` | Isolation Forest results: actual vs forecast, anomaly flag, distance |
| `FAILURE_PREDICTIONS` | XGBoost results: failure probability, predicted class, top features |
| `RUL_ESTIMATES` | Linear regression: current vibration, forecasted, estimated hours remaining |

**DDL:** [`ddl/02_tables/ml_tables_views.sql`](ddl/02_tables/ml_tables_views.sql)

## 4. Tables (OPS Schema — 3 tables)

| Table | Purpose |
|---|---|
| `ALERT_HISTORY` | All generated alerts: severity, message, acknowledgment tracking |
| `WORK_ORDER_DRAFTS` | AI-generated PdM work orders: priority, description, recommended action |
| `CONFIG` | Key-value operational configuration |

**DDL:** [`ddl/02_tables/ops_tables.sql`](ddl/02_tables/ops_tables.sql)

---

## 5. Dynamic Tables (CURATED Schema — 8 tables)

These auto-refresh when source data changes. No ETL code needed.

| Dynamic Table | Lag | Source | Purpose |
|---|---|---|---|
| `DT_SENSOR_CLEAN` | DOWNSTREAM | SENSOR_READINGS + ASSETS | Dedup, cleanse, forward-fill nulls, flag idle |
| `DT_SENSOR_FEATURES_15M` | DOWNSTREAM | DT_SENSOR_CLEAN | 15-min aggregates: avg, std, min, max, % of limit |
| `DT_ASSET_HEALTH` | 2 min | DT_SENSOR_FEATURES_15M + ML tables | Per-asset health: rule status + ML scores |
| `DT_OEE_SHIFT` | 5 min | PRODUCTION_ORDERS + LINES + PLANTS | OEE per line per shift |
| `DT_OEE_LINE_DAILY` | 5 min | DT_OEE_SHIFT | Daily OEE rollup per line |
| `DT_OEE_PLANT_DAILY` | 5 min | DT_OEE_LINE_DAILY | Daily OEE rollup per plant |
| `DT_ASSET_360` | 5 min | ASSETS + FAILURES + WOs + SPARE_PARTS | 30-day profile: MTBF, MTTR, costs |
| `DT_DOWNTIME_PARETO` | 5 min | DOWNTIME_EVENTS + LINES | Downtime by reason code, 30-day rolling |

**Pipeline dependency chain:**
```
SENSOR_READINGS → DT_SENSOR_CLEAN → DT_SENSOR_FEATURES_15M → DT_ASSET_HEALTH
PRODUCTION_ORDERS → DT_OEE_SHIFT → DT_OEE_LINE_DAILY → DT_OEE_PLANT_DAILY
DOWNTIME_EVENTS → DT_DOWNTIME_PARETO
FAILURE_EVENTS + WORK_ORDERS_HIST + SPARE_PARTS → DT_ASSET_360
```

**DDL:** [`ddl/03_dynamic_tables/dynamic_tables.sql`](ddl/03_dynamic_tables/dynamic_tables.sql)

---

## 6. Views (ML Schema — 5 views)

| View | Purpose |
|---|---|
| `V_AD_TRAIN` | Anomaly detection training: normal periods only (excludes failure windows) |
| `V_AD_TRAIN_SAMPLED` | 25% sample of V_AD_TRAIN for faster training |
| `V_CLASSIFY_TRAIN` | Failure classification: features + FAIL_24H label |
| `V_CLF_TRAIN` | Time-split training set (older data, 20% sampled) |
| `V_CLF_TEST` | Time-split test set (last 20 days) |

---

## 7. Stored Procedures (6 total)

### RAW Schema
| Procedure | Language | Purpose |
|---|---|---|
| `SP_GENERATE_SENSOR_BATCH()` | Python | Generates 60 sensor readings per cycle with realistic profiles per asset type. Applies degradation patterns from DEGRADATION_INJECTIONS. |
| `SP_GENERATE_SENSOR_HISTORY()` | Python | One-time: generates 90 days of historical data (~9.3M rows) with embedded failure patterns. |
| `SP_INJECT_DEGRADATION(asset, mode, hours)` | SQL | Injects live degradation pattern for demo. Modes: BEARING_WEAR, OVERHEATING, IMBALANCE, SEAL_LEAK, LUBRICATION_FAILURE. |

### ML Schema
| Procedure | Language | Purpose |
|---|---|---|
| `SP_SCORE_ALL()` | SQL | Runs Snowflake ML anomaly detection model (AD_VIBRATION) on last 12 hours of sensor features. Writes results to ANOMALY_SCORES. |

### OPS Schema
| Procedure | Language | Purpose |
|---|---|---|
| `SP_TRIAGE_ALERTS()` | SQL | Generates alerts from 3 sources: threshold breaches (CRITICAL/WARNING), anomaly clusters (3+ in 12h), and low RUL (<168h). Deduplicates within 4-hour windows. |
| `SP_GENERATE_WO_DRAFTS()` | SQL | Creates PdM work order drafts for CRITICAL/WARNING assets. Includes asset-type-specific repair recommendations. Skips if draft exists within 24h. |

---

## 8. Tasks & Alerts (4 total)

| Object | Type | Schedule | Purpose |
|---|---|---|---|
| `TASK_STREAM_SENSORS` | Task | 1 min | Calls SP_GENERATE_SENSOR_BATCH for live data |
| `TASK_SCORE_ALL` | Task | 15 min | Calls SP_SCORE_ALL for ML scoring |
| `TASK_TRIAGE_PIPELINE` | Task | 15 min | Calls SP_TRIAGE_ALERTS + SP_GENERATE_WO_DRAFTS |
| `ALERT_CRITICAL_ASSETS` | Alert | 15 min | Fires when any asset is CRITICAL |

**DDL:** [`ddl/05_tasks/tasks_and_alerts.sql`](ddl/05_tasks/tasks_and_alerts.sql)

---

## 9. AI Services (3 total)

| Service | Type | Purpose |
|---|---|---|
| `MAINT_DOCS_SEARCH` | Cortex Search | Vector search over 40 maintenance documents. Attributes: ASSET_TYPE, TITLE, SECTION. |
| `PDM_OEE_ANALYTICS` | Semantic View | Maps 4 curated tables with business descriptions. 5 verified queries for Cortex Analyst. |
| `PDM_COMMAND_CENTER` | Cortex Agent | Combines Analyst (data queries) + Search (doc lookup). Available in Snowflake Intelligence. |

**DDL:** [`ddl/06_ai_services/ai_services.sql`](ddl/06_ai_services/ai_services.sql)

---

## 10. Streamlit Application

| Object | Type | Purpose |
|---|---|---|
| `OEE_COMMAND_CENTER` | Streamlit App | 7-tab dashboard: Executive Overview, Asset Health, Downtime, Asset 360, Anomaly Monitor, Alerts & WOs, AI Chat |
| `OEE_APP_STAGE` | Stage | Stores streamlit_app.py and pyproject.toml |

**DDL:** [`ddl/07_streamlit/streamlit_app.sql`](ddl/07_streamlit/streamlit_app.sql)

---

## 11. Warehouse & Compute

| Object | Type | Config |
|---|---|---|
| `MFG_PDM_WH` | Warehouse | MEDIUM, auto-suspend 60s, auto-resume, query acceleration enabled |
| `SYSTEM_COMPUTE_POOL_CPU` | Compute Pool | CPU_X64_S, 1-2 nodes, auto-suspend 300s (for Streamlit container runtime) |
