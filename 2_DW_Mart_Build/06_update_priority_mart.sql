-- Step 6: Mart - Update priority roles mart

-- Primary keys provide stable row identity and prevent duplicates.
-- Priority levels are business rules that can change as leadership priorities change.
-- UPDATE changes the rule without rebuilding the warehouse or rewriting application code.
-- MERGE later synchronizes only new or changed records into the snapshot.
-- SELECT '=== ... ===' AS info
-- Prints a progress message so you know which ETL step is currently executing.

-- CREATE TEMP TABLE
-- Creates a temporary source table used only during this session for the MERGE.

-- MERGE
-- Synchronizes the snapshot by updating changed rows, inserting new rows, and deleting rows that no longer exist in the source.

SELECT '=== Updating Roles for Priority Mart ===' AS info;      -- Print a progress message before updating business priorities

UPDATE priority_mart.priority_roles                             -- Update an existing priority-role record
SET priority_lvl = 1                                            -- Change Data Engineer to the highest priority
WHERE role_name = 'Data Engineer';                              -- Update only the Data Engineer row

INSERT INTO priority_mart.priority_roles (                      -- Add a new business priority role
    role_id,
    role_name,
    priority_lvl
)
VALUES
    (4, 'Data Scientist', 3);                                   -- Insert Data Scientist with priority level 3

SELECT *
FROM priority_mart.priority_roles
ORDER BY priority_lvl, role_id;                                 -- Verify the updated priority roles


SELECT '=== Creating Source Table for Merge ===' AS info;       -- Print a progress message before building the temporary source table

CREATE OR REPLACE TEMP TABLE src_priority_jobs AS               -- Temporary source table used by the MERGE statement
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name AS company_name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    r.priority_lvl,
    CURRENT_TIMESTAMP AS updated_at                             -- Record when this batch was prepared
FROM job_postings_fact AS jpf                                   -- Warehouse job postings
LEFT JOIN company_dim AS cd                                     -- Add company names
    ON jpf.company_id = cd.company_id
INNER JOIN priority_mart.priority_roles AS r                    -- Keep only business priority roles
    ON jpf.job_title_short = r.role_name;


SELECT '=== Merging Incremental Updates ===' AS info;           -- Print a progress message before synchronizing the snapshot

MERGE INTO priority_mart.priority_jobs_snapshot AS target       -- Target snapshot table
USING src_priority_jobs AS src                                 -- Temporary source table
ON target.job_id = src.job_id                                  -- Match rows using the primary key

WHEN MATCHED
    AND target.priority_lvl IS DISTINCT FROM src.priority_lvl THEN
    UPDATE SET                                                  -- Update only when the priority changed
        priority_lvl = src.priority_lvl,
        updated_at = src.updated_at

WHEN NOT MATCHED THEN
    INSERT (                                                    -- Insert brand-new priority jobs
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
    DELETE;                                                     -- Remove jobs that are no longer priority roles


SELECT '=== Priority Mart Validation ===' AS info;              -- Print a progress message before validation

SELECT
    job_title_short,
    COUNT(*) AS job_count,                                      -- Count jobs for each priority role
    MIN(priority_lvl) AS priority_lvl,                          -- Display the assigned priority level
    MAX(updated_at) AS updated_at                               -- Show the most recent batch update
FROM priority_mart.priority_jobs_snapshot
GROUP BY job_title_short
ORDER BY job_count DESC;