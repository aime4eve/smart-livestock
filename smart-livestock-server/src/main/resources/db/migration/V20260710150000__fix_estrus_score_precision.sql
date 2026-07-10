-- Fix numeric overflow: distance_delta and temp_delta in estrus_scores
-- distance_delta can exceed 999.99 (DECIMAL(5,2) max) when comparing meters across periods
ALTER TABLE estrus_scores ALTER COLUMN distance_delta TYPE DECIMAL(10,2);
ALTER TABLE estrus_scores ALTER COLUMN temp_delta TYPE DECIMAL(8,2);
