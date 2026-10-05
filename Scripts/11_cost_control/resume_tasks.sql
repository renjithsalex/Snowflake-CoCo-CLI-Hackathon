-- =============================================================================
-- 11_COST_CONTROL: RESUME TASKS — Restart automated pipeline
-- =============================================================================
-- Run this when you're ready to start burning credits again.
-- Resume in forward dependency order (sensors → scoring → triage).
-- =============================================================================

-- Resume all tasks
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS RESUME;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL RESUME;
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE RESUME;

-- Resume alert
ALTER ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS RESUME;

-- Verify
SHOW TASKS IN DATABASE MFG_PDM_DB;
-- STATE column should show 'started' for all
