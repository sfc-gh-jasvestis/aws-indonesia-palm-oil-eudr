# EUDR Compliance Engine

**Indonesia - Palm Oil & Agriculture**
Use case: EUDR Compliance

> Automated EU Deforestation Regulation compliance for Indonesia's 51M-tonne CPO industry — geospatial deforestation checks, Dynamic Tables build compliance dossiers, and Cortex AI extracts evidence from satellite imagery metadata.

## Why Snowflake

Snowflake automates EUDR due diligence at scale — geospatial polygon checks against deforestation baselines, Dynamic Tables compile compliance dossiers per shipment, and Cortex AI generates regulatory narratives

- **Geospatial polygon checks via GEOGRAPHY functions** - Only demo using Snowflake native geospatial for EUDR deforestation verification
- **Automated due diligence statement generation** - Only demo generating EUDR regulatory narratives with Cortex AI from compliance data
- **100,000 satellite alert classification** - ML classifies GLAD deforestation alerts by confidence and false positive likelihood
- **Indonesian EUDR context at national scale** - 60% of global palm oil, Rp 200T EU export revenue at stake, realistic province-level data
- **Dynamic Tables for compliance dossier assembly** - Automatically compiles per-shipment evidence packages from multiple data sources

## What is deployed

| | |
|---|---|
| Database | `ID_PALM_OIL_EUDR` |
| Service | `ID_PALM_OIL_EUDR_APP` |
| Compute pool | `SEA_DEMOS_INDONESIA_POOL` |
| Dimension table | `RAW.COMPLIANCE_DOCS` (20 rows) |
| Fact table | `RAW.SATELLITE_ALERTS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | IDR (Rp) |

Regions in play: Jakarta, North Sumatra, Riau, East Kalimantan, Sulawesi
Segments: Primary Forest, Secondary Forest, Peatland, Cleared Plantation

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh ID_PALM_OIL_EUDR
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| EUDR Compliant Lots | `87%` | average per event |
| Deforestation-Free | `94%` | average per event |
| Smallholders Mapped | `42K` | total across Compliance Docs |
| Due Diligence Statements | `1,247` | total across Compliance Docs |
| Plots Geolocated | `98.4%` | average per event |
| Satellite Alerts (30d) | `12` | total across Compliance Docs |
| Forest Proximity Risk | `4.2%` | average per event |


## Demo flow

1. Compliance Overview
2. Geospatial Risk
3. Compliance Engine
4. Ask AI
5. Architecture & Data

## Talking points

- **15,000 polygons** - plot boundaries verified against deforestation baseline
- **94.2% compliant** - active shipments verified EUDR-compliant
- **3,000 DDS** - due diligence statements generated
- **100,000 alerts** - satellite deforestation alerts processed
- **47 plots** - flagged for deforestation overlap
- **Rp 200T+** - annual EU export revenue at risk

## Business impact

- Indonesia exported US$28.5B in palm oil products in 2023 — EU is the second-largest destination (BPS Indonesia)
- EUDR enforcement begins Dec 2025 — non-compliant shipments face EU market exclusion (European Commission)
- 15,000+ supply chain polygons need geolocation verification for Indonesia's EU palm oil trade (Trase)
- Automated compliance reduces due diligence cost by 70% vs manual verification (Proforest)

---
Generated from `generator/demo_specs/aws-indonesia-palm-oil-eudr.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-indonesia-palm-oil-eudr` instead.
