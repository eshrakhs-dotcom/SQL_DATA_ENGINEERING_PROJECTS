# SQL Data Engineering Projects

A collection of SQL projects built to showcase my data engineering and analytics skills using real-world datasets, DuckDB, and SQL.

These projects focus on solving practical business problems through data modeling, analytical SQL, and exploratory data analysis.

> Click a project below to view the full case study, SQL queries, and business insights.

---

# Projects

## 📊 [1. Exploratory Data Analysis (EDA)](./1_EDA_Project)

![Project 1 Overview](./Images/1_1_Project1_EDA.png)

> **SQL-driven analysis of the Data Engineer job market using a star-schema data warehouse.**

### Skills Demonstrated

- Multi-table SQL JOINs
- Data aggregation & statistical analysis
- Business-driven SQL querying
- Data warehouse exploration
- Exploratory Data Analysis (EDA)
- Salary and demand analysis
- Query optimization
- Analytical thinking

### Tools

- SQL
- DuckDB
- VS Code
- Git
- GitHub

---

###  🏗️ Production ETL Pipeline: Data Warehouse & Data Marts

![Data Pipeline Architecture](Images/1_2_Project2_Data_Pipeline.png)

End-to-end data engineering ETL pipeline transforming raw CSV files from Google Cloud Storage into a normalized star schema data warehouse and specialized analytical data marts.

**Skills:** Dimensional modeling, ETL pipeline development, star schema design, data mart architecture, SQL transformations, production ETL practices, incremental loading (MERGE), DuckDB, Google Cloud Storage, Git/GitHub

**Highlights:**
- Built a normalized star schema data warehouse with fact, dimension, and bridge tables.
- Developed multiple analytical data marts (Flat, Skills, Priority, and Company) for different business use cases.
- Implemented production-style incremental updates using SQL `MERGE` for INSERT, UPDATE, and DELETE operations.
- Orchestrated the complete pipeline through a single master SQL build script with validation checkpoints.
- Applied idempotent ETL design so the pipeline can be safely re-executed without side effects.