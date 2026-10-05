package com.smartlivestock.health.domain.model;

/**
 * Physiology event types recorded on the manual event stream (NIX-256).
 * ILLNESS windows are closed by paired RECOVERY events; the other types are
 * point-in-time milestones consumed by stage derivation.
 */
public enum PhysiologyEventType {
    CALVING,
    BREEDING,
    PREGNANCY_CHECK,
    DRY_OFF,
    ILLNESS,
    RECOVERY
}
