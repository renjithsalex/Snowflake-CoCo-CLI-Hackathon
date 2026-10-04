-- =============================================================================
-- ML SCHEMA TABLES & VIEWS
-- Machine Learning scoring results and training views
-- =============================================================================

CREATE OR REPLACE TABLE MFG_PDM_DB.ML.ANOMALY_SCORES (
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset identifier',
    TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'Feature window timestamp',
    VALUE FLOAT COMMENT 'Actual vibration value',
    FORECAST FLOAT COMMENT 'Expected vibration value',
    LOWER_BOUND FLOAT COMMENT 'Lower prediction interval',
    UPPER_BOUND FLOAT COMMENT 'Upper prediction interval',
    IS_ANOMALY BOOLEAN COMMENT 'Whether point is anomalous',
    PERCENTILE FLOAT COMMENT 'Percentile of the anomaly score (0-1)',
    DISTANCE FLOAT COMMENT 'Distance from expected value',
    SCORED_AT TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'When scoring was performed'
) COMMENT = 'Anomaly detection scoring results';

CREATE OR REPLACE TABLE MFG_PDM_DB.ML.FAILURE_PREDICTIONS (
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset identifier',
    SCORED_AT TIMESTAMP_NTZ(9) NOT NULL COMMENT 'When scoring was performed',
    FAILURE_PROB FLOAT COMMENT 'Probability of failure within 24 hours',
    PREDICTED_CLASS NUMBER(38,0) COMMENT 'Predicted class: 1=fail, 0=no fail',
    TOP_FEATURES VARIANT COMMENT 'Top contributing features as JSON array'
) COMMENT = 'Failure classification predictions (fail within 24h)';

CREATE OR REPLACE TABLE MFG_PDM_DB.ML.RUL_ESTIMATES (
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset identifier',
    ESTIMATED_AT TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'When estimate was made',
    FORECAST_HOURS NUMBER(38,0) COMMENT 'Forecast horizon in hours',
    CURRENT_VIBRATION FLOAT COMMENT 'Current average vibration',
    FORECASTED_VIBRATION FLOAT COMMENT 'Forecasted vibration at horizon',
    MAX_VIBRATION_LIMIT FLOAT COMMENT 'Asset vibration limit',
    ESTIMATED_RUL_HOURS FLOAT COMMENT 'Estimated remaining useful life in hours'
) COMMENT = 'Remaining useful life estimates from vibration forecast';

-- Training views for ML models
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
