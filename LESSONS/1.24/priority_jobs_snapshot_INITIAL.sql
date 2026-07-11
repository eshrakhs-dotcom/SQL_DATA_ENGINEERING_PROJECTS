/*
================================================================================
INITIAL LOAD SCRIPT: priority_jobs_snapshot
================================================================================

Business Context:
We are building the final priority_jobs_snapshot table, which combines:

1. Engineer-owned warehouse data:
   - data_jobs.job_postings_fact
   - data_jobs.company_dim

2. Business-owned priority logic:
   - staging.priority_roles

The business-owned priority_roles table defines which job titles matter most
to the business and assigns each one a priority level from 1 to 3.

The final priority_jobs_snapshot table becomes a downstream, analytics-ready
snapshot that combines job posting details, company information, salary data,
and business-defined priority levels.

Why this matters:
- The source warehouse tables are owned by engineering.
- The priority_roles table is owned by the business and may change daily.
- If the business changes a priority level or adds/removes a priority role,
  the downstream snapshot must reflect those changes during the next batch load.

Pipeline Design:
1. Initial Load:
   - Create the priority_jobs_snapshot table.
   - Load all matching priority jobs from the warehouse.
   - This script is usually run once when the table is first created.

2. Daily Batch Load:
   - Keep the snapshot table up to date.
   - Version 1: use UPDATE, INSERT, and DELETE statements.
   - Version 2: use MERGE to combine update/insert/delete logic into one statement.

Join Logic:
- LEFT JOIN company_dim:
  Keep job postings even if company details are missing.

- INNER JOIN staging.priority_roles:
  Only keep job postings that match the business-defined priority role list.

updated_at:
- CURRENT_TIMESTAMP records when the snapshot row was loaded or refreshed.
- This is important for batch processing, auditing, freshness checks, and debugging
  downstream data pipelines.
================================================================================
*/

-- Create a business-ready snapshot table in the main schema.
-- This table will store only the job postings that match our priority roles.
CREATE OR REPLACE TABLE main.priority_jobs_snapshot (
    job_id INTEGER PRIMARY KEY,
    job_title_short VARCHAR,
    company_name VARCHAR,
    job_posted_date TIMESTAMP,
    salary_year_avg DOUBLE,
    priority_lvl INTEGER,
    updated_at TIMESTAMP
);

-- Load the snapshot table from the source job postings data.
INSERT INTO main.priority_jobs_snapshot (
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_lvl,
    updated_at
)
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP AS updated_at -- Captures when this batch load happened
FROM data_jobs.job_postings_fact AS jpf -- Source job postings table from the data warehouse
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id -- LEFT JOIN keeps job postings even if company details are missing
INNER JOIN staging.priority_roles AS r
    ON jpf.job_title_short = r.role_name; -- INNER JOIN keeps only jobs that match our priority role list

SELECT *
FROM main.priority_jobs_snapshot;

SELECT
    job_title_short,
    COUNT(*) AS job_count, --counts every row within each job title, for each job category in the snapshot.
    MIN(priority_lvl) AS priority_lvl, --Each job title should normally have one priority level, assigned by the business, Since every row for a given title should share the same value,MIN() simply returns that priority level after GROUP BY.MIN() is used because every selected column must either be aggregated or included in the GROUP BY clause, and MIN() is a simple way to satisfy that requirement for a column that should have a single value per group.
    MIN(updated_at) AS updated_at --Every row has a timestamp showing when it entered the snapshot,MIN() returns the earliest timestamp for that job title.This lets us see when that group of jobs was first loaded.(MAX(updated_at) would instead show the most recent refresh.)
FROM main.priority_jobs_snapshot
GROUP BY job_title_short
ORDER BY job_count DESC;

/*
--(MAX(updated_at) would instead show the most recent refresh.
--MIN(updated_at) = the earliest time that job title appeared in the snapshot.
*/


