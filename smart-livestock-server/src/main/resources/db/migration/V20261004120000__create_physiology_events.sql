-- Migration: create_physiology_events
-- Date: 2026-10-04
-- Context: Health

-- NIX-256 Task 1a: manual physiology event stream (calving / breeding /
-- pregnancy check / dry off / illness / recovery). No ended_at column by
-- design: an illness window is closed by its paired RECOVERY event (stack
-- matching at read time). Dispositions are merged at read time and never
-- stored here.

CREATE TABLE physiology_events (
    id          BIGSERIAL PRIMARY KEY,
    livestock_id BIGINT NOT NULL REFERENCES livestock(id),
    event_type  VARCHAR(24) NOT NULL CHECK (event_type IN ('CALVING','BREEDING','PREGNANCY_CHECK','DRY_OFF','ILLNESS','RECOVERY')),
    occurred_at TIMESTAMP NOT NULL,
    source      VARCHAR(24) NOT NULL CHECK (source IN ('MANUAL','ALERT_CONFIRM')),
    ref_id      BIGINT,
    note        VARCHAR(500),
    created_by  BIGINT REFERENCES users(id),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_by  BIGINT REFERENCES users(id),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_physiology_events_livestock ON physiology_events (livestock_id, occurred_at DESC);
CREATE UNIQUE INDEX uq_physiology_manual_dup ON physiology_events (livestock_id, event_type, occurred_at, source) WHERE source = 'MANUAL';

-- Demo seed: two farm-1 cows calved 128 days ago so the physiology card
-- shows "lactating, day 128" as in the confirmed prototype. Idempotent:
-- skip when the animal already has any manual CALVING row.
INSERT INTO physiology_events (livestock_id, event_type, occurred_at, source)
SELECT ls.id, 'CALVING', NOW() - INTERVAL '128 days', 'MANUAL'
FROM livestock ls
WHERE ls.livestock_code = 'SL-2024-012' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM physiology_events pe
      WHERE pe.livestock_id = ls.id
        AND pe.event_type = 'CALVING'
        AND pe.source = 'MANUAL'
  );

INSERT INTO physiology_events (livestock_id, event_type, occurred_at, source)
SELECT ls.id, 'CALVING', NOW() - INTERVAL '128 days', 'MANUAL'
FROM livestock ls
WHERE ls.livestock_code = 'SL-2024-049' AND ls.farm_id = 1
  AND NOT EXISTS (
      SELECT 1 FROM physiology_events pe
      WHERE pe.livestock_id = ls.id
        AND pe.event_type = 'CALVING'
        AND pe.source = 'MANUAL'
  );
