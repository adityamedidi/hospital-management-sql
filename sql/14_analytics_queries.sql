-- =====================================================================
-- File:    14_analytics_queries.sql
-- Purpose: 12 analytical SQL queries demonstrating joins, subqueries,
--          window functions, CTE, PIVOT, EXISTS, and common reporting
--          needs (top doctors, inactive patients, revenue trends).
-- Author:  HMS Project
-- Date:    2025
-- Notes:   Each query is a standalone SELECT. Run the whole file with
--          SET PAGESIZE 50 SET LINESIZE 200 for readable output.
--          None of these queries modify data.
-- =====================================================================

SET PAGESIZE 50
SET LINESIZE 200
SET DEFINE OFF;

PROMPT ============================================================
PROMPT  Query 1: INNER JOIN - doctors with their department name
PROMPT ============================================================
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       d.specialization,
       dep.dept_name AS department,
       d.status
  FROM doctors d
  JOIN departments dep ON dep.dept_id = d.dept_id
 ORDER BY dep.dept_name, doctor_name;

PROMPT
PROMPT ============================================================
PROMPT  Query 2: LEFT JOIN - all patients and their appointment counts
PROMPT  (patients with no appointments still appear with 0)
PROMPT ============================================================
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       COUNT(a.appt_id)                   AS appointment_count
  FROM patients p
  LEFT JOIN appointments a ON a.patient_id = p.patient_id
 GROUP BY p.patient_id, p.first_name, p.last_name
 ORDER BY appointment_count DESC, patient_name;

PROMPT
PROMPT ============================================================
PROMPT  Query 3: Multi-table JOIN - appointment detail with patient,
PROMPT  doctor, department and bill info
PROMPT ============================================================
SELECT a.appt_id,
       TO_CHAR(a.appt_date,'YYYY-MM-DD') AS appt_date,
       a.appt_time,
       p.first_name || ' ' || p.last_name  AS patient_name,
       doc.first_name || ' ' || doc.last_name AS doctor_name,
       dep.dept_name                       AS department,
       a.status,
       b.total_amount,
       b.payment_status
  FROM appointments a
  JOIN patients      p   ON p.patient_id  = a.patient_id
  JOIN doctors       doc ON doc.doctor_id = a.doctor_id
  JOIN departments   dep ON dep.dept_id   = doc.dept_id
  LEFT JOIN billing  b   ON b.appt_id     = a.appt_id
 ORDER BY a.appt_date DESC, a.appt_time;

PROMPT
PROMPT ============================================================
PROMPT  Query 4: GROUP BY + HAVING - departments with 3+ appointments
PROMPT ============================================================
SELECT dep.dept_name,
       COUNT(a.appt_id) AS appt_count
  FROM departments dep
  JOIN doctors      d   ON d.dept_id   = dep.dept_id
  JOIN appointments a   ON a.doctor_id = d.doctor_id
 GROUP BY dep.dept_name
HAVING COUNT(a.appt_id) >= 3
 ORDER BY appt_count DESC;

PROMPT
PROMPT ============================================================
PROMPT  Query 5: Non-correlated subquery - patients whose total billed
PROMPT  exceeds the overall average total billed per patient
PROMPT ============================================================
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       NVL(SUM(b.total_amount), 0)        AS total_billed
  FROM patients p
  LEFT JOIN billing b ON b.patient_id = p.patient_id
 GROUP BY p.patient_id, p.first_name, p.last_name
HAVING NVL(SUM(b.total_amount), 0) > (
         SELECT AVG(patient_total) FROM (
           SELECT NVL(SUM(b2.total_amount), 0) AS patient_total
             FROM billing b2
            GROUP BY b2.patient_id
         )
       )
 ORDER BY total_billed DESC;

PROMPT
PROMPT ============================================================
PROMPT  Query 6: Correlated subquery - doctors whose salary is greater
PROMPT  than the average salary of their own department
PROMPT ============================================================
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       dep.dept_name AS department,
       d.salary
  FROM doctors d
  JOIN departments dep ON dep.dept_id = d.dept_id
 WHERE d.salary > (
         SELECT AVG(d2.salary)
           FROM doctors d2
          WHERE d2.dept_id = d.dept_id
       )
 ORDER BY d.salary DESC;

PROMPT
PROMPT ============================================================
PROMPT  Query 7: ROW_NUMBER() - rank appointments per patient by date
PROMPT  (most recent first)
PROMPT ============================================================
SELECT appt_id,
       patient_id,
       appt_date,
       status,
       ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY appt_date DESC) AS visit_rank
  FROM appointments
 ORDER BY patient_id, visit_rank;

PROMPT
PROMPT ============================================================
PROMPT  Query 8: RANK() - top 3 doctors by PAID revenue (last 30 days)
PROMPT ============================================================
SELECT * FROM (
  SELECT d.doctor_id,
         d.first_name || ' ' || d.last_name AS doctor_name,
         NVL(SUM(b.total_amount), 0)        AS revenue,
         RANK() OVER (ORDER BY NVL(SUM(b.total_amount), 0) DESC) AS rnk
    FROM doctors d
    JOIN appointments a ON a.doctor_id = d.doctor_id
    JOIN billing      b ON b.appt_id   = a.appt_id
                       AND b.payment_status = 'PAID'
                       AND b.bill_date >= SYSDATE - 30
   GROUP BY d.doctor_id, d.first_name, d.last_name
) WHERE rnk <= 3
 ORDER BY rnk;

PROMPT
PROMPT ============================================================
PROMPT  Query 9: SUM() OVER - running total of paid bills by patient
PROMPT ============================================================
SELECT b.bill_id,
       b.patient_id,
       b.bill_date,
       b.total_amount,
       SUM(b.total_amount) OVER (PARTITION BY b.patient_id
                                 ORDER BY b.bill_date
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
         AS running_total
  FROM billing b
 WHERE b.payment_status = 'PAID'
 ORDER BY b.patient_id, b.bill_date;

PROMPT
PROMPT ============================================================
PROMPT  Query 10: LAG / LEAD - prior and next appointment per patient
PROMPT ============================================================
SELECT patient_id,
       appt_id,
       appt_date,
       LAG(appt_date)  OVER (PARTITION BY patient_id ORDER BY appt_date) AS prev_appt_date,
       LEAD(appt_date) OVER (PARTITION BY patient_id ORDER BY appt_date) AS next_appt_date,
       appt_date - LAG(appt_date) OVER (PARTITION BY patient_id ORDER BY appt_date) AS days_since_prev
  FROM appointments
 ORDER BY patient_id, appt_date;

PROMPT
PROMPT ============================================================
PROMPT  Query 11: PIVOT - appointment count by department x status
PROMPT ============================================================
SELECT * FROM (
  SELECT dep.dept_name, a.status
    FROM appointments a
    JOIN doctors      d   ON d.doctor_id = a.doctor_id
    JOIN departments  dep ON dep.dept_id = d.dept_id
)
PIVOT (
  COUNT(*)
  FOR status IN ('SCHEDULED' AS scheduled,
                 'COMPLETED' AS completed,
                 'CANCELLED' AS cancelled)
)
ORDER BY dept_name;

PROMPT
PROMPT ============================================================
PROMPT  Query 12: NOT EXISTS - patients who haven't visited in 6 months
PROMPT ============================================================
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       p.registered_at
  FROM patients p
 WHERE NOT EXISTS (
         SELECT 1 FROM appointments a
          WHERE a.patient_id = p.patient_id
            AND a.appt_date  >= ADD_MONTHS(SYSDATE, -6)
       )
 ORDER BY patient_name;

PROMPT
PROMPT ============================================================
PROMPT  Query 13: CTE (WITH) - department-wise monthly revenue trend
PROMPT  with running total per department using SUM OVER
PROMPT ============================================================
WITH monthly_dept AS (
  SELECT dep.dept_name,
         TO_CHAR(b.bill_date, 'YYYY-MM') AS bill_month,
         SUM(b.total_amount)             AS revenue
    FROM billing b
    JOIN appointments a ON a.appt_id = b.appt_id
    JOIN doctors      d ON d.doctor_id = a.doctor_id
    JOIN departments  dep ON dep.dept_id = d.dept_id
   WHERE b.payment_status = 'PAID'
   GROUP BY dep.dept_name, TO_CHAR(b.bill_date, 'YYYY-MM')
)
SELECT dept_name,
       bill_month,
       revenue,
       SUM(revenue) OVER (PARTITION BY dept_name
                          ORDER BY bill_month
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
         AS running_total
  FROM monthly_dept
 ORDER BY dept_name, bill_month;

PROMPT
PROMPT ============================================================
PROMPT  Query 14: EXISTS - doctors who have at least one PAID bill
PROMPT ============================================================
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       d.specialization
  FROM doctors d
 WHERE EXISTS (
         SELECT 1
           FROM appointments a
           JOIN billing      b ON b.appt_id = a.appt_id
          WHERE a.doctor_id = d.doctor_id
            AND b.payment_status = 'PAID'
       )
 ORDER BY doctor_name;

PROMPT
PROMPT ============================================================
PROMPT  Query 15: Comprehensive CTE - per-patient KPI report
PROMPT  (appt count, paid total, pending total, last visit date)
PROMPT ============================================================
WITH appt_stats AS (
  SELECT patient_id,
         COUNT(*)                  AS appt_count,
         MAX(appt_date)            AS last_visit
    FROM appointments
   GROUP BY patient_id
),
paid_stats AS (
  SELECT patient_id,
         SUM(CASE WHEN payment_status = 'PAID'    THEN total_amount ELSE 0 END) AS paid_total,
         SUM(CASE WHEN payment_status = 'PENDING' THEN total_amount ELSE 0 END) AS pending_total
    FROM billing
   GROUP BY patient_id
)
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       NVL(a.appt_count, 0) AS appointments,
       NVL(a.last_visit, TO_DATE('1900-01-01','YYYY-MM-DD')) AS last_visit,
       NVL(ps.paid_total, 0)    AS paid_total,
       NVL(ps.pending_total, 0) AS pending_total
  FROM patients p
  LEFT JOIN appt_stats  a  ON a.patient_id  = p.patient_id
  LEFT JOIN paid_stats  ps ON ps.patient_id = p.patient_id
 ORDER BY paid_total DESC NULLS LAST, patient_name;

PROMPT
PROMPT ============================================================
PROMPT  Done.
PROMPT ============================================================
