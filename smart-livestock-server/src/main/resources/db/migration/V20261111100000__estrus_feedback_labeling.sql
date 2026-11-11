-- NIX-286 P2 Task 1 — estrus confirmation feedback labeling (data contract v2).
--
-- This migration collects AUDITABLE HUMAN VERDICTS on candidate estrus
-- alerts; it does NOT manufacture physiological facts. Two storage changes:
--
--   1. physiology_events gains the audit-only event type ESTRUS_CONFIRM
--      (always written with source=ALERT_CONFIRM, ref_id=alert id). It is
--      history only: it never participates in lactation/dry stage derivation
--      (PhysiologyQueryService.STAGE_TYPES stays CALVING/DRY_OFF — the new
--      enum value is outside that list by construction) and must not surface
--      in the physiology record-card list.
--   2. ground_truth_labels gains a verdict lifecycle (verdict) and the alert
--      reference (ref_alert_id) so one candidate alert maps to exactly one
--      effective human ruling.
--
-- contract v2 semantics (why verdict is NOT a ScenarioType):
--   * ScenarioType classifies WHAT a label window claims (the pattern
--     taxonomy the evaluation alignment reads); verdict records the human
--     ruling ON that claim (CONFIRMED / REJECTED / SUPERSEDED). Folding the
--     lifecycle into the pattern enum would corrupt the pattern column
--     semantics and every evaluation window built on it.
--   * Episode window: the label period is the merged >=70-score episode
--     (EstrusSeriesReplayer.mergeEpisodes — consecutive high-score positions
--     with gaps <= 24h belong to one episode) that covers the alert instant,
--     or the nearest episode whose end does not trail the alert instant by
--     more than the 24h merge gap; if no episode restores, the period
--     collapses to the point window [alert.createdAt, alert.createdAt].
--   * BREEDING_DERIVED labels (verdict = NULL) are weak evidence auto-derived
--     from a breeding record (window: breedingAt - 48h .. breedingAt, anchored
--     on occurred_at because breeding may be backdated). Their weight in
--     calibration must NOT be treated as equal to MANUAL verdicts.
--
-- Partial unique indexes enforce: one ESTRUS_CONFIRM audit row per
-- (livestock, alert) and one effective (CONFIRMED/REJECTED) verdict per
-- alert. SUPERSEDED rows (superseded rulings) and verdict-NULL rows
-- (BREEDING_DERIVED) stay unrestricted.
--
-- Rollback contract: additive-only — no existing row or column value is
-- rewritten. Rolling back means dropping the two partial indexes, restoring
-- the previous CHECKs (without the appended values) and dropping verdict /
-- ref_alert_id.

-- physiology_events: extend the event-type CHECK with ESTRUS_CONFIRM. The
-- inline unnamed CHECK of V20261004120000 resolves to the PostgreSQL
-- generated name below; DROP-then-ADD mirrors the V20261104100000 style.
ALTER TABLE physiology_events DROP CONSTRAINT IF EXISTS physiology_events_event_type_check;
ALTER TABLE physiology_events ADD CONSTRAINT physiology_events_event_type_check
    CHECK (event_type IN ('CALVING','BREEDING','PREGNANCY_CHECK','DRY_OFF','ILLNESS','RECOVERY','ESTRUS_CONFIRM'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_physiology_alert_confirm
    ON physiology_events (livestock_id, ref_id)
    WHERE source = 'ALERT_CONFIRM' AND event_type = 'ESTRUS_CONFIRM' AND ref_id IS NOT NULL;

-- ground_truth_labels: verdict lifecycle + alert reference. Nullable by
-- design — legacy rows and BREEDING_DERIVED rows carry no verdict.
ALTER TABLE ground_truth_labels ADD COLUMN IF NOT EXISTS verdict VARCHAR(16);
ALTER TABLE ground_truth_labels DROP CONSTRAINT IF EXISTS chk_gt_labels_verdict;
ALTER TABLE ground_truth_labels ADD CONSTRAINT chk_gt_labels_verdict
    CHECK (verdict IN ('CONFIRMED','REJECTED','SUPERSEDED'));
ALTER TABLE ground_truth_labels ADD COLUMN IF NOT EXISTS ref_alert_id BIGINT;

-- 'BREEDING_DERIVED' (16 chars) exceeds the original VARCHAR(10) width from
-- V38, so the source column is widened before the CHECK is rebuilt.
ALTER TABLE ground_truth_labels ALTER COLUMN source TYPE VARCHAR(24);
ALTER TABLE ground_truth_labels DROP CONSTRAINT IF EXISTS ground_truth_labels_source_check;
ALTER TABLE ground_truth_labels ADD CONSTRAINT ground_truth_labels_source_check
    CHECK (source IN ('SYNTHETIC','MANUAL','BREEDING_DERIVED'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_gt_labels_alert_active
    ON ground_truth_labels (ref_alert_id)
    WHERE ref_alert_id IS NOT NULL AND verdict IN ('CONFIRMED','REJECTED');
