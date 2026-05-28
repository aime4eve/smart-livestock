package com.smartlivestock.commerce.application.dto;

/**
 * Request DTO for subscription checkout.
 */
public class CheckoutRequest {

    private String tier;
    private String billingCycle;

    public CheckoutRequest() {
    }

    public CheckoutRequest(String tier, String billingCycle) {
        this.tier = tier;
        this.billingCycle = billingCycle;
    }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public String getBillingCycle() { return billingCycle; }
    public void setBillingCycle(String billingCycle) { this.billingCycle = billingCycle; }
}
