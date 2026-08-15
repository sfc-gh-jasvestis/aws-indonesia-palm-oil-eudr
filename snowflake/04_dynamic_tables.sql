-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for EUDR Compliance Engine
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA CURATED;

-- PLOT_DEFORESTATION_CHECK: Geospatial intersection of plot polygons with deforestation baseline
-- Source: PLOT_POLYGONS, DEFORESTATION_BASELINE
CREATE OR REPLACE DYNAMIC TABLE CURATED.PLOT_DEFORESTATION_CHECK
  TARGET_LAG = '5 minutes'
  WAREHOUSE = EUDR_WH
AS
SELECT * FROM RAW.PLOT_POLYGONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- SHIPMENT_COMPLIANCE_STATUS: Per-shipment EUDR compliance status with evidence links
-- Source: SHIPMENT_DOSSIERS, PLOT_DEFORESTATION_CHECK
CREATE OR REPLACE DYNAMIC TABLE CURATED.SHIPMENT_COMPLIANCE_STATUS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = EUDR_WH
AS
SELECT * FROM RAW.SHIPMENT_DOSSIERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- DDS_GENERATION_QUEUE: Due diligence statements ready for generation and submission
-- Source: SHIPMENT_DOSSIERS, PLOT_DEFORESTATION_CHECK, DUE_DILIGENCE_STATEMENTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.DDS_GENERATION_QUEUE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = EUDR_WH
AS
SELECT * FROM RAW.SHIPMENT_DOSSIERS;
-- TODO: Replace with actual join/aggregation logic per demo

-- RISK_HEATMAP: Geographic risk aggregation by province and concession
-- Source: PLOT_POLYGONS, SATELLITE_ALERTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.RISK_HEATMAP
  TARGET_LAG = '5 minutes'
  WAREHOUSE = EUDR_WH
AS
SELECT * FROM RAW.PLOT_POLYGONS;
-- TODO: Replace with actual join/aggregation logic per demo

