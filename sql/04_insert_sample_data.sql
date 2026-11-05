-- =====================================================================
-- File:    04_insert_sample_data.sql
-- Purpose: Populate the HMS schema with realistic sample data.
--          5 departments, 8 doctors, 12 patients, 20 appointments,
--          15 medical records, 20 prescriptions, 15 bills, 6 staff.
-- Author:  HMS Project
-- Date:    2025
-- Notes:   - Uses explicit IDs starting at 1000 (matches seq START WITH).
--          - At the end, every sequence is advanced past MAX(id) so
--            subsequent procedure/trigger calls keep working.
--          - Appointment dates use SYSDATE arithmetic so the data is
--            always spread across the last 30 days regardless of when
--            the script is run.
-- =====================================================================

SET DEFINE OFF;

-- =====================================================================
-- 1. DEPARTMENTS (5)
-- =====================================================================
INSERT INTO departments (dept_id, dept_name, location, phone)
  VALUES (1000, 'Cardiology',        'Block A, Floor 1', '555-0101');
INSERT INTO departments (dept_id, dept_name, location, phone)
  VALUES (1001, 'Neurology',         'Block A, Floor 2', '555-0102');
INSERT INTO departments (dept_id, dept_name, location, phone)
  VALUES (1002, 'Orthopedics',       'Block B, Floor 1', '555-0103');
INSERT INTO departments (dept_id, dept_name, location, phone)
  VALUES (1003, 'Pediatrics',        'Block B, Floor 2', '555-0104');
INSERT INTO departments (dept_id, dept_name, location, phone)
  VALUES (1004, 'General Medicine',  'Block C, Floor 1', '555-0105');

-- =====================================================================
-- 2. DOCTORS (8) — spread across departments
-- =====================================================================
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1000, 'John',    'Smith',     'Interventional Cardiologist', 'john.smith@hms.com',    '555-2001', DATE '2015-06-01', 1000, 220000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1001, 'Emily',   'Davis',     'Cardiac Surgeon',             'emily.davis@hms.com',   '555-2002', DATE '2017-08-15', 1000, 250000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1002, 'Michael', 'Brown',     'Neurologist',                 'michael.brown@hms.com', '555-2003', DATE '2014-03-10', 1001, 210000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1003, 'Sarah',   'Wilson',    'Neurosurgeon',                'sarah.wilson@hms.com',  '555-2004', DATE '2018-11-20', 1001, 260000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1004, 'David',   'Lee',       'Orthopedic Surgeon',          'david.lee@hms.com',     '555-2005', DATE '2016-02-14', 1002, 215000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1005, 'Anna',    'Martinez',  'Sports Medicine',             'anna.martinez@hms.com', '555-2006', DATE '2019-09-05', 1002, 180000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1006, 'Robert',  'Clark',     'Pediatrician',                'robert.clark@hms.com',  '555-2007', DATE '2013-04-22', 1003, 195000, 'ACTIVE');
INSERT INTO doctors (doctor_id, first_name, last_name, specialization, email, phone, hire_date, dept_id, salary, status)
  VALUES (1007, 'Linda',   'Walker',    'General Physician',           'linda.walker@hms.com',  '555-2008', DATE '2020-01-30', 1004, 170000, 'INACTIVE');

-- =====================================================================
-- 3. PATIENTS (12) — varied demographics
-- =====================================================================
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1000, 'James',      'Anderson',  'M', DATE '1985-03-15', 'O+',  'james.anderson@email.com',    '555-3001', '12 Oak St, Springfield');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1001, 'Mary',       'Johnson',   'F', DATE '1990-07-22', 'A+',  'mary.johnson@email.com',      '555-3002', '45 Pine Ave, Springfield');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1002, 'Robert',     'Taylor',    'M', DATE '1978-11-30', 'B+',  'robert.taylor@email.com',     '555-3003', '78 Maple Rd, Shelbyville');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1003, 'Patricia',   'Moore',     'F', DATE '1995-02-10', 'AB+', 'patricia.moore@email.com',    '555-3004', '23 Cedar Ln, Capital City');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1004, 'Thomas',     'Thomas',    'M', DATE '2000-05-18', 'O-',  'thomas.thomas@email.com',     '555-3005', '56 Birch Blvd, Springfield');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1005, 'Jennifer',   'Jackson',   'F', DATE '1988-09-25', 'A-',  'jennifer.jackson@email.com',  '555-3006', '89 Elm Way, Capital City');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1006, 'Michael',    'White',     'M', DATE '1972-12-03', 'B-',  'michael.white@email.com',     '555-3007', '34 Walnut St, Shelbyville');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1007, 'Linda',      'Harris',    'F', DATE '2001-04-14', 'AB-', 'linda.harris@email.com',      '555-3008', '67 Spruce Ct, Springfield');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1008, 'Charles',    'Martin',    'M', DATE '1965-08-20', 'O+',  'charles.martin@email.com',    '555-3009', '90 Aspen Dr, Capital City');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1009, 'Elizabeth',  'Thompson',  'F', DATE '1993-06-08', 'A+',  'elizabeth.thompson@email.com','555-3010', '11 Poplar Pl, Springfield');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1010, 'Daniel',     'Garcia',    'M', DATE '1982-01-30', 'B+',  'daniel.garcia@email.com',     '555-3011', '24 Sycamore St, Shelbyville');
INSERT INTO patients (patient_id, first_name, last_name, gender, dob, blood_group, email, phone, address)
  VALUES (1011, 'Susan',      'Rodriguez', 'F', DATE '1997-10-12', 'O+',  'susan.rodriguez@email.com',   '555-3012', '35 Magnolia Ave, Capital City');

-- =====================================================================
-- 4. APPOINTMENTS (20) — spread over the last 30 days; mix of statuses
--    appt_time is HH24:MI; the (doctor_id, appt_date, appt_time) tuple is
--    unique, so no two rows collide on the same doctor+slot.
-- =====================================================================
-- Past COMPLETED (8) — each will have a medical record + a paid bill.
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1000, 1000, 1000, TRUNC(SYSDATE) - 30, '09:00', 'COMPLETED', 'Routine heart checkup');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1001, 1001, 1002, TRUNC(SYSDATE) - 28, '10:30', 'COMPLETED', 'Migraine consultation');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1002, 1002, 1004, TRUNC(SYSDATE) - 25, '14:00', 'COMPLETED', 'Knee pain assessment');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1003, 1003, 1006, TRUNC(SYSDATE) - 22, '11:00', 'COMPLETED', 'Child fever');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1004, 1004, 1007, TRUNC(SYSDATE) - 20, '15:30', 'COMPLETED', 'General checkup');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1005, 1005, 1003, TRUNC(SYSDATE) - 18, '09:30', 'COMPLETED', 'Lower back pain');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1006, 1006, 1005, TRUNC(SYSDATE) - 15, '13:00', 'COMPLETED', 'Sports injury follow-up');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1007, 1007, 1007, TRUNC(SYSDATE) - 12, '16:00', 'COMPLETED', 'Flu symptoms');
-- Past CANCELLED (3)
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1008, 1008, 1002, TRUNC(SYSDATE) - 10, '11:00', 'CANCELLED', 'Headache review (patient cancelled)');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1009, 1009, 1001, TRUNC(SYSDATE) - 8,  '09:00', 'CANCELLED', 'ECG (cancelled)');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1010, 1010, 1003, TRUNC(SYSDATE) - 5,  '14:30', 'CANCELLED', 'Consultation (cancelled)');
-- Past COMPLETED (4) more, for extra records/bills
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1011, 1008, 1000, TRUNC(SYSDATE) - 7,  '10:00', 'COMPLETED', 'Chest pain evaluation');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1012, 1009, 1006, TRUNC(SYSDATE) - 6,  '11:30', 'COMPLETED', 'Routine vaccination');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1013, 1010, 1004, TRUNC(SYSDATE) - 4,  '15:00', 'COMPLETED', 'Wrist fracture follow-up');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1014, 1011, 1007, TRUNC(SYSDATE) - 3,  '09:00', 'COMPLETED', 'Allergy testing');
-- Upcoming SCHEDULED (5) — today and the next few days
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1015, 1000, 1000, TRUNC(SYSDATE),      '10:00', 'SCHEDULED', 'Follow-up ECG');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1016, 1001, 1002, TRUNC(SYSDATE) + 1,  '11:00', 'SCHEDULED', 'MRI review');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1017, 1002, 1004, TRUNC(SYSDATE) + 2,  '14:00', 'SCHEDULED', 'Post-op check');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1018, 1003, 1006, TRUNC(SYSDATE) + 3,  '09:30', 'SCHEDULED', 'Wellness visit');
INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, appt_time, status, reason)
  VALUES (1019, 1004, 1007, TRUNC(SYSDATE) + 5,  '13:30', 'SCHEDULED', 'Annual checkup');

-- =====================================================================
-- 5. MEDICAL_RECORDS (15) — 12 linked to appointments, 3 standalone
-- =====================================================================
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1000, 1000, 1000, 1000, 'Hypertension',              'Lisinopril 10mg',           'BP 145/92; advised low-sodium diet');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1001, 1001, 1002, 1001, 'Migraine',                  'Sumatriptan 50mg',          'Triggered by stress; 4-5 episodes per month');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1002, 1002, 1004, 1002, 'Patellar tendinitis',       'Ibuprofen 600mg',           'Rest and ice; review in 2 weeks');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1003, 1003, 1006, 1003, 'Viral fever',               'Paracetamol 500mg',         'Temperature 39C; hydrate and rest');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1004, 1004, 1007, 1004, 'Common cold',               'Cetirizine 10mg',           'Symptomatic; 5-day course');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1005, 1005, 1003, 1005, 'Lumbar strain',             'Cyclobenzaprine 5mg',       'Avoid heavy lifting; physical therapy recommended');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1006, 1006, 1005, 1006, 'Sprained ankle',            'Naproxen 250mg',            'Grade 2 sprain; R.I.C.E. protocol');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1007, 1007, 1007, 1007, 'Influenza',                 'Oseltamivir 75mg',          'Started within 48h of onset');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1008, 1008, 1000, 1011, 'Stable angina',             'Nitroglycerin 0.4mg',       'ECG normal; referred for stress test');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1009, 1009, 1006, 1012, 'Routine vaccination',       'None',                      'Annual flu shot administered');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1010, 1010, 1004, 1013, 'Wrist fracture healing',    'Calcium supplement',        'X-ray shows callus formation; continue cast');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1011, 1011, 1007, 1014, 'Seasonal allergic rhinitis','Cetirizine 10mg',           'Pollen sensitivity confirmed');
-- Three standalone records (no appointment link)
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1012, 1000, 1000, NULL, 'Hypertension follow-up',    'Continue Lisinopril',       'BP 130/85; well controlled');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1013, 1005, 1003, NULL, 'Chronic back pain',         'Physical therapy',          'MRI shows mild disc bulge at L4-L5');
INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, prescription, notes)
  VALUES (1014, 1008, 1000, NULL, 'Stable angina follow-up',   'Continue current meds',     'No new chest pain; stress test negative');

-- =====================================================================
-- 6. PRESCRIPTIONS (20) — mix of 1 and 2 per record
--    Records 1000, 1001, 1003, 1008, 1010 have 2 prescriptions;
--    the remaining 10 records have 1 each = 20 total.
-- =====================================================================
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1000, 1000, 'Lisinopril',   '10 mg',   'Once daily',      30);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1001, 1000, 'Aspirin',      '81 mg',   'Once daily',      30);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1002, 1001, 'Sumatriptan',  '50 mg',   'As needed',       10);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1003, 1001, 'Propranolol',  '20 mg',   'Twice daily',     14);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1004, 1002, 'Ibuprofen',    '600 mg',  'Three times daily', 7);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1005, 1003, 'Paracetamol',  '500 mg',  'Four times daily', 5);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1006, 1003, 'Vitamin C',    '500 mg',  'Once daily',      14);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1007, 1004, 'Cetirizine',   '10 mg',   'Once daily',       5);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1008, 1005, 'Cyclobenzaprine','5 mg',  'At bedtime',      10);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1009, 1006, 'Naproxen',     '250 mg',  'Twice daily',     10);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1010, 1007, 'Oseltamivir',  '75 mg',   'Twice daily',      5);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1011, 1008, 'Nitroglycerin','0.4 mg',  'As needed',       30);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1012, 1008, 'Atorvastatin', '20 mg',   'Once daily',      30);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1013, 1009, 'Paracetamol',  '250 mg',  'As needed',        5);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1014, 1010, 'Calcium',      '1000 mg', 'Once daily',      60);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1015, 1010, 'Vitamin D',    '1000 IU', 'Once daily',      60);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1016, 1011, 'Cetirizine',   '10 mg',   'Once daily',      30);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1017, 1012, 'Lisinopril',   '10 mg',   'Once daily',      30);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1018, 1013, 'Ibuprofen',    '400 mg',  'Three times daily',14);
INSERT INTO prescriptions (prescription_id, record_id, medicine_name, dosage, frequency, duration_days) VALUES (1019, 1014, 'Aspirin',      '81 mg',   'Once daily',      30);

-- =====================================================================
-- 7. BILLING (15) — 9 PAID, 5 PENDING, 1 CANCELLED
--    total_amount is intentionally NOT supplied; the BEFORE INSERT trigger
--    TRG_BILL_TOTAL will compute it from the three fee columns.
-- =====================================================================
-- PAID bills (9) — all linked to COMPLETED appointments.
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1000, 1000, 1000, TRUNC(SYSDATE) - 30, 200, 50,  100, 'PAID', TRUNC(SYSDATE) - 29);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1001, 1001, 1001, TRUNC(SYSDATE) - 28, 250, 80,  150, 'PAID', TRUNC(SYSDATE) - 27);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1002, 1002, 1002, TRUNC(SYSDATE) - 25, 200, 40,  200, 'PAID', TRUNC(SYSDATE) - 24);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1003, 1003, 1003, TRUNC(SYSDATE) - 22, 150, 30,  50,  'PAID', TRUNC(SYSDATE) - 21);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1004, 1004, 1004, TRUNC(SYSDATE) - 20, 100, 20,  0,   'PAID', TRUNC(SYSDATE) - 19);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1005, 1005, 1005, TRUNC(SYSDATE) - 18, 300, 60,  300, 'PAID', TRUNC(SYSDATE) - 17);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1006, 1006, 1006, TRUNC(SYSDATE) - 15, 200, 50,  150, 'PAID', TRUNC(SYSDATE) - 14);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1007, 1007, 1007, TRUNC(SYSDATE) - 12, 150, 100, 50,  'PAID', TRUNC(SYSDATE) - 11);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1008, 1008, 1011, TRUNC(SYSDATE) - 7,  500, 120, 400, 'PAID', TRUNC(SYSDATE) - 6);
-- PENDING bills (5)
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1009, 1009, 1012, TRUNC(SYSDATE) - 6,  100, 0,   50,  'PENDING', NULL);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1010, 1010, 1013, TRUNC(SYSDATE) - 4,  200, 80,  200, 'PENDING', NULL);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1011, 1011, 1014, TRUNC(SYSDATE) - 3,  100, 40,  0,   'PENDING', NULL);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1012, 1000, NULL, TRUNC(SYSDATE) - 2,  100, 50,  200, 'PENDING', NULL);
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1013, 1005, NULL, TRUNC(SYSDATE) - 1,  150, 30,  0,   'PENDING', NULL);
-- CANCELLED bill (1)
INSERT INTO billing (bill_id, patient_id, appt_id, bill_date, consultation_fee, medicine_fee, test_fee, payment_status, paid_date)
  VALUES (1014, 1008, NULL, TRUNC(SYSDATE) - 1,  200, 0,   0,   'CANCELLED', NULL);

-- =====================================================================
-- 8. STAFF (6) — across departments
-- =====================================================================
INSERT INTO staff (staff_id, first_name, last_name, role, dept_id, phone, email, hire_date, salary, status)
  VALUES (1000, 'Karen',  'Adams',   'Nurse',           1000, '555-4001', 'karen.adams@hms.com',   DATE '2016-05-12', 65000, 'ACTIVE');
INSERT INTO staff (staff_id, first_name, last_name, role, dept_id, phone, email, hire_date, salary, status)
  VALUES (1001, 'Mark',   'Baker',   'Receptionist',    1004, '555-4002', 'mark.baker@hms.com',    DATE '2019-02-18', 45000, 'ACTIVE');
INSERT INTO staff (staff_id, first_name, last_name, role, dept_id, phone, email, hire_date, salary, status)
  VALUES (1002, 'Lisa',   'Chen',    'Lab Technician',  1002, '555-4003', 'lisa.chen@hms.com',     DATE '2017-09-01', 55000, 'ACTIVE');
INSERT INTO staff (staff_id, first_name, last_name, role, dept_id, phone, email, hire_date, salary, status)
  VALUES (1003, 'James',  'Evans',   'Nurse',           1001, '555-4004', 'james.evans@hms.com',   DATE '2018-06-15', 62000, 'ACTIVE');
INSERT INTO staff (staff_id, first_name, last_name, role, dept_id, phone, email, hire_date, salary, status)
  VALUES (1004, 'Nina',   'Patel',   'Ward Assistant',  1003, '555-4005', 'nina.patel@hms.com',    DATE '2021-03-22', 35000, 'ACTIVE');
INSERT INTO staff (staff_id, first_name, last_name, role, dept_id, phone, email, hire_date, salary, status)
  VALUES (1005, 'George', 'Hill',    'Admin',           1004, '555-4006', 'george.hill@hms.com',   DATE '2015-10-10', 70000, 'ACTIVE');

COMMIT;

-- =====================================================================
-- Sync sequences past MAX(id) so subsequent inserts via procedures
-- and triggers do not collide with the sample data IDs.
-- Algorithm: ALTER INCREMENT BY (max - 999), call NEXTVAL once (returns max),
--            then ALTER INCREMENT BY 1 to restore the default step.
-- =====================================================================
DECLARE
  v_max  NUMBER;
  v_step NUMBER;
  v_dummy NUMBER;
BEGIN
  -- DEPT_SEQ
  SELECT NVL(MAX(dept_id), 999) INTO v_max FROM departments;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE dept_seq INCREMENT BY ' || v_step;
    SELECT dept_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE dept_seq INCREMENT BY 1';
  END IF;

  -- DOCTOR_SEQ
  SELECT NVL(MAX(doctor_id), 999) INTO v_max FROM doctors;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE doctor_seq INCREMENT BY ' || v_step;
    SELECT doctor_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE doctor_seq INCREMENT BY 1';
  END IF;

  -- PATIENT_SEQ
  SELECT NVL(MAX(patient_id), 999) INTO v_max FROM patients;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE patient_seq INCREMENT BY ' || v_step;
    SELECT patient_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE patient_seq INCREMENT BY 1';
  END IF;

  -- APPT_SEQ
  SELECT NVL(MAX(appt_id), 999) INTO v_max FROM appointments;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE appt_seq INCREMENT BY ' || v_step;
    SELECT appt_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE appt_seq INCREMENT BY 1';
  END IF;

  -- RECORD_SEQ
  SELECT NVL(MAX(record_id), 999) INTO v_max FROM medical_records;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE record_seq INCREMENT BY ' || v_step;
    SELECT record_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE record_seq INCREMENT BY 1';
  END IF;

  -- PRESCRIPTION_SEQ
  SELECT NVL(MAX(prescription_id), 999) INTO v_max FROM prescriptions;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE prescription_seq INCREMENT BY ' || v_step;
    SELECT prescription_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE prescription_seq INCREMENT BY 1';
  END IF;

  -- BILL_SEQ
  SELECT NVL(MAX(bill_id), 999) INTO v_max FROM billing;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE bill_seq INCREMENT BY ' || v_step;
    SELECT bill_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE bill_seq INCREMENT BY 1';
  END IF;

  -- STAFF_SEQ
  SELECT NVL(MAX(staff_id), 999) INTO v_max FROM staff;
  v_step := v_max - 999;
  IF v_step > 0 THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE staff_seq INCREMENT BY ' || v_step;
    SELECT staff_seq.NEXTVAL INTO v_dummy FROM dual;
    EXECUTE IMMEDIATE 'ALTER SEQUENCE staff_seq INCREMENT BY 1';
  END IF;
END;
/

PROMPT Sample data loaded and sequences synchronized.
