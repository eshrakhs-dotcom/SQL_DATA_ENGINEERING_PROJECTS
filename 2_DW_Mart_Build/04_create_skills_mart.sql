-- Step 4: Mart - Create skills demand mart

DROP SCHEMA IF EXISTS skills_mart CASCADE;                         -- Delete the existing mart and all objects for a clean rebuild

CREATE SCHEMA skills_mart;                                         -- Create a fresh schema for skills-demand analytics


-- ============================================================
-- SKILLS DIMENSION
-- ============================================================

CREATE TABLE skills_mart.dim_skills (                              -- Create the skills dimension table
    skill_id INTEGER PRIMARY KEY,                                  -- Unique identifier for each skill
    skills VARCHAR,                                                -- Skill name
    type VARCHAR                                                   -- Skill category
);

SELECT '=== Loading Skills Dimension ===' AS info;                 -- Print a progress message before loading the table

INSERT INTO skills_mart.dim_skills (                               -- Load skills into the mart dimension
    skill_id,
    skills,
    type
)
SELECT
    skill_id,
    skills,
    type
FROM skills_dim;                                                   -- Copy skills from the warehouse dimension


-- ============================================================
-- MONTHLY DATE DIMENSION
-- ============================================================

CREATE TABLE skills_mart.dim_date_month (                          -- Create a monthly date dimension
    month_start_date DATE PRIMARY KEY,                             -- Unique first day of each month
    year INTEGER,                                                  -- Calendar year
    month INTEGER,                                                 -- Month number from 1 to 12
    quarter INTEGER,                                               -- Quarter number from 1 to 4
    quarter_name VARCHAR,                                          -- Display label such as Q-1
    year_quarter VARCHAR                                           -- Display label such as 2024-Q1
);

SELECT '=== Loading Date Month Dimension ===' AS info;             -- Print a progress message before loading the table

INSERT INTO skills_mart.dim_date_month (                           -- Load distinct reporting months
    month_start_date,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
)
SELECT DISTINCT                                                    -- Keep only one row for each unique month
    DATE_TRUNC('month', job_posted_date) AS month_start_date,      -- Convert every date to the first day of its month
    EXTRACT(YEAR FROM job_posted_date) AS year,                    -- Extract the year
    EXTRACT(MONTH FROM job_posted_date) AS month,                  -- Extract the month number
    EXTRACT(QUARTER FROM job_posted_date) AS quarter,              -- Extract the quarter number
    'Q-' || EXTRACT(QUARTER FROM job_posted_date)::VARCHAR
        AS quarter_name,                                           -- Create labels such as Q-1
    EXTRACT(YEAR FROM job_posted_date)::VARCHAR
        || '-Q' ||
    EXTRACT(QUARTER FROM job_posted_date)::VARCHAR
        AS year_quarter                                            -- Create labels such as 2024-Q1
FROM job_postings_fact                                             -- Read posting dates from the warehouse fact table
ORDER BY month_start_date;                                         -- Load months in chronological order


-- ============================================================
-- MONTHLY SKILL-DEMAND FACT TABLE
-- ============================================================

CREATE TABLE skills_mart.fact_skill_demand_monthly (               -- Create the aggregated monthly demand fact table
    skill_id INTEGER,                                              -- Skill being measured
    month_start_date DATE,                                         -- Month of the measurement
    job_title_short VARCHAR,                                       -- Standardized job-title category
    postings_count INTEGER,                                        -- Total postings for the group
    remote_postings_count INTEGER,                                 -- Number of remote postings
    health_insurance_postings_count INTEGER,                       -- Number mentioning health insurance
    no_degree_mention_postings_count INTEGER,                      -- Number not mentioning a degree requirement

    PRIMARY KEY (
        skill_id,
        month_start_date,
        job_title_short
    ),                                                             -- One unique row per skill, month, and job title

    FOREIGN KEY (skill_id)
        REFERENCES skills_mart.dim_skills(skill_id),               -- Require the skill to exist in dim_skills

    FOREIGN KEY (month_start_date)
        REFERENCES skills_mart.dim_date_month(month_start_date)    -- Require the month to exist in dim_date_month
);

SELECT '=== Loading Skill Demand Fact ===' AS info;                -- Print a progress message before loading the fact table

INSERT INTO skills_mart.fact_skill_demand_monthly (                -- Store the aggregated demand metrics
    skill_id,
    month_start_date,
    job_title_short,
    postings_count,
    remote_postings_count,
    health_insurance_postings_count,
    no_degree_mention_postings_count
)

WITH job_postings_prep AS (                                        -- Create a temporary prepared result for this statement
    SELECT
        sjd.skill_id,                                              -- Skill linked to the job posting
        DATE_TRUNC('month', jpf.job_posted_date)
            AS month_start_date,                                   -- Convert the posting date to its reporting month
        jpf.job_title_short,                                       -- Standardized job title

        CASE
            WHEN jpf.job_work_from_home = TRUE THEN 1
            ELSE 0
        END AS is_remote,                                          -- Convert remote Boolean into a countable 1 or 0

        CASE
            WHEN jpf.job_health_insurance = TRUE THEN 1
            ELSE 0
        END AS has_health_insurance,                               -- Convert insurance Boolean into a countable 1 or 0

        CASE
            WHEN jpf.job_no_degree_mention = TRUE THEN 1
            ELSE 0
        END AS no_degree_mentioned                                 -- Convert no-degree Boolean into a countable 1 or 0

    FROM job_postings_fact AS jpf                                  -- Start with warehouse job postings

    INNER JOIN skills_job_dim AS sjd                               -- Keep job postings that have associated skills
        ON sjd.job_id = jpf.job_id                                 -- Match each posting to its skill relationships
)

SELECT
    skill_id,                                                      -- Group by skill
    month_start_date,                                              -- Group by reporting month
    job_title_short,                                               -- Group by standardized job title
    COUNT(*) AS postings_count,                                    -- Count postings in each group
    SUM(is_remote) AS remote_postings_count,                       -- Count remote postings by summing 1/0 values
    SUM(has_health_insurance)
        AS health_insurance_postings_count,                        -- Count postings mentioning health insurance
    SUM(no_degree_mentioned)
        AS no_degree_mention_postings_count                        -- Count postings not mentioning a degree
FROM job_postings_prep                                             -- Aggregate the prepared CTE records
GROUP BY ALL                                                       -- Group by every selected non-aggregated column
ORDER BY
    skill_id,
    month_start_date,
    job_title_short;                                               -- Sort the inserted result consistently


-- ============================================================
-- VALIDATE RECORD COUNTS
-- ============================================================

SELECT
    'Skill Dimension' AS table_name,                               -- Label the first validation result
    COUNT(*) AS record_count                                       -- Count all rows in dim_skills
FROM skills_mart.dim_skills

UNION ALL                                                          -- Stack the next validation result underneath

SELECT
    'Date Month Dimension',                                        -- Label the monthly date dimension
    COUNT(*)                                                       -- Count all rows in dim_date_month
FROM skills_mart.dim_date_month

UNION ALL                                                          -- Stack the final validation result underneath

SELECT
    'Skill Demand Fact',                                           -- Label the skill-demand fact table
    COUNT(*)                                                       -- Count all aggregated fact rows
FROM skills_mart.fact_skill_demand_monthly;


-- ============================================================
-- PREVIEW SAMPLE RECORDS
-- ============================================================

SELECT '=== Skill Dimension Sample ===' AS info;                   -- Print a heading before the skill sample

SELECT *
FROM skills_mart.dim_skills
LIMIT 5;                                                           -- Preview five skill-dimension records


SELECT '=== Date Month Dimension Sample ===' AS info;              -- Print a heading before the date sample

SELECT *
FROM skills_mart.dim_date_month
LIMIT 5;                                                           -- Preview five monthly date records


SELECT '=== Skill Demand Fact Sample ===' AS info;                 -- Print a heading before the fact-table sample

SELECT *
FROM skills_mart.fact_skill_demand_monthly
LIMIT 5;                                                           -- Preview five aggregated demand records
