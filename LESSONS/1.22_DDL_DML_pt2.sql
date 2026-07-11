DESCRIBE -- We want to see the structure of the table, including column names and data types.
-- We want to pick out specifically what column name we want to use in our query, and what data type it is. This is important because we need to know how to handle the data in that column, and what kind of operations we can perform on it.
SELECT
     jpf.*, -- full stop is used to select all columns from the job_postings_fact table
     cd.*
FROM data_jobs.job_postings_fact as jpf  -- data.jobs is used to speicify the database and schema where table is located as we connected datamart to a different database than the one we are currently using. 
LEFT JOIN data_jobs.company_dim as cd
    ON jpf.company_id = cd.company_id;

CREATE TABLE staging.job_postings_flat AS
DROP TABLE IF EXISTS staging.job_postings_flat;


DROP TABLE IF EXISTS staging.job_postings_flat;

CREATE TABLE staging.job_postings_flat AS
SELECT
    jpf.job_id,
    jpf.company_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    cd.name AS company_name
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id;

SELECT COUNT(*)
FROM staging.job_postings_flat;

-- ============================================================================
-- Create a flattened staging table inside the jobs_mart database.
--
-- Why are we doing this?
-- The original data lives in the data warehouse (data_jobs), where information
-- is normalized across multiple related tables (fact and dimension tables).
--
-- Instead of joining those tables every time we write an analysis query, we
-- create a denormalized (flat) table that combines the most commonly used
-- columns into a single table.
--
-- This staging table acts as a working copy inside our data mart:
-- • Easier to query
-- • Faster for analytics and reporting
-- • Reduces repeated JOIN operations
-- • Serves as the foundation for downstream transformations and dashboards
--
-- Data Flow:
-- data warehouse (data_jobs)
--            │
--            ▼
--      JOIN multiple tables
--            │
--            ▼
-- jobs_mart.staging.job_postings_flat
--            │
--            ▼
-- Business analytics, reporting, dashboards, and feature engineering
--
-- Think of the warehouse as the "source of truth" and the data mart as an
-- analytics-optimized copy designed for answering business questions.
-- ============================================================================

-- Goal:
-- Transform operational warehouse data into an analytics-ready dataset that
-- business analysts, data analysts, and BI tools can query quickly without
-- repeatedly rebuilding complex joins.

CREATE VIEW staging.priority_jobs_flat_view AS
SELECT 
jpf.*
FROM staging.job_postings_flat AS jpf
JOIN staging.priority_roles as r
    ON jpf.job_title_short = r.role_name
WHERE r.priority_lvl = 1;

SELECT 
     job_title_short,
     COUNT(*) AS job_count --We did an aggregate function to count the number of rows in the table, and we gave it an alias name job_count. So, we alos need a GROUPBY clause to group the results by job_title_short, so that we can get the count of each unique job title in the table.
FROM staging.priority_jobs_flat_view
GROUP BY job_title_short
ORDER BY job_count DESC;

CREATE TEMPORARY TABLE senior_jobs_flat_temp AS
SELECT*
FROM staging.priority_jobs_flat_view
WHERE job_title_short = 'Senior Data Engineer';

SELECT 
     job_title_short,
     COUNT(*) AS job_count --We did an aggregate function to count the number of rows in the table, and we gave it an alias name job_count. So, we alos need a GROUPBY clause to group the results by job_title_short, so that we can get the count of each unique job title in the table.
FROM senior_jobs_flat_temp
GROUP BY job_title_short
ORDER BY job_count DESC;

--We are gonna do the row count of each of the table we just made to make sure the data is consistent and we are not losing any rows in the process of creating the new tables/views.
SELECT COUNT(*) FROM staging.job_postings_flat; --This the one we are gonna ALTER
SELECT COUNT(*) FROM staging.priority_jobs_flat_view;
SELECT COUNT(*) FROM senior_jobs_flat_temp;

DELETE FROM staging.job_postings_flat
WHERE job_posted_date < '2024-01-01'; --We are gonna delete the rows that are older than 2024-01-01, because we want to focus on the most recent job postings for our analysis. This will help us get a more accurate picture of the current job market and the skills that are in demand.

SELECT COUNT(*) FROM staging.job_postings_flat; --This the one we are gonna ALTER
SELECT COUNT(*) FROM staging.priority_jobs_flat_view;
SELECT COUNT(*) FROM senior_jobs_flat_temp;

TRUNCATE TABLE staging.job_postings_flat; --We are gonna delete all the rows in the table, but keep the table structure. This is useful when we want to start fresh with a new dataset, but we don't want to drop and recreate the table.

INSERT INTO staging.job_postings_flat
SELECT
    jpf.job_id,
    jpf.company_id,
    jpf.job_title_short,
    jpf.job_title,
    jpf.job_location,
    jpf.job_via,
    jpf.job_schedule_type,
    jpf.job_work_from_home,
    jpf.search_location,
    jpf.job_posted_date,
    jpf.job_no_degree_mention,
    jpf.job_health_insurance,
    jpf.job_country,
    jpf.salary_rate,
    jpf.salary_year_avg,
    jpf.salary_hour_avg,
    cd.name AS company_name
FROM data_jobs.job_postings_fact AS jpf
LEFT JOIN data_jobs.company_dim AS cd
    ON jpf.company_id = cd.company_id
WHERE job_posted_date >= '2024-01-01'; --We are gonna insert the rows that are newer than 2024-01-01, because we want to focus on the most recent job postings for our analysis. This will help us get a more accurate picture of the current job market and the skills that are in demand.

SELECT COUNT(*) FROM staging.job_postings_flat; --This the one we are gonna ALTER
SELECT COUNT(*) FROM staging.priority_jobs_flat_view;
SELECT COUNT(*) FROM senior_jobs_flat_temp;
