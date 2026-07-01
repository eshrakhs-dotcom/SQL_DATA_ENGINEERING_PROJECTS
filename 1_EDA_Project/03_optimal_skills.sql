/*
Q: What are the mnost optiomal skills for data engineers-balancing both demand and salary
-Create a ranking column that combines demand count and median salary to identify the most valiuable skills
-Focus only on remote Data Engineer positions with specified salaries
-Why? 
   -This approach highlights skills thaty balance markwet demand and financial reward. It weights core skills that are in high demand and offer competitive salaries, providing a more holistic view of skill value for career development.

*/

SELECT
     sd.skills,
     ROUND (MEDIAN(jpf.salary_year_avg),0) AS median_salary, -- 0 is used to round to the nearest whole number. We are also analyzing median saalry based on a skill but not every skill or job posting has a median salary with it. Lets replace that with a new COUNT
     COUNT(jpf.salary_year_avg) AS demand_count -- We do nt want to inflate any skills with postings but not backing up with salary data
     MEDIAN(jpf.salary_year_avg) * COUNT (jpf.salary_year_avg) AS optimal_score -- This is a new column that combines both median salary and demand count to create a ranking metric for each skill. It multiplies the median salary by the demand count to give a weighted score that reflects both financial reward and market demand.
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

SELECT
    sd.skills,
    MEDIAN(jpf.salary_year_avg) AS median_salary,
    COUNT(jpf.*) AS demand_count,
    ROUND(LN (COUNT(jpf.salary_year_avg)),1) AS ln_demand_count,
    ROUND ((MEDIAN(jpf.salary_year_avg) * LN(COUNT(jpf.*)))/1_000_000,2) AS optimal_score -- Lets convert demand count into natural log of it. Count of those non null values of salary, job posted with salaries posted to it.  
FROM job_postings_fact AS jpf
INNER JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim AS sd
    ON sjd.skill_id = sd.skill_id
WHERE
    jpf.job_title_short = 'Data Engineer'
    AND jpf.job_work_from_home = TRUE
    AND jpf.salary_year_avg IS NOT NULL -- natural log of 0 is undefined, so we need to filter out any rows where the salary is null to avoid errors in the calculation.
GROUP BY
    sd.skills
HAVING
    COUNT(jpf.*) > 100
ORDER BY
    optimal_score DESC
LIMIT 25;


/*


Objective:
- Find skills that maximize both compensation and market demand.
- Instead of ranking by salary or demand alone, combine both into a single metric.

Methodology:
- MEDIAN(salary_year_avg)
    Uses the median instead of the average because salaries often contain extreme outliers.
    The median better represents the "typical" market salary.

- COUNT(jpf.*)
    Measures how frequently each skill appears in remote Data Engineer job postings.
    This represents employer demand.

- LN(COUNT(...))
    Applies the natural logarithm to demand count.
    Without the logarithm, extremely common skills (Python, SQL) dominate the ranking simply
    because they appear thousands of times more often than niche skills.

    The logarithm compresses very large demand values while preserving their ordering,
    allowing salary to have a more balanced influence on the final score.

- optimal_score
    optimal_score = Median Salary × ln(Demand Count)

    This rewards skills that are BOTH:
    • highly compensated
    • consistently demanded

    rather than simply the most common skills.

Why HAVING COUNT(*) > 100?
- Removes very rare skills whose salaries may be based on only a handful of postings.
- Produces rankings that are statistically more reliable.

Key Takeaways

- Terraform ranks #1 because it combines the highest median salary ($184K) with meaningful demand
  (193 postings). Although Python and SQL are far more common, Terraform's salary premium more than
  offsets its lower demand after the logarithm compresses demand counts.

- Python and SQL remain near the top because they are foundational Data Engineering skills.
  Their demand exceeds 1,100 postings each while maintaining strong six-figure median salaries,
  making them exceptionally valuable despite not having the highest pay.

- AWS, Airflow, Spark, Snowflake, and Kafka form the core cloud and data infrastructure stack.
  They consistently offer salaries between roughly $135K–$150K while maintaining several hundred
  job postings, indicating both strong compensation and widespread industry adoption.

- Cloud platforms and distributed data technologies dominate the rankings, suggesting modern
  Data Engineering increasingly revolves around scalable cloud infrastructure, orchestration,
  streaming, and distributed compute rather than traditional database administration alone.

- The logarithmic transformation reveals skills with the strongest balance of scarcity and demand,
  instead of simply rewarding the most frequently requested technologies.



*/