-- ============================================================
-- V11: Seed Commerce data — contracts, revenue_periods
-- V6 already seeds subscription (tenant_id=1, basic/trial) and feature_gates
-- This adds: demo contract for demo tenant, revenue period sample
-- ============================================================

-- 1. Update the existing trial subscription (from V6) to premium/active for demo purposes
UPDATE subscriptions
SET tier = 'premium',
    status = 'active',
    billing_model = 'direct',
    billing_cycle = 'monthly',
    started_at = '2026-01-01 00:00:00+08',
    expires_at = '2027-01-01 00:00:00+08',
    trial_ends_at = NULL
WHERE tenant_id = 1;

-- 2. Contract for demo tenant (direct billing, premium tier)
INSERT INTO contracts (contract_number, tenant_id, billing_model, effective_tier, revenue_share_ratio, status, started_at, expires_at)
VALUES ('CTR-2026-DEMO-001', 1, 'direct', 'premium', NULL, 'active', '2026-01-01 00:00:00+08', '2027-01-01 00:00:00+08');

-- 3. Sample revenue period for demo contract (current month)
INSERT INTO revenue_periods (contract_id, tenant_id, period_start, period_end, gross_amount, platform_share, partner_share, revenue_share_ratio, status)
SELECT
    c.id,
    c.tenant_id,
    '2026-04-01'::date,
    '2026-04-30'::date,
    225000,   -- gross amount in cents (2250 yuan)
    225000,   -- platform takes all (direct billing, no partner share)
    0,        -- no partner share for direct billing
    0.0000,   -- 0% revenue share
    'platform_confirmed'
FROM contracts c
WHERE c.contract_number = 'CTR-2026-DEMO-001';
