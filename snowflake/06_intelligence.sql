-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-delivery alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes validated __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_DELIVERIES.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic traceability SOPs (clearly synthetic, not legal guidance) ----------
CREATE OR REPLACE TABLE SEARCH.EUDR_SOP_DOCS AS
WITH signals AS (
  SELECT DISTINCT r.RISK_SIGNAL, b.CATEGORY
  FROM RAW.SUPPLY_DAILY r JOIN RAW.SUPPLY_BASES b ON b.ID = r.ENTITY_ID
  WHERE r.CONFIRMED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, RISK_SIGNAL)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  RISK_SIGNAL,
  CATEGORY || ' - ' || RISK_SIGNAL || ' follow-up' AS TITLE,
  'Synthetic demo SOP for a fictional supplier network; not legal advice. Supplier type: ' || CATEGORY || '. Risk signal: ' || RISK_SIGNAL || '. '
  || 'Step 1: place the deliveries from the affected plots on hold for EU-bound stock, and notify the supply base coordinator within 2 business days. '
  || 'Step 2: ' || CASE
       WHEN RISK_SIGNAL = 'Canopy loss alert inside concession' THEN 'compare the estate block polygon with the synthetic canopy layer for dates before and after the cut-off, and send a field team to photograph the block.'
       WHEN RISK_SIGNAL = 'Plot overlaps forest baseline' THEN 'check the plot polygon against the forest baseline layer, confirm the planting year with the grower, and record any overlap area in hectares.'
       WHEN RISK_SIGNAL = 'Polygon boundary outdated' THEN 'ask the plasma cooperative to re-survey the plot boundary and replace the stored polygon before the next delivery is accepted.'
       WHEN RISK_SIGNAL = 'Canopy loss alert near plot' THEN 'review the alert distance and date against the plot geolocation, and visit the plot if the alert falls inside or next to it.'
       WHEN RISK_SIGNAL = 'Plot without geolocation' THEN 'collect the plot coordinates with the grower, using a polygon where the plot boundary can be walked, and attach them to the registry before accepting more deliveries.'
       WHEN RISK_SIGNAL = 'Unregistered plot delivery' THEN 'ask the FFB dealer for the grower name and plot location behind the delivery ticket, and register the plot or reject the lot.'
       WHEN RISK_SIGNAL = 'Supplier list incomplete' THEN 'request the full supplier and plot list from the third-party mill, and keep its deliveries out of EU-bound stock until the list is complete.'
       ELSE 'review the delivery against the plot registry and escalate if unexplained.'
     END
  || ' Step 3: if geolocation mismatches exceed 5% or more than a third of intake tonnes come from unmapped plots, keep the case open and schedule a supplier visit. '
  || 'Step 4: record the outcome and the evidence; if canopy loss after the cut-off is confirmed on the plot, keep its lots out of EU-bound stock, with sign-off from the sustainability lead.' AS CONTENT
FROM signals;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.EUDR_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, RISK_SIGNAL
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, RISK_SIGNAL, CONTENT FROM SEARCH.EUDR_SOP_DOCS);

-- ---------- Geolocation-mismatch anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.GEO_MISMATCH_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, GEO_MISMATCH_PCT::FLOAT AS GEO_MISMATCH
FROM RAW.SUPPLY_DAILY;
CREATE OR REPLACE VIEW ML.GEO_MISMATCH_TRAIN AS
SELECT * FROM ML.GEO_MISMATCH_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.GEO_MISMATCH_SERIES);
CREATE OR REPLACE VIEW ML.GEO_MISMATCH_DETECT AS
SELECT * FROM ML.GEO_MISMATCH_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.GEO_MISMATCH_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.GEO_MISMATCH_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.GEO_MISMATCH_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'GEO_MISMATCH',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.GEO_MISMATCH_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS GEO_MISMATCH, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.GEO_MISMATCH_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.GEO_MISMATCH_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'GEO_MISMATCH'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.EUDR_ANALYTICS
  TABLES (
    bases AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'supply bases', 'suppliers')
      COMMENT = 'One row per supply base (city x supplier type), 90-day totals',
    risk AS ML.CANOPY_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day probability of a confirmed canopy-loss case per supply base',
    signals AS CURATED.SIGNAL_SUMMARY PRIMARY KEY (RISK_SIGNAL)
      COMMENT = 'Screening flags, confirmed canopy-loss cases and excluded lots by risk signal, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_base AS risk (ENTITY_ID) REFERENCES bases)
  FACTS (
    bases.deliveries_f AS DELIVERY_COUNT,
    bases.traced_f AS TRACED_TONNES,
    bases.intake_f AS FFB_TONNES,
    bases.flags_f AS FLAG_COUNT,
    bases.confirmed_f AS CONFIRMED_COUNT,
    bases.excluded_f AS EXCLUDED_COUNT,
    bases.decl_due_f AS DECLARATION_DUE,
    bases.decl_received_f AS DECLARATION_RECEIVED,
    risk.loss_prob_f AS LOSS_PROB_7D,
    signals.sig_flags_f AS FLAG_COUNT,
    signals.sig_confirmed_f AS CONFIRMED_COUNT,
    signals.sig_excluded_f AS EXCLUDED_COUNT,
    daily.day_deliveries_f AS DELIVERY_COUNT,
    daily.day_traced_f AS TRACED_TONNES,
    daily.day_intake_f AS FFB_TONNES,
    daily.day_flags_f AS FLAG_COUNT
  )
  DIMENSIONS (
    bases.base_id AS ENTITY_ID WITH SYNONYMS = ('entity', 'supply base', 'supply base id'),
    bases.base_name AS ENTITY_NAME,
    bases.city AS REGION WITH SYNONYMS = ('city', 'region', 'mill hub') COMMENT = 'Indonesian mill-hub city of the supply base',
    bases.supplier_type AS CATEGORY WITH SYNONYMS = ('supplier type', 'supply channel', 'category'),
    bases.risk_tier AS RISK_TIER COMMENT = 'Sourcing risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    signals.risk_signal AS RISK_SIGNAL WITH SYNONYMS = ('signal', 'red flag', 'screening signal'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    bases.supply_base_count AS COUNT(bases.base_id) WITH SYNONYMS = ('number of entities', 'number of supply bases'),
    bases.traceability_to_plot_pct AS 100 * SUM(bases.traced_f) / NULLIF(SUM(bases.intake_f), 0)
      COMMENT = 'FFB tonnes traced to a geolocated plot / FFB intake tonnes',
    bases.total_deliveries AS SUM(bases.deliveries_f) WITH SYNONYMS = ('deliveries', 'FFB deliveries'),
    bases.total_traced_tonnes AS SUM(bases.traced_f) WITH SYNONYMS = ('traced tonnes', 'tonnes traced to plot'),
    bases.total_intake_tonnes AS SUM(bases.intake_f) WITH SYNONYMS = ('FFB intake', 'intake tonnes'),
    bases.total_flags AS SUM(bases.flags_f) WITH SYNONYMS = ('screening flags', 'flags'),
    bases.total_confirmed AS SUM(bases.confirmed_f) WITH SYNONYMS = ('confirmed canopy-loss cases', 'confirmed cases'),
    bases.total_excluded AS SUM(bases.excluded_f) WITH SYNONYMS = ('excluded lots', 'lots excluded'),
    bases.flag_precision_pct AS 100 * SUM(bases.confirmed_f) / NULLIF(SUM(bases.flags_f), 0)
      COMMENT = 'Confirmed canopy-loss cases / screening flags',
    bases.declaration_rate_pct AS 100 * SUM(bases.decl_received_f) / NULLIF(SUM(bases.decl_due_f), 0)
      COMMENT = 'Supplier geolocation declarations received / declarations due',
    risk.avg_loss_prob AS AVG(risk.loss_prob_f),
    signals.signal_flags AS SUM(signals.sig_flags_f),
    signals.signal_confirmed AS SUM(signals.sig_confirmed_f),
    signals.signal_excluded AS SUM(signals.sig_excluded_f),
    signals.signal_precision_pct AS 100 * SUM(signals.sig_confirmed_f) / NULLIF(SUM(signals.sig_flags_f), 0),
    daily.daily_deliveries AS SUM(daily.day_deliveries_f),
    daily.daily_intake_tonnes AS SUM(daily.day_intake_f),
    daily.daily_traceability_pct AS 100 * SUM(daily.day_traced_f) / NULLIF(SUM(daily.day_intake_f), 0),
    daily.daily_flags AS SUM(daily.day_flags_f)
  )
  COMMENT = 'Synthetic Indonesia palm oil EUDR due-diligence readiness analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.EUDR_AGENT
  COMMENT = 'EUDR due-diligence readiness assistant over a synthetic palm oil supplier network'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic and that screening results are demo signals, not compliance verdicts. Give supply base IDs and numbers with units."
  orchestration: "Use eudr_analyst for FFB deliveries, intake and traced tonnes, traceability to plot, screening flags, confirmed canopy-loss cases, excluded lots, supplier declarations, cities, supplier types, risk signals and canopy-loss risk. Use sop_search for follow-up procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: eudr_analyst
      description: "FFB deliveries, intake tonnes, traceability to plot, screening flags, confirmed canopy-loss cases, excluded lots, flag precision, supplier declaration rate, risk signals and canopy-loss risk scores by supply base"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic traceability follow-up SOPs by supplier type and risk signal"
tool_resources:
  eudr_analyst:
    semantic_view: __DEMO_DB__.APP.EUDR_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.EUDR_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-delivery alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), BASE_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, DELIVERY_TONNES FLOAT, GEO_MISMATCH_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION ID_EUDR_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_FLAGS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (BASE_ID, EVENT_TS, DELIVERY_TONNES, GEO_MISMATCH_PCT, SOP_HINT)
    SELECT c.BASE_ID, c.EVENT_TS, c.DELIVERY_TONNES, c.GEO_MISMATCH_PCT,
           'Check ' || b.CATEGORY || ' traceability SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_DELIVERIES c
    JOIN RAW.SUPPLY_BASES b ON b.ID = c.BASE_ID
    LEFT JOIN ML.CANOPY_RISK_SCORES r ON r.ENTITY_ID = c.BASE_ID
    WHERE c.STATUS = 'FLAG'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BASE_ID = c.BASE_ID AND l.EVENT_TS = c.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('ID_EUDR_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] FFB delivery traceability alert',
      'New flagged live deliveries logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_DELIVERY_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_DELIVERIES c
    WHERE c.STATUS = 'FLAG'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BASE_ID = c.BASE_ID AND l.EVENT_TS = c.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_FLAGS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.SIGNAL_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.CANOPY_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.CANOPY_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.CANOPY_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'PROGRAM_YEARS', PROGRAM_YEARS,
             'GEO_MISMATCH_PCT', GEO_MISMATCH_PCT, 'UNMAPPED_PCT', UNMAPPED_PCT,
             'GEO_MISMATCH_7D', GEO_MISMATCH_7D, 'CONFIRMED_30D', CONFIRMED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:LOSS::FLOAT, 4) AS LOSS_PROB_7D,
         CASE WHEN PRED:probability:LOSS::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:LOSS::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
