# P0 Feasibility: Where Rebalancing Would Have Mattered

## 1. Working title
Where Rebalancing Would Have Mattered: San Francisco Bikeshare, 2013-2018

## 2. Audience and need
- **Audience:** A bikeshare operations analyst who advises where truck-based rebalancing effort should be concentrated.
- **Decision/problem:** Deciding which stations and which times of day need bikes moved, because some stations accumulate bikes while others run empty.
- **Why a data product helps:** Trip data shows departures and returns per station and hour, so the net imbalance can be measured instead of guessed.
- **What changes if useful:** The analyst can prioritize rebalancing at the highest-imbalance stations and hours.
- **Caveat:** Trip data ends in April 2018, so the product describes historical patterns, not current conditions.

## 3. Proposed analytical product and questions
**Product:** A dashboard showing station-level and hour-of-day imbalance between departures and returns, with demand-pattern and rider-type views.

**Questions:**
1. Which stations have the largest net imbalance (departures minus returns), and in which hours of the day?
2. How does trip demand vary by hour of day, weekday, and month?
3. How do Customer and Subscriber trips differ in volume, duration, and time-of-day pattern?

## 4. Source identification and access
- **Dataset / provider:** San Francisco Bikeshare, BigQuery public datasets (Google Cloud)
- **BigQuery project.dataset:** `bigquery-public-data.san_francisco_bikeshare`
- **Candidate tables:** `bikeshare_trips` (primary), `bikeshare_station_info` (optional context)
- **Location/region:** US
- **Approved and accessible:** Listed in the course starter source menu; queried successfully from the course Google Cloud environment on 10/13/2026


## 5. Quick source profile
(Queries are in `sql/00_feasibility.sql`; results in `evidence/p0-feasibility-results.md`.)

| Item | Finding |
|---|---|
| Row meaning (`bikeshare_trips`) | One row = one completed bike trip |
| Row count | About 1.9M (1947417)
| Time coverage | 2013-08-29 to 2018-04-30 |
| Candidate identifiers | `trip_id`; `start_station_id`, `end_station_id`
| Fields supporting questions | start/end timestamps, start/end station id and name, duration, subscriber type 

| Row meaning (`bikeshare_station_info`) | One row = one trip
| Refresh behavior | Static; data ends April 2018 |
| Sensitivity | Table includes `member_birth_year`, `member_gender`, `zip_code`. Used in aggregate form only; none committed. |

## 6. Need-to-source fit

| Question | Needed fields/concepts | Source object(s) | Why sufficient | Gap/assumption to test in P1 |
|---|---|---|---|---|
| Q1: Largest net imbalance by station and hour | Start/end station, start/end time | `bikeshare_trips`, `bikeshare_station_info` | Both start and end station and timestamps are present, so departures and returns can be counted per station-hour | Null/mismatched station ids; stations renamed or removed over time; start vs end timestamps for hour assignment |
| Q2: Demand by hour, weekday, month | Start timestamp | `bikeshare_trips` | Timestamps cover about 4.7 years | Time zone handling; partial first/last months |
| Q3: Customer vs Subscriber | Subscriber type, duration, start time | `bikeshare_trips` | Subscriber type and duration are recorded per trip | Meaning of subscriber type values; extreme/invalid durations |

## 7. Feasibility risks and response
1. **Station id/name inconsistency or nulls (Q1): 
2. **Static, historical data.** Evidence: data ends 2018-04-30. Next: framing all findings as historical and avoiding claims about current operations.
3. **Sensitive fields (birth year, gender, zip).** Evidence: present in trips table. Next: exclude or aggregate only; never commit row-level values.

**Fallback:** If station-level imbalance is unreliable, narrow to system-wide hourly/weekday demand patterns (Q2 and Q3), which depend only on timestamps and subscriber type.

## 8. First P1 decision
Decide the fact grain and whether trips should be modeled as one trip fact with start and end station roles, or as separate departure and return events per station-hour, based on how reliable the station ids and timestamps are.

## 9. AI/tool accountability
I used Claude to help interpret the assignment and draft this document structure. 
