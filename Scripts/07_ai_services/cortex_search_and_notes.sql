-- =============================================================================
-- 07_AI_SERVICES: Cortex Search, Semantic View, Cortex Agent
-- =============================================================================
-- Semantic View and Cortex Agent are managed via YAML files in cortex_project/
-- This script handles the Cortex Search Service (SQL-managed).
-- =============================================================================

-- Cortex Search Service: vector search over 40 maintenance documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MFG_PDM_DB.AI.MAINT_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES ASSET_TYPE, TITLE, SECTION
  WAREHOUSE = 'MFG_PDM_WH'
  TARGET_LAG = '1 hour'
  COMMENT = 'Search service over maintenance documentation for root-cause investigation'
AS (
    SELECT DOC_ID, ASSET_TYPE, TITLE, SECTION, CONTENT,
        ASSET_TYPE || ' - ' || TITLE || ' - ' || SECTION || ': ' || CONTENT AS CONTENT_FULL
    FROM MFG_PDM_DB.RAW.MAINT_DOCS
);

-- ─── NOTES ───────────────────────────────────────────────────────────────────
-- Semantic View: MFG_PDM_DB.AI.PDM_OEE_ANALYTICS
--   Managed via: cortex_project/PDM_OEE_ANALYTICS.sv.yaml
--   Deploy:  cortex agent-studio sv-deploy --file-path PDM_OEE_ANALYTICS.sv.yaml --fqn MFG_PDM_DB.AI.PDM_OEE_ANALYTICS
--   Tables:  DT_ASSET_HEALTH, DT_OEE_LINE_DAILY, DT_OEE_PLANT_DAILY, DT_DOWNTIME_PARETO
--   VQRs:    5 verified queries for common manufacturing questions
--
-- Cortex Agent: MFG_PDM_DB.AI.PDM_COMMAND_CENTER
--   Managed via: cortex_project/PDM_COMMAND_CENTER.agent.yaml
--   Deploy:  cortex agent-studio agent-deploy --file-path PDM_COMMAND_CENTER.agent.yaml --fqn MFG_PDM_DB.AI.PDM_COMMAND_CENTER
--   Tools:   Cortex Analyst (PDM_OEE_ANALYTICS) + Cortex Search (MAINT_DOCS_SEARCH)
