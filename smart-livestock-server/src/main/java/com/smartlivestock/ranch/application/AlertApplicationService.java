package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.command.AcknowledgeAlertCommand;
import com.smartlivestock.ranch.application.command.ArchiveAlertCommand;
import com.smartlivestock.ranch.application.command.HandleAlertCommand;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AlertApplicationService {

    private final AlertRepository alertRepository;

    @Transactional
    public AlertDto createAlert(Long farmId, AlertType type, Severity severity, String message) {
        Alert alert = new Alert(farmId, null, null, type, severity, message);
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }

    @Transactional(readOnly = true)
    public AlertDto getAlert(Long id) {
        Alert alert = alertRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "告警不存在: " + id));
        return AlertDto.from(alert);
    }

    @Transactional(readOnly = true)
    public List<AlertDto> listByFarm(Long farmId) {
        return alertRepository.findByFarmId(farmId).stream()
                .map(AlertDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlertDto> listByFarmAndStatus(Long farmId, AlertStatus status) {
        return alertRepository.findByFarmIdAndStatus(farmId, status).stream()
                .map(AlertDto::from)
                .toList();
    }

    @Transactional
    public AlertDto acknowledge(AcknowledgeAlertCommand command) {
        Alert alert = alertRepository.findById(command.alertId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "告警不存在: " + command.alertId()));
        alert.acknowledge(command.userId());
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }

    @Transactional
    public AlertDto handle(HandleAlertCommand command) {
        Alert alert = alertRepository.findById(command.alertId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "告警不存在: " + command.alertId()));
        alert.handle(command.userId());
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }

    @Transactional
    public AlertDto archive(ArchiveAlertCommand command) {
        Alert alert = alertRepository.findById(command.alertId())
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "告警不存在: " + command.alertId()));
        alert.archive(command.userId());
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }
}
