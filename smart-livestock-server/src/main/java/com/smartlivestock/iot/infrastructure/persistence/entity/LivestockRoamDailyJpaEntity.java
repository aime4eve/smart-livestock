package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Getter
@Setter
@Entity
@Table(name = "livestock_roam_daily",
        uniqueConstraints = @UniqueConstraint(columnNames = {"device_id", "roam_day"}))
public class LivestockRoamDailyJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "roam_day", nullable = false)
    private LocalDate roamDay;

    @Column(name = "max_distance_m", precision = 10, scale = 2)
    private BigDecimal maxDistanceM;

    @Column(name = "mean_distance_m", precision = 10, scale = 2)
    private BigDecimal meanDistanceM;

    @Column(name = "frame_count")
    private Integer frameCount;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
