CREATE OR REPLACE TABLE staging.priority_roles (
    role_id INTEGER PRIMARY KEY,
    role_name VARCHAR,
    priority_lvl INTEGER
);

INSERT INTO staging.priority_roles (role_id, role_name, priority_lvl)
VALUES
    (1, 'Data Engineer', 2),
    (2, 'Senior Data Engineer', 1),
    (3, 'Software Engineer', 3),
    (4, 'Data Scientist',2);

SELECT *
FROM staging.priority_roles;

--The table above is such a small table that it's not worth it to run in batch instead to create it from scratch. The table is small enough that it can be created and populated in a single step, which is more efficient than running multiple queries to create and populate the table. This is especially true for small tables like this one, where the overhead of running multiple queries would outweigh any potential benefits of doing so.