-- event_free_survival.sql
SET search_path TO ct;

-- Per-patient event-free days
SELECT
    o.patient_id,
    t.arm_name,
    o.event_type,
    o.censored_flag,
    (COALESCE(o.event_date, o.last_followup_date)
        - o.randomization_date)::INT AS event_free_days
FROM ct.outcomes o
JOIN ct.patients p  ON o.patient_id = p.patient_id
JOIN ct.treatments t ON p.treatment_id = t.treatment_id
ORDER BY event_free_days DESC;

-- Summary by treatment arm
WITH survival AS (
    SELECT
        t.arm_name,
        (COALESCE(o.event_date, o.last_followup_date)
            - o.randomization_date)::INT AS days,
        o.censored_flag
    FROM ct.outcomes o
    JOIN ct.patients p  ON o.patient_id = p.patient_id
    JOIN ct.treatments t ON p.treatment_id = t.treatment_id
)
SELECT
    arm_name,
    COUNT(*) AS n_patients,
    AVG(days) AS avg_event_free_days,
    MIN(days) AS min_event_free_days,
    MAX(days) AS max_event_free_days,
    COUNT(*) FILTER (WHERE censored_flag = FALSE) AS n_events,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE censored_flag = FALSE) / COUNT(*),
        2
    ) AS event_rate_pct
FROM survival
GROUP BY arm_name
ORDER BY avg_event_free_days DESC;
