package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.domain.Entity;

public class FeatureGate extends Entity {

    private String tier;
    private String featureKey;
    private String gateType;
    private Integer limitValue;
    private Integer retentionDays;
    private boolean isEnabled;

    public FeatureGate() {
    }

    public FeatureGate(String tier, String featureKey, String gateType,
                       Integer limitValue, Integer retentionDays, boolean isEnabled) {
        this.tier = tier;
        this.featureKey = featureKey;
        this.gateType = gateType;
        this.limitValue = limitValue;
        this.retentionDays = retentionDays;
        this.isEnabled = isEnabled;
    }

    public boolean allowsUnrestricted() {
        return "none".equals(gateType);
    }

    public boolean isLocked() {
        return "lock".equals(gateType);
    }

    public boolean isLimited() {
        return "limit".equals(gateType);
    }

    public boolean isFiltered() {
        return "filter".equals(gateType);
    }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public String getFeatureKey() { return featureKey; }
    public void setFeatureKey(String featureKey) { this.featureKey = featureKey; }

    public String getGateType() { return gateType; }
    public void setGateType(String gateType) { this.gateType = gateType; }

    public Integer getLimitValue() { return limitValue; }
    public void setLimitValue(Integer limitValue) { this.limitValue = limitValue; }

    public Integer getRetentionDays() { return retentionDays; }
    public void setRetentionDays(Integer retentionDays) { this.retentionDays = retentionDays; }

    public boolean isEnabled() { return isEnabled; }
    public void setEnabled(boolean enabled) { isEnabled = enabled; }
}
