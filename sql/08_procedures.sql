-- =====================================================================
-- File:    08_procedures.sql
-- Purpose: Stored procedures for the HMS schema.
-- Author:  HMS Project
-- Date:    2025
-- Procedures:
--   1. BOOK_APPOINTMENT        - schedule an appointment (no double-booking)
--   2. CANCEL_APPOINTMENT      - mark an appointment CANCELLED
--   3. COMPLETE_APPOINTMENT    - mark COMPLETED + create medical record
--   4. GENERATE_BILL           - create a bill for a patient/appointment
--   5. PROCESS_PAYMENT         - mark a bill PAID + set paid_date
--   6. PATIENT_VISIT_REPORT    - returns a SYS_REFCURSOR of visit history
-- =====================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

-- =====================================================================
-- 1. BOOK_APPOINTMENT
--    Inserts a new appointment after validating:
--      - patient exists
--      - doctor exists and is ACTIVE
--      - the doctor has no existing SCHEDULED appointment at that slot
--    The DB-level UNIQUE(doctor_id, appt_date, appt_time) is the final
--    safety net; this procedure gives a friendly error before that.
-- =====================================================================
CREATE OR REPLACE PROCEDURE book_appointment (
  p_patient_id IN NUMBER,
  p_doctor_id  IN NUMBER,
  p_appt_date  IN DATE,
  p_appt_time  IN VARCHAR2,
  p_reason     IN VARCHAR2 DEFAULT NULL
) AS
  v_count         NUMBER;
  v_doctor_name   VARCHAR2(120);
  v_doctor_status VARCHAR2(10);
  v_appt_id       NUMBER;
  e_double_book   EXCEPTION;
  e_doc_inactive  EXCEPTION;
BEGIN
  -- Verify patient exists (COUNT(*) returns 0, never raises NO_DATA_FOUND).
  SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = p_patient_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001,
      'Patient ' || p_patient_id || ' does not exist.');
  END IF;

  -- Verify doctor exists; capture name and status.
  -- If no row matches, SELECT...INTO raises NO_DATA_FOUND (handled below).
  SELECT first_name || ' ' || last_name, status
    INTO v_doctor_name, v_doctor_status
    FROM doctors
   WHERE doctor_id = p_doctor_id;
  IF v_doctor_status != 'ACTIVE' THEN
    RAISE e_doc_inactive;
  END IF;

  -- No double-booking for the same doctor+date+time (SCHEDULED rows only).
  SELECT COUNT(*) INTO v_count
    FROM appointments
   WHERE doctor_id = p_doctor_id
     AND appt_date = p_appt_date
     AND appt_time = p_appt_time
     AND status    = 'SCHEDULED';
  IF v_count > 0 THEN
    RAISE e_double_book;
  END IF;

  -- All checks passed - insert.
  INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
       VALUES (appt_seq.NEXTVAL, p_patient_id, p_doctor_id, p_appt_date, p_appt_time, 'SCHEDULED', p_reason)
       RETURNING appt_id INTO v_appt_id;

  DBMS_OUTPUT.PUT_LINE('Appointment ' || v_appt_id || ' booked for patient ' || p_patient_id ||
                       ' with Dr. ' || v_doctor_name || ' on ' || TO_CHAR(p_appt_date,'YYYY-MM-DD') ||
                       ' at ' || p_appt_time || '.');
  COMMIT;

EXCEPTION
  WHEN e_double_book THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20010,
      'Doctor ' || p_doctor_id || ' is already booked on ' ||
      TO_CHAR(p_appt_date,'YYYY-MM-DD') || ' at ' || p_appt_time || '.');
  WHEN e_doc_inactive THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20011,
      'Doctor ' || p_doctor_id || ' is not ACTIVE; cannot book.');
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20012,
      'Doctor ' || p_doctor_id || ' does not exist.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END book_appointment;
/

-- =====================================================================
-- 2. CANCEL_APPOINTMENT
--    Marks an existing appointment as CANCELLED. Only SCHEDULED rows
--    can be cancelled (you cannot cancel a COMPLETED visit).
-- =====================================================================
CREATE OR REPLACE PROCEDURE cancel_appointment (
  p_appt_id IN NUMBER
) AS
  v_current_status appointments.status%TYPE;
BEGIN
  -- Lock the row and read the current status.
  SELECT status INTO v_current_status
    FROM appointments
   WHERE appt_id = p_appt_id
     FOR UPDATE;

  IF v_current_status = 'COMPLETED' THEN
    RAISE_APPLICATION_ERROR(-20020,
      'Cannot cancel appointment ' || p_appt_id || ' because it is already COMPLETED.');
  ELSIF v_current_status = 'CANCELLED' THEN
    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appt_id || ' is already CANCELLED; nothing to do.');
  ELSE
    UPDATE appointments
       SET status = 'CANCELLED'
     WHERE appt_id = p_appt_id;
    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appt_id || ' cancelled.');
  END IF;
  COMMIT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20021,
      'Appointment ' || p_appt_id || ' not found.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END cancel_appointment;
/

-- =====================================================================
-- 3. COMPLETE_APPOINTMENT
--    Marks an appointment COMPLETED and creates a medical record plus
--    a single prescription line from the supplied text.
--    The AFTER-UPDATE trigger TRG_AUTO_BILL_ON_COMPLETE will also
--    auto-create a draft PENDING bill.
-- =====================================================================
CREATE OR REPLACE PROCEDURE complete_appointment (
  p_appt_id           IN NUMBER,
  p_diagnosis         IN VARCHAR2,
  p_prescription_text IN VARCHAR2 DEFAULT NULL
) AS
  v_appt     appointments%ROWTYPE;
  v_record_id medical_records.record_id%TYPE;
BEGIN
  SELECT * INTO v_appt
    FROM appointments
   WHERE appt_id = p_appt_id
     FOR UPDATE;

  IF v_appt.status = 'CANCELLED' THEN
    RAISE_APPLICATION_ERROR(-20030,
      'Cannot complete a CANCELLED appointment.');
  ELSIF v_appt.status = 'COMPLETED' THEN
    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appt_id || ' is already COMPLETED.');
    RETURN;
  END IF;

  -- Flip status to COMPLETED (this fires TRG_AUTO_BILL_ON_COMPLETE).
  UPDATE appointments
     SET status = 'COMPLETED'
   WHERE appt_id = p_appt_id;

  -- Insert a medical record linked to this appointment.
  INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
       VALUES (record_seq.NEXTVAL, v_appt.patient_id, v_appt.doctor_id, v_appt.appt_id,
               p_diagnosis, p_prescription_text, NULL)
       RETURNING record_id INTO v_record_id;

  -- Insert one prescription line if a prescription text was supplied.
  IF p_prescription_text IS NOT NULL THEN
    INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days)
         VALUES (prescription_seq.NEXTVAL, v_record_id, p_prescription_text,
                 'As prescribed', 'As directed', 7);
  END IF;

  DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appt_id || ' completed; medical record ' ||
                       v_record_id || ' created.');
  COMMIT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20031, 'Appointment ' || p_appt_id || ' not found.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END complete_appointment;
/

-- =====================================================================
-- 4. GENERATE_BILL
--    Creates a bill for a patient (optionally linked to an appointment).
--    The total_amount is computed automatically by TRG_BILL_TOTAL.
-- =====================================================================
CREATE OR REPLACE PROCEDURE generate_bill (
  p_patient_id       IN NUMBER,
  p_appt_id          IN NUMBER DEFAULT NULL,
  p_consultation_fee IN NUMBER  DEFAULT 0,
  p_medicine_fee     IN NUMBER  DEFAULT 0,
  p_test_fee         IN NUMBER  DEFAULT 0
) AS
  v_count  NUMBER;
  v_bill_id billing.bill_id%TYPE;
BEGIN
  -- Verify patient.
  SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = p_patient_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20040, 'Patient ' || p_patient_id || ' does not exist.');
  END IF;

  -- If appt_id supplied, verify it belongs to this patient.
  IF p_appt_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_count
      FROM appointments
     WHERE appt_id    = p_appt_id
       AND patient_id = p_patient_id;
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20041,
        'Appointment ' || p_appt_id || ' does not belong to patient ' || p_patient_id || '.');
    END IF;
  END IF;

  -- total_amount is intentionally NOT supplied; the trigger computes it.
  INSERT INTO billing (bill_id, patient_id, appt_id, bill_date,
                       consultation_fee, medicine_fee, test_fee, payment_status)
       VALUES (bill_seq.NEXTVAL, p_patient_id, p_appt_id, SYSDATE,
               p_consultation_fee, p_medicine_fee, p_test_fee, 'PENDING')
       RETURNING bill_id INTO v_bill_id;

  DBMS_OUTPUT.PUT_LINE('Bill ' || v_bill_id || ' created for patient ' || p_patient_id ||
                       ' - total = ' ||
                       TO_CHAR(p_consultation_fee + p_medicine_fee + p_test_fee) || '.');
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END generate_bill;
/

-- =====================================================================
-- 5. PROCESS_PAYMENT
--    Marks a PENDING bill as PAID and stamps paid_date = SYSDATE.
--    PAID bills cannot be re-processed; CANCELLED bills cannot be paid.
-- =====================================================================
CREATE OR REPLACE PROCEDURE process_payment (
  p_bill_id IN NUMBER
) AS
  v_status billing.payment_status%TYPE;
BEGIN
  SELECT payment_status INTO v_status
    FROM billing
   WHERE bill_id = p_bill_id
     FOR UPDATE;

  IF v_status = 'PAID' THEN
    DBMS_OUTPUT.PUT_LINE('Bill ' || p_bill_id || ' is already PAID.');
  ELSIF v_status = 'CANCELLED' THEN
    RAISE_APPLICATION_ERROR(-20050,
      'Cannot pay a CANCELLED bill (' || p_bill_id || ').');
  ELSE
    UPDATE billing
       SET payment_status = 'PAID',
           paid_date      = SYSDATE
     WHERE bill_id = p_bill_id;
    DBMS_OUTPUT.PUT_LINE('Bill ' || p_bill_id || ' paid successfully.');
  END IF;
  COMMIT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20051, 'Bill ' || p_bill_id || ' not found.');
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END process_payment;
/

-- =====================================================================
-- 6. PATIENT_VISIT_REPORT
--    Opens a SYS_REFCURSOR returning the patient's appointment + billing
--    history between two dates (inclusive). The caller is responsible
--    for fetching and closing the cursor.
-- =====================================================================
CREATE OR REPLACE PROCEDURE patient_visit_report (
  p_patient_id  IN  NUMBER,
  p_start_date  IN  DATE,
  p_end_date    IN  DATE,
  p_cursor      OUT SYS_REFCURSOR
) AS
  v_count NUMBER;
BEGIN
  -- Verify patient exists; raise NO_DATA_FOUND if not.
  SELECT COUNT(*) INTO v_count
    FROM patients
   WHERE patient_id = p_patient_id;
  IF v_count = 0 THEN
    RAISE NO_DATA_FOUND;
  END IF;

  OPEN p_cursor FOR
    SELECT a.appt_id,
           a.appt_date,
           a.appt_time,
           a.status,
           a.reason,
           doc.first_name || ' ' || doc.last_name AS doctor_name,
           dep.dept_name                            AS department,
           b.bill_id,
           b.total_amount,
           b.payment_status
      FROM appointments a
      JOIN doctors      doc ON doc.doctor_id = a.doctor_id
      JOIN departments  dep ON dep.dept_id   = doc.dept_id
      LEFT JOIN billing b   ON b.appt_id     = a.appt_id
     WHERE a.patient_id = p_patient_id
       AND a.appt_date BETWEEN p_start_date AND p_end_date
     ORDER BY a.appt_date DESC, a.appt_time DESC;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20060,
      'Patient ' || p_patient_id || ' not found.');
  WHEN OTHERS THEN
    RAISE;
END patient_visit_report;
/

PROMPT All HMS stored procedures created successfully.
