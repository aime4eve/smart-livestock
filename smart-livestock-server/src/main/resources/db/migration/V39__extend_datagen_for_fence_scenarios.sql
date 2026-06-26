-- V39: datagen 统一模拟引擎 — ScenarioType 扩展列（健康 + 围栏双维度）

ALTER TABLE synthesis_scenarios ADD COLUMN scenario_type VARCHAR(20) NOT NULL DEFAULT 'HEALTH'
    CHECK (scenario_type IN ('HEALTH','FENCE_BREACH','FENCE_APPROACH'));

ALTER TABLE ground_truth_labels ADD COLUMN scenario_type VARCHAR(20) NOT NULL DEFAULT 'HEALTH'
    CHECK (scenario_type IN ('HEALTH','FENCE_BREACH','FENCE_APPROACH'));
