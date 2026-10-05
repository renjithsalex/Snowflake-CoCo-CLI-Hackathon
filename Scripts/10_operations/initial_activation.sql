-- =============================================================================
-- 10_OPERATIONS: INITIAL ACTIVATION — First-time setup after deployment
-- =============================================================================
-- Run this ONCE after deploying all DDLs and seed data.
-- Generates historical data, refreshes pipeline, runs scoring, starts tasks.
-- Takes 5-15 minutes on a MEDIUM warehouse.
-- =============================================================================

-- Step 1: Generate 90 days of historical sensor data (~1.5M rows)
CALL MFG_PDM_DB.RAW.SP_GENERATE_SENSOR_HISTORY();

-- Step 2: Force-refresh dynamic tables
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_SENSOR_CLEAN REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_SENSOR_FEATURES_15M REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_ASSET_HEALTH REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_OEE_SHIFT REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_OEE_LINE_DAILY REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_OEE_PLANT_DAILY REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_ASSET_360 REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_DOWNTIME_PARETO REFRESH;

-- Step 3: Initial ML scoring
CALL MFG_PDM_DB.ML.SP_SCORE_ALL();

-- Step 4: Initial alert triage + work orders
CALL MFG_PDM_DB.OPS.SP_TRIAGE_ALERTS();
CALL MFG_PDM_DB.OPS.SP_GENERATE_WO_DRAFTS();

-- Step 5: Start all automated tasks
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS RESUME;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL RESUME;
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE RESUME;
ALTER ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS RESUME;

-- Verify
SELECT 'ACTIVATION COMPLETE' AS STATUS, CURRENT_TIMESTAMP() AS TS;
