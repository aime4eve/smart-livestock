-- V8: Fix password hash prefix from $2b$ to $2a$ for Spring Security compatibility
-- $2b$ is a valid BCrypt variant but Spring Security BCryptPasswordEncoder prefers $2a$.

UPDATE users
SET password_hash = '$2a$10$qmRPJJKaIMpl9WR2JPxzZetgxYYIL4/BlXkURg/E2ejVDZXJoPjM.'
WHERE username = 'owner';

UPDATE users
SET password_hash = '$2a$10$H4TUwrJ/e7Q.SpCrWubDOOeRsxvmXoTshyb44e9/Iz.0SeGjd.kaS'
WHERE username = 'platform_admin';
