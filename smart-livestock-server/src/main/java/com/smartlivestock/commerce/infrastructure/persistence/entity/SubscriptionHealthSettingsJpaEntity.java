package com.smartlivestock.commerce.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Single-row platform settings for the NIX-324 subscription-health banner
 * tiers. Column types mirror V20261103100000__create_subscription_health_settings.sql
 * exactly (INT → Integer, TIMESTAMPTZ → Instant).
 */
@Entity
@Table(name = "subscription_health_settings")
@Getter
@Setter
public class SubscriptionHealthSettingsJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "warn_days", nullable = false)
    private Integer warnDays;

    @Column(name = "caution_days", nullable = false)
    private Integer cautionDays;

    @Column(name = "danger_days", nullable = false)
    private Integer dangerDays;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private Instant updatedAt;

    @Column(name = "updated_by", length = 100)
    private String updatedBy;
}
