SELECT 
     jpf.*,
     cd.*
FROM 
     job_postings_fact AS jpf
left JOIN 
     company_dim AS cd
ON jpf.company_id = cd.company_id
LIMIT 10;

-- jpf and cd * are used we want all columns from each table

SELECT 
    jpf.job_id,
    jpf.job_title_short,
    cd.company_id,
    cd.name AS company_name,
    jpf.job_location
FROM 
     job_postings_fact AS jpf
left JOIN 
     company_dim AS cd
ON jpf.company_id = cd.company_id;

-- Its best practice to use table aliases (jpf and cd) to make the query more readable and avoid ambiguity when selecting columns from multiple tables.

SELECT 
     jpf.*,
     cd.*
FROM 
     job_postings_fact AS jpf
right JOIN 
     company_dim AS cd
ON jpf.company_id = cd.company_id;

SELECT*
FROM skills_job_dim
limit 10;

SELECT*
FROM skills_job_dim
LIMIT 10;

SELECT*
FROM skills_dim
LIMIT 10;

SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id
FROM
    job_postings_fact AS jpf
LEFT JOIN
    skills_job_dim AS sjd
ON jpf.job_id = sjd.job_id;

-- Nulls will be returned for jobs that do not have any skills associated with them in the skills_job_dim table. And they are all the way below.

SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id
FROM
    job_postings_fact AS jpf
INNER JOIN
    skills_job_dim AS sjd
ON jpf.job_id = sjd.job_id;

-- Went from 7.48M to 7.19M rows because we are only returning jobs that have skills associated with them in the skills_job_dim table.
-- So, 200k jobs do not have any skills associated with them in the skills_job_dim table.
-- Typically, we want to preserve all the jobs, even if they do not have any skills associated with them in the skills_job_dim table. So, we will use a LEFT JOIN instead of an INNER JOIN.

SELECT
    jpf.job_id,
    jpf.job_title_short,
    sjd.skill_id
FROM
    job_postings_fact AS jpf
FULL OUTER JOIN
    skills_job_dim AS sjd
ON jpf.job_id = sjd.job_id;