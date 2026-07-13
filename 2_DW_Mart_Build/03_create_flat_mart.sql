-- duckdb flat_mart.duckdb -c "read 03_create_flat_mart.sql"

--  Open the DuckDB database, run the master build script, then exit

--duckdb dw_marts.duckdb -c ".read build_dw_marts.sql"

-- Step 3: Mart - Create flat mart table

DROP SCHEMA IF EXISTS flat_mart CASCADE;      -- Delete the existing mart and all its objects for a clean rebuild
CREATE SCHEMA IF NOT EXISTS flat_mart;                              -- Create the mart schema only when needed

CREATE OR REPLACE TABLE flat_mart.job_postings AS                   -- Save the denormalized result as a physical table
SELECT
    jpf.job_id,                         -- Job identifier
    jpf.job_title_short,                -- Standard job title
    jpf.job_title,                      -- Full job title
    jpf.job_location,                   -- Job location
    jpf.job_via,                        -- Posting source
    jpf.job_schedule_type,              -- Full-time, contract, etc.
    jpf.job_work_from_home,             -- Remote-work indicator
    jpf.search_location,                -- Search location
    jpf.job_posted_date,                -- Posting date
    jpf.job_no_degree_mention,          -- No-degree indicator
    jpf.job_health_insurance,           -- Health-insurance indicator
    jpf.job_country,                    -- Job country
    jpf.salary_rate,                    -- Salary period
    jpf.salary_year_avg,                -- Average yearly salary
    jpf.salary_hour_avg,                -- Average hourly salary                                            -- Average hourly salary
    cd.company_id,                                                  -- Company identifier
    cd.name AS company_name,                                        -- Business-friendly company name
    ARRAY_AGG(                                                      -- Collect all skills into one array per job
        STRUCT_PACK(
            type := sd.type,                                        -- Skill category
            name := sd.skills                                       -- Skill name
        )
    ) FILTER (WHERE sd.skill_id IS NOT NULL) AS skills_and_types    -- Exclude empty skill matches
FROM job_postings_fact AS jpf                                      -- Begin with all job postings
LEFT JOIN company_dim AS cd                                        -- Keep jobs without company details
    ON jpf.company_id = cd.company_id                               -- Match job to company
LEFT JOIN skills_job_dim AS sjd                                    -- Connect jobs to skills
    ON jpf.job_id = sjd.job_id                                      -- Match job through bridge table
LEFT JOIN skills_dim AS sd                                         -- Add skill descriptions
    ON sjd.skill_id = sd.skill_id                                   -- Match bridge skill to dimension
GROUP BY ALL;    

SELECT 'Flat Mart Job Postings' AS table_name, COUNT(*) AS record_count  -- Validate that the flat mart was created and count all rows
FROM flat_mart.job_postings;                                             -- Read from the completed flat mart table

SELECT '=== Flat Mart Sample ===' AS info;                               -- Print a clear label before showing sample records

SELECT *                                                                 -- Return all columns from the flat mart
FROM flat_mart.job_postings                                              -- Query the denormalized job postings mart
LIMIT 10;                                                                -- Preview only 10 rows for a quick visual check                                                   -- One output row per job and company