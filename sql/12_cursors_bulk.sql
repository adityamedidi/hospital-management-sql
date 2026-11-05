-- =====================================================================
-- File:    12_cursors_bulk.sql
-- Purpose: Demonstrate explicit cursors, BULK COLLECT + FORALL, and
--          cursor FOR loops on the HMS schema.
-- Author:  HMS Project
-- Date:    2025
-- Notes:   This file is intended to be run interactively in SQL*Plus or
--          SQL Developer (it uses DBMS_OUTPUT extensively). It does NOT
--          modify any table data except for the BULK COLLECT + FORALL
--          example, which gives a 10% raise to all ACTIVE doctors in a
--          single department. Comment out that block if you don't want
--          any data changes.
-- =====================================================================

SET SERVEROUTPUT ON;
SET DEFINE OFF;

-- =====================================================================
-- 1. EXPLICIT CURSOR + LOOP
--    Loop over today's appointments and print patient + doctor names.
--    Demonstrates: explicit DECLARE / OPEN / FETCH / CLOSE.
-- =====================================================================
DECLARE
  CURSOR c_today IS
    SELECT a.appt_id,
           a.appt_time,
           p.first_name || ' ' || p.last_name AS patient_name,
           doc.first_name || ' ' || doc.last_name AS doctor_name,
           dep.dept_name                       AS department
      FROM appointments a
      JOIN patients   p   ON p.patient_id  = a.patient_id
      JOIN doctors    doc ON doc.doctor_id = a.doctor_id
      JOIN departments dep ON dep.dept_id  = doc.dept_id
     WHERE a.appt_date = TRUNC(SYSDATE)
     ORDER BY a.appt_time;

  v_row c_today%ROWTYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('---- Today''s appointments ----');
  OPEN c_today;
  LOOP
    FETCH c_today INTO v_row;
    EXIT WHEN c_today%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_row.appt_time, 6) || ' | ' ||
      RPAD(v_row.patient_name, 25) || ' | ' ||
      RPAD(v_row.doctor_name, 20) || ' | ' ||
      v_row.department);
  END LOOP;
  CLOSE c_today;
  DBMS_OUTPUT.PUT_LINE('---- End of today''s appointments ----');
END;
/

-- =====================================================================
-- 2. BULK COLLECT + FORALL
--    Give a 10% raise to all ACTIVE doctors in department 1000
--    (Cardiology) using BULK COLLECT to fetch IDs into a collection,
--    then FORALL to issue a single batched UPDATE.
--    Demonstrates: BULK COLLECT with LIMIT, FORALL, SQL%BULK_ROWCOUNT.
-- =====================================================================
DECLARE
  CURSOR c_active_cardiologists IS
    SELECT doctor_id FROM doctors WHERE dept_id = 1000 AND status = 'ACTIVE';

  TYPE t_id_tab IS TABLE OF doctors.doctor_id%TYPE;
  v_ids   t_id_tab;
  v_total NUMBER := 0;
BEGIN
  OPEN c_active_cardiologists;
  LOOP
    FETCH c_active_cardiologists BULK COLLECT INTO v_ids LIMIT 100;
    EXIT WHEN v_ids.COUNT = 0;

    FORALL i IN 1..v_ids.COUNT
      UPDATE doctors
         SET salary = salary * 1.10
       WHERE doctor_id = v_ids(i);

    -- SQL%BULK_ROWCOUNT tells us how many rows each FORALL iteration hit.
    FOR i IN 1..v_ids.COUNT LOOP
      v_total := v_total + SQL%BULK_ROWCOUNT(i);
    END LOOP;
  END LOOP;
  CLOSE c_active_cardiologists;

  DBMS_OUTPUT.PUT_LINE('BULK COLLECT + FORALL: gave 10% raise to ' ||
                       v_total || ' active Cardiology doctor(s).');
  COMMIT;
END;
/

-- =====================================================================
-- 3. CURSOR FOR LOOP
--    List all PENDING bills with patient name and amount, using the
--    implicit-declared record. The simplest PL/SQL loop pattern.
-- =====================================================================
BEGIN
  DBMS_OUTPUT.PUT_LINE('---- Pending bills ----');
  FOR r IN (
    SELECT b.bill_id,
           b.bill_date,
           b.total_amount,
           p.first_name || ' ' || p.last_name AS patient_name
      FROM billing b
      JOIN patients p ON p.patient_id = b.patient_id
     WHERE b.payment_status = 'PENDING'
     ORDER BY b.bill_date
  ) LOOP
    DBMS_OUTPUT.PUT_LINE(
      'Bill ' || RPAD(r.bill_id, 8) ||
      ' | '   || TO_CHAR(r.bill_date,'YYYY-MM-DD') ||
      ' | $'  || TO_CHAR(r.total_amount,'FM999,990.00') ||
      ' | '   || r.patient_name);
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('---- End of pending bills ----');
END;
/

PROMPT Cursors / bulk examples executed.
