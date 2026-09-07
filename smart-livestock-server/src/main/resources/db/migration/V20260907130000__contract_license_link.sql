-- ============================================================
-- V20260907130000: contract ↔ issued license linkage (NIX-191)
--
-- The issuing tool records which signed activation certificate was
-- issued against each contract, so every certificate can be traced
-- back to the commercial agreement behind it (and vice versa).
-- ============================================================

ALTER TABLE contracts ADD COLUMN issued_license_id VARCHAR(64);
