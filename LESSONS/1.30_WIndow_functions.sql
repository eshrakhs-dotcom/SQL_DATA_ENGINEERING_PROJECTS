/*
WINDOW FUNCTIONS SUMMARY

Window functions let you calculate across multiple rows while keeping the
original row-level detail. GROUP BY collapses rows; OVER() does not.
*/

-- 1) Average hourly salary by job title
-- PARTITION BY creates separate groups/windows for each job_title_short.
-- Each row stays visible, but gets the average for its job-title group.

SELECT
    job_id,
    job_title_short,
    company_id,
    salary_hour_avg,
    AVG(salary_hour_avg) OVER (
        PARTITION BY job_title_short
    ) AS avg_hourly_by_title
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL;

-- 2) Overall average hourly salary
-- This returns one single average for the entire table.
-- Unlike the window query above, this collapses everything into one row.

SELECT
    AVG(salary_hour_avg)
FROM job_postings_fact;

-- 3) Rank all jobs by hourly salary
-- RANK() assigns position based on salary.
-- Highest salary can be ranked first if ORDER BY salary_hour_avg DESC is used.

SELECT
    job_id,
    job_title_short,
    company_id,
    salary_hour_avg,
    RANK() OVER (
        ORDER BY salary_hour_avg DESC
    ) AS rank_hourly_salary
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL
ORDER BY salary_hour_avg DESC
LIMIT 10;

-- 4) Running average by job title over time
-- PARTITION BY job_title_short creates a separate running average per title.
-- ORDER BY job_posted_date makes the average build over time.

SELECT
    job_id,
    job_title_short,
    salary_hour_avg,
    AVG(salary_hour_avg) OVER (
        PARTITION BY job_title_short
        ORDER BY job_posted_date
    ) AS running_avg_hourly_by_title
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL
  AND job_title_short = 'Data Engineer'
ORDER BY job_title_short, job_posted_date
LIMIT 10;

-- 5) Rank hourly salaries within each job title
-- PARTITION BY restarts the ranking for every job title.
-- So Data Engineers get their own rank list, Data Analysts get their own, etc.

SELECT
    job_id,
    job_title_short,
    salary_hour_avg,
    RANK() OVER (
        PARTITION BY job_title_short
        ORDER BY salary_hour_avg DESC
    ) AS rank_hourly_salary
FROM job_postings_fact
WHERE salary_hour_avg IS NOT NULL
ORDER BY salary_hour_avg DESC, job_title_short
LIMIT 10;

-- Running Total Hourly Salary
-- SUM() OVER() calculates a cumulative (running) total instead of an average.
-- PARTITION BY keeps each job title in its own window.
-- ORDER BY job_posted_date processes rows chronologically so the total grows over time.

SELECT
    job_posted_date,
    job_title_short,
    salary_hour_avg,

    SUM(salary_hour_avg) OVER (
        PARTITION BY job_title_short      -- Separate running total for each job title.
        ORDER BY job_posted_date          -- Add each new row in posting-date order.
    ) AS running_total_hourly_by_title

FROM job_postings_fact

WHERE
    salary_hour_avg IS NOT NULL
    AND job_title_short = 'Data Engineer'

ORDER BY
    job_title_short,
    job_posted_date

LIMIT 10;

-- Ranking Function: Rank jobs by highest hourly salary.
-- RANK() assigns a ranking based on salary. If two salaries tie, they receive the same rank.

SELECT
    job_id,
    job_title_short,
    salary_hour_avg,

    RANK() OVER (
        ORDER BY salary_hour_avg DESC      -- Highest hourly salary receives Rank = 1.
    ) AS rank_hourly_salary

FROM job_postings_fact

WHERE
    salary_hour_avg IS NOT NULL            -- Ignore rows with missing salaries.

ORDER BY
    salary_hour_avg DESC                   -- Display highest-paying jobs first.

LIMIT 10;                                  -- Show only the Top 10 ranked jobs.

-- RANK()       → Leaves gaps after ties.      Example: 1, 1, 3, 4
-- DENSE_RANK() → No gaps after ties.          Example: 1, 1, 2, 3

-- DENSE_RANK() ranks rows by salary without skipping numbers after ties.
-- Unlike RANK(), tied rows receive the same rank, but the next rank remains consecutive (1, 1, 2, 3 instead of 1, 1, 3, 4).

-- ROW_NUMBER(): Assign a unique sequential number to each row.
-- Useful for creating IDs, removing duplicates, or selecting the "first" row in each group.

SELECT
    *,

    ROW_NUMBER() OVER (
        ORDER BY job_posted_date          -- Number rows in chronological order (oldest → newest).
    ) AS row_num

FROM job_postings_fact

ORDER BY
    job_posted_date                      -- Display rows in the same order used for numbering.

LIMIT 20;                                -- Show the first 20 numbered rows.

-- ROW_NUMBER() → Every row gets a unique number (1, 2, 3, 4...).
-- RANK()       → Ties share the same rank and leave gaps.
-- DENSE_RANK() → Ties share the same rank without leaving gaps.

-- LAG() - Time Based COmparison of OCmpany Yearly Salalry
-- LAG(): Compare each company's current posting salary to its previous posting salary over time.
-- LAG(): Compare each company's current yearly salary to its previous posting.
-- Also calculate the salary difference between consecutive postings.

SELECT
    job_id,
    company_id,
    job_title,
    job_title_short,
    job_posted_date,
    salary_year_avg,

    LAG(salary_year_avg) OVER (
        PARTITION BY company_id          -- Restart comparisons for each company separately.
        ORDER BY job_posted_date         -- Compare postings in chronological order.
    ) AS previous_posting_salary,

    salary_year_avg -
    LAG(salary_year_avg) OVER (
        PARTITION BY company_id          -- Use the same previous salary for this company.
        ORDER BY job_posted_date
    ) AS salary_change                  -- Current salary minus previous salary = change over time.

FROM
    job_postings_fact

WHERE
    salary_year_avg IS NOT NULL          -- Ignore rows with missing salary values.

ORDER BY
    company_id,
    job_posted_date

LIMIT 60;

-- LEAD(): Compare each company's current salary to its next job posting.
-- Useful for looking ahead instead of looking back.

SELECT
    job_id,
    company_id,
    job_title,
    job_title_short,
    job_posted_date,
    salary_year_avg,

    LEAD(salary_year_avg) OVER (
        PARTITION BY company_id          -- Restart comparisons for each company.
        ORDER BY job_posted_date         -- Look at postings in chronological order.
    ) AS next_posting_salary,            -- Returns the salary from the next posting.

    salary_year_avg -
    LEAD(salary_year_avg) OVER (
        PARTITION BY company_id          -- Use the same ordering to fetch the next salary.
        ORDER BY job_posted_date
    ) AS salary_change,                  -- Current salary minus the next salary.

FROM
    job_postings_fact

WHERE
    salary_year_avg IS NOT NULL          -- Ignore rows without yearly salary.

ORDER BY
    company_id,
    job_posted_date

LIMIT 60;