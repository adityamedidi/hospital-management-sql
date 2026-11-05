-- =====================================================================
-- File:    10_triggers.sql
-- Purpose: Triggers for the HMS schema (audit, auto-fill, validation
--          and auto-bill on appointment completion).
-- Author:  HMS Project
-- Date:    2025
-- Triggers:
--   1. TRG_BILL_TOTAL              - auto-sum total_amount on BILLING
--   2. TRG_AUDIT_DOCTORS           - audit DOCTORS changes
--   3. TRG_AUDIT_PATIENTS          - audit PATIENTS changes
--   4. TRG_APPT_STATUS_CHECK       - block CANCELLED -> SCHEDULED
--   5. TRG_AUTO_BILL_ON_COMPLETE   - auto-create draft bill on COMPLETE
--   6. TRG_PATIENT_REGISTERED_AT   - default registered_at = SYSTIMESTAMP
-- =====================================================================

SET DEFINE OFF;

-- =====================================================================
-- 1. TRG_BILL_TOTAL
--    BEFORE INSERT OR UPDATE on BILLING.
--    Always (re)computes total_amount from the three fee columns so the
--    stored total can never drift out of sync.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_bill_total
BEFORE INSERT OR UPDATE ON billing
FOR EACH ROW
BEGIN
  :NEW.total_amount := NVL(:NEW.consultation_fee, 0)
                     + NVL(:NEW.medicine_fee,     0)
                     + NVL(:NEW.test_fee,         0);
END trg_bill_total;
/

-- =====================================================================
-- 2. TRG_AUDIT_DOCTORS
--    AFTER INSERT/UPDATE/DELETE on DOCTORS.
--    Writes a single row to AUDIT_LOG describing the change, with the
--    OLD and NEW row contents serialized as CLOBs.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_audit_doctors
AFTER INSERT OR UPDATE OR DELETE ON doctors
FOR EACH ROW
DECLARE
  v_op   VARCHAR2(10);
  v_old  CLOB;
  v_new  CLOB;
BEGIN
  IF INSERTING THEN v_op := 'INSERT';
  ELSIF UPDATING THEN v_op := 'UPDATE';
  ELSE            v_op := 'DELETE';
  END IF;

  IF v_op IN ('UPDATE', 'DELETE') THEN
    v_old := 'doctor_id='       || :OLD.doctor_id
          || '|first_name='     || :OLD.first_name
          || '|last_name='      || :OLD.last_name
          || '|specialization=' || :OLD.specialization
          || '|status='         || :OLD.status
          || '|salary='         || :OLD.salary;
  END IF;

  IF v_op IN ('INSERT', 'UPDATE') THEN
    v_new := 'doctor_id='       || :NEW.doctor_id
          || '|first_name='     || :NEW.first_name
          || '|last_name='      || :NEW.last_name
          || '|specialization=' || :NEW.specialization
          || '|status='         || :NEW.status
          || '|salary='         || :NEW.salary;
  END IF;

  INSERT INTO audit_log (audit_id, table_name, operation, row_id,
                         old_value, new_value, changed_by, changed_at)
       VALUES (audit_seq.NEXTVAL, 'DOCTORS', v_op,
               COALESCE(:NEW.doctor_id, :OLD.doctor_id),
               v_old, v_new, USER, SYSTIMESTAMP);
END trg_audit_doctors;
/

-- =====================================================================
-- 3. TRG_AUDIT_PATIENTS
--    AFTER INSERT/UPDATE/DELETE on PATIENTS.
--    Same idea as TRG_AUDIT_DOCTORS but for PATIENTS.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_audit_patients
AFTER INSERT OR UPDATE OR DELETE ON patients
FOR EACH ROW
DECLARE
  v_op   VARCHAR2(10);
  v_old  CLOB;
  v_new  CLOB;
BEGIN
  IF INSERTING THEN v_op := 'INSERT';
  ELSIF UPDATING THEN v_op := 'UPDATE';
  ELSE            v_op := 'DELETE';
  END IF;

  IF v_op IN ('UPDATE', 'DELETE') THEN
    v_old := 'patient_id='  || :OLD.patient_id
          || '|first_name=' || :OLD.first_name
          || '|last_name='  || :OLD.last_name
          || '|gender='     || :OLD.gender
          || '|dob='        || TO_CHAR(:OLD.dob,'YYYY-MM-DD')
          || '|phone='      || :OLD.phone;
  END IF;

  IF v_op IN ('INSERT', 'UPDATE') THEN
    v_new := 'patient_id='  || :NEW.patient_id
          || '|first_name=' || :NEW.first_name
          || '|last_name='  || :NEW.last_name
          || '|gender='     || :NEW.gender
          || '|dob='        || TO_CHAR(:NEW.dob,'YYYY-MM-DD')
          || '|phone='      || :NEW.phone;
  END IF;

  INSERT INTO audit_log (audit_id, table_name, operation, row_id,
                         old_value, new_value, changed_by, changed_at)
       VALUES (audit_seq.NEXTVAL, 'PATIENTS', v_op,
               COALESCE(:NEW.patient_id, :OLD.patient_id),
               v_old, v_new, USER, SYSTIMESTAMP);
END trg_audit_patients;
/

-- =====================================================================
-- 4. TRG_APPT_STATUS_CHECK
--    BEFORE UPDATE OF status ON APPOINTMENTS.
--    Fires only when transitioning from CANCELLED -> SCHEDULED and
--    blocks the change with a friendly error.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_appt_status_check
BEFORE UPDATE OF status ON appointments
FOR EACH ROW
WHEN (OLD.status = 'CANCELLED' AND NEW.status = 'SCHEDULED')
BEGIN
  RAISE_APPLICATION_ERROR(-20070,
    'Appointment ' || :OLD.appt_id ||
    ' cannot be moved back to SCHEDULED after being CANCELLED.');
END trg_appt_status_check;
/

-- =====================================================================
-- 5. TRG_AUTO_BILL_ON_COMPLETE
--    AFTER UPDATE OF status ON APPOINTMENTS.
--    Fires only when status becomes COMPLETED from something else, and
--    auto-creates a draft PENDING bill for the appointment.
--    The TRG_BILL_TOTAL trigger on BILLING will then set total_amount.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_auto_bill_on_complete
AFTER UPDATE OF status ON appointments
FOR EACH ROW
WHEN (NEW.status = 'COMPLETED' AND (OLD.status IS NULL OR OLD.status != 'COMPLETED'))
DECLARE
  v_bill_id billing.bill_id%TYPE;
BEGIN
  INSERT INTO billing (bill_id, patient_id, appt_id, bill_date,
                       consultation_fee, medicine_fee, test_fee, payment_status)
       VALUES (bill_seq.NEXTVAL, :NEW.patient_id, :NEW.appt_id, SYSDATE,
               100, 0, 0, 'PENDING')
       RETURNING bill_id INTO v_bill_id;

  DBMS_OUTPUT.PUT_LINE('Auto-generated draft bill ' || v_bill_id ||
                       ' for completed appointment ' || :NEW.appt_id || '.');
END trg_auto_bill_on_complete;
/

-- =====================================================================
-- 6. TRG_PATIENT_REGISTERED_AT
--    BEFORE INSERT ON PATIENTS.
--    If the caller did not supply a value, default registered_at to
--    the current timestamp.
-- =====================================================================
CREATE OR REPLACE TRIGGER trg_patient_registered_at
BEFORE INSERT ON patients
FOR EACH ROW
BEGIN
  IF :NEW.registered_at IS NULL THEN
    :NEW.registered_at := SYSTIMESTAMP;
  END IF;
END trg_patient_registered_at;
/

PROMPT All HMS triggers created successfully.
