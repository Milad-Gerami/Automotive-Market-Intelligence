-- Row counts
SELECT COUNT(*) AS epa_row_count FROM epa_vehicles;
SELECT COUNT(*) AS iea_row_count FROM iea_ev_trends;

-- EPA: NULL check on key columns
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN make IS NULL THEN 1 ELSE 0 END) AS null_make,
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS null_year,
    SUM(CASE WHEN fuelType1 IS NULL THEN 1 ELSE 0 END) AS null_fuelType1,
    SUM(CASE WHEN comb08 IS NULL THEN 1 ELSE 0 END) AS null_comb08,
    SUM(CASE WHEN co2TailpipeGpm IS NULL THEN 1 ELSE 0 END) AS null_co2,
    SUM(CASE WHEN fuelCost08 IS NULL THEN 1 ELSE 0 END) AS null_fuelCost,
    SUM(CASE WHEN powertrain_group IS NULL THEN 1 ELSE 0 END) AS null_powertrain_group
FROM epa_vehicles;

-- IEA: NULL check on key columns
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN region_country IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN powertrain IS NULL THEN 1 ELSE 0 END) AS null_powertrain,
    SUM(CASE WHEN year IS NULL THEN 1 ELSE 0 END) AS null_year,
    SUM(CASE WHEN value IS NULL THEN 1 ELSE 0 END) AS null_value,
    SUM(CASE WHEN parameter IS NULL THEN 1 ELSE 0 END) AS null_parameter
FROM iea_ev_trends;

-- EPA: powertrain distribution
SELECT powertrain_group, COUNT(*) AS vehicle_count
FROM epa_vehicles
GROUP BY powertrain_group
ORDER BY vehicle_count DESC;

-- EPA: fuelType1 distribution
SELECT TOP 10 fuelType1, COUNT(*) AS count
FROM epa_vehicles
GROUP BY fuelType1
ORDER BY count DESC;

-- IEA: powertrain distribution
SELECT powertrain, COUNT(*) AS row_count
FROM iea_ev_trends
GROUP BY powertrain
ORDER BY row_count DESC;

-- IEA: parameter distribution
SELECT parameter, COUNT(*) AS row_count
FROM iea_ev_trends
GROUP BY parameter
ORDER BY row_count DESC;

-- Year ranges
SELECT MIN(year) AS earliest_year, MAX(year) AS latest_year FROM epa_vehicles;
SELECT MIN(year) AS earliest_year, MAX(year) AS latest_year FROM iea_ev_trends;

-- Spot check known vehicles
SELECT make, model, year, fuelType1, comb08, co2TailpipeGpm, fuelCost08, powertrain_group
FROM epa_vehicles
WHERE (make = 'Toyota' AND model LIKE '%Camry%' AND year = 2020)
   OR (make = 'Tesla' AND model LIKE '%Model 3%')
   OR (make = 'Ford' AND model LIKE '%F-150%' AND year = 2022)
   OR (make = 'Honda' AND model LIKE '%Civic%' AND year = 2019)
   OR (make = 'Toyota' AND model LIKE '%Prius%' AND year = 2021)
ORDER BY make, year;

-- IEA: top regions by total value
SELECT TOP 10 region_country, SUM(value) AS total_value
FROM iea_ev_trends
GROUP BY region_country
ORDER BY total_value DESC;

-- EPA: Other powertrain breakdown
SELECT fuelType1, atvType, COUNT(*) AS count
FROM epa_vehicles
WHERE powertrain_group = 'Other'
GROUP BY fuelType1, atvType
ORDER BY count DESC;