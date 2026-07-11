-- .read 'LESSONS/1.21_DDL_DML_pt1 copy 2.sql'

USE data_jobs;

DROP DATABASE IF EXISTS jobs_mart;
CREATE DATABASE jobs_mart;

USE jobs_mart;

CREATE SCHEMA IF NOT EXISTS staging;

-- Create main table
CREATE TABLE main.preferred_roles (
    role_id INTEGER PRIMARY KEY,
    role_name VARCHAR
);

-- Create staging table
CREATE TABLE staging.preferred_roles (
    role_id INTEGER,
    role_name VARCHAR
);

-- Insert rows into main table
INSERT INTO main.preferred_roles (role_id, role_name)
VALUES
    (1, 'Data Engineer'),
    (2, 'Senior Data Engineer'),
    (3, 'Data Scientist');

-- Insert rows into staging table
INSERT INTO staging.preferred_roles (role_id, role_name)
VALUES
    (1, 'Data Engineer'),
    (2, 'Senior Data Engineer'),
    (3, 'Data Scientist');

-- View original main table
SELECT *
FROM main.preferred_roles;

-- View original staging table
SELECT *
FROM staging.preferred_roles;

-- ALTER TABLE: add a new column to staging table
ALTER TABLE staging.preferred_roles
ADD COLUMN preferred_role BOOLEAN;

-- UPDATE: assign TRUE/FALSE values to the new column
UPDATE staging.preferred_roles
SET preferred_role = TRUE
WHERE role_id = 1 OR role_id = 2;

UPDATE staging.preferred_roles
SET preferred_role = FALSE
WHERE role_id = 3;

-- View staging table after adding/updating preferred_role
SELECT *
FROM staging.preferred_roles;

-- RENAME TABLE: change table name from preferred_roles to priority_roles
ALTER TABLE staging.preferred_roles
RENAME TO priority_roles;

-- View renamed table
SELECT *
FROM staging.priority_roles;

-- RENAME COLUMN: change preferred_role column name to priority_lvl
ALTER TABLE staging.priority_roles
RENAME COLUMN preferred_role TO priority_lvl;

-- ALTER COLUMN TYPE: convert BOOLEAN values to INTEGER values
-- TRUE becomes 1, FALSE becomes 0
ALTER TABLE staging.priority_roles
ALTER COLUMN priority_lvl TYPE INTEGER;

-- UPDATE: manually change Data Scientist priority level to 3
UPDATE staging.priority_roles
SET priority_lvl = 3
WHERE role_id = 3;

-- Final output
SELECT *
FROM staging.priority_roles;