# 🏗️ Data Warehouse & Mart Build: Production ETL Pipeline

An end-to-end data engineering pipeline that transforms raw CSV files from Google Cloud Storage into a normalized star schema data warehouse, then builds analytical data marts.

![Data Pipeline Architecture](../Images/1_2_Project2_Data_Pipeline.png)

## 🧾 Executive Summary

✅ Pipeline scope: Built a complete ETL pipeline from raw CSVs to star schema warehouse to analytical marts
✅ Data modeling: Designed a star schema with fact tables, dimensions, and bridge tables for many-to-many relationships
✅ ETL development: Implemented extract, transform, load processes with idempotent operations and data quality checks
✅ Mart architecture: Created specialized data marts (flat, skills, priority) with additive measures and incremental update patterns

---

## 🧩 Problem & Context

Raw job posting data arrives as flat CSV files in Google Cloud Storage—not structured for analytical queries. Analysts need to answer:

Which skills are most in-demand over time?
What are hiring trends by company and location?
How do salary patterns vary by role and skill?
Challenge: Data teams need a single source of truth system—a data warehouse—to enable consistent, reliable analysis across the organization. Additionally, specialized data marts are required to optimize resources by pre-aggregating data for specific business use cases, reducing query complexity and improving performance for common analytical patterns.

Solution: End-to-end ETL pipeline that extracts CSVs from cloud storage, normalizes them into a star schema warehouse (separating facts from dimensions), and creates specialized data marts optimized for specific use cases (flat queries, skill demand analysis, priority role tracking).

---

## 🧰 Tech Stack

## 🧰 Tech Stack

- 🦆 **Database:** DuckDB (file-based OLAP database with GCS integration via httpfs)
- 🧱 **Language:** SQL (DDL for schema design, DML for data loading and transformation)
- 📊 **Data Model:** Star schema (fact + dimension + bridge tables)
- 🛠️ **Development:** VS Code for SQL editing + Terminal for DuckDB CLI execution
- 🔧 **Automation:** Master SQL script for pipeline orchestration
- 📦 **Version Control:** Git/GitHub for versioned pipeline scripts
- ☁️ **Storage:** Google Cloud Storage for source CSV files

---

## 📂 Repository Structure

```text
2_DW_Mart_Build/
├── 01_create_tables_dw.sql      # Star schema DDL
├── 02_load_schema_dw.sql        # GCS data extraction & loading
├── 03_create_flat_mart.sql      # Denormalized flat mart
├── 04_create_skills_mart.sql    # Skills demand mart
├── 05_create_priority_mart.sql  # Priority roles mart
├── 06_update_priority_mart.sql  # Priority mart incremental update (MERGE)
├── 07_create_company_mart.sql   # Company hiring mart (Optional)
├── build_dw_marts.sql           # Master SQL build script
└── README.md                    # Project documentation
```

---

## 🏗️ Pipeline Architecture

![Data Pipeline Architecture](../Images/1_2_Project2_Data_Pipeline.png)

The pipeline transforms job posting CSVs from Google Cloud Storage into a normalized star schema data warehouse, then builds specialized analytical data marts. BI tools (Excel, Power BI, Tableau, Python) consume from both the warehouse and marts.

---

## 🏢 Data Warehouse

The data warehouse implements a star schema with company_dim, skills_dim, job_postings_fact, and skills_job_dim tables.

![Data Warehouse Schema](../Images/1_2_Data_Warehouse.png)


**SQL Files**
- **01_create_tables_dw.sql** – Defines the star schema with four core warehouse tables.
- **02_load_schema_dw.sql** – Extracts raw CSV files from Google Cloud Storage and loads them into the warehouse tables.

**Purpose**
- Build a centralized, normalized data warehouse that provides a consistent foundation for analytical reporting and downstream data marts.

**Grain**
- **One row per job posting** in the `job_postings_fact` table

---

## 📊 Flat Mart

Denormalized table with all dimensions for ad-hoc queries.

![Flat Mart Schema](../Images/1_2_Flat_Mart.png)

The flat mart provides a **fully denormalized** view by joining the fact table with all related dimensions into a single table. It is designed for fast, ad-hoc analytical queries without requiring complex joins.

**SQL File**
- **03_create_flat_mart.sql** – Builds a denormalized table by joining the fact table with all related dimensions.

**Purpose**
- Provide a denormalized table optimized for fast ad-hoc analytical queries.

**Grain**
- **One row per job posting** with all related dimensions joined.

---

## 📈 Skills Mart

![Skills Mart Schema](../Images/1_2_Skills_Mart.png)

The Skills Mart aggregates job posting data into a monthly time series, making it easy to analyze skill demand trends over time using additive business metrics.

**SQL File**
- **04_create_skills_mart.sql** – Builds the time-series skills demand mart.

**Purpose**
- Analyze skill demand trends over time using monthly aggregated metrics.

**Grain**
- **skill_id + month_start_date + job_title_short**

**Key Features**
- All business measures are **additive** (counts and sums), allowing safe re-aggregation across different reporting levels.

---

## 🚩 Priority Mart

![Priority Mart Schema](../Images/1_2_Priority_Mart.png)

The Priority Mart tracks business-defined priority roles while supporting production-style incremental updates through SQL MERGE operations.

**SQL Files**
- **05_create_priority_mart.sql** – Builds the initial priority roles table and job snapshot.
- **06_update_priority_mart.sql** – Performs incremental updates using the MERGE (upsert) pattern.

**Purpose**
- Track priority roles and maintain an up-to-date snapshot of priority job postings.

**Grain**
- **One row per job posting** with an assigned business priority level.

**Key Features**
- Uses **MERGE** operations for production-style incremental updates, supporting **INSERT**, **UPDATE**, and **DELETE** operations within a single statement.

---

## 🏢 Company Mart (Optional)

![Company Mart Schema](../Images/1_2_Company_Mart.png)

The Company Mart aggregates hiring activity by company, role, location, and month, enabling company-level hiring trend analysis.

**SQL File**
- **07_create_company_mart.sql** – Builds the company hiring trends mart.

**Purpose**
- Analyze hiring trends across companies, job roles, locations, and time.

**Grain**
- **company_id + job_title_short_id + location_id + month_start_date**

**Key Features**
- Uses **bridge tables** to model many-to-many relationships between companies, locations, and job title hierarchies.

> **Note:** This mart is optional and can be skipped if not required.

---

# 💻 Data Engineering Skills Demonstrated

## 🔄 ETL Pipeline Development

- **Extract:** Direct CSV loading from Google Cloud Storage using DuckDB's **httpfs** extension.
- **Transform:** Data normalization, type conversion (`CAST`, `DATE_TRUNC`), and data quality filtering.
- **Load:** Idempotent table creation using `DROP TABLE IF EXISTS` patterns.
- **Incremental Updates:** Production-ready **MERGE** operations supporting INSERT, UPDATE, and DELETE patterns.
- **Orchestration:** Master SQL build script (`build_dw_marts.sql`) automates execution of the complete ETL pipeline.

---

## 🏗️ Dimensional Modeling

- **Star Schema Design:** Central fact table (`job_postings_fact`) supported by dimension tables (`company_dim`, `skills_dim`).
- **Bridge Tables:** Resolve many-to-many relationships (`skills_job_dim`, `bridge_company_location`, `bridge_job_title`).
- **Grain Definition:** Proper fact table granularity for each mart (skill + month, company + title + location + month).
- **Additive Measures:** Counts and sums that can be safely re-aggregated across reporting levels.
- **Surrogate Keys:** Sequential ID generation using CTEs with self-joins (Company Mart).

---

## 🧠 SQL Advanced Techniques

- **DDL Operations:** `CREATE TABLE`, `DROP TABLE`, and `CREATE SCHEMA` for schema management.
- **DML Operations:** `INSERT INTO ... SELECT` with explicit column mapping from source tables.
- **MERGE Operations:** Incremental upsert logic using `MERGE INTO`, `WHEN MATCHED`, `WHEN NOT MATCHED`, and `WHEN NOT MATCHED BY SOURCE`.
- **CTEs:** Common Table Expressions for complex transformations and reusable logic.
- **Date Functions:** `DATE_TRUNC()` and `EXTRACT()` for temporal dimension creation.
- **String Functions:** `STRING_AGG()` for concatenation and `REPLACE()` for data cleansing.
- **Boolean Logic:** `CASE WHEN` expressions for converting Boolean flags into additive metrics.

---

## ✅ Data Quality & Production Practices

- **Idempotency:** All SQL scripts can be safely re-executed without unintended side effects.
- **Data Validation:** Verification queries validate each pipeline stage to ensure data integrity.
- **Type Safety:** Strong data typing using `VARCHAR`, `INTEGER`, `DOUBLE`, `BOOLEAN`, and `TIMESTAMP`.
- **Schema Organization:** Logical separation of analytical marts into `flat_mart`, `skills_mart`, `priority_mart`, and `company_mart` schemas.
- **Error Handling:** Structured script execution with progress messages and validation checkpoints for easier debugging.

## 🎯 Key Takeaways

- Built an end-to-end ETL pipeline that transforms raw CSV files from Google Cloud Storage into a normalized star schema data warehouse and multiple analytical data marts.
- Applied dimensional modeling principles by designing fact tables, dimension tables, and bridge tables to support scalable analytical workloads.
- Developed idempotent SQL pipelines that can be safely re-executed using `DROP ... IF EXISTS`, `CREATE`, and validation queries.
- Implemented production-style incremental data loading using SQL `MERGE` statements to perform INSERT, UPDATE, and DELETE operations efficiently.
- Created purpose-built analytical marts optimized for different business use cases, including ad-hoc reporting, skills demand analysis, priority role tracking, and company hiring trends.
- Used Common Table Expressions (CTEs), aggregate functions, date transformations, and Boolean flag conversions to build reusable and maintainable SQL transformations.
- Organized the project into modular SQL scripts orchestrated through a single build script, improving maintainability and reproducibility.
- Validated each pipeline stage with record-count checks and sample outputs to ensure data quality throughout the ETL process.