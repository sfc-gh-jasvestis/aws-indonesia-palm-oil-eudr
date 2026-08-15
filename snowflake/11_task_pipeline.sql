-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for EUDR Compliance Engine
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_REFRESH_SATELLITE
  WAREHOUSE = EUDR_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  COMMENT = 'Ingest latest satellite deforestation alerts'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_CHECK_POLYGONS
  WAREHOUSE = EUDR_WH
  AFTER APP.TASK_REFRESH_SATELLITE
  COMMENT = 'Run geospatial intersection checks on all plot polygons'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_GENERATE_DDS
  WAREHOUSE = EUDR_WH
  AFTER APP.TASK_CHECK_POLYGONS
  COMMENT = 'Generate due diligence statements for compliant shipments'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_GENERATE_DDS RESUME;
ALTER TASK APP.TASK_CHECK_POLYGONS RESUME;
ALTER TASK APP.TASK_REFRESH_SATELLITE RESUME;
