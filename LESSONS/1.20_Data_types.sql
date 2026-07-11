SELECT
     table_name,
     column_name,
     data_type
FROM information_schema.columns --Columns is a table so we use dot notation to access its columns
WHERE table_name = 'job_postings_fact';

DESCRIBE 
SELECT
     job_title_short,
     salary_year_avg
FROM
     job_postings_fact;


SELECT CAST ('123' AS INTEGER); --  anything inside single quotes is treated strictly as text (a string), not a number. To the database, '42' is no different than the word 'apple' 

SELECT
      CAST(job_id AS VARCHAR) || '-' || CAST(company_id AS VARCHAR) AS job_company_id, --"more" unique identifier, we get the hyphenated string by concatenating the two columns together. The || operator is used to concatenate strings in SQL. We need to cast both columns to VARCHAR because they are numeric types, and we want to treat them as strings for concatenation.
      CAST(job_work_from_home AS INTEGER) AS job_work_from_home, --boolean to numeric value
      CAST(job_posted_date AS DATE) AS job_posted_date, -- from timestamp to date only.
      CAST(salary_year_avg AS NUMERIC(10,0)) AS salary_year_avg -- from double to no decimal places. DECIMAL(PREC,SCALE) TO NUMERIC(PREC, SCALE), 10 is used we expect salaries to be less than 10 digits, 0 is used to allow for cents
FROM
      job_postings_fact
WHERE salary_year_avg IS NOT NULL
LIMIT 10;

SELECT
      (job_id :: VARCHAR) || '-' || (company_id :: VARCHAR) AS job_company_id, -- :: can be used to cast a column to a different data type. It is equivalent to the CAST() function.
      (job_work_from_home :: INTEGER) AS job_work_from_home, 
      (job_posted_date :: DATE) AS job_posted_date,
      (salary_year_avg :: NUMERIC(10,0)) AS salary_year_avg
FROM
      job_postings_fact
WHERE salary_year_avg IS NOT NULL
LIMIT 10;

SELECT (3 + 5.5) :: FLOAT;

SELECT (3 + 5.5) :: INT;