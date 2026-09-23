package com.smartlivestock.health.domain.port;

import com.smartlivestock.health.domain.port.dto.AlertInfo;

/**
 * ACL command port for Health context to write Ranch context data.
 */
public interface RanchCommandPort {
    void createAlert(AlertInfo alertInfo);
    void resolveAlert(Long livestockId, String alertType);

    /**
     * Resolves only ACTIVE alerts of the livestock raised by the given source
     * (e.g. "AI"). Unlike {@link #resolveAlert} this cannot clobber alerts
     * owned by another pipeline (the rule bridge only re-creates on state
     * transitions, so a cross-source resolve could silence a live fever alert).
     */
    void resolveAlertsBySource(Long livestockId, String source);
}
