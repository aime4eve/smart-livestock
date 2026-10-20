-- ============================================================
-- DEMO SEED (dev/test Flyway location ONLY — never loaded by
-- release installs; see FLYWAY_LOCATIONS in the compose files).
--
-- The super admin seed follows the admin_bootstrap activation
-- policy (V20260907120000): fresh installs get a deactivated
-- account with a publicly documented password. Local development
-- still needs it active for the context-entry journeys, so this
-- demo location re-activates it. must_change_password stays TRUE
-- — first login is forced through the password-change flow by
-- design (plan Task 9 journey includes the forced change).
-- ============================================================

UPDATE users SET is_active = TRUE
WHERE role = 'SUPER_ADMIN'
  AND account = 'Admin@HKT';
