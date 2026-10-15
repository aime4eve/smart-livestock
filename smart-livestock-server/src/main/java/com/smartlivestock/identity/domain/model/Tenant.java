package com.smartlivestock.identity.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import com.smartlivestock.identity.domain.event.TenantPhaseChangedEvent;

public class Tenant extends AggregateRoot {

    private String name;
    private String contactName;
    private String contactPhone;
    private TenantPhase phase;
    private String type;
    private String billingModel;
    private String timezone = "UTC";
    private String status = "active";
    private java.time.Instant deletedAt;

    public Tenant() {
        this.phase = TenantPhase.SAMPLE;
    }

    public Tenant(String name, String contactName, String contactPhone) {
        this.name = name;
        this.contactName = contactName;
        this.contactPhone = contactPhone;
        this.phase = TenantPhase.SAMPLE;
    }

    public void transitionToBatch() {
        if (this.phase == TenantPhase.BATCH) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "Tenant is already in BATCH phase");
        }
        this.phase = TenantPhase.BATCH;
        registerEvent(new TenantPhaseChangedEvent(getId(), this.phase));
    }

    /** BATCH → SAMPLE (operational ledger move back; idempotent on SAMPLE). */
    public void revertToSample() {
        this.phase = TenantPhase.SAMPLE;
        registerEvent(new TenantPhaseChangedEvent(getId(), this.phase));
    }

    public void reconstitutePhase(TenantPhase phase) {
        this.phase = phase;
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getContactName() { return contactName; }
    public void setContactName(String contactName) { this.contactName = contactName; }

    public String getContactPhone() { return contactPhone; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }

    public TenantPhase getPhase() { return phase; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getBillingModel() { return billingModel; }
    public void setBillingModel(String billingModel) { this.billingModel = billingModel; }

    public String getTimezone() { return timezone; }
    public void setTimezone(String timezone) { this.timezone = timezone; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public java.time.Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(java.time.Instant deletedAt) { this.deletedAt = deletedAt; }

    public boolean isDeleted() { return deletedAt != null; }

    /** Active → disabled (reversible); idempotent. */
    public void disable() { this.status = "disabled"; }

    /** disabled → active (reversible); idempotent. */
    public void enable() { this.status = "active"; }

    /** Soft delete: deleted_at set; business data untouched. */
    public void softDelete() { this.deletedAt = java.time.Instant.now(); }

    /** Clear the soft-delete marker (restore endpoint). */
    public void restore() { this.deletedAt = null; }
}
