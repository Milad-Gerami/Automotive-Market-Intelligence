# Automotive Market Intelligence Dashboard
### Project Documentation
**Last Updated:** 2026-05-14
**Author:** Milad Gerami | GitHub: Milad-Gerami

---

## 1. WHAT IS THIS PROJECT?

A professional, end-to-end BI project built on real government data. The goal is to analyze the US and global automotive market — specifically how Gas, Hybrid, and Electric vehicles compare and how the market is shifting over time.

**The business question this dashboard answers:**
> *How is the automotive market shifting across powertrain types (Gas / Hybrid / Electric), and what does that mean for efficiency, cost, and market share?*

---

## 2. DATA SOURCES

### Source 1 — EPA Fuel Economy Data (Primary)
- **Origin:** U.S. Department of Energy / EPA — fueleconomy.gov
- **Download URL:** https://fueleconomy.gov/feg/download.shtml
- **Coverage:** Every car sold in the US, model years 1984 to present
- **Size:** 49,846 rows, 84 columns (22 columns selected for load)
- **Key columns loaded:** make, model, year, fuelType1, city08, highway08, comb08, co2TailpipeGpm, fuelCost08, VClass, trany, atvType, drive, cylinders, startStop, powertrain_group (derived), vclass_group (derived), trany_group (derived)

### Source 2 — IEA Global EV Outlook 2025 (Trend Layer)
- **Origin:** International Energy Agency — iea.org
- **Key sheet:** GEVO_EV_2025
- **Coverage:** Historical data 2010–2024, global and by region
- **Size:** 16,436 rows

---

## 3. TECH STACK

| Layer | Tool |
|---|---|
| ETL / Data Pipeline | SSIS (SQL Server Integration Services) |
| Database | SQL Server (SSMS) |
| Dashboard | Power BI Desktop |
| Data Sources | CSV + Excel (government datasets) |
| Version Control | Git + GitHub |
| Editor | Visual Studio + SSMS + Power BI Desktop |

---

## 4. BUILD PHASES

### Phase 1 — Data Assessment ✅
Profiled both source datasets. Documented all 84 EPA column headers, selected 22 relevant columns, confirmed IEA sheet structure, and defined business questions for each planned visual.

---

### Phase 2 — Database Design ✅
Designed and created `AutomotiveDashboard_DB` in SQL Server with two target tables:
- `epa_vehicles` — vehicle-level catalog with derived powertrain, vehicle class, and transmission groups
- `iea_ev_trends` — global EV market trends by region, powertrain, and parameter

---

### Phase 3 — SSIS Pipeline ✅

#### EPA Pipeline Architecture
```
SQL - Truncate EPA Vehicles
           ↓
  DFT - EPA Vehicles
      SRC - EPA Vehicles (Flat File, vehicles.csv)
           ↓
      TRN - Convert to Unicode (Data Conversion)
           ↓
      TRN - Derive Groups (Derived Column)
           ↓
      DST - DB epa_vehicles
```

**Key decisions:**
- CSV flat files deliver all columns as `DT_STR` (non-unicode) — explicit Data Conversion transformation required before loading into SQL Server NVARCHAR columns
- Configure Error Output set to `Ignore Failure` on numeric conversions — handles empty strings gracefully
- TRUNCATE + reload pattern chosen for idempotency — more reliable than unique constraints when natural key columns contain NULLs
- `model` column source length set to 500 to prevent truncation before conversion

**Derived columns created:**
- `powertrain_group` — Gas / Electric (BEV) / Plug-in Hybrid (PHEV) / Hybrid (HEV) / Other
- `vclass_group` — Compact / Sedan-Large / SUV / Truck-Pickup / Minivan-Van / Other
- `trany_group` — Automatic / Manual / Other

**Result: 49,846 rows loaded**

#### IEA Pipeline Architecture
```
SQL - Truncate IEA Trends
           ↓
  DFT - IEA EV Trends
      SRC - IEA EV Trends (Excel Source, GEVO_EV_2025 sheet)
           ↓
      DST - DB iea_ev_trends
```

**Key decisions:**
- Excel sources deliver unicode and typed numerics natively — no Data Conversion transformation needed
- Column name mismatch (`Aggregate group` → `aggregate_group`) required manual drag-to-map in destination

**Result: 16,436 rows loaded**

Both pipelines are idempotent — they can be run any number of times and always produce the same clean result.

---

### Phase 4 — Data Validation ✅

| Check | Result |
|---|---|
| EPA row count | 49,846 ✅ |
| IEA row count | 16,436 ✅ |
| EPA powertrain distribution | Gas: 46,090 / Hybrid: 1,786 / Electric: 1,425 / PHEV: 442 / Other: 103 ✅ |
| IEA top regions | China, USA, Europe — matches real-world EV market ✅ |
| Spot check on known vehicles | Values realistic, EV/Hybrid/PHEV tags correct ✅ |

**Bug found and fixed:** Original `powertrain_group` derived column expression read from `atvType` only, which is blank for standard gas vehicles — all gas cars were being classified as `Other`. Fixed by updating the expression to check `fuelType1` first, then `atvType` for hybrid/PHEV classification. Gas correctly classified at 46,090 rows after fix.

**Known items handled in Power BI:**
- Filter `year > 1980` to exclude null-year rows loaded as 0
- IEA charging infrastructure rows filtered out by `parameter`
- IEA projections excluded — historical data only (`year <= 2024`)

---

### Phase 5 — Power BI Dashboard ✅

#### Connection & Data Model
- Connected to SQL Server (localhost, AutomotiveDashboard_DB) in **Import** mode
- No relationship between tables — two independent sources filtered separately by DAX measures
- Power Query filter: `epa_vehicles[year] > 1980`
- IEA filter: `iea_ev_trends[year] <= 2024`
- "Other" powertrain excluded from model (103 rows — Hydrogen, CNG, eFCV)

#### Canvas & Theme
- **Canvas size:** 1920 × 1080 (16:9)
- **Theme:** Dark — canvas background `#0F1117`
- **Container color:** `#1C1F2E`
- **KPI card background:** `#252840`

#### Color Vocabulary
| Powertrain | Color | Hex |
|---|---|---|
| Gas | Warm Gray | `#6B6B6B` |
| Electric (BEV) | Teal | `#00897B` |
| Hybrid (HEV) | Steel Blue | `#1565C0` |
| Plug-in Hybrid (PHEV) | Slate Purple | `#5E35B1` |
| Positive indicator | Green | `#00C896` |
| Negative indicator | Red | `#FF4444` |

#### DAX Measures

**EPA measures:**
```dax
Avg Fuel Cost - Gas = CALCULATE(AVERAGE(epa_vehicles[fuelCost08]), epa_vehicles[powertrain_group] = "Gas")
Avg Fuel Cost - Electric = CALCULATE(AVERAGE(epa_vehicles[fuelCost08]), epa_vehicles[powertrain_group] = "Electric (BEV)")
Avg CO2 - Gas = CALCULATE(AVERAGE(epa_vehicles[co2TailpipeGpm]), epa_vehicles[powertrain_group] = "Gas")
Avg Fuel Cost by Powertrain = CALCULATE(AVERAGE(epa_vehicles[fuelCost08]))
Avg CO2 by Powertrain = CALCULATE(AVERAGE(epa_vehicles[co2TailpipeGpm]))
```

**IEA measures:**
```dax
EV Sales Share Latest Year = CALCULATE(MAX(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV sales share", iea_ev_trends[category] = "Historical", iea_ev_trends[year] = 2024, iea_ev_trends[region_country] = "World")
Total EV Stock Global = CALCULATE(SUM(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV stock", iea_ev_trends[category] = "Historical", iea_ev_trends[year] = 2024, iea_ev_trends[region_country] = "World")
EV Sales Volume by Year = CALCULATE(SUM(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV sales", iea_ev_trends[category] = "Historical", iea_ev_trends[region_country] = "World")
EV Sales Share by Year = CALCULATE(MAX(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV sales share", iea_ev_trends[category] = "Historical", iea_ev_trends[region_country] = "World")
Gas Sales Share by Year = 100 - [EV Sales Share by Year]
EV Stock by Region = CALCULATE(SUM(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV stock", iea_ev_trends[category] = "Historical", iea_ev_trends[year] = 2024)
```

#### KPI Cards
| Card | Value | Indicator |
|---|---|---|
| Avg Fuel Cost - Gas | $3,259 | ▼ High Cost |
| Avg Fuel Cost - Electric | $847 | ✓ Low Cost |
| Avg CO2 - Gas (g/mile) | 460 | ▲ High Emissions |
| EV Sales Share 2024 (%) | 22 | ▲ +4pp vs 2023 |
| Total EV Stock - World (2024) | 140.21M | ▲ +21M vs 2023 |
| EV Sales Share Growth (pp) | 4 | ▲ Accelerating |

#### Visuals
**1 — EV vs Gas Market Share Shift (2010–2024)** — Hero visual, top left
Line and Clustered Column combo chart. EV volume bars (teal), EV share line (slate purple), Gas share line (warm gray, dashed). Story: EV share climbs from ~1% to 22% while Gas declines from ~99% to 78%.

**2 — EV Stock by Region (2024)** — Top right
Clustered bar chart. China 103.2M / Europe 15.7M / USA 6.4M. Subtitle: *Top 3 markets shown · 2024 historical data.*

**3 — Avg Annual Fuel Cost by Powertrain** — Bottom left
Clustered bar chart. Gas $3.3K vs Electric $0.8K — 75% lower annual fuel cost for EVs.

**4 — Avg CO2 Emissions by Powertrain (g/mile)** — Bottom right
Clustered bar chart. Gas 460 / Hybrid 333 / PHEV 168 / Electric 0. "⚡ Zero Tailpipe Emissions" overlay on Electric row.

#### Key Design Decisions
- **Import mode** — static dataset, no live refresh needed, faster performance
- **No table relationship** — two independent sources at different granularity; DAX filters each table independently
- **Gas Sales Share derived** — `100 - [EV Sales Share by Year]`; IEA doesn't publish Gas share directly
- **Hardcoded year = 2024** — appropriate for a static dataset; dynamic MAX(year) inside CALCULATE behaved unexpectedly
- **Container-first layout** — rectangles define zones before visuals are placed
- **"Other" excluded** — 103 rows of Hydrogen/CNG/eFCV not relevant to the Gas vs Hybrid vs EV story

---

## 5. VERSION CONTROL

**Repo:** https://github.com/Milad-Gerami/Automotive-Market-Intelligence

**What is committed:**
- SSIS package file (`Package.dtsx`)
- SQL scripts — table creation and validation queries
- This documentation file
- Dashboard screenshot

**What is not committed:**
- Raw data files (vehicles.csv and IEA Excel) — too large and not ours to redistribute
- Power BI .pbix file — screenshot is the portfolio artifact

---

*Built on real government data. Every decision documented. Every step verified.*
*Data vintage: EPA 1984–2026 · IEA 2010–2024*
