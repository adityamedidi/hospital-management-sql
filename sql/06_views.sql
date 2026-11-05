-- =====================================================================
-- File:    06_views.sql
-- Purpose: Create reporting views on top of the HMS schema.
-- Author:  HMS Project
-- Date:    2025
-- Notes:   Use CREATE OR REPLACE FORCE VIEW so the views can be created
--          even if underlying objects are added later.
-- =====================================================================

SET DEFINE OFF;

-- ---------------------------------------------------------------------
-- 1. V_ACTIVE_DOCTORS
--    Active doctors with their department name.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW v_active_doctors AS
  SELECT d.doctor_id,
         d.first_name,
         d.last_name,
         d.specialization,
         d.email,
         d.phone,
         dep.dept_name AS department
    FROM doctors d
    JOIN departments dep ON dep.dept_id = d.dept_id
   WHERE d.status = 'ACTIVE'
   WITH READ ONLY;

COMMENT ON TABLE v_active_doctors IS 'Active doctors joined with their department name.';

-- ---------------------------------------------------------------------
-- 2. V_TODAY_APPOINTMENTS
--    All appointments scheduled for today, with patient + doctor names.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW v_today_appointments AS
  SELECT a.appt_id,
         a.appt_time,
         p.first_name || ' ' || p.last_name AS patient_name,
         doc.first_name || ' ' || doc.last_name AS doctor_name,
         dep.dept_name                       AS department,
         a.status,
         a.reason
    FROM appointments a
    JOIN patients   p   ON p.patient_id  = a.patient_id
    JOIN doctors    doc ON doc.doctor_id = a.doctor_id
    JOIN departments dep ON dep.dept_id  = doc.dept_id
   WHERE a.appt_date = TRUNC(SYSDATE)
   ORDER BY a.appt_time
   WITH READ ONLY;

COMMENT ON TABLE v_today_appointments IS 'Today''s appointments with patient + doctor names.';

-- ---------------------------------------------------------------------
-- 3. V_DEPT_REVENUE
--    Total collected revenue grouped by department.
--    Revenue = SUM(total_amount) for PAID bills.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW v_dept_revenue AS
  SELECT dep.dept_id,
         dep.dept_name,
         NVL(SUM(b.total_amount), 0) AS total_revenue,
         COUNT(b.bill_id)            AS bill_count
    FROM departments dep
    LEFT JOIN doctors      d   ON d.dept_id   = dep.dept_id
    LEFT JOIN appointments a   ON a.doctor_id = d.doctor_id
    LEFT JOIN billing      b   ON b.appt_id   = a.appt_id
                              AND b.payment_status = 'PAID'
   GROUP BY dep.dept_id, dep.dept_name
   WITH READ ONLY;

COMMENT ON TABLE v_dept_revenue IS 'Total revenue grouped by department (PAID bills only).';

-- ---------------------------------------------------------------------
-- 4. V_PATIENT_HISTORY
--    Patient name + appointment count + total amount billed.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW v_patient_history AS
  SELECT p.patient_id,
         p.first_name || ' ' || p.last_name AS patient_name,
         COUNT(DISTINCT a.appt_id)          AS appointment_count,
         NVL(SUM(b.total_amount), 0)        AS total_billed
    FROM patients p
    LEFT JOIN appointments a ON a.patient_id = p.patient_id
    LEFT JOIN billing      b ON b.patient_id = p.patient_id
   GROUP BY p.patient_id, p.first_name, p.last_name
   WITH READ ONLY;

COMMENT ON TABLE v_patient_history IS 'Per-patient appointment count and total billed.';

-- ---------------------------------------------------------------------
-- 5. V_PENDING_BILLS
--    Bills with PENDING status and the patient contact info.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW v_pending_bills AS
  SELECT b.bill_id,
         b.bill_date,
         b.total_amount,
         p.patient_id,
         p.first_name || ' ' || p.last_name AS patient_name,
         p.phone,
         p.email
    FROM billing b
    JOIN patients p ON p.patient_id = b.patient_id
   WHERE b.payment_status = 'PENDING'
   ORDER BY b.bill_date
   WITH READ ONLY;

COMMENT ON TABLE v_pending_bills IS 'PENDING bills with patient contact info.';

-- ---------------------------------------------------------------------
-- 6. V_DOCTOR_WORKLOAD
--    Each doctor + their appointment count for the current month.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW v_doctor_workload AS
  SELECT d.doctor_id,
         d.first_name || ' ' || d.last_name AS doctor_name,
         d.specialization,
         dep.dept_name                       AS department,
         COUNT(a.appt_id)                    AS appointments_this_month
    FROM doctors d
    JOIN departments dep ON dep.dept_id = d.dept_id
    LEFT JOIN appointments a
           ON a.doctor_id = d.doctor_id
          AND a.appt_date >= TRUNC(SYSDATE, 'MM')
          AND a.appt_date <  ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1)
   GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization, dep.dept_name
   WITH READ ONLY;

COMMENT ON TABLE v_doctor_workload IS 'Per-doctor appointment count for the current month.';

PROMPT All HMS views created successfully.
