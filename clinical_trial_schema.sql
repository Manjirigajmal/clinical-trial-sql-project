-- clinical_trial_schema.sql
-- Run this after connecting to your database (clinical_trial_db)

-- Optional: create DB (or do it from pgAdmin)
-- CREATE DATABASE clinical_trial_db;

-- Create schema for project
CREATE SCHEMA IF NOT EXISTS ct;
SET search_path TO ct;

-- 1. Trial sites
CREATE TABLE IF NOT EXISTS ct.sites (
    site_id     INT PRIMARY KEY,
    site_code   VARCHAR(20) UNIQUE,
    site_name   VARCHAR(200) NOT NULL,
    country     VARCHAR(100),
    city        VARCHAR(100)
);

-- 2. Treatment arms
CREATE TABLE IF NOT EXISTS ct.treatments (
    treatment_id  SERIAL PRIMARY KEY,
    arm_name      VARCHAR(50) UNIQUE NOT NULL,
    dose_mg       NUMERIC(6,2),
    frequency     VARCHAR(50),
    route         VARCHAR(50)
);

-- 3. Patients
CREATE TABLE IF NOT EXISTS ct.patients (
    patient_id           INT PRIMARY KEY,
    site_id              INT REFERENCES ct.sites(site_id),
    treatment_id         INT REFERENCES ct.treatments(treatment_id),
    sex                  VARCHAR(10),
    age_years            INT,
    bmi                  NUMERIC(5,2),
    baseline_sbp         INT,
    baseline_dbp         INT,
    baseline_cholesterol INT,
    enrollment_date      DATE NOT NULL,
    inclusion_flag       BOOLEAN DEFAULT TRUE
);

-- 4. Visits
CREATE TABLE IF NOT EXISTS ct.visits (
    visit_id        SERIAL PRIMARY KEY,
    patient_id      INT NOT NULL REFERENCES ct.patients(patient_id),
    visit_number    INT,
    visit_date      DATE NOT NULL,
    cycle_number    INT,
    sbp             INT,
    dbp             INT,
    dose_taken_mg   NUMERIC(6,2),
    adherence_pct   NUMERIC(5,2)
);

-- 5. Adverse events
CREATE TABLE IF NOT EXISTS ct.adverse_events (
    ae_id           SERIAL PRIMARY KEY,
    patient_id      INT NOT NULL REFERENCES ct.patients(patient_id),
    ae_term         VARCHAR(255) NOT NULL,
    ae_category     VARCHAR(100),
    seriousness     VARCHAR(50),
    severity_grade  INT,
    related_to_drug BOOLEAN,
    ae_start_date   DATE NOT NULL,
    ae_end_date     DATE
);

-- 6. Outcomes (for event-free survival style analysis)
CREATE TABLE IF NOT EXISTS ct.outcomes (
    patient_id          INT PRIMARY KEY REFERENCES ct.patients(patient_id),
    randomization_date  DATE NOT NULL,
    last_followup_date  DATE NOT NULL,
    event_type          VARCHAR(50),
    event_date          DATE,
    censored_flag       BOOLEAN
);
