-- =============================================================================
-- 06_ML_AND_VIEWS: Training views for ML models
-- =============================================================================
-- These views are used for model training (not scoring).
-- They depend on DT_SENSOR_FEATURES_15M (must exist first).
-- =============================================================================

-- Anomaly detection training: excludes 6h window around known failures
CREATE OR REPLACE VIEW MFG_PDM_DB.ML.V_AD_TRAIN
  COMMENT = 'Training data for anomaly detection: normal operating periods only'
AS
WITH FAILURE_WINDOWS AS (
    SELECT ASSET_ID,
        DATEADD('hour', -6, DEGRADATION_START_TS) AS EXCLUDE_START,
        DATEADD('hour', DOWNTIME_HOURS + 6, FAILURE_TS) AS EXCLUDE_END
    FROM MFG_PDM_DB.RAW.FAILURE_EVENTS
)
SELECT F.ASSET_ID, F.WINDOW_START, F.AVG_VIBRATION, F.AVG_TEMPERATURE,
    F.AVG_RPM, F.AVG_POWER, F.STD_VIBRATION, F.VIB_PCT_OF_LIMIT, F.TEMP_PCT_OF_LIMIT
FROM MFG_PDM_DB.CURATED.DT_SENSOR_FEATURES_15M F
WHERE F.IS_RUNNING = FALSE
    AND NOT EXISTS (
        SELECT 1 FROM FAILURE_WINDOWS FW
        WHERE F.ASSET_ID = FW.ASSET_ID
            AND F.WINDOW_START BETWEEN FW.EXCLUDE_START AND FW.EXCLUDE_END
    );

-- Failure classification training: features + binary FAIL_24H label
CREATE OR REPLACE VIEW MFG_PDM_DB.ML.V_CLASSIFY_TRAIN
  COMMENT = 'Training data for failure classification: features + FAIL_24H label'
AS
WITH FEATURE_BASE AS (
    SELECT F.ASSET_ID, F.ASSET_TYPE, F.WINDOW_START,
        F.AVG_VIBRATION, F.AVG_TEMPERATURE, F.AVG_RPM, F.AVG_POWER,
        F.STD_VIBRATION, F.STD_TEMPERATURE, F.VIB_PCT_OF_LIMIT, F.TEMP_PCT_OF_LIMIT,
        F.VIB_DELTA, F.TEMP_DELTA, A.CRITICALITY,
        DATEDIFF('day', A.INSTALL_DATE, F.WINDOW_START::DATE) AS AGE_DAYS
    FROM MFG_PDM_DB.CURATED.DT_SENSOR_FEATURES_15M F
    JOIN MFG_PDM_DB.RAW.ASSETS A ON F.ASSET_ID = A.ASSET_ID
    WHERE F.IS_RUNNING = FALSE
)
SELECT FB.*,
    CASE WHEN EXISTS (
        SELECT 1 FROM MFG_PDM_DB.RAW.FAILURE_EVENTS FE
        WHERE FE.ASSET_ID = FB.ASSET_ID
            AND FE.FAILURE_TS BETWEEN FB.WINDOW_START AND DATEADD('hour', 24, FB.WINDOW_START)
    ) THEN 1 ELSE 0 END AS FAIL_24H
FROM FEATURE_BASE FB;
