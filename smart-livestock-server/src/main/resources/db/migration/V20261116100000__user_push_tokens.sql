-- Migration: user_push_tokens
-- Date: 2026-11-16
-- Context: Identity

-- NIX-430: APNs push tokens per user (iOS first; android rows reserved for
-- the deferred FCM phase — the schema is platform-agnostic already).
CREATE TABLE IF NOT EXISTS user_push_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- users(id) from V1__create_identity_tables
    platform VARCHAR(16) NOT NULL,                    -- ios | android
    token TEXT NOT NULL,                              -- APNs device token (hex)
    apns_env VARCHAR(16) NOT NULL DEFAULT 'sandbox',  -- sandbox | production (dev-signed builds use sandbox)
    app_version VARCHAR(32),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Rollback: DROP TABLE IF EXISTS user_push_tokens;
CREATE UNIQUE INDEX IF NOT EXISTS ux_user_push_tokens_token ON user_push_tokens (token);
CREATE INDEX IF NOT EXISTS ix_user_push_tokens_user ON user_push_tokens (user_id);

-- NIX-430 acceptance #3: per-user push toggle (default on).
ALTER TABLE users ADD COLUMN IF NOT EXISTS push_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE;
