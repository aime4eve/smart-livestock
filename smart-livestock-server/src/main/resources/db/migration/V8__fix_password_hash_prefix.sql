-- V8: Fix password hash BCrypt prefix from $2a$ to $2b$ for compatibility
-- Some BCrypt implementations use $2a$, others $2b$. Normalize to $2b$.

UPDATE users
SET password_hash = REPLACE(password_hash, '$2a$', '$2b$')
WHERE phone = '13800138000' AND role = 'OWNER';

UPDATE users
SET password_hash = REPLACE(password_hash, '$2a$', '$2b$')
WHERE phone = '13800000000' AND role = 'PLATFORM_ADMIN';
