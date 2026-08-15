-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for EUDR Compliance Engine
-- Country: INDONESIA | Currency: IDR
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- PLOT_POLYGONS: 15,000 rows — Georeferenced plot boundaries for all supply chain plantations (GeoJSON)
-- DEFORESTATION_BASELINE: 50,000 rows — Post-2020 forest cover change data from satellite imagery
-- SHIPMENT_DOSSIERS: 20,000 rows — Per-shipment compliance documentation and geolocation links
-- DUE_DILIGENCE_STATEMENTS: 3,000 rows — Generated EUDR due diligence statements for EU submission
-- SATELLITE_ALERTS: 100,000 rows — GLAD/GFW deforestation alert points with confidence scores
-- COMPLIANCE_DOCS: 200 rows — EUDR regulatory text, guidance documents, and precedent decisions
