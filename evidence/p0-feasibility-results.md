# P0 Feasibility Results

Aggregate results only. No source rows are included.
Queries are in `sql/00_feasibility.sql`. Run on 2026-10-22 from BigQuery project `francy-seis-732` [TODO: confirm this is the course project].

## Source and objects

- Source: `bigquery-public-data.san_francisco_bikeshare` (BigQuery public dataset)
- Dataset location: [TODO: confirm from dataset details]
- Tables seen: `bikeshare_trips`, `bikeshare_station_info`, `bikeshare_station_status`, `bikeshare_regions`
- Also present in dataset metadata: `arima_plus_model` (2,718 rows; not used)

| Table | Rows | Size | Last modified (UTC) |
|---|---|---|---|
| bikeshare_trips | 1,947,417 | 386.5 MB | 2026-09-09 |
| bikeshare_station_info | 472 | 0.1 MB | 2026-10-22 |
| bikeshare_station_status | 648 | 0.1 MB | 2026-10-22 |
| bikeshare_regions | 6 | ~0 MB | 2022-04-01 |

## Trips (`bikeshare_trips`)

- Apparent grain: one row per bike trip.
- `trip_id` is STRING: 0 nulls, 1,947,417 distinct values, 0 duplicates.
- Coverage: 2013-08-29 to 2018-04-30 (2013 and 2018 are partial years).
- Null `start_date`, `start_station_id`, `end_station_id`: 0 each.
- Station IDs are INT64 in trips but STRING in `station_info`.

| Year | Trips | Start ID not in station_info | End ID not in station_info |
|---|---|---|---|
| 2013 | 100,563 | 18,005 (17.9%) | 18,680 |
| 2014 | 326,339 | 70,892 (21.7%) | 71,796 |
| 2015 | 346,251 | 83,667 (24.2%) | 86,290 |
| 2016 | 210,493 | 49,099 (23.3%) | 49,721 |
| 2017 | 519,700 | 27,243 (5.2%) | 28,914 |
| 2018 | 444,071 | 16,313 (3.7%) | 19,471 |

- Distinct start station IDs in trips: 311. Of these, 290 match `station_info` and 21 do not.
- Overall, 265,219 trips (13.6%) start at a station ID missing from `station_info`.
- Trips carry their own station names and coordinates, so station_info may not be required for labels or maps.

### Rider type fields

- 2013-2016 (983,646 trips, 50.5%): `subscriber_type` is the value `nan`; the usable value is in `c_subscription_type`.
- 2017-2018: `subscriber_type` is populated; `c_subscription_type` is null.
- Observed values in both fields: Customer, Subscriber.
- Combine the two fields (treating `nan` as missing) to get one rider type for all years.

### Duration

- `duration_sec`: 0 nulls, 0 values at or below zero; min 60, median 543, max 17,270,400 (about 200 days).
- Over 1 hour: 52,682 trips (2.7%). Over 1 day: 296 trips.

### Timestamp interpretation

- `start_date` is typed TIMESTAMP (displayed as UTC).
- Hour 0 has 7,768 trips (about 0.4% of all trips). If values were true UTC, hour 0 would be a late-afternoon Pacific time peak, so this suggests they are local San Francisco times labeled as UTC.
- Full hourly shape: peaks at hour 8 (240,965 trips) and hour 17 (239,800), secondary peaks at hours 9, 16, and 18, and lows at hours 2-3 (2,432 and 1,422). The hourly counts sum to 1,947,417, matching the total.
- Interpretation: the commuter peaks at 8 and 17 show the values are San Francisco local time labeled as UTC, so no time zone conversion should be applied.

## Station info (`bikeshare_station_info`)

- Apparent grain: one row per station, current feed (refreshed daily).
- 472 rows, 472 distinct `station_id`, 0 null `station_id`, 0 null `capacity`.

## Station status (`bikeshare_station_status`)

- Apparent grain: one row per station, latest status snapshot (not history).
- 648 rows, 648 distinct `station_id`.
- `last_reported` (epoch seconds) converts to 2026-09-21 20:12:15 to 2026-10-21 23:59:09 UTC.
- `is_installed`, `is_renting`, `is_returning` are true for all 648 rows.
- 0 of 648 status station IDs match `station_info.station_id`.
- 0 of 648 status station IDs match `station_info.external_id` either, so the status table cannot be linked to station info or trips. It is excluded from the project.

## Station-level signal for the proposed question

- Departures minus returns by station (all years) ranges up to about 17.6k trips for the top station, so station-level imbalance is visible in the data.
- Hour-of-day and weekday patterns are not yet checked.

## Refresh behavior

- Trips: no new trips since April 2018, so the trip data is static historical data.
- Station info and station status: refreshed daily.

## Sensitivity and interpretation notes

- Trips include `member_birth_year`, `member_gender`, and `zip_code`. Use aggregates only; do not export or commit row-level values.
- Station imbalance reflects 2013-2018 behavior and says nothing about current conditions.

## Open items

- Check monthly trip counts for gaps (2016 looks lower than neighboring years).
- Decide how to handle trips at stations missing from `station_info`.
