package com.smartlivestock.health.domain.model;

import java.time.Instant;

/**
 * Physiology event aggregate root (NIX-256): a dated husbandry milestone on
 * one animal — calving, breeding, pregnancy check, dry off, illness or
 * recovery. Illness windows have no stored end: they are closed by the paired
 * RECOVERY event at read time (see {@code PhysiologyQueryPort}).
 */
public class PhysiologyEvent {

    private Long id;
    private Long livestockId;
    private PhysiologyEventType eventType;
    private Instant occurredAt;
    private PhysiologySource source;
    private Long refId;
    private String note;
    private Long createdBy;
    private Instant createdAt;
    private Long updatedBy;
    private Instant updatedAt;

    public PhysiologyEvent() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }

    public PhysiologyEventType getEventType() { return eventType; }
    public void setEventType(PhysiologyEventType eventType) { this.eventType = eventType; }

    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }

    public PhysiologySource getSource() { return source; }
    public void setSource(PhysiologySource source) { this.source = source; }

    public Long getRefId() { return refId; }
    public void setRefId(Long refId) { this.refId = refId; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public Long getCreatedBy() { return createdBy; }
    public void setCreatedBy(Long createdBy) { this.createdBy = createdBy; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Long getUpdatedBy() { return updatedBy; }
    public void setUpdatedBy(Long updatedBy) { this.updatedBy = updatedBy; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
