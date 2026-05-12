package com.smartlivestock.ranch.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

/**
 * Domain event fired when a livestock breaches a fence boundary.
 */
public class FenceBreachDetectedEvent extends DomainEvent {

    private final Long fenceId;
    private final Long livestockId;

    public FenceBreachDetectedEvent(Long fenceId, Long livestockId) {
        this.fenceId = fenceId;
        this.livestockId = livestockId;
    }

    public Long getFenceId() { return fenceId; }
    public Long getLivestockId() { return livestockId; }
}
