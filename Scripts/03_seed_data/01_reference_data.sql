-- =============================================================================
-- 03_SEED_DATA: Reference / master data inserts
-- =============================================================================
-- Run AFTER 02_tables. Populates all small reference tables.
-- Safe to re-run: will insert duplicates, so TRUNCATE first if re-running.
-- =============================================================================

-- ===== PLANTS (3) =====
TRUNCATE TABLE IF EXISTS MFG_PDM_DB.RAW.PLANTS;
INSERT INTO MFG_PDM_DB.RAW.PLANTS VALUES
('PLT-01', 'Pune Manufacturing Hub', 'India', 'Asia/Kolkata'),
('PLT-02', 'Bangkok Smart Factory', 'Thailand', 'Asia/Bangkok'),
('PLT-03', 'Penang Tech Plant', 'Malaysia', 'Asia/Kuala_Lumpur');

-- ===== PRODUCTION LINES (8) =====
TRUNCATE TABLE IF EXISTS MFG_PDM_DB.RAW.PRODUCTION_LINES;
INSERT INTO MFG_PDM_DB.RAW.PRODUCTION_LINES VALUES
('LN-01', 'PLT-01', 'CNC Assembly Line 1', '3-shift'),
('LN-02', 'PLT-01', 'Robotics Line 1', '3-shift'),
('LN-03', 'PLT-01', 'Press Shop Line 1', '2-shift'),
('LN-04', 'PLT-02', 'CNC Assembly Line 2', '3-shift'),
('LN-05', 'PLT-02', 'Conveyor Line 1', '3-shift'),
('LN-06', 'PLT-02', 'Pump Station Line 1', '2-shift'),
('LN-07', 'PLT-03', 'Compressor Line 1', '3-shift'),
('LN-08', 'PLT-03', 'Mixed Assembly Line 1', '3-shift');

-- ===== ASSETS (60) — synthetic generation =====
TRUNCATE TABLE IF EXISTS MFG_PDM_DB.RAW.ASSETS;
INSERT INTO MFG_PDM_DB.RAW.ASSETS
SELECT
    CASE MOD(SEQ, 10)
      WHEN 0 THEN 'CNC' WHEN 1 THEN 'CNC' WHEN 2 THEN 'ROB' WHEN 3 THEN 'ROB'
      WHEN 4 THEN 'PRS' WHEN 5 THEN 'CNV' WHEN 6 THEN 'PMP' WHEN 7 THEN 'CMP'
      WHEN 8 THEN 'CNC' WHEN 9 THEN 'ROB'
    END || '-' || LPAD(SEQ + 1, 3, '0') AS ASSET_ID,
    CASE MOD(SEQ, 10)
      WHEN 0 THEN 'LN-01' WHEN 1 THEN 'LN-01' WHEN 2 THEN 'LN-02' WHEN 3 THEN 'LN-02'
      WHEN 4 THEN 'LN-03' WHEN 5 THEN 'LN-05' WHEN 6 THEN 'LN-06' WHEN 7 THEN 'LN-07'
      WHEN 8 THEN 'LN-04' WHEN 9 THEN 'LN-08'
    END,
    CASE MOD(SEQ, 10)
      WHEN 0 THEN 'CNC' WHEN 1 THEN 'CNC' WHEN 2 THEN 'Robot' WHEN 3 THEN 'Robot'
      WHEN 4 THEN 'Press' WHEN 5 THEN 'Conveyor' WHEN 6 THEN 'Pump' WHEN 7 THEN 'Compressor'
      WHEN 8 THEN 'CNC' WHEN 9 THEN 'Robot'
    END,
    CASE MOD(SEQ, 10)
      WHEN 0 THEN 'Fanuc' WHEN 1 THEN 'DMG Mori' WHEN 2 THEN 'ABB' WHEN 3 THEN 'KUKA'
      WHEN 4 THEN 'Schuler' WHEN 5 THEN 'Siemens' WHEN 6 THEN 'Grundfos' WHEN 7 THEN 'Atlas Copco'
      WHEN 8 THEN 'Haas' WHEN 9 THEN 'Yaskawa'
    END,
    CASE MOD(SEQ, 10)
      WHEN 0 THEN 'Robodrill-A' WHEN 1 THEN 'NLX-2500' WHEN 2 THEN 'IRB-6700' WHEN 3 THEN 'KR-60'
      WHEN 4 THEN 'TwinServo-28' WHEN 5 THEN 'S120-Conv' WHEN 6 THEN 'CR-45' WHEN 7 THEN 'GA-55'
      WHEN 8 THEN 'VF-2SS' WHEN 9 THEN 'GP-50'
    END,
    DATEADD('day', -UNIFORM(365, 2500, RANDOM()), CURRENT_DATE()),
    CASE WHEN MOD(SEQ, 3) = 0 THEN 'A' WHEN MOD(SEQ, 3) = 1 THEN 'B' ELSE 'C' END,
    CASE MOD(SEQ,10) WHEN 0 THEN 3000 WHEN 1 THEN 2500 WHEN 2 THEN 1500 WHEN 3 THEN 1800
      WHEN 4 THEN 1000 WHEN 5 THEN 1200 WHEN 6 THEN 2800 WHEN 7 THEN 3500
      WHEN 8 THEN 2800 WHEN 9 THEN 1700
    END + UNIFORM(-200, 200, RANDOM()),
    (CASE MOD(SEQ,10) WHEN 0 THEN 85 WHEN 1 THEN 80 WHEN 2 THEN 70 WHEN 3 THEN 75
      WHEN 4 THEN 80 WHEN 5 THEN 60 WHEN 6 THEN 90 WHEN 7 THEN 95
      WHEN 8 THEN 82 WHEN 9 THEN 73
    END + UNIFORM(-5, 5, RANDOM()))::NUMBER(5,1),
    (CASE MOD(SEQ,10) WHEN 0 THEN 7.10 WHEN 1 THEN 6.50 WHEN 2 THEN 5.00 WHEN 3 THEN 5.50
      WHEN 4 THEN 7.50 WHEN 5 THEN 4.00 WHEN 6 THEN 8.00 WHEN 7 THEN 9.00
      WHEN 8 THEN 6.80 WHEN 9 THEN 5.20
    END + UNIFORM(-100, 100, RANDOM()) / 100.0)::NUMBER(5,2),
    (CASE MOD(SEQ,10) WHEN 0 THEN 850 WHEN 1 THEN 900 WHEN 2 THEN 700 WHEN 3 THEN 750
      WHEN 4 THEN 950 WHEN 5 THEN 400 WHEN 6 THEN 600 WHEN 7 THEN 500
      WHEN 8 THEN 880 WHEN 9 THEN 720
    END + UNIFORM(-100, 100, RANDOM()))::NUMBER(10,2)
FROM (SELECT SEQ4() AS SEQ FROM TABLE(GENERATOR(ROWCOUNT => 60)));

-- ===== SPARE PARTS (20) =====
TRUNCATE TABLE IF EXISTS MFG_PDM_DB.RAW.SPARE_PARTS;
INSERT INTO MFG_PDM_DB.RAW.SPARE_PARTS VALUES
('SP-001','CNC','Spindle Bearing Set','BEARING_WEAR',12,5,14,450.00),
('SP-002','CNC','Coolant Pump Assembly','OVERHEATING',8,3,21,320.00),
('SP-003','CNC','Ball Screw','IMBALANCE',4,2,28,890.00),
('SP-004','Robot','Servo Motor','BEARING_WEAR',6,3,21,1200.00),
('SP-005','Robot','Harmonic Drive','IMBALANCE',3,2,35,2100.00),
('SP-006','Robot','Wrist Seal Kit','SEAL_LEAK',15,5,7,85.00),
('SP-007','Conveyor','Drive Belt Set','BEARING_WEAR',20,8,7,45.00),
('SP-008','Conveyor','Roller Bearing','BEARING_WEAR',30,10,10,28.00),
('SP-009','Pump','Mechanical Seal','SEAL_LEAK',10,4,14,180.00),
('SP-010','Pump','Impeller','IMBALANCE',5,2,21,420.00),
('SP-011','Compressor','Air Filter Element','OVERHEATING',25,10,5,35.00),
('SP-012','Compressor','Oil Separator','LUBRICATION_FAILURE',8,3,14,290.00),
('SP-013','Compressor','Valve Plate Kit','SEAL_LEAK',6,3,21,380.00),
('SP-014','Press','Hydraulic Seal Kit','SEAL_LEAK',12,5,10,150.00),
('SP-015','Press','Clutch/Brake Assembly','BEARING_WEAR',3,1,42,3200.00),
('SP-016','CNC','Tool Holder','IMBALANCE',18,6,7,120.00),
('SP-017','Robot','Cable Harness','LUBRICATION_FAILURE',5,2,28,450.00),
('SP-018','Pump','Coupling Insert','IMBALANCE',8,3,7,65.00),
('SP-019','Press','Slide Gib','LUBRICATION_FAILURE',4,2,28,780.00),
('SP-020','Conveyor','Gearbox Oil','LUBRICATION_FAILURE',40,15,5,22.00);

-- ===== OPS CONFIG (12) =====
TRUNCATE TABLE IF EXISTS MFG_PDM_DB.OPS.CONFIG;
INSERT INTO MFG_PDM_DB.OPS.CONFIG (KEY, VALUE) VALUES
('ALERT_VIB_WARNING_PCT', '0.75'),
('ALERT_VIB_CRITICAL_PCT', '0.90'),
('ALERT_TEMP_WARNING_PCT', '0.75'),
('ALERT_TEMP_CRITICAL_PCT', '0.90'),
('ALERT_FAILURE_PROB_THRESHOLD', '0.60'),
('ALERT_RUL_WARNING_HOURS', '48'),
('ALERT_RUL_CRITICAL_HOURS', '12'),
('ML_SCORING_INTERVAL_MIN', '15'),
('SENSOR_STREAM_INTERVAL_MIN', '1'),
('ANOMALY_DETECTION_PERCENTILE', '0.99'),
('WO_AUTO_GENERATE', 'TRUE'),
('WO_APPROVAL_REQUIRED', 'TRUE');
