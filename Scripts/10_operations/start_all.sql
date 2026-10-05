-- =============================================================================
-- 10_OPERATIONS: START ALL — Resume all tasks and alert
-- =============================================================================
-- Run this to activate the automated pipeline after deployment or maintenance.
-- =============================================================================

-- Resume all 3 tasks
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS RESUME;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL RESUME;
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE RESUME;

-- Resume the alert
ALTER ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS RESUME;

-- Verify
SELECT 'TASK' AS OBJ_TYPE, SCHEMA_NAME || '.' || NAME AS NAME, STATE
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
-- Better: just run health_check.sql after this
