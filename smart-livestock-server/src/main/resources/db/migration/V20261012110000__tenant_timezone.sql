-- Ruling 2026-10-12: timezone anchoring with a three-level priority chain —
--   farm timezone → tenant timezone → platform default timezone
-- (platform default via smartlivestock.timezone.default, defaulting to the
-- database server's timezone semantics; UTC out of the box). Storage stays
-- UTC everywhere; these columns are presentation/boundary only.
-- Existing rows default to NULL = "not set" = fall through the chain.

ALTER TABLE tenants ADD COLUMN timezone VARCHAR(64) NULL;
ALTER TABLE farms  ADD COLUMN timezone VARCHAR(64) NULL;

COMMENT ON COLUMN tenants.timezone IS 'IANA timezone; tenant-level anchor, NULL = inherit platform default';
COMMENT ON COLUMN farms.timezone   IS 'IANA timezone; farm-level anchor (highest priority), NULL = inherit tenant';
