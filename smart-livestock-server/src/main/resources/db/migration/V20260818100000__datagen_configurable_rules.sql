-- Farm-level configurable datagen rules. Defaults preserve the original
-- hardcoded demo behavior.
ALTER TABLE datagen_farm_controls
    ADD COLUMN IF NOT EXISTS tracker_interval_seconds INTEGER NOT NULL DEFAULT 300,
    ADD COLUMN IF NOT EXISTS capsule_interval_seconds INTEGER NOT NULL DEFAULT 900,
    ADD COLUMN IF NOT EXISTS fence_excursion_probability NUMERIC(6,5) NOT NULL DEFAULT 0.02000,
    ADD COLUMN IF NOT EXISTS fence_excursion_min_minutes INTEGER NOT NULL DEFAULT 10,
    ADD COLUMN IF NOT EXISTS fence_excursion_max_minutes INTEGER NOT NULL DEFAULT 30,
    ADD COLUMN IF NOT EXISTS health_event_probability NUMERIC(6,5) NOT NULL DEFAULT 0.00500,
    ADD COLUMN IF NOT EXISTS fever_duration_min_minutes INTEGER NOT NULL DEFAULT 240,
    ADD COLUMN IF NOT EXISTS fever_duration_max_minutes INTEGER NOT NULL DEFAULT 480,
    ADD COLUMN IF NOT EXISTS motility_duration_min_minutes INTEGER NOT NULL DEFAULT 480,
    ADD COLUMN IF NOT EXISTS motility_duration_max_minutes INTEGER NOT NULL DEFAULT 720;

ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_tracker_interval;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_tracker_interval
    CHECK (tracker_interval_seconds BETWEEN 60 AND 3600);
ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_capsule_interval;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_capsule_interval
    CHECK (capsule_interval_seconds BETWEEN 300 AND 7200);
ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_fence_probability;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_fence_probability
    CHECK (fence_excursion_probability BETWEEN 0 AND 0.2);
ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_fence_duration;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_fence_duration
    CHECK (fence_excursion_min_minutes BETWEEN 5 AND 120
       AND fence_excursion_max_minutes BETWEEN 5 AND 120
       AND fence_excursion_min_minutes <= fence_excursion_max_minutes);
ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_health_probability;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_health_probability
    CHECK (health_event_probability BETWEEN 0 AND 0.1);
ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_fever_duration;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_fever_duration
    CHECK (fever_duration_min_minutes BETWEEN 120 AND 1440
       AND fever_duration_max_minutes BETWEEN 120 AND 1440
       AND fever_duration_min_minutes <= fever_duration_max_minutes);
ALTER TABLE datagen_farm_controls DROP CONSTRAINT IF EXISTS chk_datagen_motility_duration;
ALTER TABLE datagen_farm_controls ADD CONSTRAINT chk_datagen_motility_duration
    CHECK (motility_duration_min_minutes BETWEEN 120 AND 1440
       AND motility_duration_max_minutes BETWEEN 120 AND 1440
       AND motility_duration_min_minutes <= motility_duration_max_minutes);
