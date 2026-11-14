-- Migration: fence_shape_and_role_validation
-- Date: 2026-11-14
-- Context: Ranch

-- NIX-410: the fences table carried two distinct concepts conflated under
-- one name. `fence_type` (V13) is the fence ROLE — 'sub' (herd sub-fence,
-- default) vs 'boundary' (farm boundary written by RanchCommandPortImpl);
-- the front-end fence SHAPE (polygon/circle/rectangle form state) was never
-- persisted anywhere. This migration:
--   1. adds `shape` for the persisted form shape (legacy rows are all
--      vertex polygons — rectangle/circle templates historically saved
--      their template vertices, indistinguishable now, so they migrate to
--      'polygon' with no visible regression), and
--   2. pins both value domains with CHECK constraints (the API previously
--      accepted any string into fence_type, e.g. a test's "GRASS").

ALTER TABLE fences ADD COLUMN IF NOT EXISTS shape VARCHAR(16) NOT NULL DEFAULT 'polygon';

ALTER TABLE fences DROP CONSTRAINT IF EXISTS chk_fences_fence_type;
ALTER TABLE fences ADD CONSTRAINT chk_fences_fence_type
    CHECK (fence_type IN ('sub', 'boundary'));

ALTER TABLE fences DROP CONSTRAINT IF EXISTS chk_fences_shape;
ALTER TABLE fences ADD CONSTRAINT chk_fences_shape
    CHECK (shape IN ('polygon', 'circle', 'rectangle'));
