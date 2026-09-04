-- Phase C behavior feature store. Raw research waveforms remain offline artifacts.

CREATE TABLE behavior_feature_contracts (
    feature_version VARCHAR(20) PRIMARY KEY,
    schema_hash VARCHAR(64) NOT NULL UNIQUE,
    definition JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE behavior_datasets (
    id UUID PRIMARY KEY,
    scenario_id VARCHAR(100) NOT NULL,
    seed BIGINT NOT NULL,
    generator_version VARCHAR(40) NOT NULL,
    data_source VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL,
    definition_digest VARCHAR(64) NOT NULL UNIQUE,
    manifest JSONB NOT NULL,
    start_at TIMESTAMP NOT NULL,
    end_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_behavior_datasets_source
        CHECK (data_source IN ('DATAGEN','AGENTIC_PLATFORM','MANUAL_IMPORT','RESEARCH_IMPORT')),
    CONSTRAINT chk_behavior_datasets_status
        CHECK (status IN ('GENERATING','READY','FROZEN','INVALID')),
    CONSTRAINT chk_behavior_datasets_time CHECK (end_at > start_at)
);

CREATE INDEX idx_behavior_datasets_source_time
    ON behavior_datasets(data_source, start_at, end_at);
CREATE INDEX idx_behavior_datasets_scenario
    ON behavior_datasets(scenario_id, generator_version);

CREATE TABLE behavior_episodes (
    id UUID NOT NULL,
    dataset_id UUID NOT NULL REFERENCES behavior_datasets(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT NOT NULL REFERENCES livestock(id),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    dominant_behavior VARCHAR(20) NOT NULL,
    start_at TIMESTAMP NOT NULL,
    end_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id),
    CONSTRAINT uq_behavior_episodes_dataset_id UNIQUE (dataset_id, id),
    CONSTRAINT chk_behavior_episodes_dominant
        CHECK (dominant_behavior IN ('LYING','RUMINATING','FEEDING','WALKING','OTHER')),
    CONSTRAINT chk_behavior_episodes_time CHECK (end_at > start_at)
);

CREATE INDEX idx_behavior_episodes_dataset_livestock
    ON behavior_episodes(dataset_id, livestock_id, start_at);
CREATE INDEX idx_behavior_episodes_dataset_time
    ON behavior_episodes(dataset_id, start_at);

CREATE TABLE behavior_livestock_split_assignments (
    dataset_id UUID NOT NULL REFERENCES behavior_datasets(id) ON DELETE CASCADE,
    livestock_id BIGINT NOT NULL REFERENCES livestock(id),
    dataset_split VARCHAR(12) NOT NULL,
    assigned_by BIGINT,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dataset_id, livestock_id),
    CONSTRAINT chk_behavior_livestock_split
        CHECK (dataset_split IN ('TRAIN','VALIDATION','TEST'))
);

CREATE TABLE behavior_episode_split_assignments (
    dataset_id UUID NOT NULL,
    episode_id UUID NOT NULL,
    dataset_split VARCHAR(12) NOT NULL,
    assigned_by BIGINT,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (dataset_id, episode_id),
    FOREIGN KEY (dataset_id, episode_id)
        REFERENCES behavior_episodes(dataset_id, id) ON DELETE CASCADE,
    CONSTRAINT chk_behavior_episode_split
        CHECK (dataset_split IN ('TRAIN','VALIDATION','TEST'))
);

CREATE TABLE behavior_windows (
    id UUID PRIMARY KEY,
    dataset_id UUID NOT NULL REFERENCES behavior_datasets(id) ON DELETE CASCADE,
    episode_id UUID NOT NULL,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT NOT NULL REFERENCES livestock(id),
    device_id BIGINT NOT NULL REFERENCES devices(id),
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    dominant_behavior VARCHAR(20) NOT NULL,
    feature_version VARCHAR(20) NOT NULL
        REFERENCES behavior_feature_contracts(feature_version),
    feature_schema_hash VARCHAR(64) NOT NULL,
    features JSONB NOT NULL,
    input_quality VARCHAR(20) NOT NULL,
    sampling_mode VARCHAR(20) NOT NULL,
    model_compatible BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_behavior_windows_dataset_device_time_version
        UNIQUE (dataset_id, device_id, window_start, feature_version),
    CONSTRAINT uq_behavior_windows_dataset_id UNIQUE (dataset_id, id),
    FOREIGN KEY (dataset_id, episode_id)
        REFERENCES behavior_episodes(dataset_id, id) ON DELETE CASCADE,
    CONSTRAINT chk_behavior_windows_dominant
        CHECK (dominant_behavior IN ('LYING','RUMINATING','FEEDING','WALKING','OTHER')),
    CONSTRAINT chk_behavior_windows_input_quality
        CHECK (input_quality IN ('FULL_0X40','PARTIAL_0X40','COARSE_SNAPSHOT','UNKNOWN')),
    CONSTRAINT chk_behavior_windows_sampling_mode
        CHECK (sampling_mode IN ('PROTOCOL_SUMMARY','SPARSE_SNAPSHOT','RESEARCH_WAVEFORM')),
    CONSTRAINT chk_behavior_windows_time
        CHECK (window_end = window_start + INTERVAL '5 minutes')
);

CREATE INDEX idx_behavior_windows_dataset_start
    ON behavior_windows(dataset_id, window_start);
CREATE INDEX idx_behavior_windows_dataset_livestock
    ON behavior_windows(dataset_id, livestock_id, window_start);
CREATE INDEX idx_behavior_windows_dataset_quality
    ON behavior_windows(dataset_id, input_quality, model_compatible);
CREATE INDEX idx_behavior_windows_episode
    ON behavior_windows(dataset_id, episode_id);

CREATE TABLE behavior_window_labels (
    id BIGSERIAL PRIMARY KEY,
    window_id UUID NOT NULL,
    facet VARCHAR(20) NOT NULL,
    label_value VARCHAR(20) NOT NULL,
    label_source VARCHAR(30) NOT NULL,
    confidence DECIMAL(5,4) NOT NULL DEFAULT 1.0,
    labeler_id BIGINT,
    labeled_at TIMESTAMP,
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    FOREIGN KEY (window_id) REFERENCES behavior_windows(id) ON DELETE CASCADE,
    CONSTRAINT uq_behavior_window_labels UNIQUE (window_id, facet, label_value),
    CONSTRAINT chk_behavior_window_labels_facet
        CHECK (facet IN ('POSTURE','ORAL_ACTIVITY','LOCOMOTION','EVENT')),
    CONSTRAINT chk_behavior_window_labels_source
        CHECK (label_source IN (
            'SYNTHETIC','MANUAL','REPRODUCTIVE_RECORD','VIDEO','SENSOR_RULE')),
    CONSTRAINT chk_behavior_window_labels_confidence
        CHECK (confidence >= 0 AND confidence <= 1)
);

CREATE INDEX idx_behavior_window_labels_window
    ON behavior_window_labels(window_id, facet);

CREATE TABLE behavior_predictions (
    id UUID PRIMARY KEY,
    window_id UUID NOT NULL REFERENCES behavior_windows(id) ON DELETE CASCADE,
    model_name VARCHAR(80) NOT NULL,
    model_version VARCHAR(40) NOT NULL,
    predicted_dominant_behavior VARCHAR(20) NOT NULL,
    dominant_probability DECIMAL(6,5) NOT NULL,
    predicted_labels JSONB NOT NULL,
    probability_vector JSONB NOT NULL,
    capability_level VARCHAR(20) NOT NULL,
    predicted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_behavior_predictions_window_model
        UNIQUE (window_id, model_name, model_version),
    CONSTRAINT chk_behavior_predictions_dominant
        CHECK (predicted_dominant_behavior IN (
            'LYING','RUMINATING','FEEDING','WALKING','OTHER')),
    CONSTRAINT chk_behavior_predictions_capability
        CHECK (capability_level IN ('L1_RULE','L2_SUPERVISED')),
    CONSTRAINT chk_behavior_predictions_probability
        CHECK (dominant_probability >= 0 AND dominant_probability <= 1)
);

CREATE INDEX idx_behavior_predictions_window
    ON behavior_predictions(window_id, predicted_at);

INSERT INTO behavior_feature_contracts
    (feature_version, schema_hash, definition)
VALUES (
    'v1',
    'ed681cb289c0d9c7eb90d7e7a69e52663618af2f3004b71b4aa17db4ba95bfbc',
    '{"featureVersion":"v1","fields":[{"name":"sample_count","primitive":"INTEGER","unit":"samples","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":-1},{"name":"expected_sample_count","primitive":"INTEGER","unit":"samples","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":-1},{"name":"missing_feature_mask","primitive":"BITMASK","unit":"bits","required":true,"minimum":"0","maximum":"67108863","missingBitIndex":-1},{"name":"accel_mean_x","primitive":"DECIMAL","unit":"g","required":true,"minimum":"-16.0","maximum":"16.0","missingBitIndex":0},{"name":"accel_mean_y","primitive":"DECIMAL","unit":"g","required":true,"minimum":"-16.0","maximum":"16.0","missingBitIndex":1},{"name":"accel_mean_z","primitive":"DECIMAL","unit":"g","required":true,"minimum":"-16.0","maximum":"16.0","missingBitIndex":2},{"name":"accel_std_x","primitive":"DECIMAL","unit":"g","required":true,"minimum":"0.0","maximum":"16.0","missingBitIndex":3},{"name":"accel_std_y","primitive":"DECIMAL","unit":"g","required":true,"minimum":"0.0","maximum":"16.0","missingBitIndex":4},{"name":"accel_std_z","primitive":"DECIMAL","unit":"g","required":true,"minimum":"0.0","maximum":"16.0","missingBitIndex":5},{"name":"roll_mean","primitive":"DECIMAL","unit":"degrees","required":true,"minimum":"-180.0","maximum":"180.0","missingBitIndex":6},{"name":"roll_std","primitive":"DECIMAL","unit":"degrees","required":true,"minimum":"0.0","maximum":"180.0","missingBitIndex":7},{"name":"pitch_mean","primitive":"DECIMAL","unit":"degrees","required":true,"minimum":"-180.0","maximum":"180.0","missingBitIndex":8},{"name":"pitch_std","primitive":"DECIMAL","unit":"degrees","required":true,"minimum":"0.0","maximum":"180.0","missingBitIndex":9},{"name":"dominant_freq_hz","primitive":"DECIMAL","unit":"Hz","required":true,"minimum":"0.0","maximum":"12.5","missingBitIndex":10},{"name":"spectral_power_ratio","primitive":"DECIMAL","unit":"ratio","required":true,"minimum":"0.0","maximum":"1.0","missingBitIndex":11},{"name":"spectral_entropy","primitive":"DECIMAL","unit":"normalized_entropy","required":true,"minimum":"0.0","maximum":"1.0","missingBitIndex":12},{"name":"burst_count","primitive":"INTEGER","unit":"events","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":13},{"name":"zero_crossing_rate","primitive":"DECIMAL","unit":"ratio","required":true,"minimum":"0.0","maximum":"1.0","missingBitIndex":14},{"name":"step_count","primitive":"INTEGER","unit":"steps","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":15},{"name":"distance_meters","primitive":"DECIMAL","unit":"m","required":true,"minimum":"0.0","maximum":"100000.0","missingBitIndex":16},{"name":"mean_speed_mps","primitive":"DECIMAL","unit":"m/s","required":true,"minimum":"0.0","maximum":"10.0","missingBitIndex":17},{"name":"activity_class_counts.rest","primitive":"INTEGER","unit":"samples","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":18},{"name":"activity_class_counts.light","primitive":"INTEGER","unit":"samples","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":19},{"name":"activity_class_counts.active","primitive":"INTEGER","unit":"samples","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":20},{"name":"activity_class_counts.intense","primitive":"INTEGER","unit":"samples","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":21},{"name":"capsule_motility_mean","primitive":"DECIMAL","unit":"index","required":true,"minimum":"0.0","maximum":"100.0","missingBitIndex":22},{"name":"capsule_motility_std","primitive":"DECIMAL","unit":"index","required":true,"minimum":"0.0","maximum":"100.0","missingBitIndex":23},{"name":"posture_transition_count","primitive":"INTEGER","unit":"events","required":true,"minimum":"0","maximum":"100000000","missingBitIndex":24}]}'::jsonb
);
