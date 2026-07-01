
/*
- Identify the top 10 most in-demand skills for remote Data Engineer positions
- Count how frequently each skill appears in job postings
- Rank skills by demand

*/

SELECT
     sd.skills,
     COUNT(jpf.*) AS demand_count
FROM job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id
WHERE 
    jpf.job_title_short = 'Data Engineer'
    AND jpf.work_from_home = TRUE
GROUP BY sd.skills
ORDER BY demand_count DESC --Alias is allowed here on duckdb
LIMIT 10;

/*
Key Insights:

-- Rust has the highest median salary ($210,000), but demand is relatively low (232 postings),
-- suggesting it is a high-paying niche skill.

-- Terraform ($184,000) and Kubernetes ($150,500) combine strong salaries with high demand,
-- making them valuable technologies for Data Engineers seeking both compensation and job opportunities.

-- Airflow has the highest demand (9,996 postings) among the top-paying skills,
-- highlighting its importance as a core workflow orchestration tool in modern data engineering.

-- Overall, the highest-paying skills are not always the most in-demand,
-- emphasizing the trade-off between specialization (e.g., Rust, Neo4j) and broader market demand
-- (e.g., Airflow, Kubernetes, Terraform).

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

*/