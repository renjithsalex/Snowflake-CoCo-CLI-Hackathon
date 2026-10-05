-- =============================================================================
-- 10_OPERATIONS: STOP ALL — Suspend all tasks and alert
-- =============================================================================
-- Run this to STOP credit consumption from automated tasks.
-- Dynamic tables will also stop refreshing when no new data arrives.
-- The Streamlit app remains accessible but data will be stale.
-- =============================================================================

-- Suspend all 3 tasks (in reverse dependency order)
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE SUSPEND;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL SUSPEND;
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS SUSPEND;

-- Suspend the alert
ALTER ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS SUSPEND;

-- Optionally suspend the warehouse too (saves credits if nothing else uses it)
-- ALTER WAREHOUSE MFG_PDM_WH SUSPEND;

-- Verify everything is stopped
SHOW TASKS IN DATABASE MFG_PDM_DB;
-- Check STATE column — all should show 'suspended'
