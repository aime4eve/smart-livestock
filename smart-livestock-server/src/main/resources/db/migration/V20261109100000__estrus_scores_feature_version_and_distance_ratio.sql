-- Estrus scoring provenance columns (NIX-390 Task 1): the estrus_scores
-- table hosts two scoring semantics since NIX-380 — LEGACY (short-window
-- recent-3-vs-rest-4 relative ratios) and NORMALIZED-V2 (cross-event-window
-- level ratios against same-phase 24h-apart baselines). Until now both paths
-- wrote the same columns with different meanings, so readers could not tell
-- which formula produced a row.
--
-- feature_version disambiguates: NOT NULL DEFAULT 'LEGACY' backfills every
-- existing row to LEGACY (environments 86/223 have never received NIX-380,
-- so ALL pre-migration rows are legacy-semantics by construction; freshly
-- seeded demo rows also land on LEGACY). New rows carry the version stamped
-- by the scoring path ('LEGACY' or 'NORMALIZED-V2').
--
-- distance_ratio persists the normalized distance level ratio
-- (current-window mean / pooled baseline-window mean) on NORMALIZED rows so
-- the score can be recomputed exactly; NULL means distance did not
-- participate or the row is legacy-semantics.

ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS feature_version VARCHAR(16) NOT NULL DEFAULT 'LEGACY';
ALTER TABLE estrus_scores DROP CONSTRAINT IF EXISTS chk_estrus_scores_feature_version;
ALTER TABLE estrus_scores ADD CONSTRAINT chk_estrus_scores_feature_version
    CHECK (feature_version IN ('LEGACY','NORMALIZED-V2'));

ALTER TABLE estrus_scores
    ADD COLUMN IF NOT EXISTS distance_ratio DECIMAL(6,3);
