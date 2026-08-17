package com.smartlivestock.health.infrastructure.acl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import org.springframework.stereotype.Component;

@Component("healthRanchCommandPort")
public class RanchCommandPortImpl implements RanchCommandPort {

    private final AlertRepository alertRepository;
    private final ObjectMapper objectMapper;

    public RanchCommandPortImpl(AlertRepository alertRepository, ObjectMapper objectMapper) {
        this.alertRepository = alertRepository;
        this.objectMapper = objectMapper;
    }

    @Override
    public void createAlert(AlertInfo info) {
        Alert alert = new Alert(
                info.farmId(),
                info.livestockId(),
                null,
                AlertType.valueOf(info.alertType()),
                Severity.valueOf(info.severity()),
               info.message());
        alert.setSource(info.source());
        alert.setMessageKey(info.messageKey());
        alert.setMessageArgs(toJson(info.messageArgs()));
       alertRepository.save(alert);
    }

    @Override
    public void resolveAlert(Long livestockId, String alertType) {
        AlertType type = AlertType.valueOf(alertType);
        var activeAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, type,
                com.smartlivestock.ranch.domain.model.AlertStatus.ACTIVE);
        for (Alert alert : activeAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
        }
    }

    private String toJson(java.util.List<?> args) {
        if (args == null) return null;
        try {
            return objectMapper.writeValueAsString(args);
        } catch (Exception e) {
            return null;
        }
    }
}
