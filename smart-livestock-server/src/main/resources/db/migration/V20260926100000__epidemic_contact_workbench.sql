-- Epidemic contact tracing workbench: importance-ranked disposition tasks

CREATE TABLE epidemic_dispositions (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT NOT NULL REFERENCES livestock(id),
    source_livestock_id BIGINT REFERENCES livestock(id),
    source_event_id BIGINT REFERENCES contact_traces(id),
    tier VARCHAR(20) NOT NULL,
    action_code VARCHAR(40) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reason_codes TEXT[] NOT NULL DEFAULT '{}',
    due_at TIMESTAMP,
    completed_at TIMESTAMP,
    completed_by BIGINT REFERENCES users(id),
    cancel_reason_code VARCHAR(40),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT epidemic_dispositions_tier_check
        CHECK (tier IN ('CRITICAL', 'OBSERVATION', 'TRACKING', 'ARCHIVE')),
    CONSTRAINT epidemic_dispositions_action_check
        CHECK (action_code IN (
            'ISOLATE_NOTIFY_VET', 'IMMEDIATE_VET_CHECK', 'HEALTH_RECHECK',
            'CONTINUE_TRACING', 'ARCHIVE_ONLY')),
    CONSTRAINT epidemic_dispositions_status_check
        CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
);

CREATE UNIQUE INDEX uq_epidemic_disposition_active_livestock
    ON epidemic_dispositions(farm_id, livestock_id)
    WHERE status IN ('PENDING', 'IN_PROGRESS');
CREATE INDEX idx_epidemic_disposition_farm_status_due
    ON epidemic_dispositions(farm_id, status, due_at);
CREATE INDEX idx_epidemic_disposition_livestock
    ON epidemic_dispositions(farm_id, livestock_id);
CREATE INDEX idx_epidemic_disposition_source
    ON epidemic_dispositions(source_livestock_id);

-- Stable demo evidence for the confirmed prototype. Existing seed rows stay
-- intact when their timestamps were refreshed by an earlier migration.
UPDATE contact_traces
SET last_contact_at = NOW() - INTERVAL '3 hours',
    risk_score = 82,
    risk_level = 'HIGH'
WHERE from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048' AND farm_id = 1)
  AND to_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-012' AND farm_id = 1);

INSERT INTO contact_traces (
    farm_id, from_livestock_id, to_livestock_id, proximity_meters,
    contact_duration_minutes, last_contact_at, disease_type, marked_at,
    risk_score, risk_level
)
SELECT 1, src.id, dst.id, 3.30, 18, NOW() - INTERVAL '12 minutes',
       '口蹄疫疑似', NOW() - INTERVAL '2 hours', 93, 'HIGH'
FROM livestock src
JOIN livestock dst ON dst.livestock_code = 'SL-2024-049' AND dst.farm_id = 1
WHERE src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM contact_traces ct
      WHERE ct.from_livestock_id = src.id
        AND ct.to_livestock_id = dst.id
        AND ct.last_contact_at > NOW() - INTERVAL '24 hours'
  );

INSERT INTO contact_traces (
    farm_id, from_livestock_id, to_livestock_id, proximity_meters,
    contact_duration_minutes, last_contact_at, disease_type, marked_at,
    risk_score, risk_level
)
SELECT 1, src.id, dst.id, 6.00, 11, NOW() - INTERVAL '18 minutes',
       '口蹄疫疑似', NOW() - INTERVAL '2 hours', 75, 'HIGH'
FROM livestock src
JOIN livestock dst ON dst.livestock_code = 'SL-2024-050' AND dst.farm_id = 1
WHERE src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM contact_traces ct
      WHERE ct.from_livestock_id = src.id
        AND ct.to_livestock_id = dst.id
        AND ct.last_contact_at > NOW() - INTERVAL '24 hours'
  );

INSERT INTO epidemic_dispositions (
    farm_id, livestock_id, source_livestock_id, source_event_id, tier,
    action_code, status, reason_codes, due_at
)
SELECT 1, ls.id, src.id, ct.id, 'CRITICAL', 'ISOLATE_NOTIFY_VET', 'PENDING',
       ARRAY['DIRECT_SOURCE', 'NEAR', 'LONG_DURATION', 'HEALTH_ABNORMAL'],
       NOW() + INTERVAL '2 hours'
FROM livestock ls
JOIN livestock src ON src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
LEFT JOIN LATERAL (
    SELECT ct.id
    FROM contact_traces ct
    WHERE ct.farm_id = 1 AND ct.from_livestock_id = src.id AND ct.to_livestock_id = ls.id
    ORDER BY ct.last_contact_at DESC
    LIMIT 1
) ct ON TRUE
WHERE ls.livestock_code = 'SL-2024-012' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM epidemic_dispositions ed
      WHERE ed.farm_id = 1 AND ed.livestock_id = ls.id
  );

INSERT INTO epidemic_dispositions (
    farm_id, livestock_id, source_livestock_id, source_event_id, tier,
    action_code, status, reason_codes, due_at
)
SELECT 1, ls.id, src.id, ct.id, 'CRITICAL', 'IMMEDIATE_VET_CHECK', 'PENDING',
       ARRAY['DIRECT_SOURCE', 'NEAR', 'LONG_DURATION'],
       NOW() + INTERVAL '4 hours'
FROM livestock ls
JOIN livestock src ON src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
LEFT JOIN LATERAL (
    SELECT ct.id
    FROM contact_traces ct
    WHERE ct.farm_id = 1 AND ct.from_livestock_id = src.id AND ct.to_livestock_id = ls.id
    ORDER BY ct.last_contact_at DESC
    LIMIT 1
) ct ON TRUE
WHERE ls.livestock_code = 'SL-2024-049' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM epidemic_dispositions ed
      WHERE ed.farm_id = 1 AND ed.livestock_id = ls.id
  );

INSERT INTO epidemic_dispositions (
    farm_id, livestock_id, source_livestock_id, source_event_id, tier,
    action_code, status, reason_codes, due_at
)
SELECT 1, ls.id, src.id, ct.id, 'OBSERVATION', 'HEALTH_RECHECK', 'PENDING',
       ARRAY['DIRECT_SOURCE', 'MODERATE_DISTANCE'],
       NOW() + INTERVAL '24 hours'
FROM livestock ls
JOIN livestock src ON src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
LEFT JOIN LATERAL (
    SELECT ct.id
    FROM contact_traces ct
    WHERE ct.farm_id = 1 AND ct.from_livestock_id = src.id AND ct.to_livestock_id = ls.id
    ORDER BY ct.last_contact_at DESC
    LIMIT 1
) ct ON TRUE
WHERE ls.livestock_code = 'SL-2024-050' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM epidemic_dispositions ed
      WHERE ed.farm_id = 1 AND ed.livestock_id = ls.id
  );

INSERT INTO epidemic_dispositions (
    farm_id, livestock_id, source_livestock_id, tier,
    action_code, status, reason_codes, due_at
)
SELECT 1, ls.id, src.id, 'TRACKING', 'CONTINUE_TRACING', 'PENDING',
       ARRAY['INDIRECT_OR_OLDER_CONTACT'],
       NOW() + INTERVAL '72 hours'
FROM livestock ls
JOIN livestock src ON src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
WHERE ls.livestock_code = 'SL-2024-004' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM epidemic_dispositions ed
      WHERE ed.farm_id = 1 AND ed.livestock_id = ls.id
  );

INSERT INTO epidemic_dispositions (
    farm_id, livestock_id, source_livestock_id, tier,
    action_code, status, reason_codes
)
SELECT 1, ls.id, src.id, 'ARCHIVE', 'ARCHIVE_ONLY', 'PENDING',
       ARRAY['LOW_RISK']
FROM livestock ls
JOIN livestock src ON src.livestock_code = 'SL-2024-048' AND src.farm_id = 1
WHERE ls.livestock_code = 'SL-2024-008' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM epidemic_dispositions ed
      WHERE ed.farm_id = 1 AND ed.livestock_id = ls.id
  );
