

-- Array Access Example
-- Step 1: Create one row per skill.
-- Step 2: Use ARRAY_AGG() to combine those rows into a single array.
-- Step 3: Access the first element of that array using array indexing.
-- Note: ARRAY_AGG() does NOT guarantee element order unless ORDER BY is specified.

WITH skills AS (
    SELECT 'python' AS skill      -- First skill.
    UNION ALL
    SELECT 'sql'                  -- Second skill.
    UNION ALL
    SELECT 'r'                    -- Third skill.
),

skills_array AS (
    SELECT
        ARRAY_AGG(skill) AS skills    -- Combine all rows into one array.
    FROM skills
)

SELECT
    skills[1] AS first_skill          -- Arrays in DuckDB are 1-indexed; returns the first element.
FROM
    skills_array;

-- Ordered Array Example
-- Step 1: Create one row per skill.
-- Step 2: Sort the rows while building the array.
-- Step 3: Access each array element by its index.
-- Why? ORDER BY inside ARRAY_AGG() guarantees a consistent element order.

WITH skills AS (
    SELECT 'python' AS skill      -- First row.
    UNION ALL
    SELECT 'sql'                  -- Second row.
    UNION ALL
    SELECT 'r'                    -- Third row.
),

skills_array AS (
    SELECT
        ARRAY_AGG(skill ORDER BY skill) AS skills   -- Build the array in alphabetical order.
    FROM skills
)

SELECT
    skills[1] AS first_skill,     -- Index 1 → first element ('python')
    skills[2] AS second_skill,    -- Index 2 → second element ('r')
    skills[3] AS third_skill      -- Index 3 → third element ('sql')
FROM
    skills_array;

-- STRUCT
SELECT { skill: 'python', type: 'programming'} AS skill_struct;

-- STRUCT Example
-- Step 1: Create a struct (an object) with named fields.
-- Step 2: Access each field using dot notation.
-- Why? Structs group related attributes together, similar to a JSON object.

WITH skill_struct AS (
    SELECT
        STRUCT_PACK(
            skill := 'python',         -- Create a field named 'skill'.
            type := 'programming'      -- Create a field named 'type'.
        ) AS s                         -- Store the struct in column 's'.
)

SELECT
    s.skill,                           -- Access the 'skill' field.
    s.type                             -- Access the 'type' field.
FROM
    skill_struct;

-- Build one struct for each row in the table.
-- Why? Structs keep related columns together as a single object.

WITH skill_table AS (
    SELECT 'python' AS skill, 'programming' AS types
    UNION ALL
    SELECT 'sql', 'query_language'
    UNION ALL
    SELECT 'r', 'programming'
)

SELECT
    STRUCT_PACK(
        skill := skill,          -- Use the value from the 'skill' column.
        type := types            -- Use the value from the 'types' column.
    ) AS skill_struct            -- Return one struct per row.
FROM
    skill_table;

-- Array:
-- An ordered collection of values of the same type (e.g., ['python', 'sql', 'r']).
-- Use arrays when you need to store multiple related values in a single column.

-- Struct:
-- A single object with named fields (e.g., {skill: 'python', type: 'programming'}).
-- Use structs to group related attributes together, similar to a JSON object or Python dictionary.

-- Array of Structs:
-- A list where each element is a struct (e.g., [{skill:'python', type:'programming'}, {...}]).
-- Use this for nested data, where each item has multiple related fields, such as API responses or JSON documents.

--ARRAY OF STRUCTS

SELECT
[
  {skill:'python', type:'programming'},
  {skill:'sql', type:'query_language'}
] AS skills_array_of_structs
-- Build skill rows, convert each row into a struct,
-- collect the structs into one array, then access each array position.

WITH skill_table AS (
    SELECT 'python' AS skills, 'programming' AS types
    UNION ALL
    SELECT 'sql', 'query_language'
    UNION ALL
    SELECT 'r', 'programming'
),

skills_array_struct AS (
    SELECT
        ARRAY_AGG(
            STRUCT_PACK(
                skill := skills,
                type := types
            )
            ORDER BY skills
        ) AS array_struct
    FROM skill_table                 -- No semicolon here because the CTE continues.
)

SELECT
    array_struct[1].skill,  -- First object in the ordered array.
    array_struct[2].type, -- Second object.
    array_struct[3]    -- Third object.
FROM skills_array_struct;             -- Only final semicolon goes here.

-- Step 1: Create a CTE containing one JSON document.
WITH raw_skill_json AS (
    SELECT
        '{"skill":"python","type":"programming"}'::JSON AS skill_json
        -- ::JSON casts the text into a JSON object.
)

SELECT
    STRUCT_PACK(
        skill := json_extract_string(skill_json, '$.skill'),
        -- Extract the value of the "skill" key ("python").

        type := json_extract_string(skill_json, '$.type')
        -- Extract the value of the "type" key ("programming").
    ) AS skill_struct
    -- Pack the extracted values into a SQL STRUCT.

FROM raw_skill_json;

--This example: We will put our skills from skills_dim table into an array.

-- Arrays: Final Example
-- Build a temporary flat job table containing job details plus all related skills in one array.

CREATE OR REPLACE TEMP TABLE job_skills_array AS    -- Rebuild the temporary result table each time the script runs.
SELECT
    jpf.job_id,
    jpf.job_title_short,
    jpf.salary_year_avg,
    ARRAY_AGG(sd.skills) AS skills_array            -- Collect all skills linked to each job into one array.
FROM job_postings_fact AS jpf
LEFT JOIN skills_job_dim AS sjd
    ON jpf.job_id = sjd.job_id                      -- Connect each job posting to its related skill IDs.
LEFT JOIN skills_dim AS sd
    ON sd.skill_id = sjd.skill_id                   -- Convert each skill ID into its readable skill name.
GROUP BY ALL;                                       -- Group by every non-aggregated selected column.

/* -- A good way to remember it is:

--ARRAY_AGG() → Many rows ➜ One array
--UNNEST() → One array ➜ Many rows
*/
 


-- From the perspective of a Data Analyst:
-- Flatten an array of structs so each skill and its type become individual rows.

/*
The flat_skills CTE expands the skills_type array of structs into one row per skill.
Dot notation accesses the skill_name and skill_type fields inside each struct.
The outer query groups rows by skill_type and calculates the median salary for each category.
*/

-- Step 1: Create a temporary CTE that flattens the array of structs into one row per skill.
WITH flat_skills AS (
    SELECT
        job_id,
        job_title_short,
        salary_year_avg,
        UNNEST(skills_type).skill_type AS skill_type,   -- Expand the array and access the 'skill_type' field.
        UNNEST(skills_type).skill_name AS skill_name    -- Expand the array and access the 'skill_name' field.
    FROM
        job_skills_array_struct                         -- Table where each row contains an array of structs.
)

-- Step 2: Analyze salaries by skill category.
SELECT
    skill_type,                                        -- Group results by the skill category.
    MEDIAN(salary_year_avg) AS median_salary           -- Calculate the median salary for each skill type.
FROM
    flat_skills                                        -- Use the flattened data created in the CTE.
GROUP BY
    skill_type                                         -- One result per skill category.
ORDER BY
    median_salary DESC;                                -- Highest-paying skill types first.

-- Arrays store many values; structs store multiple named fields.
-- An array of structs = a list of objects (similar to a JSON array).
-- UNNEST() creates one row per object, and "." accesses fields inside each struct.
-- Data engineers flatten nested data before performing SQL analytics.