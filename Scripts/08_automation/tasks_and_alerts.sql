-- =============================================================================
-- 08_AUTOMATION: Tasks, Alerts, and their management
-- =============================================================================
-- 3 tasks + 1 alert form the automated pipeline.
-- All are created SUSPENDED and must be explicitly RESUMED.
-- =============================================================================

-- ─── TASKS ───────────────────────────────────────────────────────────────────

-- Task 1: Sensor streaming (every 1 minute)
CREATE OR REPLACE TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '1 MINUTE'
  COMMENT = 'Generates one sensor reading per asset every minute'
AS CALL MFG_PDM_DB.RAW.SP_GENERATE_SENSOR_BATCH();

-- Task 2: ML scoring (every 15 minutes)
CREATE OR REPLACE TASK MFG_PDM_DB.ML.TASK_SCORE_ALL
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '15 MINUTE'
  COMMENT = 'Periodic ML scoring: anomaly detection, failure prediction, RUL'
AS CALL MFG_PDM_DB.ML.SP_SCORE_ALL();

-- Task 3: Alert triage + work orders (every 15 minutes)
CREATE OR REPLACE TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '15 MINUTE'
  COMMENT = 'Triage pipeline: generate alerts and WO drafts'
AS
BEGIN
    CALL MFG_PDM_DB.OPS.SP_TRIAGE_ALERTS();
    CALL MFG_PDM_DB.OPS.SP_GENERATE_WO_DRAFTS();
END;

-- ─── ALERT ───────────────────────────────────────────────────────────────────

CREATE OR REPLACE ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '15 MINUTE'
  IF (EXISTS(
    SELECT 1 FROM MFG_PDM_DB.CURATED.DT_ASSET_HEALTH WHERE RULE_STATUS = 'CRITICAL'
  ))
  THEN CALL MFG_PDM_DB.OPS.SP_TRIAGE_ALERTS();

-- ─── NOTE: Run 10_operations/start_all.sql to RESUME these ─────────────────
