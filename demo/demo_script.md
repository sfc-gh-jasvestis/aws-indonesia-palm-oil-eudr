# Demo Script: EUDR Compliance Engine
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake automates EUDR due diligence at scale — geospatial polygon checks against deforestation baselines, Dynamic Tables compile compliance dossiers per shipment, and Cortex AI generates regulatory narratives"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Ir. Hendra Wijaya** | Chief Sustainability Officer | React App (SPCS) | EUDR deadline compliance, deforestation-free verification, EU buyer retention, regulatory risk |
| **Dr. Sari Indrawati** | Geospatial Analyst | Amazon QuickSight | Polygon verification, deforestation baseline mapping, satellite data integration, false positive resolution |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | PLOT_POLYGONS (15000), DEFORESTATION_BASELINE (50000), SHIPMENT_DOSSIERS (20000), DUE_DILIGENCE_STATEMENTS (3000), SATELLITE_ALERTS (100000), COMPLIANCE_DOCS (200) |
| **CURATED** | 4 Dynamic Tables | PLOT_DEFORESTATION_CHECK, SHIPMENT_COMPLIANCE_STATUS, DDS_GENERATION_QUEUE, RISK_HEATMAP |
| **ML** | ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 200 documents indexed |
| **Agent** | EUDR_COMPLIANCE_AGENT | Semantic View + Search tools |


---

## The Story

The EU Deforestation Regulation requires full geolocation traceability for all palm oil entering the EU market. Indonesia — producing 60% of global palm oil — must verify 15,000+ plot polygons against deforestation baselines and generate due diligence statements for every shipment. With Rp 200 trillion in annual EU exports at stake, automated compliance is existential.

---

## Script

### [0:00–0:45] COMPLIANCE OVERVIEW

**Show**: Compliance Overview tab

> "15,000 plot polygons verified against post-2020 deforestation baseline."

**Action**: Point at 94.2% compliance KPI

### [0:45–1:30] GEOSPATIAL RISK

**Show**: Geospatial Risk tab

> "Heat map shows deforestation risk concentrated in Central Kalimantan and Riau provinces."

**Action**: Show risk heatmap by province

### [1:30–2:15] COMPLIANCE ENGINE

**Show**: Compliance Engine tab

> "Dynamic Tables automatically compile per-shipment compliance dossiers with evidence links."

**Action**: Show a generated DDS with evidence links

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Hendra asks: 'What percentage of our shipments are EUDR-compliant?'"

**Action**: Type compliance question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services in the dual-build architecture."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **Geospatial polygon checks via GEOGRAPHY functions** — Only demo using Snowflake native geospatial for EUDR deforestation verification
2. **Automated due diligence statement generation** — Only demo generating EUDR regulatory narratives with Cortex AI from compliance data
3. **100,000 satellite alert classification** — ML classifies GLAD deforestation alerts by confidence and false positive likelihood
4. **Indonesian EUDR context at national scale** — 60% of global palm oil, Rp 200T EU export revenue at stake, realistic province-level data
5. **Dynamic Tables for compliance dossier assembly** — Automatically compiles per-shipment evidence packages from multiple data sources


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM PALM_OIL_EUDR.RAW.PLOT_POLYGONS` → 15000
- [ ] `SELECT COUNT(*) FROM PALM_OIL_EUDR.RAW.SATELLITE_ALERTS` → 100000
- [ ] `SELECT COUNT(*) FROM PALM_OIL_EUDR.RAW.DUE_DILIGENCE_STATEMENTS` → 3000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM PALM_OIL_EUDR.ML.ALERT_FALSE_POSITIVE_RESULTS WHERE IS_ANOMALY = TRUE` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM PALM_OIL_EUDR.AI.GENERATED_DDS_NARRATIVES` → >0
- [ ] `SELECT COUNT(*) FROM PALM_OIL_EUDR.AI.ALERT_CLASSIFICATION` → 100000

