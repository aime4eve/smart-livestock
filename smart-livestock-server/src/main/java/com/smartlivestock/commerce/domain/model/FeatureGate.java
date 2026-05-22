package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.domain.Entity;

public class FeatureGate extends Entity {

    private String tier;
    private String featureKey;
    private GateType gateType;
    private Integer limitValue;
    private Integer retentionDays;
    private boolean isEnabled;

    public FeatureGate() {
    }

    public FeatureGate(String tier, String featureKey, GateType gateType,
                       Integer limitValue, Integer retentionDays, boolean isEnabled) {
        this.tier = tier;
        this.featureKey = featureKey;
        this.gateType = gateType;
        this.limitValue = limitValue;
        this.retentionDays = retentionDays;
        this.isEnabled = isEnabled;
    }

    public static FeatureGate unrestricted() {
        return new FeatureGate(null, null, GateType.NONE, null, null, true);
    }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public String getFeatureKey() { return featureKey; }
    public void setFeatureKey(String featureKey) { this.featureKey = featureKey; }

    public GateType getGateType() { return gateType; }
    public void setGateType(GateType gateType) { this.gateType = gateType; }

    public Integer getLimitValue() { return limitValue; }
    public void setLimitValue(Integer limitValue) { this.limitValue = limitValue; }

    public Integer getRetentionDays() { return retentionDays; }
    public void setRetentionDays(Integer retentionDays) { this.retentionDays = retentionDays; }

    public boolean isEnabled() { return isEnabled; }
    public void setEnabled(boolean enabled) { isEnabled = enabled; }
}
