-- adverse_events.sql
SET search_path TO ct;

-- AE incidence by treatment arm
SELECT
    t.arm_name,
    COUNT(DISTINCT ae.patient_id) AS n_patients_with_ae,
    COUNT(DISTINCT p.patient_id)  AS total_patients,
    ROUND(
        100.0 * COUNT(DISTINCT ae.patient_id)
        / COUNT(DISTINCT p.patient_id),
        2
    ) AS ae_incidence_pct
FROM ct.patients p
JOIN ct.treatments t ON p.treatment_id = t.treatment_id
LEFT JOIN ct.adverse_events ae ON p.patient_id = ae.patient_id
GROUP BY t.arm_name
ORDER BY ae_incidence_pct DESC;

-- Number of events per patient (optional)
SELECT
    p.patient_id,
    t.arm_name,
    COUNT(ae.ae_id) AS n_events
FROM ct.patients p
JOIN ct.treatments t ON p.treatment_id = t.treatment_id
LEFT JOIN ct.adverse_events ae ON p.patient_id = ae.patient_id
GROUP BY p.patient_id, t.arm_name
ORDER BY n_events DESC, p.patient_id;
