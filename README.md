# seis-732-Assignment
# San-Francisco-bikeshare-imbalance
purpose: individual data -product project (P0-P4). 


Where Rebalancing Would Have Mattered: San Francisco Bikeshare, 2013-2018

An individual data-product project for the 732 course. It builds a dashboard that helps a bikeshare operations analyst see which stations and times of day had the largest imbalance between departures and returns, so rebalancing effort (moving bikes between stations by truck) can be prioritized.

Current status: P0 complete (need, audience, dataset, and feasibility). P1 onward will be added as the course progresses.

Audience and need

A bikeshare operations analyst who advises where rebalancing should be concentrated. Because the trip data ends in April 2018, the product describes historical patterns and does not claim to describe current conditions.

Questions the product should answer
Which stations have the largest net imbalance (departures minus returns), and in which hours of the day?
How does trip demand vary by hour of day, weekday, and month?
How do Customer and Subscriber trips differ in volume, duration, and time-of-day pattern?
Data source
BigQuery public dataset bigquery-public-data.san_francisco_bikeshare
Primary table: bikeshare_trips (about 1.9M trips, 2013-08-29 to 2018-04-30)
Optional context table: bikeshare_station_info
Source data is not stored in this repository. All queries run against the public dataset.
Repository structure
README.md                          this file
.gitignore                         excludes secrets, downloads, and data extracts
docs/p0-feasibility.md             P0 feasibility document
sql/00_feasibility.sql             reproducible profiling queries
evidence/p0-feasibility-results.md summarized results (aggregates only)
P0 files
P0 feasibility document
Feasibility SQL
Summarized results
How to reproduce the P0 checks
Open the BigQuery console in a Google Cloud project you can query from.
Run the queries in sql/00_feasibility.sql one at a time, checking the estimated bytes first.
Compare the aggregate results with evidence/p0-feasibility-results.md.
Data and safety notes
The evidence files contain only aggregate counts, ranges, and interpretation, not source rows.
The trips table includes member_birth_year, member_gender, and zip_code. These are used in aggregate form only, and no row-level values are committed.
No credentials, secrets, or data extracts are committed
