-- Bucket Salaries
-- < 25  = 'Low'
-- 25-50 = 'Medium'
-- > 50  = 'High'

SELECT
    job_title_short,
    salary_hour_avg,
    CASE
        WHEN salary_hour_avg < 25 THEN 'Low'
        WHEN salary_hour_avg < 50 THEN 'Medium'
        ELSE 'High'
    END AS salary_category
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL
LIMIT 10;

-- Handling Missing Data (Nulls)
-- Filter NULL salary values

SELECT
    job_title_short,
    salary_hour_avg,
    CASE
        WHEN salary_hour_avg IS NULL THEN 'Missing'
        WHEN salary_hour_avg < 25 THEN 'Low'
        WHEN salary_hour_avg < 50 THEN 'Medium'
        ELSE 'High'
    END AS salary_category
FROM job_postings_fact
LIMIT 10;

-- ============================================================================
-- Categorizing Categorical (Text) Values using CASE + LIKE
--
-- Goal:
-- Instead of bucketing numbers (salary ranges), we are now classifying text.
-- We inspect the full job_title and assign it to a broader category.
--
-- Example:
-- "Senior Data Analyst"           -> Data Analyst
-- "Lead Data Engineer"            -> Data Engineer
-- "Principal Data Scientist"      -> Data Scientist
-- Everything else                 -> Other
--
-- LIKE searches for text patterns.
-- % means "any number of characters before or after".
-- ============================================================================

SELECT
    job_title,      -- Full job title (raw text from the data)

    CASE
        -- If the title contains BOTH "Data" and "Analyst",
        -- classify it as "Data Analyst".
        WHEN job_title LIKE '%Data%' AND job_title LIKE '%Analyst%' THEN 'Data Analyst'

        -- If the title contains BOTH "Data" and "Engineer",
        -- classify it as "Data Engineer".
        WHEN job_title LIKE '%Data%' AND job_title LIKE '%Engineer%' THEN 'Data Engineer'

        -- If the title contains BOTH "Data" and "Scientist",
        -- classify it as "Data Scientist".
        WHEN job_title LIKE '%Data%' AND job_title LIKE '%Scientist%' THEN 'Data Scientist'

        -- Everything that does not match the above conditions
        -- is grouped into the "Other" category.
        ELSE 'Other'
    END AS job_title_category,   -- New derived column created by the CASE expression

    job_title_short              -- Original standardized job title for comparison

FROM job_postings_fact

-- RANDOM() shuffles the rows so we see different examples each time.
-- Otherwise the first 20 rows would always be identical.
ORDER BY RANDOM()

-- Return only 20 sample rows.
LIMIT 20;

-- ============================================================================
-- Conditional Aggregation using CASE
--
-- Goal:
-- Calculate TWO different median salaries for each job title:
--
-- 1. Median salary for jobs paying LESS than $100K.
-- 2. Median salary for jobs paying GREATER THAN OR EQUAL TO $100K.
--
-- CASE is used INSIDE the MEDIAN() function so only qualifying rows are
-- included in each calculation.
-- ============================================================================

SELECT
    job_title_short,              -- Group results by job title

    COUNT(*) AS total_postings,   -- Count how many job postings exist for this job title

    MEDIAN(
        CASE
            -- Only include salaries below $100K.
            -- Salaries >= $100K become NULL and are ignored by MEDIAN().
            WHEN salary_year_avg < 100000 THEN salary_year_avg
        END
    ) AS median_low_salary,

    MEDIAN(
        CASE
            -- Only include salaries of $100K or higher.
            -- Salaries below $100K become NULL and are ignored by MEDIAN().
            WHEN salary_year_avg >= 100000 THEN salary_year_avg
        END
    ) AS median_high_salary

FROM job_postings_fact

-- Ignore rows where annual salary is missing.
WHERE salary_year_avg IS NOT NULL

-- Calculate these statistics separately for each job title.
GROUP BY job_title_short;

-- ============================================================================
-- Final Example: Conditional Calculations
--
-- Goal:
-- Create one standardized salary metric regardless of whether the original
-- salary was stored as yearly salary or hourly salary.
--
-- Standardization Rules:
-- - If yearly salary exists, use it.
-- - Otherwise, convert hourly salary into yearly salary.
--   (Assume 2080 working hours per year.)
--
-- Then categorize standardized salaries:
-- < $75K        -> Low
-- $75K-$150K    -> Medium
-- >= $150K      -> High
-- ============================================================================

WITH salaries AS (

    SELECT
        job_title_short,
        salary_hour_avg,
        salary_year_avg,

        CASE
            -- If annual salary already exists, use it directly.
            WHEN salary_year_avg IS NOT NULL THEN salary_year_avg

            -- Otherwise convert hourly wage into annual salary.
            -- 2080 = 40 hours/week × 52 weeks/year
            WHEN salary_hour_avg IS NOT NULL THEN salary_hour_avg * 2080

        END AS standardized_salary

    FROM job_postings_fact

    -- Only keep rows that have at least one salary value.
    WHERE salary_year_avg IS NOT NULL
       OR salary_hour_avg IS NOT NULL
)

SELECT
    *,

    CASE

        -- Missing standardized salary
        WHEN standardized_salary IS NULL THEN 'Missing'

        -- Salary tiers
        WHEN standardized_salary < 75000 THEN 'Low'
        WHEN standardized_salary < 150000 THEN 'Medium'

        ELSE 'High'

    END AS salary_bucket

FROM salaries;