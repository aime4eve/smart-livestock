-- Migration: seed_telemetry_export_gate
-- Date: 2026-10-26
-- Context: Open API P0 telemetry export endpoints (NIX-323)

-- Feature gate for the Open API telemetry history/export endpoints
-- (GET /api/v1/open/farms/{farmId}/livestock/{id}/telemetry and
--  GET /api/v1/open/farms/{farmId}/devices/{id}/telemetry).
--
-- Ruling 2026-10-26 (NIX-323): "degrade, don't reject" — every tier including
-- the basic fallback granted to expired tenants can export telemetry; tiers
-- differ in the queryable data window (retention_days) and the daily call
-- budget (limit_value, enforced in the application layer — NOT via
-- QuotaCheckService, whose isActiveOrTrial gate would reject expired tenants).
--
-- Seed shape follows V20261005110000 (drinking_peer_comparison gate):
-- active trials resolve to PREMIUM via Subscription.effectiveTier().
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('basic',      'telemetry_export', 'limit', 1000,   7, TRUE),
    ('standard',   'telemetry_export', 'limit', 10000, 30, TRUE),
    ('premium',    'telemetry_export', 'limit', 100000, 180, TRUE),
    ('enterprise', 'telemetry_export', 'none',  NULL,  365, TRUE)
ON CONFLICT (tier, feature_key) DO UPDATE SET
    gate_type = EXCLUDED.gate_type,
    limit_value = EXCLUDED.limit_value,
    retention_days = EXCLUDED.retention_days,
    is_enabled = EXCLUDED.is_enabled;
