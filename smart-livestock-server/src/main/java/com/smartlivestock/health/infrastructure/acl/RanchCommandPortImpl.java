package com.smartlivestock.health.infrastructure.acl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.application.signal.SignalRevisionService;
import org.springframework.stereotype.Component;

@Component("healthRanchCommandPort")
public class RanchCommandPortImpl implements RanchCommandPort {

    private final AlertRepository alertRepository;
    private final ObjectMapper objectMapper;
    private final SignalRevisionService signalRevisionService;

    public RanchCommandPortImpl(AlertRepository alertRepository, ObjectMapper objectMapper,
                                SignalRevisionService signalRevisionService) {
        this.alertRepository = alertRepository;
        this.objectMapper = objectMapper;
        this.signalRevisionService = signalRevisionService;
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
       signalRevisionService.bumpStatus(info.farmId());
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
            signalRevisionService.bumpStatus(alert.getFarmId());
        }
    }

    @Override
    public void resolveAlertsBySource(Long livestockId, String source) {
        var activeAlerts = alertRepository.findByLivestockIdAndStatusAndSource(
                livestockId,
                com.smartlivestock.ranch.domain.model.AlertStatus.ACTIVE,
                source);
        for (Alert alert : activeAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
            signalRevisionService.bumpStatus(alert.getFarmId());
        }
    }

    @Override
    public void resolveFarmAlertsByType(Long farmId, String alertType) {
        AlertType type = AlertType.valueOf(alertType);
        var activeAlerts = alertRepository.findByFarmIdAndTypeAndStatus(
                farmId, type,
                com.smartlivestock.ranch.domain.model.AlertStatus.ACTIVE);
        for (Alert alert : activeAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
            signalRevisionService.bumpStatus(farmId);
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
