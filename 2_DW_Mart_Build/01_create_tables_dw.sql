-- Step 1: DW - Create star schema tables

DROP TABLE IF EXISTS skills_job_dim;      -- Drop bridge table first (depends on other tables)
DROP TABLE IF EXISTS job_postings_fact;   -- Drop fact table next (depends on company_dim)
DROP TABLE IF EXISTS company_dim;         -- Drop parent table after dependents are gone
DROP TABLE IF EXISTS skills_dim;          -- Drop parent table after dependents are gone
CREATE TABLE company_dim (
    company_id INTEGER PRIMARY KEY,          -- Unique company ID
    name VARCHAR                             -- Company name
);

CREATE TABLE skills_dim (
    skill_id INTEGER PRIMARY KEY,            -- Unique skill ID
    skill VARCHAR,                           -- Skill name
    type VARCHAR                             -- Skill category
);

CREATE TABLE job_postings_fact (
    job_id INTEGER PRIMARY KEY,              -- Unique job posting
    company_id INTEGER,                      -- Links to company_dim
    job_title_short VARCHAR,
    job_title VARCHAR,
    job_location VARCHAR,
    job_via VARCHAR,
    job_schedule_type VARCHAR,
    job_work_from_home BOOLEAN,
    search_location VARCHAR,
    job_posted_date TIMESTAMP,
    job_no_degree_mention BOOLEAN,
    job_health_insurance BOOLEAN,
    job_country VARCHAR,
    salary_rate VARCHAR,
    salary_year_avg DOUBLE,
    salary_hour_avg DOUBLE,
    FOREIGN KEY (company_id) REFERENCES company_dim(company_id)  -- Enforces valid company
);

CREATE TABLE skills_job_dim (
    skill_id INTEGER,
    job_id INTEGER,
    PRIMARY KEY (skill_id, job_id),          -- Composite PK (unique skill-job pair)
    FOREIGN KEY (skill_id) REFERENCES skills_dim(skill_id),      -- Links to skills
    FOREIGN KEY (job_id) REFERENCES job_postings_fact(job_id)    -- Links to jobs
);

SELECT table_name                 -- Return only the table names
FROM information_schema.tables    -- System catalog containing metadata about all tables
WHERE table_schema = 'main';      -- Show only tables in the 'main' schema

