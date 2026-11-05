-- =====================================================================
-- File:    09_functions.sql
-- Purpose: Stored functions for the HMS schema.
-- Author:  HMS Project
-- Date:    2025
-- Functions:
--   1. FN_CALCULATE_AGE(p_dob)               - returns age in years
--   2. FN_GET_DOCTOR_REVENUE(doctor, month, year) - returns PAID revenue
--   3. FN_COUNT_APPOINTMENTS(doctor, date)   - returns appt count on date
--   4. FN_GET_PATIENT_TOTAL_BILL(patient)    - returns total billed amount
--   5. FN_IS_DOCTOR_AVAILABLE(doctor, date, time) - returns 1/0 (SQL-callable)
-- =====================================================================

SET DEFINE OFF;

-- =====================================================================
-- 1. FN_CALCULATE_AGE
--    Returns the age in years given a date of birth.
--    Uses MONTHS_BETWEEN so a person born today has age 0.
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_calculate_age (
  p_dob IN DATE
) RETURN NUMBER
AS
BEGIN
  IF p_dob IS NULL THEN
    RETURN NULL;
  END IF;
  IF p_dob > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20101, 'Date of birth cannot be in the future.');
  END IF;
  RETURN FLOOR(MONTHS_BETWEEN(SYSDATE, p_dob) / 12);
END fn_calculate_age;
/

-- =====================================================================
-- 2. FN_GET_DOCTOR_REVENUE
--    Returns total PAID revenue attributable to a doctor in a given
--    month/year. Revenue = SUM(b.total_amount) for PAID bills linked
--    to the doctor's appointments.
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_get_doctor_revenue (
  p_doctor_id IN NUMBER,
  p_month     IN NUMBER,
  p_year      IN NUMBER
) RETURN NUMBER
AS
  v_total NUMBER := 0;
BEGIN
  IF p_month NOT BETWEEN 1 AND 12 THEN
    RAISE_APPLICATION_ERROR(-20110, 'p_month must be between 1 and 12.');
  END IF;

  SELECT NVL(SUM(b.total_amount), 0)
    INTO v_total
    FROM billing b
    JOIN appointments a ON a.appt_id = b.appt_id
   WHERE a.doctor_id      = p_doctor_id
     AND b.payment_status = 'PAID'
     AND b.bill_date >= TO_DATE(TO_CHAR(p_year,'FM0000') || '-' ||
                                TO_CHAR(p_month,'FM00')  || '-01', 'YYYY-MM-DD')
     AND b.bill_date <  ADD_MONTHS(TO_DATE(TO_CHAR(p_year,'FM0000') || '-' ||
                                TO_CHAR(p_month,'FM00')  || '-01', 'YYYY-MM-DD'), 1);
  RETURN v_total;
END fn_get_doctor_revenue;
/

-- =====================================================================
-- 3. FN_COUNT_APPOINTMENTS
--    Returns the number of appointments (any status) for a doctor on a
--    given date.
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_count_appointments (
  p_doctor_id IN NUMBER,
  p_date      IN DATE
) RETURN NUMBER
AS
  v_count NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_count
    FROM appointments
   WHERE doctor_id = p_doctor_id
     AND appt_date = TRUNC(p_date);
  RETURN v_count;
END fn_count_appointments;
/

-- =====================================================================
-- 4. FN_GET_PATIENT_TOTAL_BILL
--    Returns the SUM of total_amount for all bills for a patient
--    (any status). Use NVL on the caller side if you want 0 for new
--    patients (this function already returns 0 in that case).
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_get_patient_total_bill (
  p_patient_id IN NUMBER
) RETURN NUMBER
AS
  v_total NUMBER := 0;
BEGIN
  SELECT NVL(SUM(total_amount), 0)
    INTO v_total
    FROM billing
   WHERE patient_id = p_patient_id;
  RETURN v_total;
END fn_get_patient_total_bill;
/

-- =====================================================================
-- 5. FN_IS_DOCTOR_AVAILABLE
--    Returns 1 if the doctor is available at the requested date/time
--    (i.e. no SCHEDULED appointment exists at that slot and the doctor
--    is ACTIVE), else 0. Returning NUMBER (instead of BOOLEAN) means
--    the function is usable inside SQL statements.
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_is_doctor_available (
  p_doctor_id IN NUMBER,
  p_date      IN DATE,
  p_time      IN VARCHAR2
) RETURN NUMBER
AS
  v_count NUMBER := 0;
BEGIN
  -- Active check first.
  SELECT COUNT(*) INTO v_count
    FROM doctors
   WHERE doctor_id = p_doctor_id
     AND status    = 'ACTIVE';
  IF v_count = 0 THEN
    RETURN 0;
  END IF;

  -- Existing booking check.
  SELECT COUNT(*) INTO v_count
    FROM appointments
   WHERE doctor_id = p_doctor_id
     AND appt_date = TRUNC(p_date)
     AND appt_time = p_time
     AND status    = 'SCHEDULED';

  RETURN CASE WHEN v_count = 0 THEN 1 ELSE 0 END;
END fn_is_doctor_available;
/

PROMPT All HMS stored functions created successfully.
