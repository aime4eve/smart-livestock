-- Migration: seed_drinking_peer_comparison_gate
-- Date: 2026-10-05
-- Context: Health (NIX-256 Task 5a)

-- Premium gate for the drinking peer comparison endpoint
-- (GET /api/v1/farms/{farmId}/livestock/{livestockId}/drinking-peer-comparison).
-- Reuses the health-context subscription ACL (HealthSubscriptionPort ->
-- TenantContext -> subscriptions.effective_tier -> feature_gates), the same
-- mechanism and seed shape as V31 Part 6 (health_score / estrus_detect):
-- basic/standard locked, premium/enterprise open. Active trials resolve to
-- PREMIUM via Subscription.effectiveTier(), consistent with the other gates.
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    ('basic', 'drinking_peer_comparison', 'lock', NULL, NULL, FALSE),
    ('standard', 'drinking_peer_comparison', 'lock', NULL, NULL, FALSE),
    ('premium', 'drinking_peer_comparison', 'none', NULL, NULL, TRUE),
    ('enterprise', 'drinking_peer_comparison', 'none', NULL, NULL, TRUE)
ON CONFLICT (tier, feature_key) DO UPDATE SET
    gate_type = EXCLUDED.gate_type,
    limit_value = EXCLUDED.limit_value,
    retention_days = EXCLUDED.retention_days,
    is_enabled = EXCLUDED.is_enabled;
