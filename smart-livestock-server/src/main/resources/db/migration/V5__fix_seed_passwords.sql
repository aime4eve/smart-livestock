-- V5: Fix seed user passwords to use 'password123' for demo/testing
-- The original BCrypt hashes did not match any known password.
-- These hashes were generated with BCrypt cost factor 10.

UPDATE users
SET password_hash = '$2b$10$gi8HDe5GFyDi3TBfTDR8vOH0H2z1N/vdUAnnS1jWRdRAJhqS/DmSi'
WHERE username = 'owner';

UPDATE users
SET password_hash = '$2b$10$zP4d9tq8G6kho4XrKFqa5OCTTPKHovhWw9i3bpjy9evOrsATrXiwi'
WHERE username = 'platform_admin';
