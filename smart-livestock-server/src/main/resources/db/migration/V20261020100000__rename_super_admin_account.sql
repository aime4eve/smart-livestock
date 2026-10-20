-- ============================================================
-- V20261020100000: Rename the super-admin login account to an
-- email-shaped identifier (user request 2026-10-20):
--   Admin@HKT -> Admin@hkt.com
--
-- The seed migration V20261019100000 already ran on deployed
-- environments, so the rename ships forward-only (never edit an
-- applied migration — checksum). Login keeps working through the
-- same verified path: classify('Admin@hkt.com') -> EMAIL branch ->
-- normalizeEmail -> findByLoginIdentifier matches LOWER(account).
--
-- The account stays in the account column (not the email column):
-- every API create/rename path still rejects '@' in account names,
-- so this identifier can only ever exist through seeds and no
-- validated write path can collide with it (unique index backs it).
--
-- Password unchanged by this migration.
-- ============================================================

UPDATE users
SET account = 'Admin@hkt.com',
    updated_at = NOW()
WHERE role = 'SUPER_ADMIN'
  AND account = 'Admin@HKT';
