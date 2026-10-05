-- =============================================================================
-- 10_OPERATIONS: HEALTH CHECK — Full system status dashboard
-- =============================================================================
-- Run this to see the complete state of the OEE Command Center.
-- No side effects — read-only queries.
-- =============================================================================

-- ─── 1. Task status ──────────────────────────────────────────────────────────
SELECT 'TASK' AS TYPE, SCHEMA_NAME || '.' || "name" AS NAME, "state" AS STATUS, "schedule" AS SCHEDULE
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
UNION ALL
SELECT 'TASK', NULL, NULL, NULL WHERE 1=0;
-- Alternative:
SHOW TASKS IN DATABASE MFG_PDM_DB;

-- ─── 2. Alert status ─────────────────────────────────────────────────────────
SHOW ALERTS IN DATABASE MFG_PDM_DB;

-- ─── 3. Dynamic table freshness ──────────────────────────────────────────────
SELECT NAME, SCHEDULING_STATE, DATA_TIMESTAMP, TARGET_LAG, REFRESH_MODE
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(NAME_PREFIX => 'MFG_PDM_DB.CURATED.'))
QUALIFY ROW_NUMBER() OVER (PARTITION BY NAME ORDER BY DATA_TIMESTAMP DESC) = 1;

-- ─── 4. Table row counts ────────────────────────────────────────────────────
SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT
FROM MFG_PDM_DB.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA NOT IN ('INFORMATION_SCHEMA', 'PUBLIC')
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ─── 5. Sensor data freshness ────────────────────────────────────────────────
SELECT SOURCE,
    COUNT(*) AS ROW_COUNT,
    MIN(READING_TS) AS EARLIEST,
    MAX(READING_TS) AS LATEST,
    DATEDIFF('minute', MAX(READING_TS), CURRENT_TIMESTAMP()) AS MINUTES_STALE
FROM MFG_PDM_DB.RAW.SENSOR_READINGS
GROUP BY SOURCE;

-- ─── 6. ML scoring freshness ────────────────────────────────────────────────
SELECT 'ANOMALY_SCORES' AS TABLE_NAME, COUNT(*) AS CNT, MAX(SCORED_AT) AS LAST_SCORED,
    DATEDIFF('minute', MAX(SCORED_AT), CURRENT_TIMESTAMP()) AS MIN_AGO
FROM MFG_PDM_DB.ML.ANOMALY_SCORES
UNION ALL
SELECT 'FAILURE_PREDICTIONS', COUNT(*), MAX(SCORED_AT),
    DATEDIFF('minute', MAX(SCORED_AT), CURRENT_TIMESTAMP())
FROM MFG_PDM_DB.ML.FAILURE_PREDICTIONS
UNION ALL
SELECT 'RUL_ESTIMATES', COUNT(*), MAX(ESTIMATED_AT),
    DATEDIFF('minute', MAX(ESTIMATED_AT), CURRENT_TIMESTAMP())
FROM MFG_PDM_DB.ML.RUL_ESTIMATES;

-- ─── 7. Alert summary (last 24h) ────────────────────────────────────────────
SELECT ALERT_TYPE, SEVERITY, COUNT(*) AS CNT
FROM MFG_PDM_DB.OPS.ALERT_HISTORY
WHERE ALERT_TS >= DATEADD('hour', -24, CURRENT_TIMESTAMP())
GROUP BY ALERT_TYPE, SEVERITY ORDER BY CNT DESC;

-- ─── 8. Asset health distribution ───────────────────────────────────────────
SELECT RULE_STATUS, COUNT(*) AS ASSET_COUNT,
    ROUND(AVG(HEALTH_SCORE), 1) AS AVG_HEALTH
FROM MFG_PDM_DB.CURATED.DT_ASSET_HEALTH
GROUP BY RULE_STATUS ORDER BY ASSET_COUNT DESC;

-- ─── 9. Task execution history (last 10) ────────────────────────────────────
SELECT NAME, SCHEDULED_TIME, STATE, ERROR_MESSAGE
FROM TABLE(MFG_PDM_DB.INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -24, CURRENT_TIMESTAMP())
))
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;

-- ─── 10. Cortex Search status ───────────────────────────────────────────────
SHOW CORTEX SEARCH SERVICES IN DATABASE MFG_PDM_DB;
