SELECT UNNEST([1,1,1,2])
UNION ALL
SELECT UNNEST ([1,1,3]);

/*
=========================================
Create a Temporary Table for 2023 Jobs
=========================================

Goal:
Create a temporary table containing only 2023 job postings.
We'll use this table later with set operators
(UNION, UNION ALL, INTERSECT, EXCEPT).
*/

CREATE TEMP TABLE jobs_2023 AS

SELECT
    * EXCLUDE (job_id, job_posted_date) -- Keep every column except these two

FROM job_postings_fact

-- Keep only jobs posted during 2023
WHERE EXTRACT(YEAR FROM job_posted_date) = 2023;

-- Preview the temporary table
SELECT *
FROM jobs_2023;



/*
=========================================
Create a Temporary Table for 2024 Jobs
=========================================

Same idea as above, but now for 2024.
We'll compare the two tables using set operators.
*/

CREATE TEMP TABLE jobs_2024 AS

SELECT
    * EXCLUDE (job_id, job_posted_date)

FROM job_postings_fact

WHERE EXTRACT(YEAR FROM job_posted_date) = 2024;

-- Preview the temporary table
SELECT *
FROM jobs_2024;

/*
=========================================
Create a Temporary Table for 2024 Jobs
=========================================

Same idea as above, but now for 2024.
We'll compare the two tables using set operators.
*/

CREATE TEMP TABLE jobs_2024 AS

SELECT
    * EXCLUDE (job_id, job_posted_date)

FROM job_postings_fact

WHERE EXTRACT(YEAR FROM job_posted_date) = 2024;

-- Preview the temporary table
SELECT *
FROM jobs_2024;

=--Whic uniwue job postings appeared in either 2023 and 2024.

/*
=========================================
UNION Example
=========================================

Goal:
Compare two temporary tables (jobs_2023 and jobs_2024),
then combine them into one result.

UNION returns DISTINCT rows only (duplicates are removed).
*/


/*---------------------------------------------------------
Part 1: Count rows in each temporary table
---------------------------------------------------------*/

SELECT
    'jobs_2023' AS table_name, -- Label this result as coming from the 2023 table
    COUNT(*) AS total_jobs     -- Count all rows in jobs_2023
FROM jobs_2023

UNION

SELECT
    'jobs_2024' AS table_name, -- Label this result as coming from the 2024 table
    COUNT(*) AS total_jobs
FROM jobs_2024;


/*---------------------------------------------------------
Part 2: Combine both tables into one result
---------------------------------------------------------*/

SELECT *
FROM jobs_2023

UNION

SELECT *
FROM jobs_2024;

/*
====================================================
EXCEPT ALL
====================================================

Goal:
Find rows that exist in jobs_2023 but not in jobs_2024.

EXCEPT ALL removes matching rows one-for-one,
keeping any remaining duplicates.
*/

SELECT *
FROM jobs_2023

EXCEPT ALL

SELECT *
FROM jobs_2024;



/*
====================================================
INTERSECT
====================================================

Goal:
Find rows that appear in BOTH jobs_2023 and jobs_2024.

Only rows that exist in both tables are returned.
*/

SELECT *
FROM jobs_2023

INTERSECT

SELECT *
FROM jobs_2024;