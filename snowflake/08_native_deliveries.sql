-- ============================================================================
-- 08_native_deliveries.sql - Snowflake-only build: live FFB delivery feed without AWS.
-- Creates RAW.LIVE_DELIVERIES (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_DELIVERIES(N), which inserts synthetic
-- mill-gate FFB delivery events with the same value ranges and ~10% FLAG rate
-- (delivery ticket without a matching geolocated plot) as aws/publish_deliveries.py.
-- Rows are inserted directly; this simulates a mill weighbridge feed and is not
-- Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_DELIVERIES).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_DELIVERIES (
  BASE_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, DELIVERY_TONNES FLOAT, GEO_MISMATCH_PCT FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_DELIVERIES(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_DELIVERIES (BASE_ID, EVENT_TS, DELIVERY_TONNES, GEO_MISMATCH_PCT, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'SB-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS BASE_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_FLAG,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs a constant mean, so the flag offset is added outside it.
    SELECT BASE_ID, TS,
           ROUND(IFF(IS_FLAG, 4, 6) * EXP(NORMAL(0, 0.5, RANDOM())), 2),
           ROUND(GREATEST(0, IFF(IS_FLAG, 7.5, 1.2) + NORMAL(0, 0.8, RANDOM())), 2),
           IFF(IS_FLAG, 'FLAG', 'OK'), TS, 'APP.SIMULATE_DELIVERIES'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_DELIVERIES
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_DELIVERIES(5);
