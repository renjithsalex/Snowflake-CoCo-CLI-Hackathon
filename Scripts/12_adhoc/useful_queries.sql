-- =============================================================================
-- 12_ADHOC: Useful ad-hoc queries for data exploration and debugging
-- =============================================================================
-- These are standalone queries. Run any section independently.
-- =============================================================================


-- ═══════════════════════════════════════════════════════════════════════════════
-- FLEET OVERVIEW
-- ═══════════════════════════════════════════════════════════════════════════════

-- Asset health distribution
SELECT RULE_STATUS, COUNT(*) AS CNT, ROUND(AVG(HEALTH_SCORE),1) AS AVG_HS,
    LISTAGG(ASSET_ID, ', ') WITHIN GROUP (ORDER BY HEALTH_SCORE) AS ASSETS
FROM MFG_PDM_DB.CURATED.DT_ASSET_HEALTH GROUP BY RULE_STATUS ORDER BY CNT DESC;

-- Top 10 worst assets right now
SELECT ASSET_ID, ASSET_TYPE, RULE_STATUS, ROUND(HEALTH_SCORE,1) AS HS,
    ROUND(FAILURE_PROB*100,1) AS FAIL_PCT, ROUND(RUL_HOURS,0) AS RUL,
    ROUND(AVG_VIBRATION,2) AS VIB, ROUND(VIB_PCT_OF_LIMIT*100,1) AS VIB_PCT,
    ROUND(AVG_TEMPERATURE,1) AS TEMP, ROUND(TEMP_PCT_OF_LIMIT*100,1) AS TEMP_PCT
FROM MFG_PDM_DB.CURATED.DT_ASSET_HEALTH ORDER BY HEALTH_SCORE ASC LIMIT 10;

-- Asset fleet by type and plant
SELECT A.ASSET_TYPE, PL.PLANT_ID, COUNT(*) AS CNT
FROM MFG_PDM_DB.RAW.ASSETS A JOIN MFG_PDM_DB.RAW.PRODUCTION_LINES PL ON A.LINE_ID = PL.LINE_ID
GROUP BY A.ASSET_TYPE, PL.PLANT_ID ORDER BY A.ASSET_TYPE, PL.PLANT_ID;


-- ═══════════════════════════════════════════════════════════════════════════════
-- OEE ANALYSIS
-- ═══════════════════════════════════════════════════════════════════════════════

-- OEE by plant (last 30 days, compared to 85% world-class)
SELECT PLANT_NAME, ROUND(AVG(OEE)*100, 1) AS OEE_PCT,
    ROUND(AVG(AVAILABILITY)*100,1) AS AVAIL, ROUND(AVG(PERFORMANCE)*100,1) AS PERF,
    ROUND(AVG(QUALITY)*100,1) AS QUAL,
    CASE WHEN AVG(OEE) >= 0.85 THEN 'WORLD CLASS' WHEN AVG(OEE) >= 0.65 THEN 'TYPICAL' ELSE 'BELOW AVG' END AS BENCHMARK
FROM MFG_PDM_DB.CURATED.DT_OEE_PLANT_DAILY
WHERE SHIFT_DATE >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY PLANT_NAME ORDER BY OEE_PCT DESC;

-- OEE trend (daily, last 14 days)
SELECT SHIFT_DATE, ROUND(AVG(OEE)*100,1) AS OEE_PCT
FROM MFG_PDM_DB.CURATED.DT_OEE_PLANT_DAILY
WHERE SHIFT_DATE >= DATEADD('day', -14, CURRENT_DATE())
GROUP BY SHIFT_DATE ORDER BY SHIFT_DATE;

-- Worst OEE lines
SELECT LINE_NAME, PLANT_NAME, ROUND(AVG(OEE)*100,1) AS OEE_PCT
FROM MFG_PDM_DB.CURATED.DT_OEE_LINE_DAILY
WHERE SHIFT_DATE >= DATEADD('day', -30, CURRENT_DATE())
GROUP BY LINE_NAME, PLANT_NAME ORDER BY OEE_PCT ASC LIMIT 5;


-- ═══════════════════════════════════════════════════════════════════════════════
-- DOWNTIME INVESTIGATION
-- ═══════════════════════════════════════════════════════════════════════════════

-- Top 5 downtime causes (unplanned only)
SELECT REASON_CODE, SUM(EVENT_COUNT) AS EVENTS, SUM(DOWNTIME_HOURS) AS HOURS
FROM MFG_PDM_DB.CURATED.DT_DOWNTIME_PARETO
WHERE IS_PLANNED = FALSE GROUP BY REASON_CODE ORDER BY HOURS DESC LIMIT 5;

-- Planned vs unplanned split
SELECT IS_PLANNED, SUM(EVENT_COUNT) AS EVENTS, SUM(DOWNTIME_HOURS) AS HOURS,
    ROUND(SUM(DOWNTIME_HOURS) / (SELECT SUM(DOWNTIME_HOURS) FROM MFG_PDM_DB.CURATED.DT_DOWNTIME_PARETO) * 100, 1) AS PCT
FROM MFG_PDM_DB.CURATED.DT_DOWNTIME_PARETO GROUP BY IS_PLANNED;


-- ═══════════════════════════════════════════════════════════════════════════════
-- ML SCORING RESULTS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Assets with anomalies detected
SELECT ASSET_ID, ROUND(VALUE,3) AS VIB_ACTUAL, ROUND(FORECAST,3) AS VIB_EXPECTED,
    ROUND(DISTANCE,3) AS DIST, ROUND(PERCENTILE*100,1) AS PCTILE, SCORED_AT
FROM MFG_PDM_DB.ML.ANOMALY_SCORES WHERE IS_ANOMALY = TRUE ORDER BY DISTANCE DESC;

-- High failure probability assets
SELECT ASSET_ID, ROUND(FAILURE_PROB*100,1) AS FAIL_PCT, PREDICTED_CLASS, TOP_FEATURES, SCORED_AT
FROM MFG_PDM_DB.ML.FAILURE_PREDICTIONS WHERE FAILURE_PROB >= 0.5 ORDER BY FAILURE_PROB DESC;

-- Assets with low RUL
SELECT ASSET_ID, ROUND(ESTIMATED_RUL_HOURS,0) AS RUL_HRS,
    ROUND(CURRENT_VIBRATION,2) AS CURR_VIB, ROUND(MAX_VIBRATION_LIMIT,2) AS LIMIT_VIB
FROM MFG_PDM_DB.ML.RUL_ESTIMATES WHERE ESTIMATED_RUL_HOURS < 100 AND ESTIMATED_RUL_HOURS < 9999
ORDER BY ESTIMATED_RUL_HOURS;


-- ═══════════════════════════════════════════════════════════════════════════════
-- ALERTS & WORK ORDERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Recent alerts (last 24h)
SELECT ALERT_TS, ASSET_ID, ALERT_TYPE, SEVERITY, MESSAGE
FROM MFG_PDM_DB.OPS.ALERT_HISTORY
WHERE ALERT_TS >= DATEADD('hour', -24, CURRENT_TIMESTAMP())
ORDER BY ALERT_TS DESC LIMIT 20;

-- Open work order drafts
SELECT DRAFT_ID, ASSET_ID, PRIORITY, TITLE, SOURCE, STATUS, CREATED_AT
FROM MFG_PDM_DB.OPS.WORK_ORDER_DRAFTS
WHERE STATUS = 'DRAFT' ORDER BY CREATED_AT DESC;

-- Approve a work order (run with actual DRAFT_ID):
-- UPDATE MFG_PDM_DB.OPS.WORK_ORDER_DRAFTS
-- SET STATUS = 'APPROVED', APPROVED_BY = CURRENT_USER(), APPROVED_AT = CURRENT_TIMESTAMP()
-- WHERE DRAFT_ID = '<paste-draft-id>';


-- ═══════════════════════════════════════════════════════════════════════════════
-- SINGLE ASSET DEEP DIVE (replace 'CNC-001' with your asset)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Asset 360 profile
SELECT * FROM MFG_PDM_DB.CURATED.DT_ASSET_360 WHERE ASSET_ID = 'CNC-001';

-- Latest sensor readings (last 2 hours)
SELECT READING_TS, VIBRATION_MM_S, TEMPERATURE_C, RPM, PRESSURE_BAR, POWER_KW
FROM MFG_PDM_DB.RAW.SENSOR_READINGS
WHERE ASSET_ID = 'CNC-001' AND READING_TS >= DATEADD('hour', -2, CURRENT_TIMESTAMP())
ORDER BY READING_TS DESC;

-- Recent alerts for this asset
SELECT * FROM MFG_PDM_DB.OPS.ALERT_HISTORY
WHERE ASSET_ID = 'CNC-001' ORDER BY ALERT_TS DESC LIMIT 10;

-- Maintenance history
SELECT * FROM MFG_PDM_DB.RAW.WORK_ORDERS_HIST
WHERE ASSET_ID = 'CNC-001' ORDER BY CREATED_TS DESC LIMIT 10;


-- ═══════════════════════════════════════════════════════════════════════════════
-- DEGRADATION DEMO
-- ═══════════════════════════════════════════════════════════════════════════════

-- Inject bearing wear degradation on CNC-001 (48h ramp)
-- CALL MFG_PDM_DB.RAW.SP_INJECT_DEGRADATION('CNC-001', 'BEARING_WEAR', 48.0);

-- Check active degradation injections
SELECT * FROM MFG_PDM_DB.RAW.DEGRADATION_INJECTIONS WHERE ACTIVE = TRUE;

-- Cancel all degradation injections
-- UPDATE MFG_PDM_DB.RAW.DEGRADATION_INJECTIONS SET ACTIVE = FALSE;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SPARE PARTS INVENTORY
-- ═══════════════════════════════════════════════════════════════════════════════

-- Parts below reorder point (need to order)
SELECT PART_ID, ASSET_TYPE, PART_NAME, FAILURE_MODE, ON_HAND_QTY, REORDER_POINT,
    LEAD_TIME_DAYS, UNIT_COST_USD
FROM MFG_PDM_DB.RAW.SPARE_PARTS WHERE ON_HAND_QTY <= REORDER_POINT ORDER BY ON_HAND_QTY;
