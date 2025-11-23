

SET search_path TO ct;

-------------------------------------------------
-- 1. Populate sites
-------------------------------------------------
INSERT INTO ct.sites (site_id, site_code, site_name, country, city)
SELECT DISTINCT
    r.site_id,
    'SITE' || r.site_id::text    AS site_code,
    'Site ' || r.site_id::text   AS site_name,
    NULL::VARCHAR(100)           AS country,
    NULL::VARCHAR(100)           AS city
FROM ct.trial_raw r
WHERE r.site_id IS NOT NULL
ON CONFLICT (site_id) DO NOTHING;

-------------------------------------------------
-- 2. Populate treatments
-------------------------------------------------
DELETE FROM ct.treatments;

INSERT INTO ct.treatments (arm_name, dose_mg, frequency, route)
SELECT DISTINCT
    TRIM(treatment_group) AS arm_name,
    NULL::NUMERIC(6,2)    AS dose_mg,
    NULL::VARCHAR(50)     AS frequency,
    NULL::VARCHAR(50)     AS route
FROM ct.trial_raw
WHERE treatment_group IS NOT NULL;

-------------------------------------------------
-- 3. Populate patients
-------------------------------------------------
TRUNCATE TABLE ct.outcomes, ct.adverse_events, ct.visits, ct.patients
RESTART IDENTITY CASCADE;

INSERT INTO ct.patients (
    patient_id,
    site_id,
    treatment_id,
    sex,
    age_years,
    bmi,
    baseline_sbp,
    baseline_dbp,
    baseline_cholesterol,
    enrollment_date,
    inclusion_flag
)
SELECT
    r.subject_id                 AS patient_id,
    r.site_id                    AS site_id,
    t.treatment_id,
    r.gender                     AS sex,
    r.age                        AS age_years,
    NULL::NUMERIC(5,2)           AS bmi,
    r.systolic_bp                AS baseline_sbp,
    r.diastolic_bp               AS baseline_dbp,
    r.cholesterol_level          AS baseline_cholesterol,
    CASE
        WHEN r.enrollment_date ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN to_date(r.enrollment_date, 'MM/DD/YYYY')
        ELSE to_date(r.enrollment_date, 'MM/DD/YY')
    END                          AS enrollment_date,
    TRUE                         AS inclusion_flag
FROM ct.trial_raw r
JOIN ct.treatments t
  ON TRIM(r.treatment_group) = TRIM(t.arm_name);

-------------------------------------------------
-- 4. Populate baseline visits (visit 0)
-------------------------------------------------
INSERT INTO ct.visits (
    patient_id,
    visit_number,
    visit_date,
    cycle_number,
    sbp,
    dbp,
    dose_taken_mg,
    adherence_pct
)
SELECT
    r.subject_id AS patient_id,
    0            AS visit_number,
    CASE
        WHEN r.enrollment_date ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN to_date(r.enrollment_date, 'MM/DD/YYYY')
        ELSE to_date(r.enrollment_date, 'MM/DD/YY')
    END          AS visit_date,
    0            AS cycle_number,
    r.systolic_bp AS sbp,
    r.diastolic_bp AS dbp,
    NULL::NUMERIC(6,2),
    NULL::NUMERIC(5,2)
FROM ct.trial_raw r;

-------------------------------------------------
-- 5. Populate adverse events
-------------------------------------------------
INSERT INTO ct.adverse_events (
    patient_id,
    ae_term,
    ae_category,
    seriousness,
    severity_grade,
    related_to_drug,
    ae_start_date,
    ae_end_date
)
SELECT
    r.subject_id,
    'Any Adverse Event' AS ae_term,
    NULL::VARCHAR(100)  AS ae_category,
    'Non-serious'       AS seriousness,
    CASE
        WHEN r.adverse_events > 3 THEN 3
        WHEN r.adverse_events > 0 THEN r.adverse_events
        ELSE 0
    END                 AS severity_grade,
    NULL::BOOLEAN       AS related_to_drug,
    CASE
        WHEN r.enrollment_date ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN to_date(r.enrollment_date, 'MM/DD/YYYY')
        ELSE to_date(r.enrollment_date, 'MM/DD/YY')
    END                 AS ae_start_date,
    NULL::DATE          AS ae_end_date
FROM ct.trial_raw r
WHERE r.adverse_events > 0;

-------------------------------------------------
-- 6. Populate outcomes (event-free survival style)
-------------------------------------------------
INSERT INTO ct.outcomes (
    patient_id,
    randomization_date,
    last_followup_date,
    event_type,
    event_date,
    censored_flag
)
SELECT
    r.subject_id,
    d AS randomization_date,
    d AS last_followup_date,
    CASE
        WHEN r.dropout = 1 THEN 'DROPOUT'
        WHEN r.adverse_events > 0 THEN 'AE_ONLY'
        ELSE 'NONE'
    END AS event_type,
    CASE
        WHEN r.dropout = 1 OR r.adverse_events > 0 THEN d
        ELSE NULL
    END AS event_date,
    CASE
        WHEN r.dropout = 1 OR r.adverse_events > 0 THEN FALSE
        ELSE TRUE
    END AS censored_flag
FROM (
    SELECT
        subject_id,
        adverse_events,
        dropout,
        CASE
            WHEN enrollment_date ~ '^\d{1,2}/\d{1,2}/\d{4}$'
                THEN to_date(enrollment_date, 'MM/DD/YYYY')
            ELSE to_date(enrollment_date, 'MM/DD/YY')
        END AS d
    FROM ct.trial_raw
) r;
