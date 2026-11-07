package com.smartlivestock.commerce.domain.model;

import java.time.Instant;

/**
 * Single-row platform display settings (NIX-389). Domain mirror of the
 * platform_display_settings table (V20261107100000).
 */
public class PlatformDisplaySettings {

    private Long id;
    private LockedTilePolicy lockedTilePolicy;
    private Instant updatedAt;
    private String updatedBy;

    public PlatformDisplaySettings() {}

    public PlatformDisplaySettings(Long id, LockedTilePolicy lockedTilePolicy,
                                   Instant updatedAt, String updatedBy) {
        this.id = id;
        this.lockedTilePolicy = lockedTilePolicy;
        this.updatedAt = updatedAt;
        this.updatedBy = updatedBy;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public LockedTilePolicy getLockedTilePolicy() { return lockedTilePolicy; }
    public void setLockedTilePolicy(LockedTilePolicy lockedTilePolicy) { this.lockedTilePolicy = lockedTilePolicy; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    public String getUpdatedBy() { return updatedBy; }
    public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }
}
