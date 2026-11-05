-- =====================================================================
-- File:    13_exception_handling.sql
-- Purpose: Demonstrate PL/SQL exception handling:
--          - NO_DATA_FOUND
--          - DUP_VAL_ON_INDEX
--          - User-defined exception
--          - WHEN OTHERS with SQLERRM logging
-- Author:  HMS Project
-- Date:    2025
-- Notes:   This file is intended for interactive execution. Each block
--          is self-contained and prints what it caught.
-- =====================================================================

SET SERVEROUTPUT ON;
SET DEFINE OFF;

-- =====================================================================
-- 1. NO_DATA_FOUND
--    Try to read a non-existent patient. The SELECT...INTO raises
--    NO_DATA_FOUND, which we catch and report.
-- =====================================================================
DECLARE
  v_name patients.first_name%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Test 1: NO_DATA_FOUND ---');
  SELECT first_name INTO v_name
    FROM patients
   WHERE patient_id = 999999;  -- does not exist
  DBMS_OUTPUT.PUT_LINE('Got: ' || v_name);  -- never reached
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Caught NO_DATA_FOUND: no patient with that ID.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected: ' || SQLERRM);
END;
/

-- =====================================================================
-- 2. DUP_VAL_ON_INDEX
--    Try to insert a department with a name that already exists. The
--    unique constraint UQ_DEPT_NAME fires; we catch DUP_VAL_ON_INDEX.
-- =====================================================================
DECLARE
  e_dup_dept EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_dup_dept, -1);  -- ORA-00001: unique violation
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Test 2: DUP_VAL_ON_INDEX ---');
  INSERT INTO departments (dept_id, dept_name, location)
       VALUES (dept_seq.NEXTVAL, 'Cardiology', 'Duplicate test');
  COMMIT;
EXCEPTION
  WHEN e_dup_dept THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Caught DUP_VAL_ON_INDEX: a department named "Cardiology" already exists.');
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Unexpected: ' || SQLERRM);
END;
/

-- =====================================================================
-- 3. User-defined exception
--    Try to book a patient into a slot the doctor already has booked.
--    We define our own exception and RAISE it explicitly. (We use the
--    existing book_appointment procedure, which itself raises a
--    user-defined -20010 error; here we wrap that as our own exception.)
-- =====================================================================
DECLARE
  e_double_booked EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_double_booked, -20010);
  v_appt_id NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Test 3: User-defined exception (double-book) ---');

  -- First booking should succeed.
  book_appointment(p_patient_id => 1000,
                   p_doctor_id  => 1000,
                   p_appt_date  => TRUNC(SYSDATE) + 10,
                   p_appt_time  => '08:00',
                   p_reason     => 'Test booking 1');

  -- Second booking at the SAME doctor+date+time should raise -20010.
  book_appointment(p_patient_id => 1001,
                   p_doctor_id  => 1000,
                   p_appt_date  => TRUNC(SYSDATE) + 10,
                   p_appt_time  => '08:00',
                   p_reason     => 'Test booking 2 - should fail');
EXCEPTION
  WHEN e_double_booked THEN
    DBMS_OUTPUT.PUT_LINE('Caught user-defined e_double_booked: the doctor already has a booking at that slot.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Unexpected: ' || SQLERRM);
END;
/

-- =====================================================================
-- 4. WHEN OTHERS with SQLERRM logging
--    A helper that simulates work and intentionally raises. We log the
--    error message (and code) to DBMS_OUTPUT and to AUDIT_LOG so the
--    failure is recorded even though the block recovers.
-- =====================================================================
DECLARE
  v_dummy NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Test 4: WHEN OTHERS with SQLERRM logging ---');

  -- Force an error: divide by zero.
  v_dummy := 1 / 0;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Caught WHEN OTHERS: ' || SQLERRM || ' (code ' || SQLCODE || ')');
    -- Also persist the error to the audit log so it survives the session.
    INSERT INTO audit_log (audit_id, table_name, operation, row_id,
                           old_value, new_value, changed_by, changed_at)
         VALUES (audit_seq.NEXTVAL, 'PLSQL_RUNTIME', 'ERROR', NULL,
                 NULL, TO_CLOB(SQLERRM || ' (code ' || SQLCODE || ')'),
                 USER, SYSTIMESTAMP);
    COMMIT;
END;
/

PROMPT Exception-handling examples executed.
