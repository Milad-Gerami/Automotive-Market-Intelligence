# Automotive Market Intelligence Dashboard
### Master Roadmap & Reference Document
**Last Updated:** 2026-05-14
**Intern:** Milad Gerami | GitHub: Milgerd
**Target Roles:** BI Developer · SQL Developer · Business Analyst

---

## 1. WHAT IS THIS PROJECT?

A professional, end-to-end BI project built on real government data. The goal is to analyze the US and global automotive market — specifically how Gas, Hybrid, and Electric vehicles compare and how the market is shifting over time. Every phase is fully documented to produce a speak guide that can be used confidently in interviews.

This is not a toy dataset project. Both data sources are official, real-world datasets used by analysts and researchers.

**The business question this dashboard answers:**
> *How is the automotive market shifting across powertrain types (Gas / Hybrid / Electric), and what does that mean for efficiency, cost, and market share?*

---

## 2. DATA SOURCES

### Source 1 — EPA Fuel Economy Data (Primary)
- **Origin:** U.S. Department of Energy / EPA — fueleconomy.gov
- **File:** vehicles.csv
- **Download URL:** https://fueleconomy.gov/feg/download.shtml
- **Coverage:** Every car sold in the US, model years 1984 to present
- **Size:** 49,846 rows, 84 columns (22 columns selected for load)
- **Key columns loaded:** make, model, year, fuelType1, city08, highway08, comb08, co2TailpipeGpm, fuelCost08, VClass, trany, atvType, drive, displ, cylinders, startStop, phevBlended, powertrain_group (derived), vclass_group (derived), trany_group (derived)
- **Value:** Vehicle-level catalog — what cars exist, what type are they, how efficient, how costly

### Source 2 — IEA Global EV Outlook 2025 (Trend Layer)
- **Origin:** International Energy Agency — iea.org
- **File:** Multi-sheet Excel workbook
- **Key sheet:** GEVO_EV_2025
- **Columns:** region_country, category, parameter, mode, powertrain, year, unit, value, aggregate_group
- **Powertrain values in data:** BEV, EV, PHEV, FCEV + charging infrastructure rows
- **Parameter values in data:** EV stock, EV sales, EV sales share, EV stock share, EV charging points, Oil displacement, Battery demand, Electricity demand
- **Coverage:** Historical data + projections, global and by region, 2010–2030
- **Value:** Market trend story — how sales volumes and stock shift over time by powertrain type

---

## 3. TECH STACK

| Layer | Tool |
|---|---|
| ETL / Data Pipeline | SSIS (SQL Server Integration Services via Visual Studio) |
| Database | SQL Server (SSMS) |
| Dashboard | Power BI Desktop |
| Data Sources | CSV + Excel (government datasets) |
| Version Control | Git + GitHub (Milgerd) |
| Editor | Visual Studio (SSIS) + SSMS + Power BI Desktop |

---

## 4. THE 6-PHASE ROADMAP

### Phase 1 — Data Assessment ✅ COMPLETE
**Goal:** Understand the data before touching anything. Define what we keep, what we drop, what needs cleaning, and what business questions we're answering.

**What was done:**
- Documented all 84 column headers from vehicles.csv
- Selected 22 columns relevant to business questions
- Profiled both sources for nulls, data types, and quality issues
- Confirmed IEA sheet structure and powertrain breakdown
- Defined business questions for each planned visual

**Deliverable:** Column selection list + data quality notes for both sources ✅

---

### Phase 2 — Database Design ✅ COMPLETE
**Goal:** Design and create the target SQL Server schema before SSIS is touched.

**What was done:**
- Designed and created `AutomotiveDashboard_DB` in SSMS
- Created `epa_vehicles` table with final column set and data types
- Created `iea_ev_trends` table
- Schema adjusted during Phase 3 based on real data behavior (see Phase 3 notes)

**Deliverable:** Database and empty tables created in SSMS ✅

---

### Phase 3 — SSIS Pipeline ✅ COMPLETE
**Goal:** Build the full Extract → Transform → Load pipeline in Visual Studio.

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

**Key lessons learned:**
- CSV flat files deliver all columns as `DT_STR` (non-unicode) — explicit Data Conversion transformation required
- SQL Server NVARCHAR expects `DT_WSTR` (unicode) — incompatible with raw CSV strings
- Configure Error Output set to `Ignore Failure` on all numeric conversions — handles empty strings gracefully
- `model` column source length set to 500 to prevent truncation before conversion
- Schema changed from SMALLINT/TINYINT → INT, added NULL on numeric columns, widened string columns
- TRUNCATE + reload chosen over unique constraints — unique constraints fail with NULL natural keys

**Derived columns created:**
- `powertrain_group` — Gas / Electric (BEV) / Plug-in Hybrid (PHEV) / Hybrid (HEV) / Other
- `vclass_group` — Compact / Sedan-Large / SUV / Truck-Pickup / Minivan-Van / Other
- `trany_group` — Automatic / Manual / Other

**powertrain_group expression (final — uses fuelType1 as primary, atvType as secondary):**
```
[Copy of fuelType1] == "Electricity" ? "Electric (BEV)" :
[Copy of fuelType1] == "Natural Gas" ? "Other" :
[Copy of fuelType1] == "Hydrogen" ? "Other" :
[Copy of atvType] == "EV" ? "Electric (BEV)" :
[Copy of atvType] == "Plug-in Hybrid" ? "Plug-in Hybrid (PHEV)" :
[Copy of atvType] == "Hybrid" ? "Hybrid (HEV)" :
[Copy of atvType] == "PHEV" ? "Plug-in Hybrid (PHEV)" :
([Copy of fuelType1] == "Regular Gasoline" ||
 [Copy of fuelType1] == "Premium Gasoline" ||
 [Copy of fuelType1] == "Midgrade Gasoline" ||
 [Copy of fuelType1] == "Premium" ||
 [Copy of fuelType1] == "Regular" ||
 [Copy of fuelType1] == "Diesel") ? "Gas" :
"Other"
```

**Result: 49,846 rows loaded into epa_vehicles**

#### IEA Pipeline Architecture
```
SQL - Truncate IEA Trends
           ↓
  DFT - IEA EV Trends
      SRC - IEA EV Trends (Excel Source, GEVO_EV_2025 sheet)
           ↓
      DST - DB iea_ev_trends
```

**Key notes:**
- Excel sources deliver unicode and typed numerics natively — no Data Conversion needed
- Column name mismatch (`Aggregate group` → `aggregate_group`) required manual drag-to-map in destination
- Yellow truncation warnings in progress log are expected and harmless

**Result: 16,436 rows loaded into iea_ev_trends**

**Deliverable:** Working SSIS package, both pipelines idempotent ✅

---

### Phase 4 — Data Validation ✅ COMPLETE
**Goal:** Verify the loaded data is clean, complete, and accurate before building anything visual.

#### Validation Results

| Check | Result | Status |
|---|---|---|
| EPA row count | 49,846 | ✅ |
| IEA row count | 16,436 | ✅ |
| NULLs in EPA key columns | year: 2,005 nulls loaded as 0 — all others clean | ✅ Acceptable |
| NULLs in IEA key columns | All clean | ✅ |
| EPA powertrain distribution | Gas: 46,090 / Hybrid: 1,786 / Electric: 1,425 / PHEV: 442 / Other: 103 | ✅ |
| EPA fuelType1 distribution | Regular Gasoline dominant, Electricity and Diesel present, 1 blank row | ✅ |
| IEA powertrain breakdown | EV: 6,658 / BEV: 4,917 / PHEV: 2,394 / FCEV: 1,568 + charging rows | ✅ |
| IEA parameter breakdown | Vehicle metrics + infrastructure/impact metrics confirmed | ✅ |
| EPA year range | 0–2026 (0 = null years, filter year > 1980 in Power BI) | ✅ |
| IEA year range | 2010–2030 (historical + projections) | ✅ |
| Spot check on known vehicles | Values realistic, EV/Hybrid/PHEV tags correct | ✅ |
| IEA top regions | China, USA, Europe at top — matches real-world EV market | ✅ |

#### powertrain_group Bug Found and Fixed
- **Root cause:** Original derived column expression read from `atvType`, which is blank for standard gas vehicles → all gas cars classified as `Other`
- **Fix:** Updated expression to check `fuelType1` first, then `atvType` for hybrid/PHEV classification
- **Result after fix:** Gas correctly classified at 46,090 rows; Other reduced to 103 (Hydrogen, CNG, eFCV — legitimately niche)

#### Known Items to Handle in Power BI
- Filter `year > 1980` to exclude the 2,005 null-year rows (loaded as 0)
- IEA dataset contains charging infrastructure rows — filter by `parameter` to isolate vehicle metrics
- IEA projections extend to 2030 — use `category` filter to separate historical from projected data

**Deliverable:** Validation complete, data confirmed clean, green light for Power BI ✅

---

### Phase 5 — Power BI Dashboard ✅ COMPLETE
**Goal:** Connect Power BI to SQL Server, build the data model, write DAX measures, and design the visuals that tell the Gas vs Hybrid vs EV story.

#### Connection & Data Model
- Connected Power BI Desktop to SQL Server (localhost, AutomotiveDashboard_DB) using **Import** mode
- Both tables loaded: `epa_vehicles` (47,839 rows after filter) and `iea_ev_trends` (16,436 rows)
- **No relationship created between tables** — they are independent, each filtered separately by DAX measures
- **Power Query filter applied:** `epa_vehicles[year] > 1980` — excludes 2,005 null-year rows loaded as 0
- **IEA year filter applied:** `iea_ev_trends[year] <= 2024` — excludes projection years, historical data only
- **"Other" excluded from model:** Filtered out of `powertrain_group` and `vclass_group` in Power Query (103 rows — Hydrogen, CNG, eFCV — not relevant to Gas vs Hybrid vs EV story). This slightly adjusted EPA averages: Gas fuel cost $3,259, Electric $847, CO2 460 g/mile

#### Theme & Layout
- **Theme:** Dark — canvas background `#0F1117`
- **Canvas size:** 1280 x 800 (custom)
- **Container color:** `#1C1F2E` (header, KPI row, sidebar)
- **Main content area:** `#161926`
- **KPI card background:** `#252840` with rounded corners
- **Layout approach:** Container-first — rectangles define zones before any visuals are placed

#### Color Vocabulary (locked)
| Powertrain | Color | Hex |
|---|---|---|
| Gas | Warm Gray | `#6B6B6B` |
| Electric (BEV) | Teal | `#00897B` |
| Hybrid (HEV) | Steel Blue | `#1565C0` |
| Plug-in Hybrid (PHEV) | Slate Purple | `#5E35B1` |
| Positive indicator | Green | `#00C896` |
| Negative indicator | Red | `#FF4444` |
| Axis / labels | Muted gray-blue | `#A0A4B8` |
| Gridlines | Dark blue-gray | `#3D4166` |

#### DAX Measures Built

**EPA measures (vehicle-level):**
```
Avg Fuel Cost - Gas = CALCULATE(AVERAGE(epa_vehicles[fuelCost08]), epa_vehicles[powertrain_group] = "Gas")
Avg Fuel Cost - Electric = CALCULATE(AVERAGE(epa_vehicles[fuelCost08]), epa_vehicles[powertrain_group] = "Electric (BEV)")
Avg CO2 - Gas = CALCULATE(AVERAGE(epa_vehicles[co2TailpipeGpm]), epa_vehicles[powertrain_group] = "Gas")
Vehicle Count = COUNTROWS(epa_vehicles)
Avg Fuel Cost by Powertrain = CALCULATE(AVERAGE(epa_vehicles[fuelCost08]))
Avg CO2 by Powertrain = CALCULATE(AVERAGE(epa_vehicles[co2TailpipeGpm]))
```

**IEA measures (market trend):**
```
EV Sales Share Latest Year = CALCULATE(MAX(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV sales share", iea_ev_trends[category] = "Historical", iea_ev_trends[year] = 2024, iea_ev_trends[region_country] = "World")

Total EV Stock Global = CALCULATE(SUM(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV stock", iea_ev_trends[category] = "Historical", iea_ev_trends[year] = 2024, iea_ev_trends[region_country] = "World")

YoY EV Sales Share Change = [EV Sales Share 2024] - [EV Sales Share 2023] -- hardcoded years, static dataset

EV Sales Volume by Year = CALCULATE(SUM(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV sales", iea_ev_trends[category] = "Historical", iea_ev_trends[region_country] = "World")

EV Sales Share by Year = CALCULATE(MAX(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV sales share", iea_ev_trends[category] = "Historical", iea_ev_trends[region_country] = "World")

Gas Sales Share by Year = 100 - [EV Sales Share by Year]

EV Stock by Region = CALCULATE(SUM(iea_ev_trends[value]), iea_ev_trends[parameter] = "EV stock", iea_ev_trends[category] = "Historical", iea_ev_trends[year] = 2024)
```

**Key DAX lesson:** Nested MAX(year) inside CALCULATE behaved unexpectedly — hardcoded year = 2024 used instead. Valid approach for a static dataset. The `region_country = "World"` filter was critical — without it MAX() grabbed the highest regional value (Norway ~92%) instead of the global aggregate (22%).

#### KPI Cards (Top Row)
| Card | Value | Indicator | Color |
|---|---|---|---|
| Avg Fuel Cost - Gas | $3,259 | ▼ High Cost | Red |
| Avg Fuel Cost - Electric | $847 | ✓ Low Cost | Green |
| Avg CO2 - Gas (g/mile) | 460 | ▲ High Emissions | Red |
| EV Sales Share 2024 (%) | 22 | ▲ +4pp vs 2023 | Green |
| Total EV Stock - World (2024) | 140.21M | ▲ +21M vs 2023 | Green |
| EV Sales Share Growth (pp) | 4 | ▲ Accelerating | Green |

**KPI card structure:** Title text box (top) → Card visual with background off, number centered → Indicator text box (bottom). Card background `#252840`, rounded corners enabled via border matching background color.

#### Visuals Built

**1 — EV vs Gas Market Share Shift (2010–2024)** — Hero visual, top left
- Type: Line and Clustered Column Chart (combo/dual-axis)
- Bars: EV Sales Volume by Year (left axis, teal `#00897B`)
- Line 1: EV Sales Share by Year (right axis, solid, slate purple `#5E35B1`)
- Line 2: Gas Sales Share by Year (right axis, dashed, warm gray `#6B6B6B`)
- Story: EV volume growing exponentially; EV share climbing from ~1% to 22%; Gas share declining from ~99% to 78%

**2 — EV Stock by Region (2024)** — Top right
- Type: Clustered Bar Chart
- Regions: China (103.2M), Europe (15.7M), USA (6.4M)
- Color: Teal `#00897B` — single color, regional not powertrain chart
- Data labels: white, 1 decimal place
- Story: China dominates global EV adoption by a massive margin — 6.5x Europe, 16x USA

**3 — Avg Annual Fuel Cost by Powertrain** — Bottom left
- Type: Clustered Bar Chart
- Data labels: white, K format
- Story: Gas $3.3K vs Electric $0.8K — EVs cost 75% less to fuel annually
- Other excluded via right-click Exclude on visual

**4 — Avg CO2 Emissions by Powertrain (g/mile)** — Bottom right
- Type: Clustered Bar Chart
- Data labels: white, no display units
- Electric (BEV): ⚡ Zero Tailpipe Emissions text box overlay (teal, background matching container to cover 0 label)
- Story: Gas 460 g/mile, Hybrid 333, PHEV 168, Electric 0

#### Slicers (Left Sidebar)
- **Year** (IEA data): Between style, range slider 2010–2024, teal slider color
- **Powertrain** (EPA data): Vertical list, 4 values (Other excluded from model)
- **Vehicle Class** (EPA data): Vertical list, 5 values (Other excluded from model)
- **Interaction configuration:** Year slicer set to not filter EPA visuals (Edit Interactions) — EPA data is a static catalog, year filtering doesn't apply meaningfully

#### Design Decisions Worth Knowing
- **Import vs DirectQuery:** Import chosen — static dataset, no live refresh needed, faster performance
- **No table relationship:** Two independent sources with different granularity — no direct join makes sense. DAX measures filter each table independently
- **"Other" excluded from model:** Conscious decision — 103 rows of Hydrogen/CNG/eFCV are not relevant to the Gas vs Hybrid vs EV story. Exclusion slightly shifted averages (documented above)
- **Gas Sales Share derived:** `100 - [EV Sales Share by Year]` — IEA doesn't publish Gas share directly. Acknowledged approximation, directionally correct and tells the market shift story clearly
- **Hardcoded year = 2024:** Dynamic MAX(year) inside CALCULATE behaved unexpectedly during DAX debugging. Hardcoded value is appropriate for a static dataset
- **Container-first layout:** Rectangles define zones before any visuals are placed — professional approach that prevents repositioning later
- **Dark theme:** Chosen to differentiate from the Executive Risk Command Center (light theme) on the same portfolio

**Deliverable:** Power BI dashboard complete, portfolio screenshot taken ✅

---

### Phase 6 — Documentation & Speak Guide
**Goal:** Document every decision made across all phases for interview preparation.

**Speak guide sections:**
- Project overview (the elevator pitch)
- Data sources — why these, what they contain, how credible they are
- SSIS pipeline — what was dirty, what cleaning decisions were made and why
- Database design — why these tables, these data types, these constraints
- Dashboard design — what business question each visual answers
- Key findings — what did the data actually show about Gas vs Hybrid vs EV
- What I learned

**Deliverable:** Speak guide MD file ready for interview prep ⏳ Pending

---

## 5. WORKFLOW RULES (EVERY SESSION)

- **One phase at a time** — complete and verify before moving forward
- **Evidence before moving on** — if a step produces output, we look at it before the next step
- **Document as we go** — notes on every cleaning decision get added here in real time, not at the end
- **Claude provides the prompt / instruction → Milad executes → reports back → Claude verifies → next step**
- **No assumptions** — if something looks unexpected, we stop and investigate before continuing

---

## 6. CURRENT STATUS

| Phase | Status |
|---|---|
| Phase 1 — Data Assessment | ✅ Complete |
| Phase 2 — Database Design | ✅ Complete |
| Phase 3 — SSIS Pipeline | ✅ Complete |
| Phase 4 — Data Validation | ✅ Complete |
| Phase 5 — Power BI Dashboard | ✅ Complete |
| Phase 6 — Speak Guide | ⏳ Pending |

**Next immediate action:** Commit Phase 5 files to GitHub (dashboard screenshot + updated roadmap), then begin Phase 6 Speak Guide.

**Repo structure to organize before committing:**
```
Personal_Repo/
  docs/
    Automotive-Dashboard_Master-Roadmap.md
  sql/
    create_tables.sql
    validation_queries.sql
  ssis/
    AutomotiveDashboard.dtsx
  dashboard/
    Automotive_Market_Intelligence_Dashboard.pbix (optional)
    dashboard_screenshot.png
```

---

## 7. VERSION CONTROL & GITHUB

This project is versioned on GitHub under the Milgerd account, same as LaunchForge AI.

**What gets committed:**
- SSIS package files (.dtsx)
- SQL scripts — table creation, validation queries
- This master roadmap document (updated as phases complete)
- The speak guide (built progressively through Phase 6)
- Any documentation files created during the project

**What does NOT get committed:**
- The raw data files (vehicles.csv and IEA Excel) — too large and not ours to redistribute
- Power BI .pbix file — committed optionally, but the dashboard screenshot is what goes on the portfolio

**Git workflow (same discipline as LaunchForge):**
```
git add <specific files>        — never blindly add everything
git commit -m 'clear message'  — one logical change per commit
git push origin main            — push after each phase completes
git status                      — always check before committing
```

**Commit milestones:**
- End of Phase 1 — column selection doc + data notes ✅
- End of Phase 2 — SQL table creation scripts ✅
- End of Phase 3 — SSIS package files ✅
- End of Phase 4 — validation query scripts ✅
- End of Phase 5 — dashboard screenshot + updated roadmap ⏳ Pending commit
- End of Phase 6 — completed speak guide ⏳ Pending

---

## 8. PORTFOLIO INTEGRATION

When complete, the dashboard screenshot will be added to the portfolio site (milad-gerami.github.io) alongside the Executive Risk Command Center, following the same format — project name, tech stack tags, and key metrics.

---

*Built on real government data. Every decision documented. Every step verified.*
