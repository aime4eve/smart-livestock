-- NIX-245: USD per-head-per-month pricing model.
-- STANDARD/PREMIUM livestock caps are removed: billing scales per head with
-- herd-size bands, so a numeric cap would only block large herds instead of
-- driving upgrades. BASIC keeps its 50-head free-tier cap.
-- gate_type 'none' (as used by enterprise) means unrestricted.
UPDATE feature_gates
SET gate_type = 'none', limit_value = NULL
WHERE feature_key = 'livestock_management'
  AND tier IN ('standard', 'premium')
  AND gate_type = 'limit';
