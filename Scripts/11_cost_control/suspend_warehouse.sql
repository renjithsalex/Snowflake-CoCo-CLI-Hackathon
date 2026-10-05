-- =============================================================================
-- 11_COST_CONTROL: SUSPEND WAREHOUSE — Force warehouse to stop consuming
-- =============================================================================
-- WHY: A Snowflake warehouse consumes credits ONLY while RUNNING.
--      When suspended, cost = $0. AUTO_SUSPEND handles this automatically,
--      but you can force-suspend for immediate savings.
--
-- HOW WAREHOUSE BILLING WORKS:
--   - Credits are charged per-second while the warehouse is RUNNING
--   - Minimum 60-second charge per resume event
--   - A suspended warehouse costs NOTHING (no storage, no compute)
--   - AUTO_RESUME = TRUE means it wakes up automatically on next query
--
-- ─── COST BY WAREHOUSE SIZE ──────────────────────────────────────────────────
--
-- ┌───────────┬──────────────┬──────────────┬──────────────┬────────────────┐
-- │ Size      │ Credits/Hour │ $/Hour (Std) │ $/Hour (Ent) │ If ON 24/7/mo  │
-- ├───────────┼──────────────┼──────────────┼──────────────┼────────────────┤
-- │ X-SMALL   │ 1            │ $3           │ $4           │ $2,160-$2,880  │
-- │ SMALL     │ 2            │ $6           │ $8           │ $4,320-$5,760  │
-- │ MEDIUM    │ 4            │ $12          │ $16          │ $8,640-$11,520 │
-- │ LARGE     │ 8            │ $24          │ $32          │ $17,280-$23k   │
-- └───────────┴──────────────┴──────────────┴──────────────┴────────────────┘
--
-- KEY INSIGHT: With AUTO_SUSPEND = 60 and tasks running every 1-15 min,
--   the warehouse wakes up, runs for 2-10 seconds, then suspends after 60s
--   idle. So you pay ~1 min of compute per task execution.
--
-- ACTUAL COST for OEE Command Center:
--   MEDIUM (current): ~5-6 credits/day = ~$15-24/day = ~$450-720/month
--   SMALL (recommended): ~3-4 credits/day = ~$9-16/day = ~$270-480/month
--   SUSPENDED: $0/day
--
-- WHEN TO SUSPEND:
--   - Overnight / weekends when nobody is looking at dashboards
--   - During development when you don't need live data
--   - When you've stopped tasks and want to ensure zero spend
--
-- WHEN NOT TO SUSPEND:
--   - If tasks are still running (they'll fail or queue up)
--   - If users are actively querying the Streamlit app
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════════════════════
-- SUSPEND WAREHOUSE (immediate, zero cost)
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER WAREHOUSE MFG_PDM_WH SUSPEND;

-- Verify
SHOW WAREHOUSES LIKE 'MFG_PDM_WH';
-- STATE should be 'Suspended'


-- ═══════════════════════════════════════════════════════════════════════════════
-- RESUME WAREHOUSE (starts billing again)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ALTER WAREHOUSE MFG_PDM_WH RESUME;

-- Or just run any query — AUTO_RESUME = TRUE will wake it up automatically.


-- ═══════════════════════════════════════════════════════════════════════════════
-- DOWNSIZE WAREHOUSE (permanent cost reduction, keeps running)
-- ═══════════════════════════════════════════════════════════════════════════════
-- After initial data generation, MEDIUM isn't needed.
-- SMALL handles the ongoing workload at half the cost.

-- ALTER WAREHOUSE MFG_PDM_WH SET WAREHOUSE_SIZE = 'SMALL';

-- Or go to X-SMALL for demo/dev (quarter the cost):
-- ALTER WAREHOUSE MFG_PDM_WH SET WAREHOUSE_SIZE = 'XSMALL';


-- ═══════════════════════════════════════════════════════════════════════════════
-- OPTIMIZE AUTO-SUSPEND TIMING
-- ═══════════════════════════════════════════════════════════════════════════════
-- Current: 60 seconds. This is good for task-driven workloads.
-- For interactive use (Streamlit), you might want 120-300s to avoid
-- cold-start delays on every page load.

-- Check current setting:
SELECT "name", "size", "auto_suspend", "auto_resume"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Aggressive (saves most, slight cold-start penalty):
-- ALTER WAREHOUSE MFG_PDM_WH SET AUTO_SUSPEND = 60;

-- Balanced (good for interactive + automated):
-- ALTER WAREHOUSE MFG_PDM_WH SET AUTO_SUSPEND = 120;

-- Interactive-friendly (less savings, no cold starts):
-- ALTER WAREHOUSE MFG_PDM_WH SET AUTO_SUSPEND = 300;
