-- ============================================================
-- V20260702150000: Normalize breed to English canonical codes
--
-- Problem: livestock.breed stored a mix of English (Angus, Simmental,
-- Limousin) and Chinese values with no DB constraint,
-- causing i18n mismatches in the frontend.
--
-- This migration converts all breed values to uppercase English codes
-- and adds a CHECK constraint to prevent future invalid values.
-- ============================================================

-- Step 1: Normalize all existing breed values to canonical codes
UPDATE livestock SET breed = 'ANGUS'     WHERE breed IN ('Angus', '安格斯', '安格斯牛');
UPDATE livestock SET breed = 'WAGYU'     WHERE breed IN ('Wagyu', '和牛');
UPDATE livestock SET breed = 'SIMMENTAL' WHERE breed IN ('Simmental', '西门塔尔', '西门塔尔牛');
UPDATE livestock SET breed = 'LIMOUSIN'  WHERE breed IN ('Limousin', '利木赞', '利木赞牛');
UPDATE livestock SET breed = 'OTHER'     WHERE breed IS NOT NULL AND breed NOT IN ('ANGUS', 'WAGYU', 'SIMMENTAL', 'LIMOUSIN');

-- Step 2: Set NULL breeds to OTHER so the CHECK constraint can be added safely
UPDATE livestock SET breed = 'OTHER' WHERE breed IS NULL;

-- Step 3: Add CHECK constraint
ALTER TABLE livestock ADD CONSTRAINT chk_livestock_breed
    CHECK (breed IN ('ANGUS', 'WAGYU', 'SIMMENTAL', 'LIMOUSIN', 'OTHER'));
