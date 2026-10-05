-- =============================================================================
-- 02_TABLES: ML Schema — Scoring result tables
-- =============================================================================

CREATE OR REPLACE TABLE MFG_PDM_DB.ML.ANOMALY_SCORES (
    ASSET_ID    VARCHAR NOT NULL,
    TS          TIMESTAMP_NTZ NOT NULL,
    VALUE       FLOAT,
    FORECAST    FLOAT,
    LOWER_BOUND FLOAT,
    UPPER_BOUND FLOAT,
    IS_ANOMALY  BOOLEAN,
    PERCENTILE  FLOAT,
    DISTANCE    FLOAT,
    SCORED_AT   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Anomaly detection scoring results';

CREATE OR REPLACE TABLE MFG_PDM_DB.ML.FAILURE_PREDICTIONS (
    ASSET_ID        VARCHAR NOT NULL,
    SCORED_AT       TIMESTAMP_NTZ NOT NULL,
    FAILURE_PROB    FLOAT,
    PREDICTED_CLASS NUMBER(38,0),
    TOP_FEATURES    VARIANT
) COMMENT = 'Failure classification predictions (fail within 24h)';

CREATE OR REPLACE TABLE MFG_PDM_DB.ML.RUL_ESTIMATES (
    ASSET_ID              VARCHAR NOT NULL,
    ESTIMATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FORECAST_HOURS        NUMBER(38,0),
    CURRENT_VIBRATION     FLOAT,
    FORECASTED_VIBRATION  FLOAT,
    MAX_VIBRATION_LIMIT   FLOAT,
    ESTIMATED_RUL_HOURS   FLOAT
) COMMENT = 'Remaining useful life estimates from vibration forecast';
