-- Ruling follow-up 2026-10-15: after the global-login rollout, the dial-code
-- picker merges to E.164 (+86 13800…), which no longer matches legacy bare
-- 11-digit CN numbers stored without a country code. Normalize once:
--   11 digits starting with 1  → +86 (CN mobile)
--   12 digits starting with 254 → +254 (KE mobile, local form 0254…/254…)
-- Other shapes (already "+" or non-CN/KE locals) are left untouched — login
-- still tries the raw form as a fallback candidate.
-- Idempotent: the LIKE guards re-match nothing after the update.

UPDATE users SET phone = '+86' || phone
 WHERE phone ~ '^[0-9]{11}$' AND phone ~ '^1[3-9]';

UPDATE users SET phone = '+254' || phone
 WHERE phone ~ '^[0-9]{12}$' AND phone ~ '^254';

COMMENT ON COLUMN users.phone IS 'E.164 preferred; legacy bare 11-digit CN/12-digit KE forms still accepted at login via fallback lookup';
