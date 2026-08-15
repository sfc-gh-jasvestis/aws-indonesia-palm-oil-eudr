-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for EUDR Compliance Engine
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.EUDR_COMPLIANCE_ANALYTICS
  COMMENT = 'EUDR compliance status, geospatial risk, and due diligence analytics'
AS
  TABLES (
    CURATED.PLOT_DEFORESTATION_CHECK AS plot_deforestation_check,CURATED.SHIPMENT_COMPLIANCE_STATUS AS shipment_compliance_status,CURATED.DDS_GENERATION_QUEUE AS dds_generation_queue,CURATED.RISK_HEATMAP AS risk_heatmap
  );
