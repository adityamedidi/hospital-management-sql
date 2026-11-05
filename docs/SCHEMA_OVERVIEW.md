# Schema Overview

A plain-English explanation of every table in the **Hospital Management System**
schema, in the order they are created by `sql/02_create_tables.sql`.

---

## 1. DEPARTMENTS

Stores the clinical/administrative departments of the hospital. Each doctor and
staff member is assigned to exactly one department. `dept_name` is unique so we
never accidentally create two "Cardiology" rows.

**Why it matters:** it's the anchor for revenue-by-department reporting
(`V_DEPT_REVENUE`) and for the doctor/staff FK relationships.

---

## 2. DOCTORS

The medical professionals working at the hospital. Each doctor has a
specialization (e.g. "Interventional Cardiologist"), an email (unique), a
salary (must be positive), and an ACTIVE/INACTIVE status so we can keep
historical records without showing retired doctors in active lists.

A trigger (`TRG_AUDIT_DOCTORS`) writes every INSERT/UPDATE/DELETE on this table
into `AUDIT_LOG`.

---

## 3. PATIENTS

People registered with the hospital. Demographics (gender with CHECK
constraint restricting to M/F/O, date of birth, blood group with CHECK
restricting to the 8 standard blood groups) plus contact info. A trigger
(`TRG_PATIENT_REGISTERED_AT`) auto-fills `registered_at = SYSDATE` if not
supplied.

A trigger (`TRG_AUDIT_PATIENTS`) audits all changes on this table.

---

## 4. APPOINTMENTS

The scheduling table — links a patient with a doctor at a particular date and
time. Status moves through `SCHEDULED → COMPLETED` or `SCHEDULED → CANCELLED`.

Key constraints:
- `UNIQUE(doctor_id, appt_date, appt_time)` — DB-level guard against double-booking.
- Trigger `TRG_APPT_STATUS_CHECK` blocks moving a CANCELLED appointment back to SCHEDULED.
- Trigger `TRG_AUTO_BILL_ON_COMPLETE` auto-creates a draft `BILLING` row when the
  status flips to COMPLETED.

---

## 5. MEDICAL_RECORDS

Clinical notes a doctor writes for a patient. Optionally linked back to the
appointment that triggered the visit. Stores diagnosis, a free-text
prescription summary, and notes. Each record can own many `PRESCRIPTIONS` rows
(line items), and those cascade-delete with the record.

---

## 6. PRESCRIPTIONS

Line items attached to a medical record — one per medicine. Each has a dosage,
frequency and duration (in days). `ON DELETE CASCADE` from `MEDICAL_RECORDS`
means deleting a record automatically cleans up its prescriptions.

---

## 7. BILLING

The invoice for a patient. Three fee columns (`consultation_fee`,
`medicine_fee`, `test_fee`) which a trigger (`TRG_BILL_TOTAL`) sums into
`total_amount` automatically — so the total is never out of sync. Payment
status is `PENDING` by default; `PROCESS_PAYMENT(p_bill_id)` flips it to `PAID`
and stamps `paid_date`. An appointment link is optional because some bills
(test-only, walk-in pharmacy) aren't tied to an appointment.

---

## 8. STAFF

Non-doctor employees of the hospital (nurses, lab technicians, receptionists,
admin, etc.). Structurally similar to `DOCTORS` but without the
specialization/appt relationships. Salary must be positive; email is unique;
status is ACTIVE/INACTIVE.

---

## 9. AUDIT_LOG

A generic audit table written by triggers on `DOCTORS` and `PATIENTS`. Each
row captures: which table, what operation (INSERT/UPDATE/DELETE), the row's
PK, the OLD and NEW row contents (as CLOBs), who changed it (`USER`) and when
(`SYSDATE`). It is intentionally not FK-linked to the live tables — once a
row is logged, it stays even if the source row is deleted.

---

## Sequences & keys

All surrogate PKs are populated from sequences (`DEPT_SEQ`, `DOCTOR_SEQ`,
`PATIENT_SEQ`, `APPT_SEQ`, `RECORD_SEQ`, `PRESCRIPTION_SEQ`, `BILL_SEQ`,
`STAFF_SEQ`, `AUDIT_SEQ`), each starting at 1000 with `INCREMENT BY 1 NOCACHE`.
NOCACHE is chosen for a teaching project (no gaps from cached values); in a
high-throughput production system you'd use a small cache instead.

---

## Naming conventions

| Object type | Prefix | Example |
|-------------|--------|---------|
| Table       | (none, plural noun) | `PATIENTS`, `BILLING` |
| Sequence    | `<TABLE>_SEQ`       | `PATIENT_SEQ` |
| Index       | `IDX_<TABLE>_<COL>` | `IDX_APPT_DATE` |
| View        | `V_<NAME>`          | `V_DEPT_REVENUE` |
| Procedure   | `<VERB>_<NOUN>`     | `BOOK_APPOINTMENT` |
| Function    | `FN_<NAME>`         | `FN_CALCULATE_AGE` |
| Trigger     | `TRG_<NAME>`        | `TRG_BILL_TOTAL` |
| Package     | `<DOMAIN>_PKG`      | `BILLING_PKG` |
| Synonym     | `SYN_<OBJECT>`      | `SYN_DOCTORS` |
