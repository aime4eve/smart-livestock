-- ============================================================
-- V4: Seed Data — platform_admin, demo tenant, owner, demo API key
-- ============================================================
-- All passwords are BCrypt-hashed (cost factor 10). Never store plaintext.
-- API key stores only SHA-256 hash; the plaintext is shown once at creation.

-- 1. Platform admin user (no tenant affiliation)
INSERT INTO users (username, password_hash, name, phone, role, tenant_id, is_active)
VALUES (
    'platform_admin',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    '平台管理员',
    '13800000000',
    'PLATFORM_ADMIN',
    NULL,
    TRUE
);

-- 2. Demo tenant (SAMPLE phase)
INSERT INTO tenants (id, name, contact_name, contact_phone, phase)
VALUES (1, 'Demo牧场', '张牧场', '13800138000', 'SAMPLE');

-- 3. Owner user (belongs to demo tenant)
INSERT INTO users (username, password_hash, name, phone, role, tenant_id, is_active)
VALUES (
    'owner',
    '$2a$10$dXJ3SW6G7P50lGmMQgel6uVktDQd7hF1R3vQAoLQLqQooARqQf9Ia',
    '张牧场',
    '13800138000',
    'OWNER',
    1,
    TRUE
);

-- 4. Demo farm for the demo tenant
INSERT INTO farms (id, tenant_id, name, latitude, longitude, area_hectares)
VALUES (1, 1, '主牧场', 28.2458000, 112.8519000, 500.00);

-- 5. Assign owner to the demo farm
INSERT INTO user_farm_assignments (user_id, farm_id, role, status)
SELECT u.id, f.id, 'OWNER', 'ACTIVE'
FROM users u, farms f
WHERE u.username = 'owner' AND f.name = '主牧场';

-- 6. Demo API key (bound to demo tenant)
-- Plaintext key (for documentation only, not used in production):
--   sl_test_dGhpcyBpcyBhIGRlbW8gYXBpIGtleSBmb3Igc2VlZCA=
-- SHA-256 hash stored below:
INSERT INTO api_keys (tenant_id, key_name, key_hash, key_prefix, status, expires_at)
VALUES (
    1,
    'Demo API Key',
    '67f3156d44802c1d7422ea2802c8bfce25e0f18bdcd54516d1c3defa2e82b45b',
    'sl_test_',
    'ACTIVE',
    '2027-12-31 23:59:59'
);

-- Reset sequences to avoid ID collisions after explicit ID inserts
SELECT setval('tenants_id_seq', (SELECT COALESCE(MAX(id), 1) FROM tenants));
SELECT setval('farms_id_seq', (SELECT COALESCE(MAX(id), 1) FROM farms));
