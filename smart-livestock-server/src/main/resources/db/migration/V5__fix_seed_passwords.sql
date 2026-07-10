-- V5: Fix seed user passwords to use '123' for demo/testing
-- The original BCrypt hashes did not match any known password.
-- These hashes were generated and verified with bcrypt.checkpw('123', hash) → True.

UPDATE users
SET password_hash = '$2b$10$5hlsd.KwNOWmJni4DSEb2uJH71XzQvoTJy.0M/QXEklP7IhGe5dDC'
WHERE phone = '13800138000' AND role = 'OWNER';

UPDATE users
SET password_hash = '$2b$10$JeoWESTICwRS7mUC6QElae6vTJbhtpwNJ09ZuqIWlwqheqUjboFbG'
WHERE phone = '13800000000' AND role = 'PLATFORM_ADMIN';
