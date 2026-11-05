-- Simulation run registry + per-animal ground truth (plan 2026-11-05, Task 2:
-- literature-parameterized datagen herd simulator for baseline-evaluation and
-- calving-preparation rehearsal).
--
-- Additive-only migration: two NEW tables, no existing table, column or row is
-- touched. simulation_runs keeps the replayable generation parameters (seed +
-- JSONB params + window) so an evaluation run (Task 3) can be traced back to
-- its exact inputs. simulation_truth_baselines stores the generator-known true
-- baseline and event class per animal per run — the scoring anchor for
-- learned-baseline MAE/bias evaluation.
--
-- Note: params JSONB is written via JdbcTemplate with a ?::jsonb cast (no JPA
-- entity maps these tables; SimpleJdbcInsert does not support JSONB).

CREATE TABLE IF NOT EXISTS simulation_runs (
    id BIGSERIAL PRIMARY KEY,
    seed BIGINT NOT NULL,
    params JSONB NOT NULL,
    herd_size INTEGER NOT NULL,
    days INTEGER NOT NULL,
    created_by BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS simulation_truth_baselines (
    id BIGSERIAL PRIMARY KEY,
    run_id BIGINT NOT NULL REFERENCES simulation_runs(id),
    livestock_id BIGINT NOT NULL,
    true_baseline DECIMAL(5,2) NOT NULL,
    herd_class VARCHAR(12) NOT NULL
        CHECK (herd_class IN ('CLEAN','WATER','FEVER','ESTRUS','PREPARTUM','DETACHED')),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_simulation_truth_baselines_run_livestock UNIQUE (run_id, livestock_id)
);

CREATE INDEX IF NOT EXISTS idx_simulation_truth_baselines_run
    ON simulation_truth_baselines (run_id);
