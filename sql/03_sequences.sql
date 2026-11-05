-- =====================================================================
-- File:    03_sequences.sql
-- Purpose: Create sequences used to populate surrogate primary keys.
--          All sequences START WITH 1000, INCREMENT BY 1, NOCACHE so
--          there are no gaps from cached values (useful for a teaching
--          project; in production you would use a small CACHE).
-- Author:  HMS Project
-- Date:    2025
-- =====================================================================

SET DEFINE OFF;

-- Idempotent: drop the sequence if it already exists, then recreate.
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE dept_seq';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE doctor_seq';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE patient_seq';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE appt_seq';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE record_seq';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE prescription_seq';EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE bill_seq';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE staff_seq';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE audit_seq';       EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Sequence for DEPARTMENTS.dept_id
CREATE SEQUENCE dept_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for DOCTORS.doctor_id
CREATE SEQUENCE doctor_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for PATIENTS.patient_id
CREATE SEQUENCE patient_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for APPOINTMENTS.appt_id
CREATE SEQUENCE appt_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for MEDICAL_RECORDS.record_id
CREATE SEQUENCE record_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for PRESCRIPTIONS.prescription_id
CREATE SEQUENCE prescription_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for BILLING.bill_id
CREATE SEQUENCE bill_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for STAFF.staff_id
CREATE SEQUENCE staff_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Sequence for AUDIT_LOG.audit_id
CREATE SEQUENCE audit_seq
  START WITH 1000
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

PROMPT All HMS sequences created successfully.
