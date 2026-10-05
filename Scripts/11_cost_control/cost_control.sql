-- =============================================================================
-- 11_COST_CONTROL: Resource monitors, credit tracking, warehouse management
-- =============================================================================
-- Run key sections as needed. Not all at once.
-- =============================================================================

-- ─── 1. Resource Monitor (150 credits/month hard limit) ──────────────────────

CREATE OR REPLACE RESOURCE MONITOR MFG_PDM_MONITOR
  WITH CREDIT_QUOTA = 150
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 75 PERCENT DO NOTIFY
    ON 90 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE MFG_PDM_WH SET RESOURCE_MONITOR = MFG_PDM_MONITOR;

-- ─── 2. Downsize warehouse for steady-state (saves ~50% credits) ─────────────
-- After initial data generation, MEDIUM isn't needed.
-- SMALL is sufficient for ongoing 1-min sensor inserts + 15-min scoring.

-- ALTER WAREHOUSE MFG_PDM_WH SET WAREHOUSE_SIZE = 'SMALL';

-- ─── 3. Credit usage tracking (last 7 days) ─────────────────────────────────

SELECT WAREHOUSE_NAME, DATE_TRUNC('day', START_TIME) AS DAY,
    ROUND(SUM(CREDITS_USED), 2) AS CREDITS,
    ROUND(SUM(CREDITS_USED_CLOUD_SERVICES), 2) AS CLOUD_CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'MFG_PDM_WH'
AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1, 2 ORDER BY DAY DESC;

-- ─── 4. Credit usage by query type (understand what costs the most) ──────────

SELECT QUERY_TYPE,
    COUNT(*) AS QUERY_COUNT,
    ROUND(SUM(CREDITS_USED_CLOUD_SERVICES), 4) AS CLOUD_CREDITS,
    ROUND(AVG(TOTAL_ELAPSED_TIME) / 1000, 2) AS AVG_SECONDS
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE WAREHOUSE_NAME = 'MFG_PDM_WH'
AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY QUERY_TYPE ORDER BY CLOUD_CREDITS DESC;

-- ─── 5. Task execution cost estimate (last 24h) ─────────────────────────────

SELECT NAME,
    COUNT(*) AS EXECUTIONS,
    ROUND(AVG(DATEDIFF('second', SCHEDULED_TIME, COMPLETED_TIME)), 1) AS AVG_DURATION_SEC
FROM TABLE(MFG_PDM_DB.INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -24, CURRENT_TIMESTAMP())
))
WHERE STATE = 'SUCCEEDED'
GROUP BY NAME ORDER BY EXECUTIONS DESC;

-- ─── 6. Dynamic table refresh cost ──────────────────────────────────────────

SELECT NAME,
    REFRESH_TRIGGER,
    COUNT(*) AS REFRESH_COUNT,
    ROUND(SUM(STATISTICS:"insertedRows"::INT), 0) AS TOTAL_ROWS_INSERTED
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME_PREFIX => 'MFG_PDM_DB.CURATED.',
    DATA_TIMESTAMP_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
))
GROUP BY NAME, REFRESH_TRIGGER ORDER BY REFRESH_COUNT DESC;

-- ─── 7. Auto-suspend settings (ensure no wasted idle time) ─────────────────

SHOW WAREHOUSES LIKE 'MFG_PDM_WH';
-- Look for AUTO_SUSPEND = 60 (1 minute)

-- ─── 8. Estimated monthly cost breakdown ────────────────────────────────────
-- MEDIUM WH at $4/credit:
--   Task sensor stream: ~4 credits/day (runs every minute, ~2s each)
--   Task scoring: ~1 credit/day (every 15 min, ~5s each)
--   DT refreshes: ~1 credit/day (automatic)
--   Ad-hoc queries: ~0.5 credit/day
--   TOTAL: ~6-7 credits/day → ~200 credits/month on MEDIUM
--
-- SMALL WH at $2/credit:
--   Same workload: ~3-4 credits/day → ~100 credits/month
--
-- RECOMMENDATION: Downsize to SMALL after initial setup.
