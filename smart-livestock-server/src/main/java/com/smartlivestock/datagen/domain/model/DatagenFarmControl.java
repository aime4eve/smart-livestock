package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

public class DatagenFarmControl extends AggregateRoot {
    private Long tenantId;
    private Long farmId;
    private Long scenarioId;
    private boolean enabled;
    private Instant createdAt;
    private Instant updatedAt;

    public void enable() { this.enabled = true; }

    public void disable() { this.enabled = false; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public Long getScenarioId() { return scenarioId; }
    public void setScenarioId(Long scenarioId) { this.scenarioId = scenarioId; }

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
