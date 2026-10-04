-- =============================================================================
-- MFG_PDM_DB: Manufacturing Predictive Maintenance Database
-- =============================================================================
-- Purpose: Central database for the OEE Command Center application
-- Contains 5 functional schemas: RAW, CURATED, AI, ML, OPS, APP
-- =============================================================================

CREATE DATABASE IF NOT EXISTS MFG_PDM_DB
  COMMENT = 'Predictive Maintenance & OEE Command Center database';

CREATE WAREHOUSE IF NOT EXISTS MFG_PDM_WH
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  ENABLE_QUERY_ACCELERATION = TRUE
  COMMENT = 'Predictive Maintenance & OEE Command Center warehouse';

-- Schema: RAW - Source of truth, never modified after insert
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.RAW
  COMMENT = 'Raw ingestion layer: synthetic IoT sensors, ERP, CMMS data';

-- Schema: CURATED - Auto-refreshing summaries via Dynamic Tables
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.CURATED
  COMMENT = 'Curated layer: cleaned sensors, features, OEE, asset health via Dynamic Tables';

-- Schema: AI - Intelligence layer
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.AI
  COMMENT = 'Cortex Agent, Semantic View, Cortex Search for root-cause investigation';

-- Schema: ML - Machine Learning scoring
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.ML
  COMMENT = 'ML models, scoring, predictions (anomaly detection, classification, forecast)';

-- Schema: OPS - Operational actions
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.OPS
  COMMENT = 'Operational layer: alerts, work order drafts, notifications, triage pipeline';

-- Schema: APP - Streamlit application
CREATE SCHEMA IF NOT EXISTS MFG_PDM_DB.APP
  COMMENT = 'Streamlit OEE Command Center application';
