-- =====================================================================
-- File:    07_synonyms.sql
-- Purpose: Create synonyms for cross-schema access to HMS tables and
--          views. Other schemas (e.g. reporting tools) can then query
--          the data without prefixing every object with HMS_USER.
-- Author:  HMS Project
-- Date:    2025
-- Notes:   - Private synonyms are created by default (no privilege needed).
--          - To create PUBLIC synonyms you must be granted
--            CREATE PUBLIC SYNONYM and run as a user with that privilege.
-- =====================================================================

SET DEFINE OFF;

-- ---------------------------------------------------------------------
-- Private synonyms (always safe to create in the current schema).
-- These let you write  SELECT * FROM doctors  instead of
--                       SELECT * FROM hms_user.doctors
-- if you connect as a different schema that needs to read these objects.
-- Here we just alias them locally for demonstration.
-- ---------------------------------------------------------------------
CREATE OR REPLACE SYNONYM syn_departments      FOR departments;
CREATE OR REPLACE SYNONYM syn_doctors          FOR doctors;
CREATE OR REPLACE SYNONYM syn_patients         FOR patients;
CREATE OR REPLACE SYNONYM syn_appointments     FOR appointments;
CREATE OR REPLACE SYNONYM syn_medical_records  FOR medical_records;
CREATE OR REPLACE SYNONYM syn_prescriptions    FOR prescriptions;
CREATE OR REPLACE SYNONYM syn_billing          FOR billing;
CREATE OR REPLACE SYNONYM syn_staff            FOR staff;
CREATE OR REPLACE SYNONYM syn_audit_log        FOR audit_log;

-- Synonyms for the views (handy for read-only reporting users).
CREATE OR REPLACE SYNONYM syn_v_active_doctors     FOR v_active_doctors;
CREATE OR REPLACE SYNONYM syn_v_today_appointments FOR v_today_appointments;
CREATE OR REPLACE SYNONYM syn_v_dept_revenue       FOR v_dept_revenue;
CREATE OR REPLACE SYNONYM syn_v_patient_history    FOR v_patient_history;
CREATE OR REPLACE SYNONYM syn_v_pending_bills      FOR v_pending_bills;
CREATE OR REPLACE SYNONYM syn_v_doctor_workload    FOR v_doctor_workload;

-- ---------------------------------------------------------------------
-- PUBLIC synonyms (commented out by default; uncomment and run as a
-- user with CREATE PUBLIC SYNONYM privilege if you want every schema
-- in the database to see these objects without an explicit schema prefix).
-- ---------------------------------------------------------------------
-- CREATE OR REPLACE PUBLIC SYNONYM departments     FOR hms_user.departments;
-- CREATE OR REPLACE PUBLIC SYNONYM doctors         FOR hms_user.doctors;
-- CREATE OR REPLACE PUBLIC SYNONYM patients        FOR hms_user.patients;
-- CREATE OR REPLACE PUBLIC SYNONYM appointments    FOR hms_user.appointments;
-- CREATE OR REPLACE PUBLIC SYNONYM medical_records FOR hms_user.medical_records;
-- CREATE OR REPLACE PUBLIC SYNONYM prescriptions   FOR hms_user.prescriptions;
-- CREATE OR REPLACE PUBLIC SYNONYM billing         FOR hms_user.billing;
-- CREATE OR REPLACE PUBLIC SYNONYM staff           FOR hms_user.staff;

PROMPT All HMS synonyms created successfully.
