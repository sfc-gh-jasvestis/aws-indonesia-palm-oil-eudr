# Palm Oil EUDR Due-Diligence Readiness

**Indonesia - Agriculture supply chain**
Use case: Plot-level traceability and deforestation screening for a fictional palm oil supplier network

> Traceability analytics for 40 supply bases in a fictional palm oil supplier network across 8 Indonesian mill-hub cities and 5 supplier types: dynamic tables, a holdout-evaluated canopy-loss classifier, an FFB delivery forecast and grounded AI answers. Screening results are demo signals, not compliance verdicts.

## Why Snowflake

- **Dynamic tables** reconcile FFB deliveries, traceability to plot, screening flags, confirmed canopy-loss cases and declaration rates from RAW supply-base data, with checks in `run_core.py`
- **Canopy-loss classification** gives a holdout-evaluated next-7-day probability per supply base
- **Delivery forecast** projects 14 days of network-wide FFB deliveries with prediction intervals, for mill intake planning
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live deliveries**: a native mill-gate simulator (Snowflake only) or S3 uploads and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.SUPPLY_BASES` (40 rows) |
| Fact table | `RAW.SUPPLY_DAILY` (3,600 supply-base-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `SIGNAL_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.CANOPY_RISK_SCORES`, `ML.CANOPY_RISK_HOLDOUT_METRICS`, `ML.DELIVERY_FORECAST`, `ML.GEO_MISMATCH_ANOMALIES` |

Mill-hub cities: Pekanbaru, Medan, Jambi, Palembang, Pontianak, Palangka Raya, Samarinda, Banjarmasin.
Supplier types: Own estate, Plasma smallholders, Independent smallholders, FFB dealers, Third-party mills.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Traceability to Plot | 76.9% |
| FFB Deliveries | 193,855 |
| FFB Intake (kt) | 1,117 |
| Screening Flags | 598 |
| Confirmed Canopy-Loss Cases | 116 |
| Flag Precision | 19.4% |
| Lots Excluded from EU Stock | 61 |
| Supplier Declaration Rate | 80.9% |
| Supply Bases Monitored | 40 |
| Plot Geolocation Coverage | 69.2% |
| Geolocation Checks Pending | 2,324 |
| Registered Plots | 21,665 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily FFB deliveries against screening flags, flags and confirmed canopy-loss cases by risk signal, supply base table
2. Predictive: holdout metrics, risk bands, 14-day FFB delivery forecast, geolocation mismatch anomalies
3. Plot Registry: supplier declaration rate, plot geolocation coverage and pending checks, declaration rate against confirmed cases, then generate the action memo
4. Live Deliveries: run `CALL APP.SIMULATE_DELIVERIES(20)` (Snowflake only) or `python aws/publish_deliveries.py --account <AWS_ACCOUNT_ID> --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_DELIVERY_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- About one screening flag in five is confirmed as canopy loss (19.4%). Most flags end as false positives, which is where field-team time goes.
- Canopy loss alerts near plots produce the most confirmed cases. Fire hotspot cluster flags hit every supply base around a city at once and are never confirmed.
- The risk model is evaluated on a time-based holdout: precision 0.51 and recall 0.35 at 0.5, against a 0.165 base rate. Present it as triage, not a verdict.
- Fire hotspot cluster days are excluded from model training, because they are not driven by the supply base.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
