-- =============================================================================
-- 10_OPERATIONS: RESET DATA — Clear transient data, keep structure + seed
-- =============================================================================
-- Use after testing to start fresh. Keeps tables, SPs, DTs, tasks intact.
-- Clears: sensor readings, ML scores, alerts, WO drafts, degradation injections
-- Keeps: assets, plants, lines, spare parts, maint docs, prod orders, config
-- =============================================================================

-- ⚠️ CAUTION: This deletes operational data!

-- Suspend tasks first
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE SUSPEND;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL SUSPEND;
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS SUSPEND;

-- Clear transient data
TRUNCATE TABLE MFG_PDM_DB.RAW.SENSOR_READINGS;
TRUNCATE TABLE MFG_PDM_DB.RAW.DEGRADATION_INJECTIONS;
TRUNCATE TABLE MFG_PDM_DB.ML.ANOMALY_SCORES;
TRUNCATE TABLE MFG_PDM_DB.ML.FAILURE_PREDICTIONS;
TRUNCATE TABLE MFG_PDM_DB.ML.RUL_ESTIMATES;
TRUNCATE TABLE MFG_PDM_DB.OPS.ALERT_HISTORY;
TRUNCATE TABLE MFG_PDM_DB.OPS.WORK_ORDER_DRAFTS;

-- Force-refresh DTs (they'll now be empty)
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_SENSOR_CLEAN REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_SENSOR_FEATURES_15M REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_ASSET_HEALTH REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_ASSET_360 REFRESH;

-- Re-generate history if needed:
-- CALL MFG_PDM_DB.RAW.SP_GENERATE_SENSOR_HISTORY();  -- ~5-15 min
-- Then run: 10_operations/refresh_pipeline.sql
-- Then run: 10_operations/start_all.sql

SELECT 'Data reset complete. Run SP_GENERATE_SENSOR_HISTORY to repopulate.' AS STATUS;
