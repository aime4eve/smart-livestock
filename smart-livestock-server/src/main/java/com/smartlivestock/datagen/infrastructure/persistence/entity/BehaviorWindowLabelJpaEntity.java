package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "behavior_window_labels")
@Getter
@Setter
public class BehaviorWindowLabelJpaEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "window_id", nullable = false)
    private UUID windowId;

    @Column(name = "facet", nullable = false, length = 20)
    private String facet;

    @Column(name = "label_value", nullable = false, length = 20)
    private String labelValue;

    @Column(name = "label_source", nullable = false, length = 30)
    private String labelSource;

    @Column(name = "confidence", nullable = false, precision = 5, scale = 4)
    private BigDecimal confidence;

    @Column(name = "labeler_id")
    private Long labelerId;

    @Column(name = "labeled_at")
    private Instant labeledAt;

    @Column(name = "note")
    private String note;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
