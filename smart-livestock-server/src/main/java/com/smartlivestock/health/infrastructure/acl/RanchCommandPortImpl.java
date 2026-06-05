package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import org.springframework.stereotype.Component;

@Component("healthRanchCommandPort")
public class RanchCommandPortImpl implements RanchCommandPort {

    private final AlertRepository alertRepository;

    public RanchCommandPortImpl(AlertRepository alertRepository) {
        this.alertRepository = alertRepository;
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
        alertRepository.save(alert);
    }
}
