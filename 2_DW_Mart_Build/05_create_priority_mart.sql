-- Step 5: Mart - Create priority roles mart

DROP SCHEMA IF EXISTS priority_mart CASCADE;                  -- Remove the existing mart and all dependent objects for a clean rebuild

CREATE SCHEMA priority_mart;                                  -- Create a fresh schema for priority-role analytics


SELECT '=== Loading Roles for Priority Mart ===' AS info;     -- Print a progress message before loading the roles table

CREATE TABLE priority_mart.priority_roles (                   -- Create the business-owned priority-role reference table
    role_id INTEGER PRIMARY KEY,                              -- Unique identifier for each role
    role_name VARCHAR,                                        -- Job title used to match warehouse postings
    priority_lvl INTEGER                                      -- Business ranking; lower number means higher priority
);

INSERT INTO priority_mart.priority_roles (                    -- Load the manually defined priority roles
    role_id,
    role_name,
    priority_lvl
)
VALUES
    (1, 'Data Engineer', 2),                                  -- Priority level 2
    (2, 'Senior Data Engineer', 1),                           -- Highest-priority role
    (3, 'Software Engineer', 3);                              -- Priority level 3

SELECT *
FROM priority_mart.priority_roles;                            -- Validate that the priority roles loaded correctly


SELECT '=== Loading Snapshot for Priority Mart ===' AS info;  -- Print a progress message before loading the snapshot

CREATE TABLE priority_mart.priority_jobs_snapshot (           -- Create the current snapshot of priority job postings
    job_id INTEGER PRIMARY KEY,                               -- Unique job-posting identifier
    job_title_short VARCHAR,                                  -- Standardized job title
    company_name VARCHAR,                                     -- Company name from company_dim
    job_posted_date TIMESTAMP,                                -- Original posting timestamp
    salary_year_avg DOUBLE,                                   -- Average annual salary
    priority_lvl INTEGER,                                     -- Business-defined priority level
    updated_at TIMESTAMP                                      -- Timestamp of the latest snapshot load
);

INSERT INTO priority_mart.priority_jobs_snapshot (            -- Load the initial priority-job snapshot
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_lvl,
    updated_at
)
SELECT
    jpf.job_id,                                               -- Job identifier from the warehouse fact table
    jpf.job_title_short,                                      -- Standardized role used for matching
    cd.name AS company_name,                                  -- Add the descriptive company name
    jpf.job_posted_date,                                      -- Preserve the original posting date
    jpf.salary_year_avg,                                      -- Preserve annual salary
    r.priority_lvl,                                           -- Add the business-defined priority ranking
    CURRENT_TIMESTAMP AS updated_at                           -- Record when this snapshot batch was loaded
FROM job_postings_fact AS jpf                                 -- Source warehouse job-postings fact table
LEFT JOIN company_dim AS cd                                   -- Keep jobs even if company details are unavailable
    ON jpf.company_id = cd.company_id                         -- Match each posting to its company
INNER JOIN priority_mart.priority_roles AS r                  -- Keep only roles listed in the priority table
    ON jpf.job_title_short = r.role_name;                     -- Match the job title to the business-owned role name


SELECT *
FROM priority_mart.priority_jobs_snapshot;                    -- Validate the completed snapshot table


SELECT
    job_title_short,                                          -- Group the snapshot by priority role
    COUNT(*) AS job_count,                                    -- Count all snapshot rows for each role
    MIN(priority_lvl) AS priority_lvl,                        -- Return the shared priority level for each role
    MIN(updated_at) AS updated_at                             -- Return the earliest load timestamp in each role group
FROM priority_mart.priority_jobs_snapshot                     -- Read from the priority snapshot
GROUP BY job_title_short                                      -- Produce one summary row per job title
ORDER BY job_count DESC;                                      -- Show the most common priority roles first
