-- =============================================================================
-- 10_OPERATIONS: REFRESH PIPELINE — Manually trigger full refresh cycle
-- =============================================================================
-- Use this when you want immediate data updates without waiting for tasks.
-- Useful after seed data changes or debugging.
-- =============================================================================

-- Step 1: Generate a batch of sensor readings
CALL MFG_PDM_DB.RAW.SP_GENERATE_SENSOR_BATCH();

-- Step 2: Force-refresh dynamic tables (in dependency order)
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_SENSOR_CLEAN REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_SENSOR_FEATURES_15M REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_ASSET_HEALTH REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_OEE_SHIFT REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_OEE_LINE_DAILY REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_OEE_PLANT_DAILY REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_ASSET_360 REFRESH;
ALTER DYNAMIC TABLE MFG_PDM_DB.CURATED.DT_DOWNTIME_PARETO REFRESH;

-- Step 3: Run ML scoring
CALL MFG_PDM_DB.ML.SP_SCORE_ALL();

-- Step 4: Run alert triage + work orders
CALL MFG_PDM_DB.OPS.SP_TRIAGE_ALERTS();
CALL MFG_PDM_DB.OPS.SP_GENERATE_WO_DRAFTS();

SELECT 'Pipeline refresh complete' AS STATUS, CURRENT_TIMESTAMP() AS TS;
