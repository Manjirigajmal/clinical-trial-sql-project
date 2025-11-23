

SET search_path TO ct;

DROP TABLE IF EXISTS ct.trial_raw;

CREATE TABLE ct.trial_raw (
    subject_id         INT,
    site_id            INT,
    age                INT,
    gender             TEXT,
    enrollment_date    TEXT,      -- keep as text, we parse later
    treatment_group    TEXT,
    adverse_events     INT,
    dropout            INT,
    systolic_bp        INT,
    diastolic_bp       INT,
    cholesterol_level  INT
);

