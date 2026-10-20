-- ============================================================
-- V20261019100000: Super admin role + seed account (context entry)
--
-- 1. users.role CHECK gains SUPER_ADMIN: a root-login-only role that
--    holds no business authority of its own; it enters the system via
--    switched context tokens (design 2026-10-19 section 4.1).
-- 2. Seed the single super admin account Admin@HKT / Admin@2026.
--    The account contains '@' so every API create/rename path rejects
--    it (LoginIdentifiers.isValidAccount) — the account can only exist
--    through this seed, which also rules out name collisions from any
--    verified write path (design ruling 5).
--
--    Activation policy mirrors V20260907120000__admin_bootstrap.sql:
--      - deployments that already hold a CURRENT deployment license:
--        the account stays active but is locked to the password-change
--        flow on first login (must_change_password = TRUE);
--      - fresh installs (no CURRENT license ever imported): the account
--        is seeded deactivated (is_active = FALSE) so a publicly
--        documented credential never ships active on an unattended box;
--        dev/test re-activate it through the db/demo location.
-- ============================================================

ALTER TABLE users DROP CONSTRAINT chk_users_role;
ALTER TABLE users ADD CONSTRAINT chk_users_role
    CHECK (role IN ('OWNER', 'WORKER', 'PLATFORM_ADMIN', 'B2B_ADMIN', 'API_CONSUMER', 'SUPER_ADMIN'));

-- Idempotent: the system carries exactly one super admin.
INSERT INTO users (account, username, name, password_hash, phone, email,
                   role, tenant_id, is_active, must_change_password)
SELECT 'Admin@HKT', '超级管理员', '超级管理员',
       '$2a$10$h6ca7nvCpbhQpjdHTxm88.rME./2OFCwAKXStbonUaNEStlb9INeC',
       NULL, NULL,
       'SUPER_ADMIN', NULL,
       EXISTS (SELECT 1 FROM deployment_licenses WHERE status = 'CURRENT'),
       TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE role = 'SUPER_ADMIN');
