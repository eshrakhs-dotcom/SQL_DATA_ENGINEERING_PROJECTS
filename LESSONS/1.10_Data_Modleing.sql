SELECT
job_id,
job_title_short,
company_id,

salary_year_avg
FROM
job_postings_fact

LIMIT 10;
WHERE
   NAME IN ('FACEBOOK', 'META')

SELECT*
FROM skills_dim
LIMIT 5

-- (.) is used after the schema name to access the tables within that schema.

SELECT *
FROM information_schema.table_constraints
WHERE table_catalog = 'data_jobs';

/*
Key takeaway:
If data tables work but schema/meta queries fail,
the database connection is probably fine.
Check version differences, metadata syntax,
or whether you're connected to the correct database.
*/
