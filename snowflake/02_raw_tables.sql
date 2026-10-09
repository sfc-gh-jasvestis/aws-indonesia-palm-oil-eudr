-- Synthetic supply-base observations for a fictional palm oil supplier network
-- in Indonesia. 40 supply bases = 8 cities x 5 supplier types. Nothing is
-- seeded as a prediction. Randomness is HASH-seeded, so every rebuild is
-- reproducible: per-base canopy-loss propensity, declaration drift between
-- periodic supplier geolocation declarations, missed declarations, type-weighted
-- risk signals, false-positive screening flags, and two area-wide fire
-- hotspot clusters. Screening results are demo signals, not compliance verdicts.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.SUPPLY_BASES AS
WITH bases AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS BASE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT BASE_INDEX,
         MOD(ABS(HASH(BASE_INDEX, 'program')), 1000000) / 1e6 AS U_PROGRAM,
         MOD(ABS(HASH(BASE_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(BASE_INDEX, 'declare')), 1000000) / 1e6 AS U_DECLARE,
         MOD(ABS(HASH(BASE_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(BASE_INDEX, 'tier')), 1000000) / 1e6 AS U_TIER,
         MOD(ABS(HASH(BASE_INDEX, 'size')), 1000000) / 1e6 AS U_SIZE
  FROM bases
), bases_named AS (
  SELECT *,
         -- Every city x supplier type combination appears exactly once.
         CASE MOD(BASE_INDEX, 8) WHEN 0 THEN 'Pekanbaru' WHEN 1 THEN 'Medan'
              WHEN 2 THEN 'Jambi' WHEN 3 THEN 'Palembang' WHEN 4 THEN 'Pontianak'
              WHEN 5 THEN 'Palangka Raya' WHEN 6 THEN 'Samarinda'
              ELSE 'Banjarmasin' END AS REGION,
         CASE FLOOR(BASE_INDEX / 8) WHEN 0 THEN 'Own estate' WHEN 1 THEN 'Plasma smallholders'
              WHEN 2 THEN 'Independent smallholders' WHEN 3 THEN 'FFB dealers'
              ELSE 'Third-party mills' END AS CATEGORY
  FROM draws
)
SELECT 'SB-' || LPAD(BASE_INDEX::VARCHAR, 4, '0') AS ID,
       REGION || ' ' || CATEGORY AS NAME,
       REGION, CATEGORY, BASE_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.3 + U_PROGRAM * 5.7, 1) AS PROGRAM_YEARS,
       ROUND(0.6 + U_SIZE * 0.8, 3) AS SIZE_FACTOR,
       -- Base daily probability of a confirmed canopy-loss case 0.3%-2.5%,
       -- higher for indirect supply; ~15% of bases sit near forest frontiers (x3).
       (0.003 + U_RATE * 0.022)
         * CASE CATEGORY WHEN 'Own estate' THEN 0.4 WHEN 'Plasma smallholders' THEN 0.8
                         WHEN 'Independent smallholders' THEN 1.4 WHEN 'FFB dealers' THEN 1.6
                         ELSE 1.1 END
         * IFF(U_RATE > 0.85, 3, 1) AS BASE_LOSS_RATE,
       7 * (1 + FLOOR(U_DECLARE * 3)) AS DECLARATION_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS DECLARATION_RETURN_PROB,
       -- Share of intake tonnes that typically comes from plots without geolocation.
       CASE CATEGORY WHEN 'Own estate' THEN 1 WHEN 'Plasma smallholders' THEN 6
                     WHEN 'Independent smallholders' THEN 30 WHEN 'FFB dealers' THEN 38
                     ELSE 20 END AS BASE_UNMAPPED_PCT,
       'Active' AS STATUS
FROM bases_named;

CREATE TABLE RAW.SUPPLY_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), hotspot_events AS (
  -- Two area-wide fire hotspot clusters; every base in the city area gets a flag.
  SELECT * FROM VALUES (27, 'Pekanbaru'), (64, 'Palangka Raya') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT b.ID AS ENTITY_ID, b.BASE_INDEX, b.CATEGORY, b.REGION, b.PROGRAM_YEARS,
         b.SIZE_FACTOR, b.BASE_UNMAPPED_PCT,
         b.BASE_LOSS_RATE, b.DECLARATION_INTERVAL_DAYS, b.DECLARATION_RETURN_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + b.BASE_INDEX * 5, b.DECLARATION_INTERVAL_DAYS) AS DAYS_SINCE_DECLARATION,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'loss')), 1000000) / 1e6 AS U_LOSS,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'fp')), 1000000) / 1e6 AS U_FP,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'signal')), 1000000) / 1e6 AS U_SIG,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'trucks')), 1000000) / 1e6 AS U_TRUCKS,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(b.ID, d.DAY_INDEX, 'exclude')), 1000000) / 1e6 AS U_EXCLUDE,
         h.REGION IS NOT NULL AS HOTSPOT_EVENT
  FROM RAW.SUPPLY_BASES b CROSS JOIN days d
  LEFT JOIN hotspot_events h ON h.DAY_INDEX = d.DAY_INDEX AND h.REGION = b.REGION
), declarations AS (
  SELECT *,
         IFF(DAYS_SINCE_DECLARATION = 0, 1, 0) AS DECLARATION_DUE,
         IFF(DAYS_SINCE_DECLARATION = 0 AND U_DONE < DECLARATION_RETURN_PROB, 1, 0) AS DECLARATION_RECEIVED,
         -- Traceability drift rises between supplier declarations; weak discipline carries it over.
         DAYS_SINCE_DECLARATION / DECLARATION_INTERVAL_DAYS + (1 - DECLARATION_RETURN_PROB) AS DRIFT
  FROM base
), activity AS (
  SELECT *,
         CASE WHEN U_LOSS < LEAST(0.5, BASE_LOSS_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_YEARS))) / 4 THEN 2
              WHEN U_LOSS < LEAST(0.5, BASE_LOSS_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_YEARS))) THEN 1
              ELSE 0 END AS LOSS_COUNT
  FROM declarations
), screening AS (
  SELECT *,
         -- Screening catches about 85% of canopy-loss cases; the rest stays undetected.
         IFF(HOTSPOT_EVENT, 0, IFF(U_DETECT < 0.85, LOSS_COUNT, 0)) AS CONFIRMED_COUNT,
         -- False-positive flags: higher where plot data is weaker.
         IFF(HOTSPOT_EVENT, 1, IFF(U_FP < CASE CATEGORY WHEN 'Independent smallholders' THEN 0.18
                                                         WHEN 'FFB dealers' THEN 0.15
                                                         WHEN 'Third-party mills' THEN 0.12
                                                         WHEN 'Plasma smallholders' THEN 0.10 ELSE 0.07 END, 1, 0)) AS FALSE_POSITIVE_COUNT
  FROM activity
), measured AS (
  SELECT *,
         CONFIRMED_COUNT + FALSE_POSITIVE_COUNT AS FLAG_COUNT,
         ROUND(CASE CATEGORY WHEN 'Own estate' THEN 40 WHEN 'Plasma smallholders' THEN 60
                             WHEN 'Independent smallholders' THEN 90 WHEN 'FFB dealers' THEN 50 ELSE 6 END
               * SIZE_FACTOR * (0.7 + 0.6 * U_TRUCKS)) AS DELIVERY_COUNT,
         CASE CATEGORY WHEN 'Own estate' THEN 12 WHEN 'Plasma smallholders' THEN 4
                       WHEN 'Independent smallholders' THEN 1.5 WHEN 'FFB dealers' THEN 8 ELSE 30 END
           * (0.85 + 0.3 * U_NOISE) AS AVG_DELIVERY_TONNES,
         LEAST(95, BASE_UNMAPPED_PCT + 6 * DRIFT + 8 * LOSS_COUNT + 2 * U_NOISE) AS UNMAPPED_SHARE
  FROM screening
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       DELIVERY_COUNT,
       ROUND(DELIVERY_COUNT * AVG_DELIVERY_TONNES * (1 - UNMAPPED_SHARE / 100), 2) AS TRACED_TONNES,
       ROUND(DELIVERY_COUNT * AVG_DELIVERY_TONNES, 2) AS FFB_TONNES,
       FLAG_COUNT, CONFIRMED_COUNT,
       IFF(CONFIRMED_COUNT > 0 AND U_EXCLUDE < 0.6, 1, 0) AS LOTS_EXCLUDED,
       CASE WHEN FLAG_COUNT = 0 THEN 'None'
            WHEN HOTSPOT_EVENT THEN 'Fire hotspot cluster'
            WHEN CATEGORY = 'Own estate' THEN IFF(U_SIG < 0.6, 'Canopy loss alert inside concession', 'Plot overlaps forest baseline')
            WHEN CATEGORY = 'Plasma smallholders' THEN IFF(U_SIG < 0.55, 'Plot overlaps forest baseline', 'Polygon boundary outdated')
            WHEN CATEGORY = 'Independent smallholders' THEN IFF(U_SIG < 0.45, 'Canopy loss alert near plot', IFF(U_SIG < 0.8, 'Plot without geolocation', 'Plot overlaps forest baseline'))
            WHEN CATEGORY = 'FFB dealers' THEN IFF(U_SIG < 0.55, 'Unregistered plot delivery', 'Canopy loss alert near plot')
            ELSE IFF(U_SIG < 0.5, 'Supplier list incomplete', 'Canopy loss alert near plot') END AS RISK_SIGNAL,
       DECLARATION_DUE, DECLARATION_RECEIVED,
       ROUND(0.5 + 2.0 * DRIFT + 3.0 * LOSS_COUNT + U_NOISE * 0.8, 2) AS GEO_MISMATCH_PCT,
       ROUND(UNMAPPED_SHARE, 1) AS UNMAPPED_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Plot registry coverage per supply base (snapshot): registered plots, plots with
-- geolocation on file, and plots whose geolocation check is still pending.
CREATE TABLE RAW.PLOT_REGISTRY AS
WITH sized AS (
  SELECT ID, CATEGORY,
         ROUND(CASE CATEGORY WHEN 'Own estate' THEN 60 WHEN 'Plasma smallholders' THEN 450
                             WHEN 'Independent smallholders' THEN 1200 WHEN 'FFB dealers' THEN 650 ELSE 220 END
               * (0.6 + MOD(ABS(HASH(ID, 'plots')), 1000000) / 1e6 * 0.8)) AS PLOTS,
         CASE CATEGORY WHEN 'Own estate' THEN 1.0 WHEN 'Plasma smallholders' THEN 0.88
                       WHEN 'Independent smallholders' THEN 0.50 WHEN 'FFB dealers' THEN 0.45 ELSE 0.62 END
           + MOD(ABS(HASH(ID, 'geo')), 1000000) / 1e6 * 0.25 AS GEO_SHARE
  FROM RAW.SUPPLY_BASES
)
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Own estate' THEN 'Estate block polygons' WHEN 'Plasma smallholders' THEN 'Plasma plot polygons'
                     WHEN 'Independent smallholders' THEN 'Smallholder plot points and polygons'
                     WHEN 'FFB dealers' THEN 'Dealer-declared plot list' ELSE 'Third-party mill supplier list' END AS EVIDENCE_TYPE,
       PLOTS AS REQUIRED_QTY,
       LEAST(PLOTS, ROUND(PLOTS * GEO_SHARE)) AS ON_FILE_QTY,
       ROUND((PLOTS - LEAST(PLOTS, ROUND(PLOTS * GEO_SHARE))) * MOD(ABS(HASH(ID, 'pending')), 1000000) / 1e6 * 0.6) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM sized;
