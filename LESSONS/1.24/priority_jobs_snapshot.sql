-- CREATE TEMP TABLE (Has our query that creates our source table, so that we cna refernce it in our other statements below).

CREATE OR REPLACE TEMP TABLE src_priority_jobs AS
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
    ON jpf.job_title_short = r.role_name;


-- UPDATE statement (Captures the matched rows that may have chnaged between source and target tables, and updates the target table with the new values from the source table).
-- Update is used when a value within a or multiple columns changes. For our case, we will use this if our priiroity_lvl changes for a role, not if a new role gets added but if priority_lvl vhnages like software engineer goes from 3 to 2 then we will update the priority_lvl column in the target table with the new value from the source table.

-- UPDATE main.priority_jobs_snapshot AS target
-- SET
--     priority_lvl = src.priority_lvl, -- the temp table we previoulsy created
--     updated_at = src.updated_at
-- FROM src_priority_jobs AS src
-- WHERE target.job_id = src.job_id -- Match on job_id to ensure we are updating the correct row
--     AND target.priority_lvl IS DISTINCT FROM src.priority_lvl; -- Only update if the priority level has changed 

-- --INSERT statement (if the b usiness added jobs to tht prioirty roles table, then. we need to insert those nmew rows into our target table )

-- INSERT INTO main.priority_jobs_snapshot (
--     job_id,
--     job_title_short,
--     company_name,
--     job_posted_date,
--     salary_year_avg,
--     priority_lvl,
--     updated_at
-- )
-- SELECT
--     src.job_id,
--     src.job_title_short,
--     src.company_name,
--     src.job_posted_date,
--     src.salary_year_avg,
--     src.priority_lvl,
--     src.updated_at
-- FROM src_priority_jobs AS src
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM main.priority_jobs_snapshot AS target
--     WHERE target.job_id = src.job_id -- Only insert if the job_id does not already exist in the target table
-- );


-- -- DELETE statement

-- DELETE FROM main.priority_jobs_snapshot AS target
-- WHERE NOT EXISTS (
--     SELECT 1
--     FROM src_priority_jobs AS src
--     WHERE target.job_id = src.job_id -- Only delete if the job_id does not exist in the source table
-- );

--MERGE INTO
MERGE INTO main.priority_jobs_snapshot AS target
USING src_priority_jobs AS src
ON target.job_id = src.job_id

WHEN MATCHED 
    AND target.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET
        priority_lvl = src.priority_lvl,
        updated_at = src.updated_at

WHEN NOT MATCHED THEN
    INSERT (
        job_id,
        job_title_short,
        company_name,
        job_posted_date,
        salary_year_avg,
        priority_lvl,
        updated_at
    )
    VALUES (
        src.job_id,
        src.job_title_short,
        src.company_name,
        src.job_posted_date,
        src.salary_year_avg,
        src.priority_lvl,
        src.updated_at
    )

WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

-- Final validation output after batch load
SELECT
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_lvl) AS priority_lvl,
    MAX(updated_at) AS updated_at
FROM main.priority_jobs_snapshot
GROUP BY job_title_short
ORDER BY job_count DESC;



/*
================================================================================
DAILY BATCH PIPELINE: UPDATE / INSERT / DELETE / MERGE PATTERN
================================================================================

Business Problem:
The business owns the priority_roles table. That table can change over time:

- A role can be added.
- A role can be removed.
- A priority level can change.

The engineering-owned priority_jobs_snapshot table must stay synchronized with
the latest business rules and warehouse data.

Pipeline Flow:
1. Build today's source dataset in a temporary table.
2. Compare today's source table against the existing snapshot table.
3. Apply changes:
   - UPDATE rows that already exist but changed.
   - INSERT rows that are new.
   - DELETE rows that no longer exist in the source.
4. Run a validation query to confirm the final state of the snapshot.

Why create src_priority_jobs?
src_priority_jobs represents today's truth. It combines:
- job_postings_fact: source job postings from the warehouse
- company_dim: company names from the warehouse
- priority_roles: business-owned priority logic

This temp table exists only during the current DuckDB session/script run.
It lets us reference the same source dataset repeatedly without rewriting the
same JOIN logic multiple times.

Join Logic:
- LEFT JOIN company_dim:
  Keeps all job postings even if company details are missing.

- INNER JOIN priority_roles:
  Keeps only job postings whose job title matches the business priority list.
  If a role is not in priority_roles, it should not enter the snapshot.

updated_at:
CURRENT_TIMESTAMP records when the batch processed the row.
This is useful for:
- Data freshness checks
- Auditing
- Debugging pipeline runs
- Confirming which rows changed during a batch

================================================================================
UPDATE / INSERT / DELETE VERSION
================================================================================

UPDATE:
Used when a row already exists in the snapshot, but one of its values changed.

Example:
Software Engineer priority changes from 3 to 2.
The job_id already exists, so we update priority_lvl and updated_at.

INSERT:
Used when a row exists in today's source but does not exist in the snapshot.

Example:
Business adds Data Scientist as a new priority role.
Those matching job postings are inserted into the snapshot.

DELETE:
Used when a row exists in the snapshot but no longer exists in today's source.

Example:
Business removes Software Engineer from priority_roles.
Those rows should be removed from the snapshot so stale data does not remain.

================================================================================
MERGE VERSION
================================================================================

MERGE combines UPDATE, INSERT, and DELETE logic into one statement.

MERGE reads like this:

- MATCHED:
  If target.job_id exists in both source and target, update it only if the
  priority level changed.

- NOT MATCHED:
  If a source row does not exist in the target, insert it.

- NOT MATCHED BY SOURCE:
  If a target row no longer exists in the source, delete it.

Important:
All WHEN clauses belong to one MERGE statement.
Do not put semicolons between WHEN MATCHED, WHEN NOT MATCHED, and
WHEN NOT MATCHED BY SOURCE. Only put one semicolon at the very end.

================================================================================
FINAL VALIDATION QUERY
================================================================================

The final SELECT does not modify data.

It checks whether the batch load worked by summarizing the snapshot table:

- COUNT(*) AS job_count:
  Counts how many job posting rows exist inside each job title bucket.

- MIN(priority_lvl) AS priority_lvl:
  Returns the priority level for each job title group.
  Since each job title should have one assigned priority, MIN() is used mainly
  to satisfy GROUP BY rules.

- MAX(updated_at) AS updated_at:
  Shows the most recent time rows in that job title group were refreshed.

This validation output helps confirm:
- The expected job titles are present.
- Job counts look reasonable.
- Priority levels updated correctly.
- The batch ran recently.

================================================================================
Big Picture:
This is a simplified real-world batch data pipeline.

Source data + business rules
        ↓
Temporary source table
        ↓
MERGE into snapshot table
        ↓
Validation query
        ↓
Analytics-ready downstream table
================================================================================
*/
