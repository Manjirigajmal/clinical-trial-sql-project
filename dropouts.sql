-- dropouts.sql
SET search_path TO ct;

SELECT
    t.arm_name,
    COUNT(*) FILTER (WHERE o.event_type = 'DROPOUT') AS dropouts,
    COUNT(*) AS total,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE o.event_type = 'DROPOUT') / COUNT(*),
        2
    ) AS dropout_rate_pct
FROM ct.outcomes o
JOIN ct.patients p  ON o.patient_id = p.patient_id
JOIN ct.treatments t ON p.treatment_id = t.treatment_id
GROUP BY t.arm_name
ORDER BY dropout_rate_pct DESC;
