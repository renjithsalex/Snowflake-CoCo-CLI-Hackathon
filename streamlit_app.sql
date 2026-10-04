-- =============================================================================
-- STREAMLIT APPLICATION DEPLOYMENT
-- =============================================================================

-- Create stage for app files
CREATE STAGE IF NOT EXISTS MFG_PDM_DB.APP.OEE_APP_STAGE
  COMMENT = 'Stage for OEE Command Center Streamlit app files';

-- Upload files (run from SnowSQL or Snowsight):
-- PUT file://streamlit_app.py @MFG_PDM_DB.APP.OEE_APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- PUT file://pyproject.toml @MFG_PDM_DB.APP.OEE_APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Create the Streamlit app with container runtime
CREATE STREAMLIT MFG_PDM_DB.APP.OEE_COMMAND_CENTER
  ROOT_LOCATION = '@MFG_PDM_DB.APP.OEE_APP_STAGE'
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = MFG_PDM_WH
  COMPUTE_POOL = SYSTEM_COMPUTE_POOL_CPU
  TITLE = 'OEE Command Center'
  COMMENT = 'OEE Command Center - Predictive Maintenance & OEE Dashboard';
