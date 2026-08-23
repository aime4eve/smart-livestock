package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "behavior_predictions")
@Getter
@Setter
public class BehaviorPredictionJpaEntity {
    @Id
    private UUID id;

    @Column(name = "window_id", nullable = false)
    private UUID windowId;

    @Column(name = "model_name", nullable = false, length = 80)
    private String modelName;

    @Column(name = "model_version", nullable = false, length = 40)
    private String modelVersion;

    @Column(name = "predicted_dominant_behavior", nullable = false, length = 20)
    private String predictedDominantBehavior;

    @Column(name = "dominant_probability", nullable = false, precision = 6, scale = 5)
    private BigDecimal dominantProbability;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "predicted_labels", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> predictedLabels;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "probability_vector", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> probabilityVector;

    @Column(name = "capability_level", nullable = false, length = 20)
    private String capabilityLevel;

    @Column(name = "predicted_at", nullable = false)
    private Instant predictedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
