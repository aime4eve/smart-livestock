-- Seed subscription_services for existing tenants so the admin
-- "subscription service management" page has verifiable data.
-- Each tenant gets one licensed service matching their subscription tier.
-- service_key_hash = sha256(raw_key); prefix = first 8 hex chars.

INSERT INTO subscription_services (
    tenant_id, service_name, service_key_prefix, service_key_hash,
    effective_tier, device_quota, status, started_at, expires_at,
    last_heartbeat_at, heartbeat_interval_hrs, grace_period_days
)
SELECT
    t.id,
    'GPS Tracking & Health Monitoring',
    '84f14317',
    '84f14317215daa0ee03131c879749ab7682ff73e4bbe1428d2d5fc2d477d13d0',
    COALESCE(LOWER(s.tier), 'premium'),
    50,
    'active',
    now() - interval '30 days',
    now() + interval '335 days',
    now() - interval '2 hours',
    24,
    7
FROM tenants t
LEFT JOIN LATERAL (
    SELECT tier FROM subscriptions WHERE tenant_id = t.id ORDER BY id DESC LIMIT 1
) s ON true
WHERE NOT EXISTS (
    SELECT 1 FROM subscription_services ss WHERE ss.tenant_id = t.id
)
AND LOWER(t.phase) = 'sample';
