package com.smartlivestock.health.infrastructure.persistence.entity;

import com.smartlivestock.health.domain.model.EpidemicDispositionAction;
import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.domain.model.EpidemicDispositionTier;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "epidemic_dispositions")
@Getter
@Setter
public class EpidemicDispositionJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;

    @Column(name = "source_livestock_id")
    private Long sourceLivestockId;

    @Column(name = "source_event_id")
    private Long sourceEventId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EpidemicDispositionTier tier;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_code", nullable = false, length = 40)
    private EpidemicDispositionAction actionCode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EpidemicDispositionStatus status = EpidemicDispositionStatus.PENDING;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "reason_codes", nullable = false, columnDefinition = "text[]")
    private List<String> reasonCodes = new ArrayList<>();

    @Column(name = "due_at")
    private Instant dueAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "completed_by")
    private Long completedBy;

    @Column(name = "cancel_reason_code", length = 40)
    private String cancelReasonCode;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}
