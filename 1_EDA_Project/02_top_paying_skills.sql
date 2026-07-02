/*
- Calculate median salary for each skill required in data engineer postions
-Focus on remote positions with specified salaries
-Include skill frequency to identify both salary and demand
- Why? Helps identify which skills command the highest compensation while also showing how copmmon those skils are, providing a more complete picture for skill development and career planning.
*/

SELECT
     sd.skills,
     ROUND (MEDIAN(jpf.salary_year_avg),0) AS median_salary, -- 0 is used to round to the nearest whole number
     COUNT(jpf.*) AS demand_count
FROM job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
     ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
     ON sjd.skill_id = sd.skill_id
WHERE 
     jpf.job_title_short = 'Data Engineer'
     AND jpf.job_work_from_home = True
GROUP BY 
     sd.skills -- sd is used because it is the alias for the skills_dim table, which contains the skills column. Grouping by sd.skills allows us to calculate the median salary and demand count for each unique skill.
HAVING
     COUNT(jpf.*) > 100 -- Only include skills that appear in more than 100 job postings to ensure statistical significance for in demand skills.
ORDER BY
     median_salary DESC --Alias is allowed here on duckdb
LIMIT 25;

/*
The data type is double hence the median_salary output is a decimal number. 
The ROUND function is used to round the median_salary to the nearest whole number for easier interpretation.

Key Insights:
-Rust remains the top paying skill at $210k median salary
-Terraform and Golang both bhjave high median salaries of $200k and $195k respectively, indicating strong demand for these skills in the data engineering field.
-Other notable skills with both high pay and moderate to high demand include Scala, Spark, and Kubernetes, which are essential for big data processing and cloud-native application development.
-Spring: $175k median salary (364 postings)
-Neo4j: $170k median salary (150 postings)
-GDPR: $169.6k median salary (120 postings)
-GraphQL: $167.5k median salary (200 postings)
-BitBucket, Ruby, Redisand Jupyter all appear in the top 25 list, indicating that a diverse set of skills can lead to lucrative opportunities in data engineering.

Takeaway: While the very top paying skill (Rust) still has a relatively low number of postings, the other skills in the top 25 list show that there are multiple pathways to high-paying roles in data engineering, especially for those with expertise in cloud technologies, big data frameworks, and programming languages that are in demand.

────────────┬───────────────┬──────────────┐
│   skills   │ median_salary │ demand_count │
│  varchar   │    double     │    int64     │
├────────────┼───────────────┼──────────────┤
│ rust       │      210000.0 │          232 │
│ golang     │      184000.0 │          912 │
│ terraform  │      184000.0 │         3248 │
│ spring     │      175500.0 │          364 │
│ neo4j      │      170000.0 │          277 │
│ gdpr       │      169616.0 │          582 │
│ zoom       │      168438.0 │          127 │
│ graphql    │      167500.0 │          445 │
│ mongo      │      162250.0 │          265 │
│ fastapi    │      157500.0 │          204 │
│ django     │      155000.0 │          265 │
│ bitbucket  │      155000.0 │          478 │
│ crystal    │      154224.0 │          129 │
│ c          │      151500.0 │          444 │
│ atlassian  │      151500.0 │          249 │
│ typescript │      151000.0 │          388 │
│ kubernetes │      150500.0 │         4202 │
│ node       │      150000.0 │          179 │
│ css        │      150000.0 │          262 │
│ ruby       │      150000.0 │          736 │
│ airflow    │      150000.0 │         9996 │
│ redis      │      149000.0 │          605 │
│ vmware     │      148798.0 │          136 │
│ ansible    │      148798.0 │          475 │
│ jupyter    │      147500.0 │          400 │
└────────────┴───────────────┴──────────────
*/