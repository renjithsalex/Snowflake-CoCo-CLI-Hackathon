-- =============================================================================
-- 02_TABLES: RAW Schema — 11 source-of-truth tables
-- =============================================================================
-- These are never modified after insert (append-only pattern).
-- Prerequisite: 01_infrastructure scripts
-- =============================================================================

-- IoT sensor time-series (~1.5M rows after history generation)
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.SENSOR_READINGS (
    ASSET_ID        VARCHAR NOT NULL  COMMENT 'Asset identifier FK',
    READING_TS      TIMESTAMP_NTZ NOT NULL COMMENT 'Sensor reading timestamp (UTC)',
    VIBRATION_MM_S  FLOAT          COMMENT 'Vibration velocity (mm/s)',
    TEMPERATURE_C   FLOAT          COMMENT 'Operating temperature (Celsius)',
    RPM             FLOAT          COMMENT 'Rotational speed',
    PRESSURE_BAR    FLOAT          COMMENT 'Operating pressure (bar)',
    POWER_KW        FLOAT          COMMENT 'Power consumption (kW)',
    INGEST_TS       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Data ingestion timestamp',
    SOURCE          VARCHAR DEFAULT 'HISTORY' COMMENT 'Data source: HISTORY or STREAM'
) COMMENT = 'IoT sensor readings from plant assets';

-- 60 machines across 3 plants
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.ASSETS (
    ASSET_ID                VARCHAR,
    LINE_ID                 VARCHAR,
    ASSET_TYPE              VARCHAR,
    MANUFACTURER            VARCHAR,
    MODEL                   VARCHAR,
    INSTALL_DATE            DATE,
    CRITICALITY             VARCHAR,
    RATED_RPM               NUMBER(10,0),
    MAX_TEMP_C              NUMBER(5,1),
    MAX_VIBRATION_MM_S      NUMBER(5,2),
    HOURLY_DOWNTIME_COST_USD NUMBER(10,2)
) COMMENT = 'Plant assets/equipment master data with operational limits';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.PLANTS (
    PLANT_ID    VARCHAR,
    PLANT_NAME  VARCHAR,
    COUNTRY     VARCHAR,
    TIMEZONE    VARCHAR
) COMMENT = 'Manufacturing plants master data';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.PRODUCTION_LINES (
    LINE_ID       VARCHAR,
    PLANT_ID      VARCHAR,
    LINE_NAME     VARCHAR,
    SHIFT_PATTERN VARCHAR
) COMMENT = 'Production lines master data';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.PRODUCTION_ORDERS (
    ORDER_ID             VARCHAR NOT NULL,
    LINE_ID              VARCHAR NOT NULL,
    PRODUCT_SKU          VARCHAR NOT NULL,
    SHIFT_DATE           DATE NOT NULL,
    SHIFT                VARCHAR NOT NULL,
    PLANNED_RUNTIME_MIN  NUMBER(38,0) NOT NULL,
    RUN_TIME_MIN         NUMBER(38,0) NOT NULL,
    IDEAL_CYCLE_TIME_SEC NUMBER(6,2) NOT NULL,
    TOTAL_COUNT          NUMBER(38,0) NOT NULL,
    GOOD_COUNT           NUMBER(38,0) NOT NULL,
    SCRAP_COUNT          NUMBER(38,0) NOT NULL,
    CONSTRAINT PK_PRODUCTION_ORDERS PRIMARY KEY (ORDER_ID)
) COMMENT = 'ERP production orders per line per shift for OEE calculation';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.DOWNTIME_EVENTS (
    EVENT_ID    VARCHAR NOT NULL,
    ASSET_ID    VARCHAR,
    LINE_ID     VARCHAR NOT NULL,
    START_TS    TIMESTAMP_NTZ NOT NULL,
    END_TS      TIMESTAMP_NTZ NOT NULL,
    REASON_CODE VARCHAR NOT NULL,
    IS_PLANNED  BOOLEAN NOT NULL,
    CONSTRAINT PK_DOWNTIME PRIMARY KEY (EVENT_ID)
) COMMENT = 'Downtime events (planned and unplanned)';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.FAILURE_EVENTS (
    EVENT_ID             NUMBER(38,0) NOT NULL AUTOINCREMENT,
    ASSET_ID             VARCHAR NOT NULL,
    FAILURE_TS           TIMESTAMP_NTZ NOT NULL,
    FAILURE_MODE         VARCHAR NOT NULL,
    DEGRADATION_START_TS TIMESTAMP_NTZ NOT NULL,
    DEGRADATION_HOURS    NUMBER(5,1) NOT NULL,
    DOWNTIME_HOURS       NUMBER(5,1) NOT NULL,
    CONSTRAINT PK_FAILURE_EVENTS PRIMARY KEY (EVENT_ID)
) COMMENT = 'Ground truth: failure events for ML training';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.WORK_ORDERS_HIST (
    WO_ID            VARCHAR NOT NULL,
    ASSET_ID         VARCHAR NOT NULL,
    CREATED_TS       TIMESTAMP_NTZ NOT NULL,
    CLOSED_TS        TIMESTAMP_NTZ,
    WO_TYPE          VARCHAR NOT NULL,
    PRIORITY         VARCHAR NOT NULL,
    FAILURE_MODE     VARCHAR,
    ROOT_CAUSE       VARCHAR,
    ACTION_TAKEN     VARCHAR,
    PARTS_USED       VARCHAR,
    TECHNICIAN       VARCHAR NOT NULL,
    DOWNTIME_MIN     NUMBER(38,0),
    COST_USD         NUMBER(10,2),
    TECHNICIAN_NOTES VARCHAR,
    CONSTRAINT PK_WO PRIMARY KEY (WO_ID)
) COMMENT = 'Maintenance work order history from CMMS';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.SPARE_PARTS (
    PART_ID        VARCHAR NOT NULL,
    ASSET_TYPE     VARCHAR NOT NULL,
    PART_NAME      VARCHAR NOT NULL,
    FAILURE_MODE   VARCHAR,
    ON_HAND_QTY    NUMBER(38,0) NOT NULL,
    REORDER_POINT  NUMBER(38,0) NOT NULL,
    LEAD_TIME_DAYS NUMBER(38,0) NOT NULL,
    UNIT_COST_USD  NUMBER(10,2) NOT NULL,
    CONSTRAINT PK_SPARE_PARTS PRIMARY KEY (PART_ID)
) COMMENT = 'Spare parts inventory with reorder points';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.MAINT_DOCS (
    DOC_ID     VARCHAR NOT NULL,
    ASSET_TYPE VARCHAR NOT NULL,
    TITLE      VARCHAR NOT NULL,
    SECTION    VARCHAR NOT NULL,
    CONTENT    VARCHAR NOT NULL,
    CONSTRAINT PK_DOCS PRIMARY KEY (DOC_ID)
) COMMENT = 'Maintenance troubleshooting manuals for Cortex Search';

CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.DEGRADATION_INJECTIONS (
    ASSET_ID     VARCHAR NOT NULL,
    FAILURE_MODE VARCHAR NOT NULL,
    START_TS     TIMESTAMP_NTZ NOT NULL,
    RAMP_HOURS   NUMBER(5,1) NOT NULL,
    ACTIVE       BOOLEAN DEFAULT TRUE
) COMMENT = 'Control table for injecting live degradation patterns for demo';
