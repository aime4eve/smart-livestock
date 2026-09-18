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

@Getter
@Setter
@Entity
@Table(name = "gateway_distance_profiles",
        uniqueConstraints = @UniqueConstraint(columnNames = {"gateway_id", "bucket_rssi"}))
public class GatewayDistanceProfileJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "gateway_id", length = 128, nullable = false)
    private String gatewayId;

    @Column(name = "bucket_rssi", nullable = false)
    private Integer bucketRssi;

    @Column(name = "sample_count", nullable = false)
    private Integer sampleCount;

    @Column(name = "dist_p50_m", nullable = false, precision = 10, scale = 2)
    private BigDecimal distP50M;

    @Column(name = "dist_p90_m", nullable = false, precision = 10, scale = 2)
    private BigDecimal distP90M;

    @Column(name = "window_days", nullable = false)
    private Integer windowDays = 30;

    @Column(name = "computed_at", nullable = false)
    private Instant computedAt = Instant.now();
}
