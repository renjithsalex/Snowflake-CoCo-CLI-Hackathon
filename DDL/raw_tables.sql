-- =============================================================================
-- RAW SCHEMA TABLES
-- Source-of-truth tables for IoT sensor data, asset registry, production, 
-- downtime events, maintenance docs, spare parts, and work order history
-- =============================================================================

-- SENSOR_READINGS: Heart of the system - IoT time-series data
-- 5 sensors per asset, updated every 1-15 minutes
-- Expected volume: ~500K rows per 90 days for 60 assets
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.SENSOR_READINGS (
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset identifier FK',
    READING_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'Sensor reading timestamp (UTC)',
    VIBRATION_MM_S FLOAT COMMENT 'Vibration velocity (mm/s)',
    TEMPERATURE_C FLOAT COMMENT 'Operating temperature (Celsius)',
    RPM FLOAT COMMENT 'Rotational speed',
    PRESSURE_BAR FLOAT COMMENT 'Operating pressure (bar)',
    POWER_KW FLOAT COMMENT 'Power consumption (kW)',
    INGEST_TS TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP() COMMENT 'Data ingestion timestamp',
    SOURCE VARCHAR(16777216) DEFAULT 'HISTORY' COMMENT 'Data source: HISTORY or STREAM'
) COMMENT = 'IoT sensor readings from plant assets (5-min intervals history, 1-min live stream)';

-- ASSETS: Master data for 60 machines across 3 plants
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.ASSETS (
    ASSET_ID VARCHAR(16777216),
    LINE_ID VARCHAR(16777216),
    ASSET_TYPE VARCHAR(16777216),
    MANUFACTURER VARCHAR(16777216),
    MODEL VARCHAR(16777216),
    INSTALL_DATE DATE,
    CRITICALITY VARCHAR(16777216),
    RATED_RPM NUMBER(10,0),
    MAX_TEMP_C NUMBER(5,1),
    MAX_VIBRATION_MM_S NUMBER(5,2),
    HOURLY_DOWNTIME_COST_USD NUMBER(10,2)
) COMMENT = 'Plant assets/equipment master data with operational limits';

-- PLANTS: 3 manufacturing plants
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.PLANTS (
    PLANT_ID VARCHAR(16777216),
    PLANT_NAME VARCHAR(16777216),
    COUNTRY VARCHAR(16777216),
    TIMEZONE VARCHAR(16777216)
) COMMENT = 'Manufacturing plants master data';

-- PRODUCTION_LINES: 8 production lines across plants
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.PRODUCTION_LINES (
    LINE_ID VARCHAR(16777216),
    PLANT_ID VARCHAR(16777216),
    LINE_NAME VARCHAR(16777216),
    SHIFT_PATTERN VARCHAR(16777216)
) COMMENT = 'Production lines master data';

-- PRODUCTION_ORDERS: ERP production orders for OEE calculation
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.PRODUCTION_ORDERS (
    ORDER_ID VARCHAR(16777216) NOT NULL COMMENT 'Unique production order identifier',
    LINE_ID VARCHAR(16777216) NOT NULL COMMENT 'Production line FK',
    PRODUCT_SKU VARCHAR(16777216) NOT NULL COMMENT 'Product SKU being manufactured',
    SHIFT_DATE DATE NOT NULL COMMENT 'Shift date',
    SHIFT VARCHAR(16777216) NOT NULL COMMENT 'Shift: A (06-14), B (14-22), C (22-06)',
    PLANNED_RUNTIME_MIN NUMBER(38,0) NOT NULL COMMENT 'Planned production time in minutes',
    RUN_TIME_MIN NUMBER(38,0) NOT NULL COMMENT 'Actual run time in minutes',
    IDEAL_CYCLE_TIME_SEC NUMBER(6,2) NOT NULL COMMENT 'Ideal cycle time per unit in seconds',
    TOTAL_COUNT NUMBER(38,0) NOT NULL COMMENT 'Total units produced',
    GOOD_COUNT NUMBER(38,0) NOT NULL COMMENT 'Units passing quality check',
    SCRAP_COUNT NUMBER(38,0) NOT NULL COMMENT 'Defective/scrapped units',
    CONSTRAINT PK_PRODUCTION_ORDERS PRIMARY KEY (ORDER_ID)
) COMMENT = 'ERP production orders per line per shift for OEE calculation';

-- DOWNTIME_EVENTS: Stop events with reason codes
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.DOWNTIME_EVENTS (
    EVENT_ID VARCHAR(16777216) NOT NULL COMMENT 'Unique downtime event identifier',
    ASSET_ID VARCHAR(16777216) COMMENT 'Asset involved (null for line-level events)',
    LINE_ID VARCHAR(16777216) NOT NULL COMMENT 'Production line affected',
    START_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'Downtime start (UTC)',
    END_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'Downtime end (UTC)',
    REASON_CODE VARCHAR(16777216) NOT NULL COMMENT 'Reason: EQUIPMENT_FAILURE, PM_SCHEDULED, CHANGEOVER, MATERIAL_SHORTAGE, OPERATOR, QUALITY_HOLD',
    IS_PLANNED BOOLEAN NOT NULL COMMENT 'True for planned downtime (PM, changeover)',
    CONSTRAINT PK_DOWNTIME PRIMARY KEY (EVENT_ID)
) COMMENT = 'Downtime events (planned and unplanned) affecting production lines';

-- FAILURE_EVENTS: Ground truth for ML model training
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.FAILURE_EVENTS (
    EVENT_ID NUMBER(38,0) NOT NULL AUTOINCREMENT COMMENT 'Unique failure event ID',
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset that failed',
    FAILURE_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'Timestamp of actual failure',
    FAILURE_MODE VARCHAR(16777216) NOT NULL COMMENT 'Type: BEARING_WEAR, OVERHEATING, IMBALANCE, SEAL_LEAK, LUBRICATION_FAILURE',
    DEGRADATION_START_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'When degradation pattern began (24-72h before failure)',
    DEGRADATION_HOURS NUMBER(5,1) NOT NULL COMMENT 'Hours of degradation before failure',
    DOWNTIME_HOURS NUMBER(5,1) NOT NULL COMMENT 'Hours of downtime after failure',
    CONSTRAINT PK_FAILURE_EVENTS PRIMARY KEY (EVENT_ID)
) COMMENT = 'Ground truth: injected failure events for model training/evaluation';

-- WORK_ORDERS_HIST: Maintenance work order history
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.WORK_ORDERS_HIST (
    WO_ID VARCHAR(16777216) NOT NULL COMMENT 'Unique work order identifier',
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset FK',
    CREATED_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'Work order creation timestamp',
    CLOSED_TS TIMESTAMP_NTZ(9) COMMENT 'Work order closure timestamp',
    WO_TYPE VARCHAR(16777216) NOT NULL COMMENT 'Type: PM (preventive), CM (corrective), PdM (predictive)',
    PRIORITY VARCHAR(16777216) NOT NULL COMMENT 'Priority: P1-P4',
    FAILURE_MODE VARCHAR(16777216) COMMENT 'Failure mode (for CM/PdM orders)',
    ROOT_CAUSE VARCHAR(16777216) COMMENT 'Identified root cause',
    ACTION_TAKEN VARCHAR(16777216) COMMENT 'Corrective/preventive action description',
    PARTS_USED VARCHAR(16777216) COMMENT 'Parts consumed (comma-separated)',
    TECHNICIAN VARCHAR(16777216) NOT NULL COMMENT 'Assigned technician name',
    DOWNTIME_MIN NUMBER(38,0) COMMENT 'Total downtime in minutes',
    COST_USD NUMBER(10,2) COMMENT 'Total repair/maintenance cost in USD',
    TECHNICIAN_NOTES VARCHAR(16777216) COMMENT 'Free-text technician observations and notes',
    CONSTRAINT PK_WO PRIMARY KEY (WO_ID)
) COMMENT = 'Maintenance work order history from CMMS (corrective and preventive)';

-- SPARE_PARTS: Inventory with reorder points
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.SPARE_PARTS (
    PART_ID VARCHAR(16777216) NOT NULL COMMENT 'Unique part identifier',
    ASSET_TYPE VARCHAR(16777216) NOT NULL COMMENT 'Applicable asset type',
    PART_NAME VARCHAR(16777216) NOT NULL COMMENT 'Part description',
    FAILURE_MODE VARCHAR(16777216) COMMENT 'Associated failure mode',
    ON_HAND_QTY NUMBER(38,0) NOT NULL COMMENT 'Current stock quantity',
    REORDER_POINT NUMBER(38,0) NOT NULL COMMENT 'Minimum stock before reorder',
    LEAD_TIME_DAYS NUMBER(38,0) NOT NULL COMMENT 'Supplier lead time in days',
    UNIT_COST_USD NUMBER(10,2) NOT NULL COMMENT 'Cost per unit in USD',
    CONSTRAINT PK_SPARE_PARTS PRIMARY KEY (PART_ID)
) COMMENT = 'Spare parts inventory with reorder points and costs';

-- MAINT_DOCS: Maintenance documentation for Cortex Search
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.MAINT_DOCS (
    DOC_ID VARCHAR(16777216) NOT NULL COMMENT 'Unique document section ID',
    ASSET_TYPE VARCHAR(16777216) NOT NULL COMMENT 'Applicable asset type',
    TITLE VARCHAR(16777216) NOT NULL COMMENT 'Document section title',
    SECTION VARCHAR(16777216) NOT NULL COMMENT 'Section category: SYMPTOMS, CAUSES, INSPECTION, FIX, SAFETY',
    CONTENT VARCHAR(16777216) NOT NULL COMMENT 'Troubleshooting guide text content',
    CONSTRAINT PK_DOCS PRIMARY KEY (DOC_ID)
) COMMENT = 'Maintenance troubleshooting manuals and procedures for Cortex Search';

-- DEGRADATION_INJECTIONS: Control table for demo degradation
CREATE OR REPLACE TABLE MFG_PDM_DB.RAW.DEGRADATION_INJECTIONS (
    ASSET_ID VARCHAR(16777216) NOT NULL COMMENT 'Asset to inject degradation',
    FAILURE_MODE VARCHAR(16777216) NOT NULL COMMENT 'Failure mode to simulate',
    START_TS TIMESTAMP_NTZ(9) NOT NULL COMMENT 'When degradation started',
    RAMP_HOURS NUMBER(5,1) NOT NULL COMMENT 'Hours for full degradation',
    ACTIVE BOOLEAN DEFAULT TRUE COMMENT 'Whether this injection is active'
) COMMENT = 'Control table for injecting live degradation patterns for demo';
