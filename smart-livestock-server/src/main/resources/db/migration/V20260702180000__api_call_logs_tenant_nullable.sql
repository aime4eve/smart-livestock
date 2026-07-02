-- ============================================================
-- V40: Allow api_call_logs.tenant_id to be NULL
--   Auth endpoints (e.g., /auth/login) have no tenant context
--   at request time, but we still want to log these calls.
-- ============================================================

ALTER TABLE api_call_logs ALTER COLUMN tenant_id DROP NOT NULL;
