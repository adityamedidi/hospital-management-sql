-- =====================================================================
-- File:    05_indexes.sql
-- Purpose: Create B-tree indexes on frequently filtered / joined columns.
-- Author:  HMS Project
-- Date:    2025
-- Notes:   PK and UNIQUE columns already have implicit indexes created
--          by Oracle; we add explicit indexes for FK columns and other
--          frequently-filtered columns.
-- =====================================================================

SET DEFINE OFF;

-- Idempotent: drop the index if it already exists, then recreate.
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_doctors_dept';          EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_doctors_specialization'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_appt_patient';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_appt_doctor';            EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_appt_date';              EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_billing_patient';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_billing_status';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_medrec_patient';         EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Speeds up "list doctors in this department" joins.
CREATE INDEX idx_doctors_dept ON doctors(dept_id);

-- Speeds up "find a doctor by specialization" searches.
CREATE INDEX idx_doctors_specialization ON doctors(specialization);

-- Speeds up "appointment history for patient X" queries.
CREATE INDEX idx_appt_patient ON appointments(patient_id);

-- Speeds up "appointments for doctor X" queries (the unique index on
-- (doctor_id, appt_date, appt_time) covers doctor_id as a leading column,
-- but a single-column index is still useful for queries that don't filter
-- on date/time).
CREATE INDEX idx_appt_doctor ON appointments(doctor_id);

-- Speeds up "appointments for date X" and range scans by date.
CREATE INDEX idx_appt_date ON appointments(appt_date);

-- Speeds up "all bills for a patient" queries.
CREATE INDEX idx_billing_patient ON billing(patient_id);

-- Speeds up "all PENDING bills" / "all PAID bills" queries.
CREATE INDEX idx_billing_status ON billing(payment_status);

-- Speeds up "medical history for a patient" queries.
CREATE INDEX idx_medrec_patient ON medical_records(patient_id);

PROMPT All HMS indexes created successfully.
