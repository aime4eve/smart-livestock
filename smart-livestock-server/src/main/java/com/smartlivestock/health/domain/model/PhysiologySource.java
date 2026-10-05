package com.smartlivestock.health.domain.model;

/**
 * Origin of a physiology event. MANUAL rows come from user entry and are the
 * only editable/deletable ones; ALERT_CONFIRM rows are confirmed from an
 * alert side flow and are read-only (409 on edit/delete attempts).
 */
public enum PhysiologySource {
    MANUAL,
    ALERT_CONFIRM
}
