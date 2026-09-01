-- NIX-179 fault tolerance: per-binding TB channel health, used by the blade
-- fallback in AgenticPlatformSyncDispatcher. Blade polling stays excluded for
-- a bound device only while its TB channel looks healthy; a frozen cursor or
-- repeated failures degrade the device back to the blade channel.
-- last_poll_at: last cycle that attempted this device (success or not);
-- consecutive_failures: page/API/ingest failures in a row, reset on a clean cycle.
ALTER TABLE tb_device_bindings
    ADD COLUMN IF NOT EXISTS last_poll_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS consecutive_failures INTEGER NOT NULL DEFAULT 0;
