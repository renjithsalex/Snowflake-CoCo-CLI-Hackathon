-- =============================================================================
-- TASKS: Automated pipeline running every 1-15 minutes
-- =============================================================================

-- TASK 1: Sensor data generation (every 1 minute)
CREATE OR REPLACE TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '1 MINUTE'
  COMMENT = 'Generates one sensor reading per asset every minute for live streaming'
AS CALL MFG_PDM_DB.RAW.SP_GENERATE_SENSOR_BATCH();

-- TASK 2: ML scoring (every 15 minutes)
CREATE OR REPLACE TASK MFG_PDM_DB.ML.TASK_SCORE_ALL
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '15 MINUTE'
  COMMENT = 'Periodic ML scoring: anomaly detection, failure prediction, RUL estimation'
AS CALL MFG_PDM_DB.ML.SP_SCORE_ALL();

-- TASK 3: Alert triage + work order generation (every 15 minutes)
CREATE OR REPLACE TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '15 MINUTE'
  COMMENT = 'Triage pipeline: generate alerts and WO drafts from asset health + ML scores'
AS
BEGIN
    CALL MFG_PDM_DB.OPS.SP_TRIAGE_ALERTS();
    CALL MFG_PDM_DB.OPS.SP_GENERATE_WO_DRAFTS();
END;

-- ALERT: Email notification for critical assets
CREATE OR REPLACE ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS
  WAREHOUSE = MFG_PDM_WH
  SCHEDULE = '15 MINUTE'
  IF (EXISTS(
    SELECT 1 FROM MFG_PDM_DB.CURATED.DT_ASSET_HEALTH WHERE RULE_STATUS = 'CRITICAL'
  ))
  THEN CALL MFG_PDM_DB.OPS.SP_TRIAGE_ALERTS();

-- Resume tasks after deployment
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS RESUME;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL RESUME;
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE RESUME;
