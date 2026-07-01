/*
Find the top 10 companies for posting jobs
They must have >3000 postings
*/

-- jpf.* is used to count all columns from the jpf table

SELECT 
    cd.name AS company_name,
    COUNT(jpf.*) AS posting_count
FROM
    job_postings_fact AS jpf
LEFT JOIN
    company_dim AS cd
ON jpf.company_id = cd.company_id
GROUP BY
    cd.name;

EXPLAIN ANALYZE
SELECT 
    cd.name AS company_name,
    COUNT(jpf.*) AS posting_count
FROM
    job_postings_fact AS jpf
LEFT JOIN
    company_dim AS cd
ON jpf.company_id = cd.company_id
WHERE jpf.job_country = 'United States'
GROUP BY
    cd.name
HAVING COUNT(jpf.*) > 3000
ORDER BY posting_count DESC
LIMIT 10;




/*
Goal:
Find the top 10 companies in the United States
that have posted more than 3,000 job listings.
*/

SELECT
    -- Retrieve the company name from the company_dim table.
    -- "AS company_name" simply renames the output column.
    cd.name AS company_name,

    -- Count how many rows (job postings) belong to each company.
    -- Every row in job_postings_fact represents ONE job posting.
    COUNT(jpf.*) AS posting_count

FROM
    -- Start with the job postings table because this is where
    -- every individual job posting is stored.
    job_postings_fact AS jpf

LEFT JOIN
    -- Bring in the company table so we can replace company_id
    -- with the actual company name.
    company_dim AS cd

ON
    -- Match rows where both tables have the same company_id.
    --
    -- Example:
    --
    -- job_postings_fact
    -- company_id
    -- ----------
    -- 101
    -- 101
    -- 205
    --
    -- company_dim
    -- company_id | name
    -- -------------------------
    -- 101        | Google
    -- 205        | Microsoft
    --
    -- After the JOIN:
    --
    -- job_id | company_id | name
    -- ------------------------------
    -- 1      | 101        | Google
    -- 2      | 101        | Google
    -- 3      | 205        | Microsoft
    --
    -- Think of the LEFT JOIN as temporarily attaching the
    -- company's information onto every matching job posting.
    --
    -- Because it's a LEFT JOIN:
    -- • Every job posting from jpf is kept.
    -- • If a company_id has no matching company,
    --   the job posting still appears,
    --   but the company columns become NULL.
    --
    -- In this dataset an INNER JOIN would likely produce
    -- the same result because every company_id has a match.
    jpf.company_id = cd.company_id

WHERE
    -- Only keep job postings located in the United States
    -- BEFORE grouping begins.
    jpf.job_country = 'United States'

GROUP BY
    -- This is the most important part.
    --
    -- SQL needs to know HOW to form groups before it can COUNT().
    --
    -- We group by company name because we want ONE result per company.
    --
    -- Imagine after filtering we have:
    --
    -- Google
    -- Google
    -- Google
    -- Microsoft
    -- Microsoft
    -- Amazon
    --
    -- GROUP BY cd.name creates:
    --
    -- Group 1: Google
    -- Group 2: Microsoft
    -- Group 3: Amazon
    --
    -- COUNT() is then calculated separately for each group.
    cd.name

HAVING
    -- HAVING filters AFTER GROUP BY.
    --
    -- WHERE filters rows.
    -- HAVING filters groups.
    --
    -- Example:
    --
    -- Google      4,500 jobs
    -- Microsoft   3,900 jobs
    -- Amazon      2,700 jobs
    --
    -- HAVING removes Amazon because
    -- 2,700 is not greater than 3,000.
    COUNT(jpf.*) > 3000

ORDER BY
    -- Sort the remaining companies from highest
    -- posting count to lowest.
    posting_count DESC

LIMIT 10;
    -- Return only the top 10 companies.