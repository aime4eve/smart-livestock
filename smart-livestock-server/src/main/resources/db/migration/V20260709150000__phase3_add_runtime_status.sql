-- Phase 3: Add runtime_status column to devices table
-- runtimeStatus existed in Device domain model but was never persisted to DB.
ALTER TABLE devices ADD COLUMN IF NOT EXISTS runtime_status VARCHAR(20);
