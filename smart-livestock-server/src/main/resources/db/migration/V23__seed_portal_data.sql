-- ============================================================
-- V23: Seed data for Analytics + API Portal
-- ============================================================

-- 1. Update existing Demo API Key with portal fields (idempotent)
UPDATE api_keys SET
    scopes = COALESCE(scopes, 'livestock:read,fence:read,alert:read,device:read,gps:read'),
    requests_per_minute = COALESCE(requests_per_minute, 60),
    daily_quota = COALESCE(daily_quota, 5000),
    role = COALESCE(role, 'api_consumer')
WHERE key_prefix = 'sl_test_' AND key_name = 'Demo API Key';

-- 2. Insert test developer key (SHA-256 hash, idempotent via ON CONFLICT)
-- rawKey = sl_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
-- Use via: X-API-Key: sl_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
INSERT INTO api_keys (tenant_id, key_name, key_hash, key_prefix, status, role, scopes, requests_per_minute, daily_quota, description, created_at)
VALUES (
    1,
    '测试开发者 Key',
    'b7b4a29466f1fe2acae6af5121bc0cbb48dc9d2e476e65d309d0c597947e175b',
    'sl_live_a1b2',
    'ACTIVE',
    'api_consumer',
    'livestock:read,fence:read,alert:read,device:read,gps:read,health:read',
    60,
    10000,
    'Phase 2c dev test key — use X-API-Key header',
    NOW()
)
ON CONFLICT (key_hash) DO NOTHING;
