-- ============================================================
-- V16: Seed b2b_admin and worker users for customer journey testing
-- All passwords are BCrypt-hashed '123' (cost factor 10).
-- Hashes generated and verified immediately via bcrypt.checkpw().
-- ============================================================

-- 1. b2b_admin user (B端管理员, associated with demo tenant)
-- Phone: 13900139000, Password: 123
-- Hash verified: bcrypt.checkpw('123', hash) → True
INSERT INTO users (password_hash, name, phone, role, tenant_id, is_active)
VALUES (
    '$2b$10$zf486dlhPR41LOE.Nt/QsuK3MWDYLLVLsAU1HNsZ.k7/HwDj.JMji',
    'B端管理员',
    '13900139000',
    'B2B_ADMIN',
    1,
    TRUE
);

-- 2. worker user (牧工, associated with demo tenant)
-- Phone: 13800138001, Password: 123
-- Hash verified: bcrypt.checkpw('123', hash) → True
INSERT INTO users (password_hash, name, phone, role, tenant_id, is_active)
VALUES (
    '$2b$10$9clRguet3YCKt1DQ1HwazubvJ48DL2Ip7m6Kpx3P864SJUPpsQSlq',
    '李牧工',
    '13800138001',
    'WORKER',
    1,
    TRUE
);

-- 3. Second farm for multi-farm switching test
INSERT INTO farms (tenant_id, name, latitude, longitude, area_hectares)
VALUES (1, '南山分场', 28.2000000, 112.9000000, 300.00);

-- 4. Assign owner to the second farm
INSERT INTO user_farm_assignments (user_id, farm_id, role, status)
SELECT u.id, f.id, 'OWNER', 'ACTIVE'
FROM users u, farms f
WHERE u.phone = '13800138000' AND u.role = 'OWNER'
  AND f.name = '南山分场' AND f.tenant_id = 1;

-- 5. Assign worker to the main farm (farm_id=1)
INSERT INTO user_farm_assignments (user_id, farm_id, role, status)
SELECT u.id, f.id, 'WORKER', 'ACTIVE'
FROM users u, farms f
WHERE u.phone = '13800138001' AND u.role = 'WORKER'
  AND f.id = 1;
