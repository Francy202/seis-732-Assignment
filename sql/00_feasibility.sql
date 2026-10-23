-- P0 feasibility checks: bigquery-public-data.san_francisco_bikeshare
-- Run each query separately. Check the validator's estimated bytes first.
-- Tip: set "Maximum bytes billed" (e.g. 1 GB) in Query settings.
-- Table and column names verified against Queries 1-2 (run 2026-10-22).
-- Tables used: bikeshare_trips, bikeshare_station_info, bikeshare_station_status

-- 1. Which tables/views exist in this dataset? (metadata only)
SELECT table_name, table_type
FROM `bigquery-public-data.san_francisco_bikeshare.INFORMATION_SCHEMA.TABLES`
ORDER BY table_name;

-- 2. Schema of the candidate tables (metadata only)
SELECT table_name, column_name, data_type, is_nullable
FROM `bigquery-public-data.san_francisco_bikeshare.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('bikeshare_trips', 'bikeshare_station_info', 'bikeshare_station_status')
ORDER BY table_name, ordinal_position;

-- 3. Table size and last-modified time (metadata only)
SELECT table_id, row_count, ROUND(size_bytes / 1e6, 1) AS size_mb,
       TIMESTAMP_MILLIS(last_modified_time) AS last_modified
FROM `bigquery-public-data.san_francisco_bikeshare.__TABLES__`;

-- 4. Row counts
SELECT 'bikeshare_trips' AS table_name, COUNT(*) AS row_count
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
UNION ALL
SELECT 'bikeshare_station_info', COUNT(*)
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
UNION ALL
SELECT 'bikeshare_station_status', COUNT(*)
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_status`;

-- 5. Trips: time coverage, key nulls, duplicate trip IDs
SELECT
  MIN(start_date) AS earliest_trip,
  MAX(start_date) AS latest_trip,
  COUNTIF(trip_id IS NULL) AS null_trip_ids,
  COUNT(DISTINCT trip_id) AS distinct_trip_ids,
  COUNT(*) - COUNT(DISTINCT trip_id) AS duplicate_trip_id_rows,
  COUNTIF(start_date IS NULL) AS null_start_date,
  COUNTIF(start_station_id IS NULL) AS null_start_station_id,
  COUNTIF(end_station_id IS NULL) AS null_end_station_id
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`;

-- 6. Trips per year (continuous coverage? gaps?)
SELECT EXTRACT(YEAR FROM start_date) AS trip_year, COUNT(*) AS trips
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
GROUP BY trip_year
ORDER BY trip_year;

-- 7. Duration and subscriber type quality
SELECT
  COUNTIF(duration_sec IS NULL) AS null_duration,
  COUNTIF(duration_sec <= 0) AS zero_or_negative_duration,
  MIN(duration_sec) AS min_duration_sec,
  MAX(duration_sec) AS max_duration_sec,
  APPROX_QUANTILES(duration_sec, 100)[OFFSET(50)] AS median_duration_sec,
  COUNTIF(subscriber_type IS NULL) AS null_subscriber_type,
  COUNT(DISTINCT subscriber_type) AS distinct_subscriber_types
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`;

-- 8. Subscriber type values (small aggregate, no row-level data)
SELECT subscriber_type, COUNT(*) AS trips
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
GROUP BY subscriber_type
ORDER BY trips DESC;

-- 9. Station info: key uniqueness and nulls
SELECT
  COUNT(*) AS station_rows,
  COUNT(DISTINCT station_id) AS distinct_station_ids,
  COUNTIF(station_id IS NULL) AS null_station_ids,
  COUNTIF(capacity IS NULL) AS null_capacity
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`;

-- 10. Do trip station IDs match station info?
-- Trips station IDs are likely INT64 while station_info.station_id is likely STRING,
-- so both sides are compared as STRING. Adjust after checking Query 2.
WITH trip_stations AS (
  SELECT CAST(start_station_id AS STRING) AS station_id, 'start' AS side
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  UNION ALL
  SELECT CAST(end_station_id AS STRING), 'end'
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
)
SELECT
  t.side,
  COUNT(*) AS trip_rows,
  COUNTIF(t.station_id IS NULL) AS null_ids,
  COUNTIF(t.station_id IS NOT NULL AND s.station_id IS NULL) AS ids_not_in_station_info
FROM trip_stations t
LEFT JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` s
  ON t.station_id = CAST(s.station_id AS STRING)
GROUP BY t.side;

-- 11. Station status: what time range does it cover, and is it a snapshot or history?
SELECT
  MIN(last_reported) AS earliest_report,
  MAX(last_reported) AS latest_report,
  COUNT(*) AS status_rows,
  COUNT(DISTINCT station_id) AS distinct_stations
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_status`;

-- 12. Does the data support Question 1 (departures vs. returns by station)?
-- Compact aggregate: top 10 stations by absolute net flow.
WITH dep AS (
  SELECT CAST(start_station_id AS STRING) AS station_id, COUNT(*) AS departures
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  GROUP BY station_id
),
ret AS (
  SELECT CAST(end_station_id AS STRING) AS station_id, COUNT(*) AS returns
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  GROUP BY station_id
)
SELECT
  COALESCE(d.station_id, r.station_id) AS station_id,
  IFNULL(d.departures, 0) AS departures,
  IFNULL(r.returns, 0) AS returns,
  IFNULL(d.departures, 0) - IFNULL(r.returns, 0) AS net_departures
FROM dep d
FULL OUTER JOIN ret r ON d.station_id = r.station_id
ORDER BY ABS(IFNULL(d.departures, 0) - IFNULL(r.returns, 0)) DESC
LIMIT 10;


-- P0 follow-up checks: bigquery-public-data.san_francisco_bikeshare
-- Second round of checks, based on the first-round results.
-- Check validator bytes first. All of these scan only the 386 MB trips table at most.

-- F1. Which subscriber fields are populated, by year?
-- First round: subscriber_type = 'nan' (a string) on ~50% of trips.
SELECT EXTRACT(YEAR FROM start_date) AS yr,
       subscriber_type, c_subscription_type, COUNT(*) AS trips
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
GROUP BY yr, subscriber_type, c_subscription_type
ORDER BY yr, subscriber_type, c_subscription_type;

-- F2. Trip station IDs that are missing from station_info, by year and side
SELECT EXTRACT(YEAR FROM t.start_date) AS yr,
       COUNT(*) AS trips,
       COUNTIF(si.station_id IS NULL) AS start_unmatched,
       COUNTIF(ei.station_id IS NULL) AS end_unmatched
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
LEFT JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` si
  ON CAST(t.start_station_id AS STRING) = si.station_id
LEFT JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` ei
  ON CAST(t.end_station_id AS STRING) = ei.station_id
GROUP BY yr
ORDER BY yr;

-- F3. Distinct stations seen in trips vs. matched in station_info
SELECT COUNT(DISTINCT t.start_station_id) AS trip_start_stations,
       COUNT(DISTINCT IF(si.station_id IS NOT NULL, t.start_station_id, NULL)) AS matched_in_info
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` t
LEFT JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` si
  ON CAST(t.start_station_id AS STRING) = si.station_id;

-- F4. Duration outliers (max was ~200 days)
SELECT COUNT(*) AS trips,
       COUNTIF(duration_sec > 3600) AS over_1_hour,
       COUNTIF(duration_sec > 86400) AS over_1_day
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`;

-- F5. Station status: real timestamps, flags, and overlap with station_info
SELECT MIN(TIMESTAMP_SECONDS(s.last_reported)) AS earliest_report,
       MAX(TIMESTAMP_SECONDS(s.last_reported)) AS latest_report,
       COUNT(*) AS status_stations,
       COUNTIF(si.station_id IS NULL) AS not_in_station_info,
       COUNTIF(s.is_installed) AS installed,
       COUNTIF(s.is_renting) AS renting,
       COUNTIF(s.is_returning) AS returning
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_status` s
LEFT JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` si
  USING (station_id);

-- F6. Is start_date really UTC? Check the hour-of-day shape.
-- If the values are actually San Francisco local time, expect commuter peaks near 8 and 17.
-- If they are true UTC, the peaks would sit around 15-16 and 0-1.
SELECT EXTRACT(HOUR FROM start_date) AS hour_of_day, COUNT(*) AS trips
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- F7. Same check as F6, returned as ONE row (easier to copy/paste in full)
SELECT STRING_AGG(CONCAT(CAST(h AS STRING), ':', CAST(n AS STRING)), ', ' ORDER BY h) AS hourly_trips
FROM (
  SELECT EXTRACT(HOUR FROM start_date) AS h, COUNT(*) AS n
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  GROUP BY h
);

-- F8. Station status IDs did not match station_info.station_id (F5).
-- Test whether they match station_info.external_id instead.
SELECT COUNT(*) AS status_stations,
       COUNTIF(si.external_id IS NOT NULL) AS matched_on_external_id
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_status` s
LEFT JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` si
  ON s.station_id = si.external_id;
