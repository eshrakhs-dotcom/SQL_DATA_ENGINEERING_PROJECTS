SELECT CHAR_LENGTH('SQL');

SELECT LOWER ('SQL');

SELECT UPPER('SQL');

SELECT LEFT ('SQL',2);

SELECT RIGHT ('SQL',2);

SELECT SUBSTRING ('SQL', 2,1);

SELET CONCAT ('SQL', '-', 'Functions');

SELECT 'SQL' || '-' || 'Functions';

-- Removes leading and trailing spaces from a string (useful for cleaning messy text).
SELECT TRIM(' SQL ');


-- Replaces every occurrence of one piece of text with another (Q → _).
SELECT REPLACE('SQL', 'Q', '_');


-- Uses a regular expression to replace everything before '@' with '@', effectively masking the username.
SELECT REGEXP_REPLACE('data.nerd@gmail.com', '^.*(@)', '\1');

/*
====================================================
Final Example - Clean and Categorize Job Titles
====================================================

Goal:
Clean messy job titles, then classify them into
Data Analyst, Data Scientist, Data Engineer, or Other.
*/

-- Step 1: Create a CTE with cleaned job titles
WITH title_lower AS (
    SELECT
        job_title,

        -- Remove extra spaces and convert everything to lowercase
        LOWER(TRIM(job_title)) AS job_title_clean

    FROM job_postings_fact
)

-- Step 2: Categorize each cleaned job title
SELECT
    job_title,

    CASE
        -- Contains both "data" and "analyst"
        WHEN job_title_clean LIKE '%data%'
         AND job_title_clean LIKE '%analyst%'
            THEN 'Data Analyst'

        -- Contains both "data" and "scientist"
        WHEN job_title_clean LIKE '%data%'
         AND job_title_clean LIKE '%scientist%'
            THEN 'Data Scientist'

        -- Contains both "data" and "engineer"
        WHEN job_title_clean LIKE '%data%'
         AND job_title_clean LIKE '%engineer%'
            THEN 'Data Engineer'

        -- Everything else
        ELSE 'Other'
    END AS job_title_category

FROM title_lower

-- Randomize the output so you see different examples
ORDER BY RANDOM()

LIMIT 30;

SELECT NULLIF(5+5,20); -- If not null then give the first exprtession as an output.

SELECT
     NULLIF(salary_year_avg,0),
     NULLIF(salary_hour_avg IS NOT NULL O)

/*
====================================================
Find Rows That Have At Least One Salary Value
====================================================

Goal:
Return jobs where either the yearly salary OR hourly salary is available.
This helps identify rows that contain usable salary information.
*/

SELECT
    salary_year_avg,
    salary_hour_avg

FROM job_postings_fact

-- Keep rows where at least one salary column has a value
WHERE salary_hour_avg IS NOT NULL
   OR salary_year_avg IS NOT NULL

-- Sort by yearly salary (lowest to highest)
ORDER BY salary_year_avg

-- Show only the first 10 rows
LIMIT 10;

/*
====================================================
COALESCE() Example
====================================================

Goal:
Standardize salaries into one column.

Some jobs report yearly salaries.
Others report hourly wages.

COALESCE() lets us combine both into a single
"standardized_salary" column so we can sort,
filter, aggregate, and analyze salaries consistently.
*/

SELECT
    salary_year_avg,
    salary_hour_avg,

    -- COALESCE() checks values from left to right and
    -- returns the FIRST value that is NOT NULL.
    -- This lets us merge two salary columns into one.
    COALESCE(

        salary_year_avg,          -- Use the actual yearly salary whenever it exists.

        salary_hour_avg * 2080    -- Otherwise estimate an annual salary
                                  -- (40 hrs/week × 52 weeks = 2,080 hrs/year).

    ) AS standardized_salary

FROM job_postings_fact

-- Ignore rows where BOTH salary columns are missing.
WHERE salary_year_avg IS NOT NULL
   OR salary_hour_avg IS NOT NULL

-- Sort using the standardized salary rather than two separate columns.
ORDER BY standardized_salary

LIMIT 10;

-- Final Example: Simplify salary analysis using COALESCE + CASE

SELECT
    job_title_short,
    salary_year_avg,
    salary_hour_avg,

    COALESCE(salary_year_avg, salary_hour_avg * 2080) AS standardized_salary, -- Create one annual salary value using the first non-NULL salary.

    CASE
        WHEN COALESCE(salary_year_avg, salary_hour_avg * 2080) IS NULL THEN 'Missing'   -- No salary information available.
        WHEN COALESCE(salary_year_avg, salary_hour_avg * 2080) < 75000 THEN 'Low'       -- Annual salary below $75k.
        WHEN COALESCE(salary_year_avg, salary_hour_avg * 2080) < 150000 THEN 'Mid'      -- Annual salary between $75k and $150k.
        ELSE 'High'                                                                      -- Annual salary of $150k or more.
    END AS salary_bucket                                                                -- Assign each job to a salary category.

FROM job_postings_fact

ORDER BY standardized_salary DESC; -- Show the highest-paying jobs first.