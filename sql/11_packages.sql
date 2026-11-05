-- =====================================================================
-- File:    11_packages.sql
-- Purpose: Two PL/SQL packages (spec + body) that bundle related
--          billing and appointment operations.
-- Author:  HMS Project
-- Date:    2025
-- Packages:
--   - BILLING_PKG       (CREATE_BILL, MARK_PAID, CANCEL_BILL,
--                        GET_BILL_DETAILS refcursor, GET_OUTSTANDING_TOTAL)
--   - APPOINTMENT_PKG   (SCHEDULE, RESCHEDULE, CANCEL, GET_NEXT_AVAILABLE_SLOT)
-- =====================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

-- =====================================================================
-- PACKAGE 1: BILLING_PKG
-- =====================================================================
CREATE OR REPLACE PACKAGE billing_pkg AS
  -- Create a new bill for a patient (optionally linked to an appointment).
  PROCEDURE create_bill (
    p_patient_id       IN NUMBER,
    p_appt_id          IN NUMBER DEFAULT NULL,
    p_consultation_fee IN NUMBER  DEFAULT 0,
    p_medicine_fee     IN NUMBER  DEFAULT 0,
    p_test_fee         IN NUMBER  DEFAULT 0,
    p_bill_id          OUT NUMBER
  );

  -- Mark a bill PAID; stamp paid_date.
  PROCEDURE mark_paid (p_bill_id IN NUMBER);

  -- Mark a bill CANCELLED.
  PROCEDURE cancel_bill (p_bill_id IN NUMBER);

  -- Return all bill details for a bill_id through a SYS_REFCURSOR.
  PROCEDURE get_bill_details (
    p_bill_id IN NUMBER,
    p_cursor  OUT SYS_REFCURSOR
  );

  -- Return the sum of PENDING (outstanding) bill amounts for a patient.
  FUNCTION get_outstanding_total (p_patient_id IN NUMBER) RETURN NUMBER;
END billing_pkg;
/

CREATE OR REPLACE PACKAGE BODY billing_pkg AS
  -------------------------------------------------------------------
  -- CREATE_BILL
  -------------------------------------------------------------------
  PROCEDURE create_bill (
    p_patient_id       IN NUMBER,
    p_appt_id          IN NUMBER DEFAULT NULL,
    p_consultation_fee IN NUMBER  DEFAULT 0,
    p_medicine_fee     IN NUMBER  DEFAULT 0,
    p_test_fee         IN NUMBER  DEFAULT 0,
    p_bill_id          OUT NUMBER
  ) AS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = p_patient_id;
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20301, 'Patient ' || p_patient_id || ' does not exist.');
    END IF;

    INSERT INTO billing (bill_id, patient_id, appt_id, bill_date,
                         consultation_fee, medicine_fee, test_fee, payment_status)
         VALUES (bill_seq.NEXTVAL, p_patient_id, p_appt_id, SYSDATE,
                 p_consultation_fee, p_medicine_fee, p_test_fee, 'PENDING')
         RETURNING bill_id INTO p_bill_id;

    DBMS_OUTPUT.PUT_LINE('BILLING_PKG.CREATE_BILL: bill ' || p_bill_id || ' created.');
    COMMIT;
  END create_bill;

  -------------------------------------------------------------------
  -- MARK_PAID
  -------------------------------------------------------------------
  PROCEDURE mark_paid (p_bill_id IN NUMBER) AS
    v_status billing.payment_status%TYPE;
  BEGIN
    SELECT payment_status INTO v_status
      FROM billing
     WHERE bill_id = p_bill_id
       FOR UPDATE;

    IF v_status = 'CANCELLED' THEN
      RAISE_APPLICATION_ERROR(-20302,
        'Cannot mark CANCELLED bill ' || p_bill_id || ' as PAID.');
    ELSIF v_status = 'PAID' THEN
      DBMS_OUTPUT.PUT_LINE('BILLING_PKG.MARK_PAID: bill ' || p_bill_id || ' already PAID.');
    ELSE
      UPDATE billing
         SET payment_status = 'PAID',
             paid_date      = SYSDATE
       WHERE bill_id = p_bill_id;
      DBMS_OUTPUT.PUT_LINE('BILLING_PKG.MARK_PAID: bill ' || p_bill_id || ' marked PAID.');
    END IF;
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20303, 'Bill ' || p_bill_id || ' not found.');
  END mark_paid;

  -------------------------------------------------------------------
  -- CANCEL_BILL
  -------------------------------------------------------------------
  PROCEDURE cancel_bill (p_bill_id IN NUMBER) AS
    v_status billing.payment_status%TYPE;
  BEGIN
    SELECT payment_status INTO v_status
      FROM billing
     WHERE bill_id = p_bill_id
       FOR UPDATE;

    IF v_status = 'PAID' THEN
      RAISE_APPLICATION_ERROR(-20304,
        'Cannot cancel PAID bill ' || p_bill_id || '.');
    ELSIF v_status = 'CANCELLED' THEN
      DBMS_OUTPUT.PUT_LINE('BILLING_PKG.CANCEL_BILL: bill ' || p_bill_id || ' already CANCELLED.');
    ELSE
      UPDATE billing
         SET payment_status = 'CANCELLED'
       WHERE bill_id = p_bill_id;
      DBMS_OUTPUT.PUT_LINE('BILLING_PKG.CANCEL_BILL: bill ' || p_bill_id || ' cancelled.');
    END IF;
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20305, 'Bill ' || p_bill_id || ' not found.');
  END cancel_bill;

  -------------------------------------------------------------------
  -- GET_BILL_DETAILS  (refcursor out)
  -------------------------------------------------------------------
  PROCEDURE get_bill_details (
    p_bill_id IN NUMBER,
    p_cursor  OUT SYS_REFCURSOR
  ) AS
  BEGIN
    OPEN p_cursor FOR
      SELECT b.bill_id,
             b.patient_id,
             p.first_name || ' ' || p.last_name AS patient_name,
             b.appt_id,
             b.bill_date,
             b.consultation_fee,
             b.medicine_fee,
             b.test_fee,
             b.total_amount,
             b.payment_status,
             b.paid_date
        FROM billing b
        JOIN patients p ON p.patient_id = b.patient_id
       WHERE b.bill_id = p_bill_id;
  END get_bill_details;

  -------------------------------------------------------------------
  -- GET_OUTSTANDING_TOTAL
  -------------------------------------------------------------------
  FUNCTION get_outstanding_total (p_patient_id IN NUMBER) RETURN NUMBER AS
    v_total NUMBER := 0;
  BEGIN
    SELECT NVL(SUM(total_amount), 0)
      INTO v_total
      FROM billing
     WHERE patient_id     = p_patient_id
       AND payment_status = 'PENDING';
    RETURN v_total;
  END get_outstanding_total;
END billing_pkg;
/

-- =====================================================================
-- PACKAGE 2: APPOINTMENT_PKG
-- =====================================================================
CREATE OR REPLACE PACKAGE appointment_pkg AS
  -- Schedule a new appointment.
  PROCEDURE schedule (
    p_patient_id IN NUMBER,
    p_doctor_id  IN NUMBER,
    p_appt_date  IN DATE,
    p_appt_time  IN VARCHAR2,
    p_reason     IN VARCHAR2 DEFAULT NULL,
    p_appt_id    OUT NUMBER
  );

  -- Move an existing SCHEDULED appointment to a new date/time.
  PROCEDURE reschedule (
    p_appt_id   IN NUMBER,
    p_new_date  IN DATE,
    p_new_time  IN VARCHAR2
  );

  -- Mark an appointment CANCELLED.
  PROCEDURE cancel (p_appt_id IN NUMBER);

  -- Return the next available free slot (as a DATE) for a doctor on
  -- a given date, scanning a list of standard slots starting 09:00.
  FUNCTION get_next_available_slot (
    p_doctor_id IN NUMBER,
    p_date      IN DATE
  ) RETURN TIMESTAMP;
END appointment_pkg;
/

CREATE OR REPLACE PACKAGE BODY appointment_pkg AS
  -------------------------------------------------------------------
  -- SCHEDULE
  -------------------------------------------------------------------
  PROCEDURE schedule (
    p_patient_id IN NUMBER,
    p_doctor_id  IN NUMBER,
    p_appt_date  IN DATE,
    p_appt_time  IN VARCHAR2,
    p_reason     IN VARCHAR2 DEFAULT NULL,
    p_appt_id    OUT NUMBER
  ) AS
    v_count NUMBER;
  BEGIN
    -- Validate patient.
    SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = p_patient_id;
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20401, 'Patient ' || p_patient_id || ' does not exist.');
    END IF;

    -- Validate doctor is ACTIVE.
    SELECT COUNT(*) INTO v_count
      FROM doctors
     WHERE doctor_id = p_doctor_id
       AND status    = 'ACTIVE';
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20402,
        'Doctor ' || p_doctor_id || ' is not ACTIVE; cannot schedule.');
    END IF;

    -- No double-booking.
    IF fn_is_doctor_available(p_doctor_id, p_appt_date, p_appt_time) = 0 THEN
      RAISE_APPLICATION_ERROR(-20403,
        'Doctor ' || p_doctor_id || ' is not available at the requested slot.');
    END IF;

    INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
         VALUES (appt_seq.NEXTVAL, p_patient_id, p_doctor_id, p_appt_date, p_appt_time, 'SCHEDULED', p_reason)
         RETURNING appt_id INTO p_appt_id;

    DBMS_OUTPUT.PUT_LINE('APPOINTMENT_PKG.SCHEDULE: appt ' || p_appt_id || ' created.');
    COMMIT;
  END schedule;

  -------------------------------------------------------------------
  -- RESCHEDULE
  -------------------------------------------------------------------
  PROCEDURE reschedule (
    p_appt_id   IN NUMBER,
    p_new_date  IN DATE,
    p_new_time  IN VARCHAR2
  ) AS
    v_appt appointments%ROWTYPE;
  BEGIN
    SELECT * INTO v_appt
      FROM appointments
     WHERE appt_id = p_appt_id
       FOR UPDATE;

    IF v_appt.status != 'SCHEDULED' THEN
      RAISE_APPLICATION_ERROR(-20410,
        'Only SCHEDULED appointments can be rescheduled (appt ' || p_appt_id ||
        ' is ' || v_appt.status || ').');
    END IF;

    -- Check the new slot is free for the same doctor.
    IF fn_is_doctor_available(v_appt.doctor_id, p_new_date, p_new_time) = 0 THEN
      RAISE_APPLICATION_ERROR(-20411,
        'Doctor ' || v_appt.doctor_id || ' is not available at the new slot.');
    END IF;

    UPDATE appointments
       SET appt_date = p_new_date,
           appt_time = p_new_time
     WHERE appt_id = p_appt_id;

    DBMS_OUTPUT.PUT_LINE('APPOINTMENT_PKG.RESCHEDULE: appt ' || p_appt_id || ' moved to ' ||
                         TO_CHAR(p_new_date,'YYYY-MM-DD') || ' ' || p_new_time || '.');
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20412, 'Appointment ' || p_appt_id || ' not found.');
  END reschedule;

  -------------------------------------------------------------------
  -- CANCEL
  -------------------------------------------------------------------
  PROCEDURE cancel (p_appt_id IN NUMBER) AS
    v_status appointments.status%TYPE;
  BEGIN
    SELECT status INTO v_status
      FROM appointments
     WHERE appt_id = p_appt_id
       FOR UPDATE;

    IF v_status = 'COMPLETED' THEN
      RAISE_APPLICATION_ERROR(-20420,
        'Cannot cancel COMPLETED appointment ' || p_appt_id || '.');
    ELSIF v_status = 'CANCELLED' THEN
      DBMS_OUTPUT.PUT_LINE('APPOINTMENT_PKG.CANCEL: appt ' || p_appt_id || ' already CANCELLED.');
    ELSE
      UPDATE appointments
         SET status = 'CANCELLED'
       WHERE appt_id = p_appt_id;
      DBMS_OUTPUT.PUT_LINE('APPOINTMENT_PKG.CANCEL: appt ' || p_appt_id || ' cancelled.');
    END IF;
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20421, 'Appointment ' || p_appt_id || ' not found.');
  END cancel;

  -------------------------------------------------------------------
  -- GET_NEXT_AVAILABLE_SLOT
  -- Scans standard 30-minute slots from 09:00 to 17:00 on p_date and
  -- returns the first TIMESTAMP for which the doctor is available.
  -------------------------------------------------------------------
  FUNCTION get_next_available_slot (
    p_doctor_id IN NUMBER,
    p_date      IN DATE
  ) RETURN TIMESTAMP AS
    v_slot   VARCHAR2(5);
    v_result TIMESTAMP := NULL;
  BEGIN
    FOR hour IN 9..16 LOOP
      v_slot := LPAD(hour, 2, '0') || ':00';
      IF fn_is_doctor_available(p_doctor_id, p_date, v_slot) = 1 THEN
        v_result := TO_TIMESTAMP(TO_CHAR(p_date,'YYYY-MM-DD') || ' ' || v_slot || ':00',
                                 'YYYY-MM-DD HH24:MI:SS');
        RETURN v_result;
      END IF;
      v_slot := LPAD(hour, 2, '0') || ':30';
      IF fn_is_doctor_available(p_doctor_id, p_date, v_slot) = 1 THEN
        v_result := TO_TIMESTAMP(TO_CHAR(p_date,'YYYY-MM-DD') || ' ' || v_slot || ':00',
                                 'YYYY-MM-DD HH24:MI:SS');
        RETURN v_result;
      END IF;
    END LOOP;
    RETURN NULL;  -- no free slot in the 09:00-17:00 window
  END get_next_available_slot;
END appointment_pkg;
/

PROMPT All HMS packages created successfully.
