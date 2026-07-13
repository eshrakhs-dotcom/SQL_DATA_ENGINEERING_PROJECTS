-- Preview the source CSV before loading it into the data warehouse.                               -- Automatically detect column names and data types

-- Step 2: DW - Load data from CSV files into tables
-- Load order follows foreign key dependencies: independent dimensions first, fact table next, bridge table last.

SELECT '=== Loading company_dim Table ===' AS info;      -- Print progress label before loading company_dim

INSERT INTO company_dim (company_id, name)                         -- Load first: no foreign key dependencies
SELECT company_id, name                                           -- Select only columns defined in company_dim
FROM read_csv(
    'https://storage.googleapis.com/sql_de/company_dim.csv',
    AUTO_DETECT = true                                            -- Infer CSV column names and data types
);

SELECT '=== Loading skills_dim Table ===' AS info; 

INSERT INTO skills_dim (skill_id, skills, type)                     -- Load first: no foreign key dependencies
SELECT skill_id, skills, type                                      -- Select only columns defined in skills_dim
FROM read_csv(
    'https://storage.googleapis.com/sql_de/skills_dim.csv',
    AUTO_DETECT = true                                            -- Infer CSV column names and data types
);

SELECT '=== Loading job_postings_fact Table ===' AS info;

INSERT INTO job_postings_fact (                                   -- Load after company_dim because company_id is a foreign key
    job_id,
    company_id,
    job_title_short,
    job_title,
    job_location,
    job_via,
    job_schedule_type,
    job_work_from_home,
    search_location,
    job_posted_date,
    job_no_degree_mention,
    job_health_insurance,
    job_country,
    salary_rate,
    salary_year_avg,
    salary_hour_avg
)
SELECT
    job_id,
    company_id,
    job_title_short,
    job_title,
    job_location,
    job_via,
    job_schedule_type,
    job_work_from_home,
    search_location,
    job_posted_date,
    job_no_degree_mention,
    job_health_insurance,
    job_country,
    salary_rate,
    salary_year_avg,
    salary_hour_avg
FROM read_csv(
    'https://storage.googleapis.com/sql_de/job_postings_fact.csv',
    AUTO_DETECT = true                                            -- Infer CSV column names and data types
);

SELECT '=== Loading skills_job_dim Table ===' AS info;  

INSERT INTO skills_job_dim (skill_id, job_id)                      -- Load last: depends on skills_dim and job_postings_fact
SELECT skill_id, job_id                                           -- Each row connects one skill to one job
FROM read_csv(
    'https://storage.googleapis.com/sql_de/skills_job_dim.csv',
    AUTO_DETECT = true                                            -- Infer CSV column names and data types
);