-- Date Functions
-- Demonstrates type casting using the :: operator.

SELECT
    job_posted_date,                           -- Original TIMESTAMP value
    job_posted_date::DATE AS date,             -- Cast to DATE (drops the time)
    job_posted_date::TIME AS time,             -- Cast to TIME (keeps only the time)
    job_posted_date::TIMESTAMP AS timestamp,   -- Explicit cast to TIMESTAMP
    job_posted_date::TIMESTAMPTZ AS timestampz -- TIMESTAMP WITH TIME ZONE
FROM job_postings_fact
LIMIT 10;

/*
=========================================
TIMESTAMP WITH TIME ZONE (TIMESTAMPTZ)
=========================================

The timezone offset (e.g. -06) tells SQL how far the local time is from UTC
(Coordinated Universal Time), the global time standard.

Example:
2025-03-10 14:35:20-06

Means:
- Local time: 2:35 PM
- UTC time: 8:35 PM
- "-06" means this timestamp is 6 hours behind UTC.

Common timezone offsets:
  Utah (MST)              -07
  Utah (Daylight Saving)  -06
  New York (EST)          -05
  London (UTC)            +00
  Berlin                  +01
  Tokyo                   +09

Why do data engineers care?

Large data systems collect events from many countries and time zones.
Without timezone information, it is impossible to accurately compare
when events actually occurred.

TIMESTAMPTZ stores the timestamp together with its timezone offset,
allowing databases to convert every timestamp to the same reference
time (UTC). This keeps logs, ETL pipelines, distributed systems,
and analytics consistent across the world.

Quick summary:
::            = Type casting operator
::DATE        = Keep only the date
::TIME        = Keep only the time
::TIMESTAMP   = Date + time (no timezone)
::TIMESTAMPTZ = Date + time + timezone offset (e.g. -06)
*/

-- Extract Year & Month
-- Count how many Data Engineer jobs were posted each month.

SELECT
    EXTRACT(YEAR FROM job_posted_date) AS job_posted_year,     -- Extract the year (e.g., 2025)
    EXTRACT(MONTH FROM job_posted_date) AS job_posted_month,   -- Extract the month (1-12)
    COUNT(job_id) AS job_count                                -- Count jobs posted that month
FROM job_postings_fact
WHERE job_title_short = 'Data Engineer'                       -- Only Data Engineer postings
GROUP BY
    EXTRACT(YEAR FROM job_posted_date),
    EXTRACT(MONTH FROM job_posted_date)
ORDER BY
    job_posted_year,
    job_posted_month;

/*
=========================================
EXTRACT() DATE FUNCTION
=========================================

Purpose:
Analyze hiring trends by counting how many Data Engineer jobs
were posted each month.

How it works:
- EXTRACT(YEAR FROM job_posted_date) gets the posting year.
- EXTRACT(MONTH FROM job_posted_date) gets the posting month.
- COUNT(job_id) counts the number of job postings.
- WHERE filters to only Data Engineer roles.
- GROUP BY creates one bucket for each Year + Month combination.
- ORDER BY sorts the results chronologically.

Example output:

2024 | 1 | 125 jobs
2024 | 2 | 138 jobs
2024 | 3 | 149 jobs

Real-world use:
This is commonly used for dashboards and trend analysis to answer
questions like:
"How has hiring demand for Data Engineers changed month by month?"
*/

-- DATE_TRUNC() Examples
-- Truncate timestamps to different levels of time granularity.

SELECT
    job_posted_date,                                            -- Original timestamp
    DATE_TRUNC('year', job_posted_date) AS truncated_year,       -- Jan 1st of that year
    DATE_TRUNC('quarter', job_posted_date) AS truncated_quarter, -- First day of the quarter
    DATE_TRUNC('month', job_posted_date) AS truncated_month,     -- First day of the month
    DATE_TRUNC('week', job_posted_date) AS truncated_week,       -- Beginning of the week
    DATE_TRUNC('day', job_posted_date) AS truncated_day,         -- Midnight of that day
    DATE_TRUNC('hour', job_posted_date) AS truncated_hour        -- Beginning of that hour
FROM job_postings_fact
ORDER BY RANDOM()
LIMIT 10;

-- Count monthly Data Engineer job postings for 2024.

SELECT
    DATE_TRUNC('month', job_posted_date) AS job_posted_month, -- Round each posting date to the first day of its month
    COUNT(job_id) AS job_count                               -- Count jobs in each month
FROM job_postings_fact
WHERE
    job_title_short = 'Data Engineer'
    AND DATE_TRUNC('year', job_posted_date) = '2024-01-01'
    -- Equivalent to:
    -- EXTRACT(YEAR FROM job_posted_date) = 2024
GROUP BY
    DATE_TRUNC('month', job_posted_date)
ORDER BY
    job_posted_month;

    /*
=========================================
DATE_TRUNC() + GROUP BY
=========================================

Purpose:
Count how many Data Engineer jobs were posted each month
during the year 2024.

How it works:

- DATE_TRUNC('month', ...) rounds every posting date
  to the first day of its month.
- WHERE filters to:
    • Only Data Engineer jobs
    • Only postings from 2024
- COUNT(job_id) counts the jobs in each month.
- GROUP BY creates one bucket for every month.
- ORDER BY displays the months chronologically.

Why DATE_TRUNC instead of EXTRACT?

EXTRACT(MONTH) returns only the month number (1-12).

DATE_TRUNC('month') returns the full month timestamp
(e.g. 2024-03-01), making it easier to sort, group,
and plot on time-series dashboards.

Real-world use:
Used to build monthly hiring trend charts and KPI
dashboards for recruiting or workforce analytics.
*/

-- Convert a UTC timestamp into another time zone.

-- Convert a UTC timestamp to Eastern Standard Time (EST)
SELECT
    '2026-01-01 00:00:00+00'::TIMESTAMPTZ AT TIME ZONE 'EST';

-- Convert job posting timestamps from UTC to EST for New York jobs
SELECT
    job_title_short,
    job_location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS job_posted_est
FROM job_postings_fact
WHERE job_location LIKE 'New York, NY';

/*
=========================================
AT TIME ZONE (Timezone Conversion)
=========================================

Purpose:
Display timestamps in the local timezone of the user or business.

Why are there TWO AT TIME ZONE statements?

job_posted_date
AT TIME ZONE 'UTC'
AT TIME ZONE 'EST'

Step 1:
AT TIME ZONE 'UTC'

Tell SQL:
"This timestamp should be interpreted as being stored in UTC."

Without this step, SQL doesn't necessarily know which timezone
the original timestamp represents.

Step 2:
AT TIME ZONE 'EST'

Now convert that UTC timestamp into Eastern Standard Time.

Think of it like translating languages:

Original timestamp
      ↓
Interpret as UTC
      ↓
Translate into EST
      ↓
Display to the user

Example:

Stored:
2026-01-01 00:00:00 UTC

Converted:
2025-12-31 19:00:00 EST

The moment in time never changes.
Only the displayed local time changes.

Why do data engineers do this?

✓ Databases usually store timestamps in UTC.
✓ Users want reports in their own local timezone.
✓ Dashboards, reports, and applications convert UTC
  into local time right before displaying it.

This keeps storage standardized while allowing everyone
to see the correct local time.
*/

/*
=========================================
Find What Hour Jobs Are Posted (EST)
=========================================

Goal:
Count how many jobs are posted during each hour of the day,
after converting timestamps from UTC to Eastern Standard Time.

Business use case:
• Find peak posting hours.
• Determine when recruiters post jobs.
• Build hourly dashboards.
--Paste in chatgpt to get the graph plot of the output 
*/

SELECT
    -- Extract only the HOUR (0-23) after converting UTC to EST
    EXTRACT(
        HOUR FROM job_posted_date
        AT TIME ZONE 'UTC'
        AT TIME ZONE 'EST'
    ) AS job_posted_hour,

    -- Count how many jobs were posted during that hour
    COUNT(job_id) AS job_count

FROM job_postings_fact

-- Only analyze jobs located in New York
WHERE job_location LIKE 'New York, NY'

-- Group every posting into its hourly bucket
GROUP BY
    EXTRACT(
        HOUR FROM job_posted_date
        AT TIME ZONE 'UTC'
        AT TIME ZONE 'EST'
    )

-- Optional: sort hours from midnight to 11 PM
ORDER BY job_posted_hour;
