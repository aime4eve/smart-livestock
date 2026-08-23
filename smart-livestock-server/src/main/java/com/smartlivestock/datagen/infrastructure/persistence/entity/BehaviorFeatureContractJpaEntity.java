package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;

@Entity
@Table(name = "behavior_feature_contracts")
@Getter
@Setter
public class BehaviorFeatureContractJpaEntity {
    @Id
    @Column(name = "feature_version", length = 20)
    private String featureVersion;

    @Column(name = "schema_hash", nullable = false, length = 64)
    private String schemaHash;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "definition", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> definition;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
