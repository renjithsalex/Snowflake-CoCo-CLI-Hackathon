-- =============================================================================
-- 11_COST_CONTROL: SUSPEND TASKS — Stop all automated credit consumption
-- =============================================================================
-- WHY: Tasks are the #1 ongoing cost driver in the OEE Command Center.
--      Suspending them immediately stops all automated credit burn.
--
-- WHAT GETS SUSPENDED:
--   TASK_STREAM_SENSORS   — runs every 1 minute  → biggest cost driver
--   TASK_SCORE_ALL        — runs every 15 minutes
--   TASK_TRIAGE_PIPELINE  — runs every 15 minutes
--   ALERT_CRITICAL_ASSETS — checks every 15 minutes
--
-- WHAT KEEPS RUNNING (even after suspend):
--   Dynamic Tables — they refresh when source data changes, but with no
--                    new sensor data arriving, they effectively stop too.
--   Cortex Search  — has its own background refresh (minimal cost).
--   Streamlit App  — stays accessible but shows stale data.
--
-- ─── COST IMPACT ─────────────────────────────────────────────────────────────
--
-- ┌──────────────────────────┬────────────┬────────────┬──────────────────────┐
-- │ Component                │ Running    │ Suspended  │ Monthly Savings      │
-- ├──────────────────────────┼────────────┼────────────┼──────────────────────┤
-- │ TASK_STREAM_SENSORS      │ ~3 cr/day  │ 0 cr/day   │ ~$270-360/mo saved   │
-- │ TASK_SCORE_ALL           │ ~0.5 cr/d  │ 0 cr/day   │ ~$45-60/mo saved     │
-- │ TASK_TRIAGE_PIPELINE     │ ~0.3 cr/d  │ 0 cr/day   │ ~$27-36/mo saved     │
-- │ DT Refreshes (triggered) │ ~1 cr/day  │ ~0 cr/day  │ ~$90-120/mo saved    │
-- │ Warehouse idle spin-up   │ ~0.5 cr/d  │ 0 cr/day   │ ~$45-60/mo saved     │
-- ├──────────────────────────┼────────────┼────────────┼──────────────────────┤
-- │ TOTAL                    │ ~5-6 cr/d  │ ~0 cr/day  │ ~$480-640/mo saved   │
-- └──────────────────────────┴────────────┴────────────┴──────────────────────┘
-- (Based on $3/credit Standard Edition; Enterprise = $4/credit → multiply by 1.33)
--
-- YES, suspend DOES reduce cost to near-zero because:
--   1. No tasks → no queries → warehouse auto-suspends after 60s idle
--   2. No new sensor data → DTs have nothing to refresh
--   3. The warehouse only costs credits while RUNNING (not while suspended)
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════════════════════
-- OPTION A: SUSPEND ALL TASKS (full shutdown)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Suspend in reverse dependency order (triage depends on scoring data)
ALTER TASK MFG_PDM_DB.OPS.TASK_TRIAGE_PIPELINE SUSPEND;
ALTER TASK MFG_PDM_DB.ML.TASK_SCORE_ALL SUSPEND;
ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS SUSPEND;

-- Suspend the alert too
ALTER ALERT MFG_PDM_DB.OPS.ALERT_CRITICAL_ASSETS SUSPEND;


-- ═══════════════════════════════════════════════════════════════════════════════
-- OPTION B: SUSPEND ONLY SENSOR STREAMING (keep scoring + triage active)
-- ═══════════════════════════════════════════════════════════════════════════════
-- This is useful when you already have enough data and just want ML/alerts
-- to keep running on existing data. Saves ~60% of task costs.

-- ALTER TASK MFG_PDM_DB.RAW.TASK_STREAM_SENSORS SUSPEND;
-- (TASK_SCORE_ALL and TASK_TRIAGE_PIPELINE keep running)


-- ═══════════════════════════════════════════════════════════════════════════════
-- VERIFY: Check all tasks are suspended
-- ═══════════════════════════════════════════════════════════════════════════════

SHOW TASKS IN DATABASE MFG_PDM_DB;
-- STATE column should show 'suspended' for all

SHOW ALERTS IN DATABASE MFG_PDM_DB;
-- STATE column should show 'suspended'
