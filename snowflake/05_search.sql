-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for EUDR Compliance Engine
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.COMPLIANCE_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, COMMODITY, ARTICLE_REF
  WAREHOUSE = EUDR_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.COMPLIANCE_DOCS
);
