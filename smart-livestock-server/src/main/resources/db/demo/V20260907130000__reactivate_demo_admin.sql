-- ============================================================
-- DEMO SEED (dev/test Flyway location ONLY — never loaded by
-- release installs; see FLYWAY_LOCATIONS in the compose files).
--
-- NIX-191 deactivated the well-known seeded platform admins on
-- fresh installs. Local development still needs the familiar
-- 13800000000/123 account, so this demo location re-activates it.
-- ============================================================

UPDATE users SET is_active = TRUE, must_change_password = FALSE
WHERE role = 'PLATFORM_ADMIN'
  AND phone IN ('13800000000', '13700000000');
