-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for EUDR Compliance Engine
-- ============================================================================
USE DATABASE PALM_OIL_EUDR;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_indonesia_palm_oil_eudr_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: DEFORESTATION_OVERLAP_ALERT
CREATE OR REPLACE ALERT APP.DEFORESTATION_OVERLAP_ALERT
  WAREHOUSE = EUDR_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Plot deforestation risk detected — EUDR compliance at risk'
IF (EXISTS (
  SELECT 1 FROM CURATED.PLOT_DEFORESTATION_CHECK
  WHERE 1=1 -- Condition: New plot polygon overlaps with post-2020 deforestation area
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_palm_oil_eudr_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] EUDR Compliance Engine: Plot deforestation risk detected — EUDR compliance at risk',
    'Plot deforestation risk detected — EUDR compliance at risk'
  );

ALTER ALERT APP.DEFORESTATION_OVERLAP_ALERT RESUME;

-- Alert: DDS_DEADLINE_ALERT
CREATE OR REPLACE ALERT APP.DDS_DEADLINE_ALERT
  WAREHOUSE = EUDR_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'EUDR submission deadline approaching'
IF (EXISTS (
  SELECT 1 FROM CURATED.PLOT_DEFORESTATION_CHECK
  WHERE 1=1 -- Condition: Due diligence statement submission deadline within 7 days
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_palm_oil_eudr_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] EUDR Compliance Engine: EUDR submission deadline approaching',
    'EUDR submission deadline approaching'
  );

ALTER ALERT APP.DDS_DEADLINE_ALERT RESUME;

