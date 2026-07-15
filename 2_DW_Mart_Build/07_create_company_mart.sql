/*
============================================================
STEP 7 (BONUS): CREATE COMPANY PROSPECTING MART
============================================================

Purpose:
Build a company-focused dimensional mart for analyzing:

- Which companies are hiring
- Which job titles they are hiring for
- Where they are hiring
- Monthly hiring volume
- Salary ranges
- Remote-work share
- Health-insurance share
- No-degree-mentioned share

Mart structure:

Dimensions:
- dim_company
- dim_job_title_short
- dim_job_title
- dim_location
- dim_date_month

Bridge tables:
- bridge_company_location
- bridge_job_title

Fact table:
- fact_company_hiring_monthly

Load order:
Dimensions → Bridge tables → Fact table → Validation

Run this script after the main warehouse tables have been created and loaded.
*/


-- ============================================================
-- CREATE COMPANY MART SCHEMA
-- ============================================================

DROP SCHEMA IF EXISTS company_mart CASCADE;                      -- Remove the existing mart and all objects for a clean rebuild

CREATE SCHEMA company_mart;                                      -- Create a fresh schema for company prospecting analytics


-- ============================================================
-- 1. COMPANY DIMENSION
-- ============================================================

SELECT '=== Loading Company Dimension ===' AS info;              -- Print progress message before loading the table

CREATE TABLE company_mart.dim_company (                          -- Create one row per company
    company_id INTEGER PRIMARY KEY,                              -- Unique company identifier
    company_name VARCHAR                                         -- Business-friendly company name
);

INSERT INTO company_mart.dim_company (                           -- Load company records into the mart
    company_id,
    company_name
)
SELECT
    company_id,
    name AS company_name                                         -- Rename source name column for clarity
FROM company_dim;                                                -- Copy companies from the warehouse dimension


-- ============================================================
-- 2. SHORT JOB-TITLE DIMENSION
-- ============================================================

SELECT '=== Loading Job Title Short Dimension ===' AS info;      -- Print progress message before loading the table

CREATE TABLE company_mart.dim_job_title_short (                  -- Create one row per standardized job title
    job_title_short_id INTEGER PRIMARY KEY,                      -- Generated identifier for each short title
    job_title_short VARCHAR                                      -- Standardized job title
);

INSERT INTO company_mart.dim_job_title_short (                   -- Load distinct standardized job titles
    job_title_short_id,
    job_title_short
)

WITH distinct_titles AS (                                        -- Create a temporary list of unique short titles
    SELECT DISTINCT
        job_title_short
    FROM job_postings_fact
    WHERE job_title_short IS NOT NULL                            -- Exclude missing titles
),

numbered_titles AS (                                             -- Assign a repeatable numeric ID alphabetically
    SELECT
        t1.job_title_short,
        COUNT(t2.job_title_short) + 1 AS job_title_short_id      -- Count titles alphabetically before the current title
    FROM distinct_titles AS t1
    LEFT JOIN distinct_titles AS t2
        ON t2.job_title_short < t1.job_title_short               -- Compare titles alphabetically
    GROUP BY
        t1.job_title_short
)

SELECT
    job_title_short_id,
    job_title_short
FROM numbered_titles
ORDER BY job_title_short;                                        -- Load titles in alphabetical order


-- ============================================================
-- 3. FULL JOB-TITLE DIMENSION
-- ============================================================

SELECT '=== Loading Job Title Dimension ===' AS info;            -- Print progress message before loading the table

CREATE TABLE company_mart.dim_job_title (                        -- Create one row per full job-title variation
    job_title_id INTEGER PRIMARY KEY,                            -- Generated identifier for each full title
    job_title VARCHAR                                            -- Complete job-title text
);

INSERT INTO company_mart.dim_job_title (                         -- Load distinct full job titles
    job_title_id,
    job_title
)

WITH distinct_titles AS (                                        -- Create a temporary list of unique full titles
    SELECT DISTINCT
        job_title
    FROM job_postings_fact
    WHERE job_title IS NOT NULL                                  -- Exclude missing titles
),

numbered_titles AS (                                             -- Assign a repeatable numeric ID alphabetically
    SELECT
        t1.job_title,
        COUNT(t2.job_title) + 1 AS job_title_id                  -- Count titles alphabetically before the current title
    FROM distinct_titles AS t1
    LEFT JOIN distinct_titles AS t2
        ON t2.job_title < t1.job_title                           -- Compare titles alphabetically
    GROUP BY
        t1.job_title
)

SELECT
    job_title_id,
    job_title
FROM numbered_titles
ORDER BY job_title;                                              -- Load titles in alphabetical order


-- ============================================================
-- 4. LOCATION DIMENSION
-- ============================================================

SELECT '=== Loading Location Dimension ===' AS info;             -- Print progress message before loading the table

CREATE TABLE company_mart.dim_location (                         -- Create one row per country-location combination
    location_id INTEGER PRIMARY KEY,                             -- Generated location identifier
    job_country VARCHAR,                                         -- Country of the job posting
    job_location VARCHAR                                         -- Detailed location from the posting
);

INSERT INTO company_mart.dim_location (                          -- Load unique location combinations
    location_id,
    job_country,
    job_location
)

WITH distinct_locations AS (                                     -- Create unique country-location combinations
    SELECT DISTINCT
        job_country,
        job_location
    FROM job_postings_fact
    WHERE job_country IS NOT NULL
      AND job_location IS NOT NULL                               -- Exclude incomplete locations
),

numbered_locations AS (                                          -- Assign a repeatable numeric ID by alphabetical order
    SELECT
        t1.job_country,
        t1.job_location,
        COUNT(t2.job_country) + 1 AS location_id                 -- Count locations ordered before the current location
    FROM distinct_locations AS t1
    LEFT JOIN distinct_locations AS t2
        ON t2.job_country < t1.job_country
        OR (
            t2.job_country = t1.job_country
            AND t2.job_location < t1.job_location
        )                                                        -- Sort first by country and then by location
    GROUP BY
        t1.job_country,
        t1.job_location
)

SELECT
    location_id,
    job_country,
    job_location
FROM numbered_locations
ORDER BY
    job_country,
    job_location;                                                -- Load locations in consistent alphabetical order


-- ============================================================
-- 5. MONTHLY DATE DIMENSION
-- ============================================================

SELECT '=== Loading Date Month Dimension ===' AS info;           -- Print progress message before loading the table

CREATE TABLE company_mart.dim_date_month (                       -- Create one row per reporting month
    month_start_date DATE PRIMARY KEY,                           -- First day of each month
    year INTEGER,                                                -- Calendar year
    month INTEGER                                                -- Month number from 1 to 12
);

INSERT INTO company_mart.dim_date_month (                        -- Load distinct reporting months
    month_start_date,
    year,
    month
)
SELECT DISTINCT
    DATE_TRUNC('month', job_posted_date)::DATE
        AS month_start_date,                                     -- Convert each timestamp to the first day of its month
    EXTRACT(YEAR FROM job_posted_date) AS year,                  -- Extract the calendar year
    EXTRACT(MONTH FROM job_posted_date) AS month                 -- Extract the month number
FROM job_postings_fact
WHERE job_posted_date IS NOT NULL;                               -- Exclude postings without dates


-- ============================================================
-- 6. COMPANY-LOCATION BRIDGE TABLE
-- ============================================================

SELECT '=== Loading Company Location Bridge ===' AS info;        -- Print progress message before loading the bridge

CREATE TABLE company_mart.bridge_company_location (              -- Connect companies to all locations where they hire
    company_id INTEGER,                                          -- Company identifier
    location_id INTEGER,                                         -- Location identifier

    PRIMARY KEY (
        company_id,
        location_id
    ),                                                            -- Prevent duplicate company-location combinations

    FOREIGN KEY (company_id)
        REFERENCES company_mart.dim_company(company_id),          -- Require a valid company

    FOREIGN KEY (location_id)
        REFERENCES company_mart.dim_location(location_id)         -- Require a valid location
);

INSERT INTO company_mart.bridge_company_location (               -- Load unique company-location relationships
    company_id,
    location_id
)
SELECT DISTINCT
    jpf.company_id,
    loc.location_id
FROM job_postings_fact AS jpf                                    -- Start with warehouse job postings
INNER JOIN company_mart.dim_location AS loc
    ON jpf.job_country = loc.job_country
   AND jpf.job_location = loc.job_location                       -- Match each posting to its location dimension row
WHERE jpf.company_id IS NOT NULL;                                -- Exclude postings without a company


-- ============================================================
-- 7. JOB-TITLE BRIDGE TABLE
-- ============================================================

SELECT '=== Loading Job Title Bridge ===' AS info;               -- Print progress message before loading the bridge

CREATE TABLE company_mart.bridge_job_title (                     -- Connect standardized titles to full title variations
    job_title_short_id INTEGER,                                  -- Standardized job-title identifier
    job_title_id INTEGER,                                        -- Full job-title identifier

    PRIMARY KEY (
        job_title_short_id,
        job_title_id
    ),                                                            -- Prevent duplicate title relationships

    FOREIGN KEY (job_title_short_id)
        REFERENCES company_mart.dim_job_title_short(
            job_title_short_id
        ),                                                        -- Require a valid short title

    FOREIGN KEY (job_title_id)
        REFERENCES company_mart.dim_job_title(job_title_id)       -- Require a valid full title
);

INSERT INTO company_mart.bridge_job_title (                      -- Load unique short-title to full-title relationships
    job_title_short_id,
    job_title_id
)
SELECT DISTINCT
    djs.job_title_short_id,
    djt.job_title_id
FROM job_postings_fact AS jpf                                    -- Start with warehouse job postings
INNER JOIN company_mart.dim_job_title_short AS djs
    ON jpf.job_title_short = djs.job_title_short                  -- Match standardized job title
INNER JOIN company_mart.dim_job_title AS djt
    ON jpf.job_title = djt.job_title                              -- Match full job title
WHERE jpf.job_title_short IS NOT NULL
  AND jpf.job_title IS NOT NULL;                                 -- Keep only complete title relationships


-- ============================================================
-- 8. MONTHLY COMPANY-HIRING FACT TABLE
-- ============================================================

SELECT '=== Loading Company Hiring Fact ===' AS info;            -- Print progress message before loading the fact table

CREATE TABLE company_mart.fact_company_hiring_monthly (          -- Store monthly company hiring metrics
    company_id INTEGER,                                          -- Company being measured
    job_title_short_id INTEGER,                                  -- Standardized job-title category
    job_country VARCHAR,                                         -- Country of the postings
    month_start_date DATE,                                       -- Reporting month
    postings_count INTEGER,                                      -- Number of postings
    median_salary_year DOUBLE,                                   -- Median annual salary
    min_salary_year DOUBLE,                                      -- Minimum annual salary
    max_salary_year DOUBLE,                                      -- Maximum annual salary
    remote_share DOUBLE,                                         -- Share of postings that are remote
    health_insurance_share DOUBLE,                               -- Share mentioning health insurance
    no_degree_mention_share DOUBLE,                              -- Share not mentioning a degree

    PRIMARY KEY (
        company_id,
        job_title_short_id,
        job_country,
        month_start_date
    ),                                                            -- One row per company, title, country, and month

    FOREIGN KEY (company_id)
        REFERENCES company_mart.dim_company(company_id),          -- Link fact records to company dimension

    FOREIGN KEY (job_title_short_id)
        REFERENCES company_mart.dim_job_title_short(
            job_title_short_id
        ),                                                        -- Link fact records to job-title dimension

    FOREIGN KEY (month_start_date)
        REFERENCES company_mart.dim_date_month(
            month_start_date
        )                                                         -- Link fact records to monthly date dimension
);

INSERT INTO company_mart.fact_company_hiring_monthly (           -- Load aggregated company-hiring metrics
    company_id,
    job_title_short_id,
    job_country,
    month_start_date,
    postings_count,
    median_salary_year,
    min_salary_year,
    max_salary_year,
    remote_share,
    health_insurance_share,
    no_degree_mention_share
)

WITH job_postings_prepared AS (                                   -- Prepare row-level postings before aggregation
    SELECT
        jpf.company_id,
        djs.job_title_short_id,
        jpf.job_country,

        DATE_TRUNC('month', jpf.job_posted_date)::DATE
            AS month_start_date,                                  -- Convert posting date to reporting month

        jpf.salary_year_avg,                                      -- Annual salary used for salary statistics

        CASE
            WHEN jpf.job_work_from_home = TRUE THEN 1.0
            ELSE 0.0
        END AS is_remote,                                         -- Convert remote Boolean to numeric 1.0 or 0.0

        CASE
            WHEN jpf.job_health_insurance = TRUE THEN 1.0
            ELSE 0.0
        END AS has_health_insurance,                              -- Convert insurance Boolean to numeric 1.0 or 0.0

        CASE
            WHEN jpf.job_no_degree_mention = TRUE THEN 1.0
            ELSE 0.0
        END AS no_degree_required                                 -- Convert no-degree Boolean to numeric 1.0 or 0.0

    FROM job_postings_fact AS jpf                                 -- Start with warehouse job postings

    INNER JOIN company_mart.dim_job_title_short AS djs
        ON jpf.job_title_short = djs.job_title_short              -- Convert title text into the mart's title ID

    WHERE jpf.company_id IS NOT NULL
      AND jpf.job_posted_date IS NOT NULL
      AND jpf.job_country IS NOT NULL                             -- Keep only records required by the fact table grain
)

SELECT
    company_id,                                                   -- Group by company
    job_title_short_id,                                           -- Group by standardized job-title category
    job_country,                                                  -- Group by country
    month_start_date,                                             -- Group by month

    COUNT(*) AS postings_count,                                   -- Count postings in each company-title-country-month group

    MEDIAN(salary_year_avg) AS median_salary_year,                -- Calculate the middle salary value
    MIN(salary_year_avg) AS min_salary_year,                      -- Calculate the lowest salary
    MAX(salary_year_avg) AS max_salary_year,                      -- Calculate the highest salary

    AVG(is_remote) AS remote_share,                               -- Calculate remote posting ratio from 0 to 1

    AVG(has_health_insurance)
        AS health_insurance_share,                                -- Calculate insurance-mentioned ratio from 0 to 1

    AVG(no_degree_required)
        AS no_degree_mention_share                                -- Calculate no-degree-mentioned ratio from 0 to 1

FROM job_postings_prepared                                       -- Aggregate the prepared job-posting records

GROUP BY
    company_id,
    job_title_short_id,
    job_country,
    month_start_date;                                             -- Produce one row at the defined fact-table grain


-- ============================================================
-- VALIDATE RECORD COUNTS
-- ============================================================

SELECT
    'Company Dimension' AS table_name,                            -- Label the company dimension
    COUNT(*) AS record_count                                      -- Count company rows
FROM company_mart.dim_company

UNION ALL                                                         -- Stack the next validation result

SELECT
    'Job Title Short Dimension',
    COUNT(*)
FROM company_mart.dim_job_title_short

UNION ALL                                                         -- Stack the next validation result

SELECT
    'Job Title Dimension',
    COUNT(*)
FROM company_mart.dim_job_title

UNION ALL                                                         -- Stack the next validation result

SELECT
    'Location Dimension',
    COUNT(*)
FROM company_mart.dim_location

UNION ALL                                                         -- Stack the next validation result

SELECT
    'Date Month Dimension',
    COUNT(*)
FROM company_mart.dim_date_month

UNION ALL                                                         -- Stack the next validation result

SELECT
    'Company Location Bridge',
    COUNT(*)
FROM company_mart.bridge_company_location

UNION ALL                                                         -- Stack the next validation result

SELECT
    'Job Title Bridge',
    COUNT(*)
FROM company_mart.bridge_job_title

UNION ALL                                                         -- Stack the final validation result

SELECT
    'Company Hiring Fact',
    COUNT(*)
FROM company_mart.fact_company_hiring_monthly;


-- ============================================================
-- PREVIEW SAMPLE RECORDS
-- ============================================================

SELECT '=== Company Dimension Sample ===' AS info;               -- Print heading before the company sample

SELECT *
FROM company_mart.dim_company
LIMIT 5;                                                          -- Preview five company records


SELECT '=== Job Title Short Dimension Sample ===' AS info;       -- Print heading before standardized-title sample

SELECT *
FROM company_mart.dim_job_title_short
LIMIT 10;                                                         -- Preview ten standardized titles


SELECT '=== Job Title Dimension Sample ===' AS info;             -- Print heading before full-title sample

SELECT *
FROM company_mart.dim_job_title
LIMIT 10;                                                         -- Preview ten full job titles


SELECT '=== Location Dimension Sample ===' AS info;              -- Print heading before location sample

SELECT *
FROM company_mart.dim_location
LIMIT 10;                                                         -- Preview ten locations


SELECT '=== Date Month Dimension Sample ===' AS info;            -- Print heading before monthly date sample

SELECT *
FROM company_mart.dim_date_month
ORDER BY month_start_date DESC
LIMIT 10;                                                         -- Preview the ten most recent reporting months


SELECT '=== Company Location Bridge Sample ===' AS info;         -- Print heading before bridge-table sample

SELECT
    bcl.company_id,                                               -- Company identifier from the bridge
    dc.company_name,                                              -- Descriptive company name
    bcl.location_id,                                              -- Location identifier from the bridge
    dl.job_country,                                               -- Country from location dimension
    dl.job_location                                               -- Detailed location from location dimension
FROM company_mart.bridge_company_location AS bcl                 -- Begin with company-location relationships
INNER JOIN company_mart.dim_company AS dc
    ON bcl.company_id = dc.company_id                             -- Add company details
INNER JOIN company_mart.dim_location AS dl
    ON bcl.location_id = dl.location_id                           -- Add location details
LIMIT 10;                                                         -- Preview ten company-location relationships


SELECT '=== Job Title Bridge Sample ===' AS info;                -- Print heading before job-title bridge sample

SELECT
    bjt.job_title_short_id,                                       -- Standardized-title identifier
    djs.job_title_short,                                          -- Standardized job-title name
    bjt.job_title_id,                                             -- Full-title identifier
    djt.job_title                                                 -- Full job-title variation
FROM company_mart.bridge_job_title AS bjt                        -- Begin with title relationships
INNER JOIN company_mart.dim_job_title_short AS djs
    ON bjt.job_title_short_id = djs.job_title_short_id            -- Add standardized title
INNER JOIN company_mart.dim_job_title AS djt
    ON bjt.job_title_id = djt.job_title_id                        -- Add full title
WHERE djs.job_title_short = 'Data Engineer'                       -- Show Data Engineer title variations
LIMIT 10;                                                         -- Preview ten relationships


SELECT '=== Company Hiring Fact Sample ===' AS info;             -- Print heading before fact-table sample

SELECT
    fchm.company_id,                                              -- Company identifier
    dc.company_name,                                              -- Company name
    djs.job_title_short,                                          -- Standardized job-title category
    fchm.job_country,                                             -- Country being measured
    fchm.month_start_date,                                        -- Reporting month
    fchm.postings_count,                                          -- Number of postings
    fchm.median_salary_year                                       -- Median annual salary
FROM company_mart.fact_company_hiring_monthly AS fchm            -- Begin with monthly company-hiring metrics
INNER JOIN company_mart.dim_company AS dc
    ON fchm.company_id = dc.company_id                            -- Add company name
INNER JOIN company_mart.dim_job_title_short AS djs
    ON fchm.job_title_short_id = djs.job_title_short_id           -- Add standardized job-title name
ORDER BY
    fchm.postings_count DESC,
    fchm.median_salary_year DESC                                  -- Show companies with the most postings and highest median salary
LIMIT 10;                                                         -- Preview the top ten fact records