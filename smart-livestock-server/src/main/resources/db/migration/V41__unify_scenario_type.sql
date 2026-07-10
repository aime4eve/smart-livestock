-- V40: 统一 scenario_type + pattern → type（系统性重构）
ALTER TABLE synthesis_scenarios ADD COLUMN type VARCHAR(40);
UPDATE synthesis_scenarios SET type = CASE WHEN scenario_type = 'HEALTH' THEN pattern ELSE scenario_type END;
ALTER TABLE synthesis_scenarios ALTER COLUMN type SET NOT NULL;
ALTER TABLE synthesis_scenarios DROP COLUMN scenario_type;
ALTER TABLE synthesis_scenarios DROP COLUMN pattern;

ALTER TABLE ground_truth_labels ADD COLUMN type VARCHAR(40);
UPDATE ground_truth_labels SET type = CASE WHEN scenario_type = 'HEALTH' THEN pattern ELSE scenario_type END;
ALTER TABLE ground_truth_labels ALTER COLUMN type SET NOT NULL;
ALTER TABLE ground_truth_labels DROP COLUMN scenario_type;
ALTER TABLE ground_truth_labels DROP COLUMN pattern;
