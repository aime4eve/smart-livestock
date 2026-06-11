package com.smartlivestock.health.domain.port;

import com.smartlivestock.health.domain.port.dto.AlertInfo;

/**
 * ACL command port for Health context to write Ranch context data.
 */
public interface RanchCommandPort {
    void createAlert(AlertInfo alertInfo);
    void resolveAlert(Long livestockId, String alertType);
}
