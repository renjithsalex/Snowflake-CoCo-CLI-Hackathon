-- =============================================================================
-- AI SERVICES: Cortex Search, Semantic View, Cortex Agent
-- =============================================================================

-- Cortex Search Service: Vector search over maintenance documents
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

-- Semantic View: PDM_OEE_ANALYTICS
-- Maps 4 curated tables with business descriptions for Cortex Analyst
-- Enables English-to-SQL conversion for non-technical users
-- Contains 5 verified queries for common manufacturing questions
-- NOTE: Semantic Views are defined via YAML files, not SQL DDL
-- See: cortex_project/PDM_OEE_ANALYTICS.sv.yaml

-- Cortex Agent: PDM_COMMAND_CENTER
-- Combines Cortex Analyst (data queries) + Cortex Search (doc search)
-- Available in Snowflake Intelligence for conversational analytics
-- NOTE: Cortex Agents are defined via YAML files, not SQL DDL
-- See: cortex_project/PDM_COMMAND_CENTER.agent.yaml
