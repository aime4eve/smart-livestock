-- Ruling 2026-10-14: tenant lifecycle — status (active/disabled, reversible)
-- and soft delete (deleted_at, recoverable). Business data is NEVER
-- physically removed: audit trail and history stay intact. Tenants without
-- business ties (e.g. dev test tenants) can be deleted directly — the
-- preconditions only block tenants with ACTIVE devices or a live
-- subscription.
-- The old PUT /status endpoint echoed without persisting; status now lands
-- here.

ALTER TABLE tenants ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE tenants ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'disabled'));

COMMENT ON COLUMN tenants.deleted_at IS 'soft delete marker; NULL = live, set = deleted (recoverable via restore endpoint)';
COMMENT ON COLUMN tenants.status IS 'active | disabled — login/API gate, reversible (the old PUT /status endpoint never persisted)';
