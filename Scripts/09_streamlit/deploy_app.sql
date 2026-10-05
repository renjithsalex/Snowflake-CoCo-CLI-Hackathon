-- =============================================================================
-- 09_STREAMLIT: Application deployment
-- =============================================================================
-- Deploys the Streamlit app on container runtime.
-- Prerequisites: streamlit_app.py and pyproject.toml in workspace root
-- =============================================================================

-- Create stage
CREATE STAGE IF NOT EXISTS MFG_PDM_DB.APP.OEE_APP_STAGE
  COMMENT = 'Stage for OEE Command Center Streamlit app files';

-- Upload app files (adjust paths for your environment)
PUT file:///workspace/streamlit_app.py @MFG_PDM_DB.APP.OEE_APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file:///workspace/pyproject.toml   @MFG_PDM_DB.APP.OEE_APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Verify files uploaded
LIST @MFG_PDM_DB.APP.OEE_APP_STAGE;

-- Create Streamlit app (requires SYSTEM_COMPUTE_POOL_CPU)
CREATE OR REPLACE STREAMLIT MFG_PDM_DB.APP.OEE_COMMAND_CENTER
  ROOT_LOCATION = '@MFG_PDM_DB.APP.OEE_APP_STAGE'
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = MFG_PDM_WH
  COMPUTE_POOL = SYSTEM_COMPUTE_POOL_CPU
  TITLE = 'OEE Command Center'
  COMMENT = 'OEE Command Center - Predictive Maintenance & OEE Dashboard';
