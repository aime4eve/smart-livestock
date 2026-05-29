-- V15: Drop username column from users table
-- Login uses phone field; username was never needed by any business logic.

ALTER TABLE users DROP COLUMN IF EXISTS username;
