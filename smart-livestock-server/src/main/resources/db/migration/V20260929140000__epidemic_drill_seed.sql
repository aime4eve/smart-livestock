-- Epidemic drill seed for the contact-tracing workbench (Task 4).
--
-- Background: V31 seeded epidemic demo data by hardcoded livestock_code
-- 'SL-2024-048', which silently inserted 0 rows on databases where that code
-- does not exist (the migration "succeeded" while the workbench stayed empty).
-- This migration replaces that fragile approach:
--   * drill livestock are picked dynamically from the CURRENT farm 1 herd
--     (first 4 living livestock ordered by id — no hardcoded codes);
--   * idempotency: if any contact_traces row with disease_type='疫情演练'
--     already exists, the whole block is skipped (early RETURN);
--   * fail-loudly: the inserted row count is asserted afterwards, so a database
--     with a living herd can never end up silently empty again.
--
-- Data shape: livestock #1 (lowest living id) is the drill source with 3 marked
-- outgoing contact rows. Two extra UNMARKED rows model the standing analyzer's
-- contact pool (dual-track design: plain contact facts without epidemic
-- semantics — disease_type/marked_at stay NULL).

DO $$
DECLARE
    v_herd_size   INT;
    v_marked_rows INT := 0;
    v_pool_rows   INT := 0;
BEGIN
    -- Idempotency guard: drill rows already present -> skip entirely.
    IF EXISTS (SELECT 1 FROM contact_traces WHERE disease_type = '疫情演练') THEN
        RAISE NOTICE 'epidemic drill seed: drill rows already present, skipping';
        RETURN;
    END IF;

    -- Prerequisite check: fail loudly when farm 1 has no herd to build from,
    -- instead of silently inserting nothing.
    v_herd_size := (SELECT count(*) FROM livestock
                    WHERE farm_id = 1 AND deleted_at IS NULL);
    IF v_herd_size < 2 THEN
        RAISE EXCEPTION 'epidemic drill seed prerequisite not met: farm 1 has % living livestock, drill seed needs at least 2', v_herd_size;
    END IF;

    -- Marked drill rows: source = first living livestock (#1), contacts to
    -- #2..#4. Proximity/duration/risk follow the V31 seed conventions
    -- (3-8 m, 25-45 min, risk_score 55-82, MEDIUM/HIGH mixed); last_contact_at
    -- = now() - 3 hours with a small random offset (+/- 10 minutes).
    WITH herd AS (
        SELECT id, row_number() OVER (ORDER BY id) AS rn
        FROM livestock
        WHERE farm_id = 1 AND deleted_at IS NULL
        ORDER BY id
        LIMIT 4
    )
    INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id,
                                proximity_meters, contact_duration_minutes,
                                last_contact_at, disease_type, marked_at,
                                risk_score, risk_level)
    SELECT 1,
           s.id,
           t.id,
           CASE t.rn WHEN 2 THEN 3.0 + random() * 2.0   -- 3-5 m, closest
                     WHEN 3 THEN 5.0 + random() * 2.0   -- 5-7 m
                     ELSE 6.0 + random() * 2.0 END,     -- 6-8 m
           CASE t.rn WHEN 2 THEN 40 + (random() * 6)::int   -- 40-45 min
                     WHEN 3 THEN 30 + (random() * 6)::int   -- 30-35 min
                     ELSE 25 + (random() * 6)::int END,     -- 25-30 min
           (now() - interval '3 hours') + ((random() * 20 - 10) * interval '1 minute'),
           '疫情演练',
           now() - interval '2 hours',
           CASE t.rn WHEN 2 THEN 78 + (random() * 5)::int   -- 78-82
                     WHEN 3 THEN 63 + (random() * 6)::int   -- 63-68
                     ELSE 55 + (random() * 6)::int END,     -- 55-60
           CASE t.rn WHEN 2 THEN 'HIGH'
                     WHEN 3 THEN 'HIGH'
                     ELSE 'MEDIUM' END
    FROM herd s
    JOIN herd t ON t.rn IN (2, 3, 4)
    WHERE s.rn = 1;
    GET DIAGNOSTICS v_marked_rows = ROW_COUNT;

    -- Unmarked contact-pool rows (standing-track side of the dual-track
    -- design): plain contact facts between non-source livestock; disease_type
    -- and marked_at stay NULL.
    WITH herd AS (
        SELECT id, row_number() OVER (ORDER BY id) AS rn
        FROM livestock
        WHERE farm_id = 1 AND deleted_at IS NULL
        ORDER BY id
        LIMIT 4
    )
    INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id,
                                proximity_meters, contact_duration_minutes,
                                last_contact_at, disease_type, marked_at,
                                risk_score, risk_level)
    SELECT 1,
           a.id,
           b.id,
           4.0 + random() * 2.0,                           -- 4-6 m
           28 + (random() * 10)::int,                      -- 28-37 min
           CASE WHEN b.rn = 3
                THEN (now() - interval '5 hours') + ((random() * 20 - 10) * interval '1 minute')
                ELSE (now() - interval '26 hours') + ((random() * 20 - 10) * interval '1 minute') END,
           NULL,   -- disease_type: no epidemic semantics
           NULL,   -- marked_at
           CASE WHEN b.rn = 3 THEN 62 + (random() * 6)::int   -- 62-67
                ELSE 55 + (random() * 5)::int END,           -- 55-59
           'MEDIUM'
    FROM herd a
    JOIN herd b ON (a.rn, b.rn) IN ((2, 3), (3, 4));
    GET DIAGNOSTICS v_pool_rows = ROW_COUNT;

    -- Fail-loudly row-count assertion (core requirement): with a living herd
    -- present, the drill data must actually have landed.
    IF v_marked_rows + v_pool_rows < 5 THEN
        RAISE EXCEPTION 'epidemic drill seed inserted % rows, expected 5 (farm 1 livestock=%)',
            v_marked_rows + v_pool_rows, v_herd_size;
    END IF;

    RAISE NOTICE 'epidemic drill seed: % marked + % pool rows inserted for farm 1 (herd=%)',
        v_marked_rows, v_pool_rows, v_herd_size;
END $$;
