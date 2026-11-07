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
 * Single-row platform settings for the NIX-389 locked-tile presentation
 * policy. Column types mirror V20261107100000__platform_display_settings.sql
 * exactly (TIMESTAMPTZ → Instant); the CHECK constraint keeps the policy
 * inside {SHOW_LOCKED, HIDE} at the database level.
 */
@Entity
@Table(name = "platform_display_settings")
@Getter
@Setter
public class PlatformDisplaySettingsJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "locked_tile_policy", nullable = false, length = 20)
    private String lockedTilePolicy;

    @Column(name = "updated_at", insertable = false, updatable = false)
    private Instant updatedAt;

    @Column(name = "updated_by", length = 100)
    private String updatedBy;
}
