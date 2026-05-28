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

-- 3. Revenue periods — 3 months of history for demo dashboard
-- Feb: settled, Mar: platform_confirmed, Apr: platform_confirmed
-- Amounts in cents, showing gradual growth

INSERT INTO revenue_periods (contract_id, tenant_id, period_start, period_end, gross_amount, platform_share, partner_share, revenue_share_ratio, status)
SELECT
    c.id,
    c.tenant_id,
    month_start,
    (month_start + INTERVAL '1 month' - INTERVAL '1 day')::date,
    amount,
    amount,
    0,
    0.0000,
    status
FROM contracts c
CROSS JOIN (
    VALUES
        ('2026-02-01'::date, 180000, 'settled'),             -- 1800 yuan
        ('2026-03-01'::date, 205000, 'platform_confirmed'),  -- 2050 yuan
        ('2026-04-01'::date, 225000, 'platform_confirmed')   -- 2250 yuan
) AS months(month_start, amount, status)
WHERE c.contract_number = 'CTR-2026-DEMO-001';
