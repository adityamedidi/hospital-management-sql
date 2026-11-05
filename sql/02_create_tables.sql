-- =====================================================================
-- File:    02_create_tables.sql
-- Purpose: Create all HMS tables with primary keys, foreign keys,
--          CHECK / UNIQUE / NOT NULL constraints and ON DELETE CASCADE.
-- Author:  HMS Project
-- Date:    2025
-- Notes:   Surrogate PKs are plain NUMBER columns populated from the
--          sequences declared in 03_sequences.sql (START WITH 1000,
--          INCREMENT BY 1, NOCACHE).
--          Safe to re-run because every CREATE TABLE is preceded by a
--          conditional DROP.
-- =====================================================================

SET DEFINE OFF;

-- ---------------------------------------------------------------------
-- 1. DEPARTMENTS
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE departments CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Top-level hospital departments.
CREATE TABLE departments (
  dept_id    NUMBER         PRIMARY KEY,
  dept_name  VARCHAR2(80)   NOT NULL,
  location   VARCHAR2(120),
  phone      VARCHAR2(20),
  created_at TIMESTAMP      DEFAULT SYSDATE,
  CONSTRAINT uq_dept_name UNIQUE (dept_name)
);

COMMENT ON TABLE  departments            IS 'Hospital departments (Cardiology, Neurology, etc.).';
COMMENT ON COLUMN departments.dept_id    IS 'Surrogate primary key populated from DEPT_SEQ.';
COMMENT ON COLUMN departments.dept_name  IS 'Unique department name.';
COMMENT ON COLUMN departments.created_at IS 'Row creation timestamp; defaults to SYSDATE.';

-- ---------------------------------------------------------------------
-- 2. DOCTORS
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE doctors CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Doctors employed by the hospital; each belongs to a department.
CREATE TABLE doctors (
  doctor_id      NUMBER         PRIMARY KEY,
  first_name     VARCHAR2(50)   NOT NULL,
  last_name      VARCHAR2(50)   NOT NULL,
  specialization VARCHAR2(80)   NOT NULL,
  email          VARCHAR2(120),
  phone          VARCHAR2(20),
  hire_date      DATE           NOT NULL,
  dept_id        NUMBER,
  salary         NUMBER(10, 2),
  status         VARCHAR2(10)   DEFAULT 'ACTIVE',
  created_at     TIMESTAMP      DEFAULT SYSDATE,
  CONSTRAINT fk_doctor_dept     FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
  CONSTRAINT uq_doctor_email    UNIQUE (email),
  CONSTRAINT ck_doctor_salary   CHECK (salary > 0),
  CONSTRAINT ck_doctor_status   CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

COMMENT ON TABLE doctors IS 'Doctors employed by the hospital; each belongs to one department.';

-- ---------------------------------------------------------------------
-- 3. PATIENTS
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE patients CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Registered patients with demographics and contact info.
CREATE TABLE patients (
  patient_id    NUMBER         PRIMARY KEY,
  first_name    VARCHAR2(50)   NOT NULL,
  last_name     VARCHAR2(50)   NOT NULL,
  gender        CHAR(1),
  dob           DATE           NOT NULL,
  blood_group   VARCHAR2(3),
  email         VARCHAR2(120),
  phone         VARCHAR2(20)   NOT NULL,
  address       VARCHAR2(255),
  registered_at TIMESTAMP      DEFAULT SYSDATE,
  CONSTRAINT ck_patient_gender CHECK (gender IN ('M', 'F', 'O')),
  CONSTRAINT ck_patient_blood  CHECK (blood_group IN
        ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);

COMMENT ON TABLE patients IS 'Registered patients; demographics and contact info.';

-- ---------------------------------------------------------------------
-- 4. APPOINTMENTS
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE appointments CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Scheduling: links a patient with a doctor at a date and time.
CREATE TABLE appointments (
  appt_id    NUMBER         PRIMARY KEY,
  patient_id NUMBER         NOT NULL,
  doctor_id  NUMBER         NOT NULL,
  appt_date  DATE           NOT NULL,
  appt_time  VARCHAR2(5)    NOT NULL,
  status     VARCHAR2(10)   DEFAULT 'SCHEDULED',
  reason     VARCHAR2(255),
  created_at TIMESTAMP      DEFAULT SYSDATE,
  CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  CONSTRAINT fk_appt_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id),
  -- Prevent double-booking the same doctor at the same slot.
  CONSTRAINT uq_appt_doctor_slot UNIQUE (doctor_id, appt_date, appt_time),
  CONSTRAINT ck_appt_status CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_appt_time   CHECK (appt_time BETWEEN '00:00' AND '23:59')
);

COMMENT ON TABLE  appointments           IS 'Books a patient with a doctor at a date/time.';
COMMENT ON COLUMN appointments.appt_time IS 'HH24:MI string, e.g. 09:30.';

-- ---------------------------------------------------------------------
-- 5. MEDICAL_RECORDS
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE medical_records CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Clinical record authored by a doctor for a patient; optional appt link.
CREATE TABLE medical_records (
  record_id    NUMBER          PRIMARY KEY,
  patient_id   NUMBER          NOT NULL,
  doctor_id    NUMBER          NOT NULL,
  appt_id      NUMBER,
  diagnosis    VARCHAR2(500)   NOT NULL,
  prescription VARCHAR2(1000),
  notes        VARCHAR2(1000),
  record_date  TIMESTAMP       DEFAULT SYSDATE,
  CONSTRAINT fk_mr_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  CONSTRAINT fk_mr_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id),
  CONSTRAINT fk_mr_appt    FOREIGN KEY (appt_id)    REFERENCES appointments(appt_id)
);

COMMENT ON TABLE medical_records IS 'Clinical record authored by a doctor for a patient; optionally tied to an appointment.';

-- ---------------------------------------------------------------------
-- 6. PRESCRIPTIONS  (cascade-deletes with MEDICAL_RECORDS)
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE prescriptions CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Line items per medical record (one row per medicine).
CREATE TABLE prescriptions (
  prescription_id NUMBER         PRIMARY KEY,
  record_id       NUMBER         NOT NULL,
  medicine_name   VARCHAR2(120)  NOT NULL,
  dosage          VARCHAR2(50)   NOT NULL,
  frequency       VARCHAR2(50)   NOT NULL,
  duration_days   NUMBER,
  CONSTRAINT fk_pres_record   FOREIGN KEY (record_id) REFERENCES medical_records(record_id)
                                                         ON DELETE CASCADE,
  CONSTRAINT ck_pres_duration CHECK (duration_days > 0)
);

COMMENT ON TABLE prescriptions IS 'Line items per medical record; cascaded delete with parent.';

-- ---------------------------------------------------------------------
-- 7. BILLING
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE billing CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Invoices for patients; total_amount is auto-set by TRG_BILL_TOTAL.
CREATE TABLE billing (
  bill_id          NUMBER         PRIMARY KEY,
  patient_id       NUMBER         NOT NULL,
  appt_id          NUMBER,
  bill_date        DATE           DEFAULT SYSDATE NOT NULL,
  consultation_fee NUMBER(10, 2)  DEFAULT 0,
  medicine_fee     NUMBER(10, 2)  DEFAULT 0,
  test_fee         NUMBER(10, 2)  DEFAULT 0,
  total_amount     NUMBER(10, 2),
  payment_status   VARCHAR2(10)   DEFAULT 'PENDING',
  paid_date        DATE,
  CONSTRAINT fk_bill_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  CONSTRAINT fk_bill_appt    FOREIGN KEY (appt_id)    REFERENCES appointments(appt_id),
  CONSTRAINT ck_bill_status  CHECK (payment_status IN ('PAID', 'PENDING', 'CANCELLED')),
  CONSTRAINT ck_bill_fees    CHECK (consultation_fee >= 0
                                    AND medicine_fee  >= 0
                                    AND test_fee      >= 0)
);

COMMENT ON TABLE  billing              IS 'Invoices for patients; total_amount auto-set by TRG_BILL_TOTAL.';
COMMENT ON COLUMN billing.total_amount IS 'Auto-calculated as consultation_fee + medicine_fee + test_fee.';

-- ---------------------------------------------------------------------
-- 8. STAFF
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE staff CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Non-doctor hospital staff (nurses, technicians, admin, etc.).
CREATE TABLE staff (
  staff_id    NUMBER         PRIMARY KEY,
  first_name  VARCHAR2(50)   NOT NULL,
  last_name   VARCHAR2(50)   NOT NULL,
  role        VARCHAR2(50)   NOT NULL,
  dept_id     NUMBER,
  phone       VARCHAR2(20),
  email       VARCHAR2(120),
  hire_date   DATE           NOT NULL,
  salary      NUMBER(10, 2),
  status      VARCHAR2(10)   DEFAULT 'ACTIVE',
  CONSTRAINT fk_staff_dept   FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
  CONSTRAINT uq_staff_email  UNIQUE (email),
  CONSTRAINT ck_staff_salary CHECK (salary > 0),
  CONSTRAINT ck_staff_status CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

COMMENT ON TABLE staff IS 'Non-doctor hospital staff (nurses, technicians, admin, etc.).';

-- ---------------------------------------------------------------------
-- 9. AUDIT_LOG
-- ---------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE audit_log CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- Generic audit trail written by triggers on DOCTORS and PATIENTS.
CREATE TABLE audit_log (
  audit_id   NUMBER         PRIMARY KEY,
  table_name VARCHAR2(40)   NOT NULL,
  operation  VARCHAR2(10)   NOT NULL,
  row_id     NUMBER,
  old_value  CLOB,
  new_value  CLOB,
  changed_by VARCHAR2(60)   DEFAULT USER,
  changed_at TIMESTAMP      DEFAULT SYSDATE
);

COMMENT ON TABLE  audit_log            IS 'Generic audit trail written by triggers on DOCTORS and PATIENTS.';
COMMENT ON COLUMN audit_log.old_value  IS 'CLOB snapshot of the row before the change (NULL for INSERT).';
COMMENT ON COLUMN audit_log.new_value  IS 'CLOB snapshot of the row after the change (NULL for DELETE).';

PROMPT All HMS tables created successfully.
