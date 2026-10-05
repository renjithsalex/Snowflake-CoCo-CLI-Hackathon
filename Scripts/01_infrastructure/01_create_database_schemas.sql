-- =============================================================================
-- 01_INFRASTRUCTURE: Database, Schemas, Warehouse
-- =============================================================================
-- Run this FIRST on a fresh account. Safe to re-run (IF NOT EXISTS).
-- Role required: ACCOUNTADMIN or SYSADMIN with CREATE DATABASE privilege
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Database
CREATE DATABASE IF NOT EXISTS MFG_PDM_DB
  COMMENT = 'Predictive Maintenance & OEE Command Center database';

-- Warehouse (MEDIUM for data generation; can downsize to SMALL for steady-state)
CREATE WAREHOUSE IF NOT EXISTS MFG_PDM_WH
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  ENABLE_QUERY_ACCELERATION = TRUE
  COMMENT = 'Predictive Maintenance & OEE Command Center warehouse';

-- 6 functional schemas
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.RAW
  COMMENT = 'Raw ingestion layer: synthetic IoT sensors, ERP, CMMS data';

CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.CURATED
  COMMENT = 'Curated layer: cleaned sensors, features, OEE, asset health via Dynamic Tables';

CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.AI
  COMMENT = 'Cortex Agent, Semantic View, Cortex Search for root-cause investigation';

CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.ML
  COMMENT = 'ML models, scoring, predictions (anomaly detection, classification, forecast)';

CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.OPS
  COMMENT = 'Operational layer: alerts, work order drafts, notifications, triage pipeline';

CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.APP
  COMMENT = 'Streamlit OEE Command Center application';

-- Verify
SELECT SCHEMA_NAME, COMMENT FROM MFG_PDM_DB.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA', 'PUBLIC') ORDER BY SCHEMA_NAME;
