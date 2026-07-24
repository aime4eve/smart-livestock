-- V20260724100000: Add a second platform_admin account (phone 13700000000, password 123)
-- Hash generated and verified with bcrypt.checkpw -> True
-- Idempotent: skips if the phone already exists.

INSERT INTO users (password_hash, name, phone, role, tenant_id, is_active)
SELECT
    '$2b$10$JeoWESTICwRS7mUC6QElae6vTJbhtpwNJ09ZuqIWlwqheqUjboFbG',
    'Platform Admin 2',
    '13700000000',
    'PLATFORM_ADMIN',
    NULL,
    TRUE
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE phone = '13700000000' AND role = 'PLATFORM_ADMIN'
);
