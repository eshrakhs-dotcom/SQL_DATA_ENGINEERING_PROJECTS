# SQL Data Engineering EDA Project

![Exploratory data analysis of the Data Engineer job market using SQL, DuckDB, and a star-schema data warehouse](../Images/1_1_Project1_EDA.png)



# Executive Summary

This project analyzes thousands of Data Engineer job postings to answer three key business questions:

- Which skills are most in demand?
- Which skills command the highest salaries?
- Which skills provide the best balance between demand and compensation?

Using SQL across a relational data warehouse, I built analytical queries that combine multiple tables, aggregations, and statistical functions to generate actionable insights into today's data engineering job market.

## If You Only Have a Minute

Review the three core analyses in this project:

1. **[01_top_demanded_skills.sql](./01_top_demanded_skills.sql)** – Demand analysis using multi-table joins to identify the most requested skills for remote Data Engineer roles.

2. **[02_top_paying_skills.sql](./02_top_paying_skills.sql)** – Salary analysis using aggregations to determine which technical skills command the highest median compensation.

3. **[03_optimal_skills.sql](./03_optimal_skills.sql)** – Combines salary and market demand using a logarithmic scoring model to identify the most valuable skills to learn.


### Project Scope

- Built 3 analytical SQL queries to answer business questions
- Performed multi-table joins across a star-schema data warehouse
- Applied aggregations, filtering, sorting, and analytical functions
- Identified the most in-demand, highest-paying, and most valuable technical skills

If you only have a minute, review these SQL files:

- **01_top_demanded_skills.sql** – Demand analysis using multi-table joins
- **02_top_paying_skills.sql** – Salary analysis using aggregations
- **03_optimal_skills.sql** – Combined salary and demand optimization

---

# Business Problem

The data engineering job market is constantly evolving, making it difficult to determine which technical skills are worth learning.

This project answers three practical business questions:

- 🎯 Which skills are most in demand for Data Engineers?
- 💰 Which skills command the highest salaries?
- ⚖️ Which skills provide the best balance between salary and demand?

---

# Data Warehouse

This project queries a star-schema data warehouse consisting of one fact table, two dimension tables, and a bridge table.

![Data Warehouse Schema](../Images/1_2_Data_Warehouse.png)

### Database Structure

**Fact Table**

- `job_postings_fact`
  - Stores job posting information such as title, salary, location, posting date, and company.
**Dimension Tables**

- `company_dim`
  - Company information.

- `skills_dim`
  - Technical skills and skill categories.

**Bridge Table**

- `skills_job_dim`
  - Resolves the many-to-many relationship between job postings and required skills.

---

## 🧰 Tech Stack

- 🐤 **Query Engine:** DuckDB for fast OLAP-style analytical queries
- 🧮 **Language:** SQL (ANSI-style with analytical functions)
- 📊 **Data Model:** Star schema with fact, dimension, and bridge tables
- 🛠️ **Development:** VS Code for SQL development and DuckDB CLI via Terminal
- 📦 **Version Control:** Git & GitHub for source control and version management

---

# Repository Structure

```text
1_EDA_Project/
│
├── 01_top_demanded_skills.sql
├── 02_top_paying_skills.sql
├── 03_optimal_skills.sql
├── README.md
└── Images/
```
---

# Analysis Overview

## Query Structure

- **[Top Demanded Skills](./01_top_demanded_skills.sql)** – Identifies the 10 most in-demand skills for remote Data Engineer positions

- **[Top Paying Skills](./02_top_paying_skills.sql)** – Analyzes the 25 highest-paying skills with salary and demand metrics

- **[Optimal Skills](./03_optimal_skills.sql)** – Calculates an optimal score using the natural log of demand combined with median salary to identify the most valuable skills to learn

## Key Insights

- 🧠 Core languages: SQL and Python each appear in ~29,000 job postings, making them the most demanded skills
- ☁️ Cloud platforms: AWS and Azure are critical for modern data engineering roles-
- 🧱 Infra & tooling: Kubernetes, Docker, and Terraform are associated with premium salaries
- 🔥 Big data tools: Apache Spark shows strong demand with competitive compensation

## 💻 SQL Skills Demonstrated

### Query Design & Optimization

- **Complex Joins:** Multi-table `INNER JOIN` operations across `job_postings_fact`, `skills_job_dim`, and `skills_dim`
- **Aggregations:** `COUNT()`, `MEDIAN()`, and `ROUND()` for statistical analysis
- **Filtering:** `WHERE` clauses with multiple conditions (`job_title_short`, `job_work_from_home`, `salary_year_avg IS NOT NULL`)
- **Sorting & Limiting:** `ORDER BY` with `DESC` and `LIMIT` for Top-N analysis

### Data Analysis Techniques

- **Grouping:** `GROUP BY` to aggregate results by skill
- **Mathematical Functions:** `LN()` to normalize demand using the natural logarithm
- **Calculated Metrics:** Derived an **optimal score** by combining log-transformed demand with median salary
- **Aggregate Filtering:** `HAVING` clause to retain only skills appearing in more than 100 job postings
- **NULL Handling:** Filtered incomplete records using `salary_year_avg IS NOT NULL`

