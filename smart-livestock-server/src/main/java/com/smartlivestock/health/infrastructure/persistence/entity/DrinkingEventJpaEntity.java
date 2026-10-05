package com.smartlivestock.health.infrastructure.persistence.entity;

import com.smartlivestock.health.domain.model.DrinkingEventLabel;
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

import java.math.BigDecimal;
import java.time.Instant;

/**
 * {@code drinking_events} row (NIX-256 Task 3). {@code source} is a plain
 * string (dynamic passthrough of the temperature point source + MANUAL /
 * ALGORITHM_CANDIDATE — see {@link com.smartlivestock.health.domain.model.DrinkingEventSources});
 * {@code tempDrop}/{@code minTemp} are null on MANUAL rows, which carry no
 * temperature observation.
 */
@Entity
@Table(name = "drinking_events")
@Getter
@Setter
public class DrinkingEventJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "livestock_id")
    private Long livestockId;

    @Column(name = "event_start_at", nullable = false)
    private Instant eventStartAt;

    @Column(name = "event_end_at", nullable = false)
    private Instant eventEndAt;

    @Column(name = "temp_drop", precision = 10, scale = 2)
    private BigDecimal tempDrop;

    @Column(name = "min_temp", precision = 10, scale = 2)
    private BigDecimal minTemp;

    @Column(nullable = false, length = 20)
    private String source;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private DrinkingEventLabel label = DrinkingEventLabel.UNLABELED;

    @Column(nullable = false, precision = 4, scale = 3)
    private BigDecimal confidence = BigDecimal.ONE;

    @Column(name = "algorithm_version", nullable = false, length = 10)
    private String algorithmVersion;

    @Column(length = 500)
    private String note;

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
