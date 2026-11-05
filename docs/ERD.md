# ERD — Entity Relationship Diagram (textual)

This document describes the entities, attributes, primary/foreign keys and
relationships in the **Hospital Management System** schema. Read top-to-bottom;
cardinality is shown with crow's-foot style notation (`1───*` = one-to-many).

---

## 1. DEPARTMENTS

Holds the hospital's clinical departments (Cardiology, Neurology, …).

| Column | Type | Constraints |
|--------|------|-------------|
| `dept_id`    | NUMBER       | PRIMARY KEY |
| `dept_name`  | VARCHAR2(80) | NOT NULL UNIQUE |
| `location`   | VARCHAR2(120)| |
| `phone`      | VARCHAR2(20) | |
| `created_at` | TIMESTAMP    | DEFAULT SYSDATE |

Relationships:
- `1───*` DOCTORS  (one department has many doctors)
- `1───*` STAFF    (one department has many staff)

---

## 2. DOCTORS

Doctors employed by the hospital; each belongs to one department.

| Column | Type | Constraints |
|--------|------|-------------|
| `doctor_id`       | NUMBER        | PRIMARY KEY |
| `first_name`      | VARCHAR2(50)  | NOT NULL |
| `last_name`       | VARCHAR2(50)  | NOT NULL |
| `specialization`  | VARCHAR2(80)  | NOT NULL |
| `email`           | VARCHAR2(120) | UNIQUE |
| `phone`           | VARCHAR2(20)  | |
| `hire_date`       | DATE          | NOT NULL |
| `dept_id`         | NUMBER        | FK → DEPARTMENTS(dept_id) |
| `salary`          | NUMBER(10,2)  | CHECK (salary > 0) |
| `status`          | VARCHAR2(10)  | CHECK (status IN ('ACTIVE','INACTIVE')) DEFAULT 'ACTIVE' |
| `created_at`      | TIMESTAMP     | DEFAULT SYSDATE |

Relationships:
- `*───1` DEPARTMENTS
- `1───*` APPOINTMENTS  (a doctor has many appointments)
- `1───*` MEDICAL_RECORDS (a doctor authors many records)

---

## 3. PATIENTS

People registered with the hospital.

| Column | Type | Constraints |
|--------|------|-------------|
| `patient_id`   | NUMBER        | PRIMARY KEY |
| `first_name`   | VARCHAR2(50)  | NOT NULL |
| `last_name`    | VARCHAR2(50)  | NOT NULL |
| `gender`       | CHAR(1)       | CHECK (gender IN ('M','F','O')) |
| `dob`          | DATE          | NOT NULL |
| `blood_group`  | VARCHAR2(3)   | CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')) |
| `email`        | VARCHAR2(120) | |
| `phone`        | VARCHAR2(20)  | NOT NULL |
| `address`      | VARCHAR2(255) | |
| `registered_at`| TIMESTAMP     | DEFAULT SYSDATE (set by trigger TRG_PATIENT_REGISTERED_AT) |

Relationships:
- `1───*` APPOINTMENTS
- `1───*` MEDICAL_RECORDS
- `1───*` BILLING

---

## 4. APPOINTMENTS

Books a patient with a doctor at a date/time.

| Column | Type | Constraints |
|--------|------|-------------|
| `appt_id`   | NUMBER        | PRIMARY KEY |
| `patient_id`| NUMBER        | FK → PATIENTS(patient_id) |
| `doctor_id` | NUMBER        | FK → DOCTORS(doctor_id) |
| `appt_date` | DATE          | NOT NULL |
| `appt_time` | VARCHAR2(5)   | NOT NULL (HH24:MI) |
| `status`    | VARCHAR2(10)  | CHECK (status IN ('SCHEDULED','COMPLETED','CANCELLED')) DEFAULT 'SCHEDULED' |
| `reason`    | VARCHAR2(255) | |
| `created_at`| TIMESTAMP     | DEFAULT SYSDATE |

Constraints:
- `UQ_APPT_DOCTOR_SLOT` UNIQUE(doctor_id, appt_date, appt_time) — prevents double-booking at the DB level.
- Trigger `TRG_APPT_STATUS_CHECK` prevents moving a CANCELLED appointment back to SCHEDULED.
- Trigger `TRG_AUTO_BILL_ON_COMPLETE` auto-creates a draft bill when status → COMPLETED.

Relationships:
- `*───1` PATIENTS
- `*───1` DOCTORS
- `1───0..1` MEDICAL_RECORDS (a medical record may reference the appointment)
- `1───0..1` BILLING (a bill may reference the appointment)

---

## 5. MEDICAL_RECORDS

A clinical record authored by a doctor for a patient; optionally linked to an appointment.

| Column | Type | Constraints |
|--------|------|-------------|
| `record_id`     | NUMBER         | PRIMARY KEY |
| `patient_id`    | NUMBER         | FK → PATIENTS(patient_id) |
| `doctor_id`     | NUMBER         | FK → DOCTORS(doctor_id) |
| `appt_id`       | NUMBER         | FK → APPOINTMENTS(appt_id) (nullable) |
| `diagnosis`     | VARCHAR2(500)  | NOT NULL |
| `prescription`  | VARCHAR2(1000) | |
| `notes`         | VARCHAR2(1000) | |
| `record_date`   | TIMESTAMP      | DEFAULT SYSDATE |

Relationships:
- `*───1` PATIENTS
- `*───1` DOCTORS
- `*───0..1` APPOINTMENTS
- `1───*` PRESCRIPTIONS (with ON DELETE CASCADE)

---

## 6. PRESCRIPTIONS

Line items for each medical record (one record can have many prescribed medicines).

| Column | Type | Constraints |
|--------|------|-------------|
| `prescription_id` | NUMBER        | PRIMARY KEY |
| `record_id`       | NUMBER        | FK → MEDICAL_RECORDS(record_id) ON DELETE CASCADE |
| `medicine_name`   | VARCHAR2(120) | NOT NULL |
| `dosage`          | VARCHAR2(50)  | NOT NULL (e.g. "500 mg") |
| `frequency`       | VARCHAR2(50)  | NOT NULL (e.g. "Twice daily") |
| `duration_days`   | NUMBER        | CHECK (duration_days > 0) |

Relationships:
- `*───1` MEDICAL_RECORDS

---

## 7. BILLING

An invoice for a patient; optionally linked to an appointment.

| Column | Type | Constraints |
|--------|------|-------------|
| `bill_id`          | NUMBER        | PRIMARY KEY |
| `patient_id`       | NUMBER        | FK → PATIENTS(patient_id) |
| `appt_id`          | NUMBER        | FK → APPOINTMENTS(appt_id) (nullable) |
| `bill_date`        | DATE          | DEFAULT SYSDATE NOT NULL |
| `consultation_fee` | NUMBER(10,2)  | DEFAULT 0 |
| `medicine_fee`     | NUMBER(10,2)  | DEFAULT 0 |
| `test_fee`         | NUMBER(10,2)  | DEFAULT 0 |
| `total_amount`     | NUMBER(10,2)  | (auto-set by TRG_BILL_TOTAL) |
| `payment_status`   | VARCHAR2(10)  | CHECK (payment_status IN ('PAID','PENDING','CANCELLED')) DEFAULT 'PENDING' |
| `paid_date`        | DATE          | (nullable; set by PROCESS_PAYMENT) |

Relationships:
- `*───1` PATIENTS
- `*───0..1` APPOINTMENTS

---

## 8. STAFF

Non-doctor hospital staff (nurses, technicians, admin, …).

| Column | Type | Constraints |
|--------|------|-------------|
| `staff_id`    | NUMBER        | PRIMARY KEY |
| `first_name`  | VARCHAR2(50)  | NOT NULL |
| `last_name`   | VARCHAR2(50)  | NOT NULL |
| `role`        | VARCHAR2(50)  | NOT NULL |
| `dept_id`     | NUMBER        | FK → DEPARTMENTS(dept_id) |
| `phone`       | VARCHAR2(20)  | |
| `email`       | VARCHAR2(120) | UNIQUE |
| `hire_date`   | DATE          | NOT NULL |
| `salary`      | NUMBER(10,2)  | CHECK (salary > 0) |
| `status`      | VARCHAR2(10)  | CHECK (status IN ('ACTIVE','INACTIVE')) DEFAULT 'ACTIVE' |

Relationships:
- `*───1` DEPARTMENTS

---

## 9. AUDIT_LOG

Generic audit trail written by triggers on DOCTORS and PATIENTS.

| Column | Type | Constraints |
|--------|------|-------------|
| `audit_id`   | NUMBER        | PRIMARY KEY |
| `table_name` | VARCHAR2(40)  | NOT NULL |
| `operation`  | VARCHAR2(10)  | NOT NULL |
| `row_id`     | NUMBER        | |
| `old_value`  | CLOB          | |
| `new_value`  | CLOB          | |
| `changed_by` | VARCHAR2(60)  | DEFAULT USER |
| `changed_at` | TIMESTAMP     | DEFAULT SYSDATE |

No FKs — it's a passive log, decoupled from the live tables.

---

## Overall relationship map

```
                         DEPARTMENTS
                        /           \
                       1             1
                       |             |
                       *             *
                    DOCTORS        STAFF
                     |  *
                     |  └────────────┐
                     1               │
                     *               │
                 APPOINTMENTS        │
                  |        \         │
                  1         0..1     │
                  *          \       │
              PATIENTS ───────  BILLING
                  |     \
                  1      1
                  *      *
            MEDICAL_RECORDS
                  |
                  1
                  *
            PRESCRIPTIONS

   (DOCTORS, PATIENTS) ──trigger──> AUDIT_LOG
```
