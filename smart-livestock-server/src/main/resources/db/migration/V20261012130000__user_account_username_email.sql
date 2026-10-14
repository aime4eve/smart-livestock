-- Ruling 2026-10-12: global-ready login identifiers on the users registry
-- table (no separate credential store). Four distinct concerns:
--   account  = login id, globally unique (case-insensitive)
--   username = display name, may repeat
--   phone    = login id (E.164 going forward; WhatsApp shares the number),
--              globally unique
--   email    = login id, globally unique (case-insensitive)
-- Existing phones are migrated as-is (no country guessing); legacy bare
-- 11-digit logins keep working via the login-time fallback lookup.

ALTER TABLE users ADD COLUMN account  VARCHAR(50);
ALTER TABLE users ADD COLUMN username VARCHAR(100);
ALTER TABLE users ADD COLUMN email    VARCHAR(255);

-- users.name currently doubles as the display name; new rows prefer
-- username, existing rows keep rendering name.
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_account
    ON users(LOWER(account)) WHERE account IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email
    ON users(LOWER(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_phone
    ON users(phone) WHERE phone IS NOT NULL AND phone <> '';

COMMENT ON COLUMN users.account  IS 'login account, globally unique, case-insensitive; null for legacy users until set';
COMMENT ON COLUMN users.username IS 'display name, not unique';
COMMENT ON COLUMN users.email    IS 'login email, globally unique, case-insensitive';
