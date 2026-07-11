--Subquery

--Lets filter down the job_postings_fact table to only include job postings with salary data.
SELECT *
FROM (
    SELECT*
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
    OR salary_hour_avg IS NOT NULL
) AS valid_salaries --It's good practice to have Aliases for undersanding. 
LIMIT 10;

--CTE (job postings with associated salaries)

WITH valid_salaries AS (
    SELECT *
    FROM job_postings_fact
    WHERE salary_year_avg IS NOT NULL
    OR salary_hour_avg IS NOT NULL
)
SELECT *
FROM valid_salaries
LIMIT 10;

-- 🛠️ Scenario 1 – Subquery in `SELECT`
-- Show each job's salary next to the overall market median:

SELECT
    job_title_short,
    (
        SELECT MEDIAN(salary_year_avg)
        FROM job_postings_fact
    ) AS market_median_salary
FROM job_postings_fact
WHERE salary_year_avg IS NOT NULL
LIMIT 10;

-- 🛠️ Scenario 2 – Subquery in `FROM`
-- Stage only jobs that are remote before aggregating to determine the remote median salary per job

SELECT
    job_title_short,
    MEDIAN(salary_year_avg) AS median_salary,
    (
        SELECT MEDIAN(salary_year_avg)
        FROM job_postings_fact
    ) AS market_median_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_work_from_home = TRUE
) AS clean_jobs
WHERE salary_year_avg IS NOT NULL
GROUP BY job_title_short
LIMIT 10;

/*
=============================================================
SUBQUERY IN THE FROM CLAUSE (Temporary Table Pattern)
=============================================================

Purpose:
- Create a temporary table (derived table) before running the main query.
- Think of it as staging or preprocessing the data first, then performing
  aggregations and analysis on the cleaned dataset.

Execution Order:

1. INNER QUERY (FROM Subquery)
   - Select only the columns we need.
   - Filter the dataset (ex: remote jobs only).
   - Give the temporary table an alias (ex: clean_jobs).

        FROM (
            SELECT ...
            FROM job_postings_fact
            WHERE job_work_from_home = TRUE
        ) AS clean_jobs

2. OUTER QUERY
   - Uses the temporary table as if it were a real table.
   - Removes any remaining NULL values.
   - Groups rows by the category we want to analyze.
   - Applies aggregate functions (MEDIAN, AVG, COUNT, SUM, etc.).

3. GROUP BY
   - We GROUP BY job_title_short because each job title is a category.
   - salary_year_avg is NOT grouped because it is being aggregated
     with MEDIAN().
   - Rule:
       Categories -> GROUP BY
       Numbers to summarize -> Aggregate Function

Result:
- Median remote salary for each job title.
- A second subquery in SELECT calculates the overall market median
  so each job title can be compared against the overall market.

Mental Model:
Raw Data
     ↓
FROM Subquery (Create Temporary Table)
     ↓
Filtered / Clean Dataset
     ↓
GROUP BY Categories
     ↓
Aggregate Metrics (MEDIAN, AVG, COUNT...)
     ↓
Final Results
=============================================================
*/

-- 🛠 Scenario 3 — Subquery in HAVING
-- Keep only job titles whose median salary is above the overall remote median.
-- Results being greater than the market_remote_median_salary will be shown on the final output of this query scenario. 

SELECT
    job_title_short,
    MEDIAN(salary_year_avg) AS median_salary,
    (
        SELECT MEDIAN(salary_year_avg)
        FROM job_postings_fact
        WHERE job_work_from_home = TRUE
    ) AS market_remote_median_salary
FROM (
    SELECT
        job_title_short,
        salary_year_avg
    FROM job_postings_fact
    WHERE job_work_from_home = TRUE
) AS clean_jobs
GROUP BY job_title_short
HAVING MEDIAN(salary_year_avg) > (
    SELECT MEDIAN(salary_year_avg)
    FROM job_postings_fact
    WHERE job_work_from_home = TRUE
)
LIMIT 10;


-- CTE Example
-- Compare how much more (or less) remote roles pay compared to onsite roles for each job title.
-- Use a CTE to calculate the median salary by title and work arrangement, then compare those medians.

WITH title_median AS (
    SELECT
        job_title_short,
        job_work_from_home,
        MEDIAN(salary_year_avg)::INT AS median_salary
    FROM job_postings_fact
    WHERE job_country = 'United States'
    GROUP BY
        job_title_short,
        job_work_from_home
)

SELECT
    r.job_title_short,
    r.median_salary AS remote_median_salary,
    o.median_salary AS onsite_median_salary,
    (r.median_salary - o.median_salary) AS remote_premium
FROM title_median AS r
INNER JOIN title_median AS o
    ON r.job_title_short = o.job_title_short
WHERE r.job_work_from_home = TRUE
    AND o.job_work_from_home = FALSE
ORDER BY remote_premium DESC;

/*
==========================================================================================
CTE (Common Table Expression) Example

Business Question:
Compare the median salary of remote vs onsite jobs for each job title in the United States.

Why use a CTE?
Instead of repeatedly calculating the median salary for remote and onsite jobs,
we calculate it ONCE and store the result in a temporary named result set called
'title_median'. The CTE exists only while this query is executing and does not
modify the underlying database or tables.

Step 1: Build the CTE
- Group all U.S. job postings by:
      • job_title_short
      • job_work_from_home (TRUE/FALSE)
- Calculate the median salary for each group.
- The CTE now looks something like:

    Job Title         Remote?    Median Salary
    ------------------------------------------
    Data Engineer      TRUE         135000
    Data Engineer      FALSE        120000
    Data Scientist     TRUE         132500
    Data Scientist     FALSE        125000
    ...

Step 2: Self-Join the CTE
Use the SAME CTE twice:
    r = remote jobs
    o = onsite jobs

Join them on job_title_short so that each remote row is matched with its
corresponding onsite row.

Step 3: Compare salaries
Now that remote and onsite salaries are on the same row, we can calculate:

    remote_premium =
        remote_median_salary
      - onsite_median_salary

Positive value  -> Remote jobs pay more.
Negative value  -> Onsite jobs pay more.

Final Output:
One row per job title showing:
    • Job title
    • Remote median salary
    • Onsite median salary
    • Difference between them (remote premium)

This is much cleaner than writing multiple subqueries because the CTE computes
the intermediate result once and lets us reuse it throughout the query.
==========================================================================================
*/

SELECT *
FROM range(3) AS tgt(key); --Target table is a table that we want to join with the source table. In this case, we are using the range function to generate a series of numbers from 0 to 2 (3 is exclusive). The tgt(key) syntax is used to give the generated column an alias of "key". This will be useful for joining with the source table later on.

SELECT *
FROM range(2) AS tgt(ky)

SELECT *
FROM range(3) AS src(key)
WHERE EXISTS (
    SELECT *
    FROM range(2) AS tgt(key)
    WHERE src.key = tgt.key
);

SELECT *
FROM range(3) AS src(key)
WHERE NOT EXISTS (
    SELECT *
    FROM range(2) AS tgt(key)
    WHERE src.key = tgt.key
);

*/
For our case, the source table is the job_postings_fact table, and the target table is the skills_job_dim table. We want to find all job postings that do not have a matching company in the company_dim table. This will help us identify any job postings that may be missing company information.
If there's no skills assocaited with the jod id then it will ksip obve rhte job id.

/*

-- 🏁 Final Example
-- Identify job postings that have no associated skills before loading them into a data mart

SELECT *
FROM job_postings_fact
ORDER BY job_id
LIMIT 10;

SELECT *
FROM skills_job_dim
ORDER BY job_id
LIMIT 40;

SELECT *
FROM job_postings_fact AS tgt
WHERE NOT EXISTS (
    SELECT *
    FROM skills_job_dim AS src
    WHERE tgt.job_id = src.job_id
)
ORDER BY job_id;

SELECT *
FROM job_postings_fact AS tgt
WHERE EXISTS (
    SELECT *
    FROM skills_job_dim AS src
    WHERE tgt.job_id = src.job_id
)
ORDER BY job_id;