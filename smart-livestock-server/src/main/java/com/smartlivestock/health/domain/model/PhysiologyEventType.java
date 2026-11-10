package com.smartlivestock.health.domain.model;

/**
 * Physiology event types recorded on the manual event stream (NIX-256).
 * ILLNESS windows are closed by paired RECOVERY events; the other types are
 * point-in-time milestones consumed by stage derivation.
 *
 * <p>ESTRUS_CONFIRM (NIX-286 contract v2) is audit-only history: it is
 * written exclusively with source {@link PhysiologySource#ALERT_CONFIRM} when
 * a human confirms/rejects a candidate estrus alert. It never participates in
 * stage derivation (kept out of PhysiologyQueryService.STAGE_TYPES) and must
 * not surface in the physiology record-card list.</p>
 */
public enum PhysiologyEventType {
    CALVING,
    BREEDING,
    PREGNANCY_CHECK,
    DRY_OFF,
    ILLNESS,
    RECOVERY,

    /** Audit-only estrus-alert verdict row (NIX-286) — see class javadoc. */
    ESTRUS_CONFIRM
}
