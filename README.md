# Hospital Management System (HMS) — SQL & PL/SQL

A complete relational database project for a **Hospital Management System** built entirely with Oracle SQL and PL/SQL. The schema models patients, doctors, appointments, medical records, prescriptions, billing, staff and a full audit log, and demonstrates every major server-side database feature: tables, constraints, sequences, views, indexes, synonyms, stored procedures, functions, triggers, packages, cursors, bulk operations, exception handling and analytical queries.

---

## Tech stack

- **Oracle Database 19c+** (also runs on Oracle XE 18c/21c)
- **PL/SQL** for procedural logic
- **SQL\*Plus** as the execution client (`sqlplus` CLI)

No external application code is required — the project is 100% server-side.

---

## Features demonstrated

| Area | Where |
|------|-------|
| Tables & constraints (PK / FK / CHECK / UNIQUE / NOT NULL / ON DELETE CASCADE) | `sql/02_create_tables.sql` |
| Sequences (NOCACHE surrogate keys) | `sql/03_sequences.sql` |
| Realistic sample data | `sql/04_insert_sample_data.sql` |
| B-tree indexes on hot columns | `sql/05_indexes.sql` |
| 6 views (active doctors, today's appts, dept revenue, patient history, pending bills, doctor workload) | `sql/06_views.sql` |
| Synonyms for cross-schema access | `sql/07_synonyms.sql` |
| 6 stored procedures (book, cancel, complete, bill, pay, visit report) | `sql/08_procedures.sql` |
| 5 functions (age, doctor revenue, appt count, patient bill total, availability) | `sql/09_functions.sql` |
| 6 triggers (bill total, audit doctors/patients, appt status check, auto-bill on complete, registered_at) | `sql/10_triggers.sql` |
| 2 packages — `BILLING_PKG`, `APPOINTMENT_PKG` (spec + body) | `sql/11_packages.sql` |
| Explicit cursor, BULK COLLECT + FORALL, cursor FOR loop | `sql/12_cursors_bulk.sql` |
| Exception handling (NO_DATA_FOUND, DUP_VAL_ON_INDEX, user-defined, WHEN OTHERS) | `sql/13_exception_handling.sql` |
| 12 analytical queries (joins, subqueries, window functions, CTE, PIVOT) | `sql/14_analytics_queries.sql` |
| Clean teardown in reverse dependency order | `sql/15_drop_all.sql` |

---

## Schema / ERD

A full textual ER diagram is in [`docs/ERD.md`](docs/ERD.md), and a per-table explanation is in [`docs/SCHEMA_OVERVIEW.md`](docs/SCHEMA_OVERVIEW.md).

### Entities at a glance

```
DEPARTMENTS 1───* DOCTORS
DEPARTMENTS 1───* STAFF
DOCTORS    *───* PATIENTS  (via APPOINTMENTS)
PATIENTS   1───* APPOINTMENTS *───1 DOCTORS
PATIENTS   1───* MEDICAL_RECORDS *───1 DOCTORS
APPOINTMENTS 0..1 ─── MEDICAL_RECORDS
MEDICAL_RECORDS 1───* PRESCRIPTIONS
PATIENTS   1───* BILLING
APPOINTMENTS 0..1 ─── BILLING
(any audited table) ──> AUDIT_LOG
```

---

## Setup & running

### Option A — One-shot via `scripts/run_all.sh`

```bash
cd /home/z/my-project/projects/hospital-management-sql
./scripts/run_all.sh hms_user/your_password@//localhost:1521/XEPDB1
```

The script:
1. `cd`s into `sql/`
2. Runs every `.sql` file in numeric order (`01_…` through `15_…`)
3. Sets `WHENEVER SQLERROR EXIT SQL.SQLCODE` so the run aborts on the first error
4. Prefixes each file's output with a banner so you can see progress

### Option B — Manual via SQL\*Plus

```bash
sqlplus hms_user/your_password@//localhost:1521/XEPDB1 @sql/02_create_tables.sql
sqlplus hms_user/your_password@//localhost:1521/XEPDB1 @sql/03_sequences.sql
# ... and so on
```

### Option C — SQL Developer / DBeaver

Open each file in `sql/` in order and press `F5` (Run as Script).

> The `01_create_user.sql` script is **commented out by default** because most
> developers already have a schema. Uncomment it and run as `SYSDBA` if you want
> to create the `hms_user` schema from scratch.

---

## File-by-file description

| File | Purpose |
|------|---------|
| `01_create_user.sql` | (Optional) creates the `hms_user` schema with the right privileges. |
| `02_create_tables.sql` | All 9 tables with constraints. |
| `03_sequences.sql` | 9 sequences (`DEPT_SEQ`, `DOCTOR_SEQ`, …) starting at 1000, NOCACHE. |
| `04_insert_sample_data.sql` | 5 departments, 8 doctors, 12 patients, 20 appts, 15 records, 20 prescriptions, 15 bills, 6 staff. |
| `05_indexes.sql` | 8 indexes on frequently filtered/joined columns. |
| `06_views.sql` | 6 reporting views. |
| `07_synonyms.sql` | Public/private synonyms for cross-schema access. |
| `08_procedures.sql` | 6 stored procedures including one returning a `SYS_REFCURSOR`. |
| `09_functions.sql` | 5 scalar/table-callable functions. |
| `10_triggers.sql` | 6 triggers (audit, validation, auto-fill, auto-bill). |
| `11_packages.sql` | `BILLING_PKG` and `APPOINTMENT_PKG` (spec + body). |
| `12_cursors_bulk.sql` | Explicit cursor, BULK COLLECT + FORALL, cursor FOR loop. |
| `13_exception_handling.sql` | NO_DATA_FOUND, DUP_VAL_ON_INDEX, user-defined, WHEN OTHERS. |
| `14_analytics_queries.sql` | 12 analytical queries. |
| `15_drop_all.sql` | Drops every object in reverse dependency order. |

---

## Sample analytical queries (highlights)

A few representative queries from `sql/14_analytics_queries.sql`:

**Top 3 doctors by revenue (last 30 days)**
```sql
SELECT * FROM (
  SELECT d.first_name || ' ' || d.last_name AS doctor,
         SUM(b.total_amount)                AS revenue,
         RANK() OVER (ORDER BY SUM(b.total_amount) DESC) AS rnk
    FROM doctors d
    JOIN billing  b ON b.patient_id IN (SELECT patient_id FROM appointments a WHERE a.doctor_id = d.doctor_id)
   WHERE b.bill_date >= SYSDATE - 30
   GROUP BY d.doctor_id, d.first_name, d.last_name
) WHERE rnk <= 3;
```

**Patients who haven't visited in 6 months (using NOT EXISTS)**
```sql
SELECT p.patient_id, p.first_name, p.last_name
  FROM patients p
 WHERE NOT EXISTS (
         SELECT 1 FROM appointments a
          WHERE a.patient_id = p.patient_id
            AND a.appt_date  >= ADD_MONTHS(SYSDATE, -6));
```

**Department-wise monthly revenue trend (window function)**
```sql
SELECT dept_name, bill_month,
       revenue,
       SUM(revenue) OVER (PARTITION BY dept_name ORDER BY bill_month) AS running_total
  FROM ( … );
```

### Representative output (described)

- `V_DEPT_REVENUE` returns one row per department with the total amount billed — e.g. `Cardiology | 4250`, `Neurology | 3100`, `Orthopedics | 2750`.
- `FN_CALCULATE_AGE(DOB)` returns the patient's age in years as a NUMBER — e.g. `42`.
- `BILLING_PKG.GET_OUTSTANDING_TOTAL(1003)` returns the sum of `PENDING` bills for patient 1003 — e.g. `950`.
- `APPOINTMENT_PKG.GET_NEXT_AVAILABLE_SLOT(1001, SYSDATE)` returns the next free `TIMESTAMP` for the doctor on the given date.

(Actual values depend on `SYSDATE` at the time the sample data is loaded, because appointments are spread across the last 30 days.)

---

## Cleanup

To drop every object created by the project:

```bash
sqlplus hms_user/your_password@//localhost:1521/XEPDB1 @sql/15_drop_all.sql
```

---

## License

MIT © 2025 — see `LICENSE` field above. Free to use, modify and distribute with attribution.

> A `LICENSE` file is not bundled by default; the MIT text is hereby granted in this README.
