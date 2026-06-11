package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertReadStatusJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AlertApplicationService {

    private final AlertRepository alertRepository;
    private final SpringDataAlertReadStatusRepository readStatusRepository;

    // ── Create ──

    @Transactional
    public AlertDto createAlert(Long farmId, AlertType type, Severity severity, String message) {
        Alert alert = new Alert(farmId, null, null, type, severity, message);
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }

    @Transactional
    public AlertDto createAlert(Long farmId, Long livestockId, Long fenceId,
                                AlertType type, Severity severity, String message) {
        Alert alert = new Alert(farmId, livestockId, fenceId, type, severity, message);
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }

    // ── Read (single) ──

    @Transactional(readOnly = true)
    public AlertDto getAlert(Long id) {
        return AlertDto.from(getAlertDomain(id));
    }

    @Transactional(readOnly = true)
    public AlertDto getAlertWithReadStatus(Long id, Long userId) {
        Alert alert = getAlertDomain(id);
        boolean read = readStatusRepository.existsByAlertIdAndUserId(id, userId);
        return AlertDto.from(alert).withRead(read);
    }

    @Transactional(readOnly = true)
    public Alert getAlertDomain(Long id) {
        return alertRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "告警不存在: " + id));
    }

    // ── List ──

    @Transactional(readOnly = true)
    public List<AlertDto> listByFarm(Long farmId) {
        return alertRepository.findByFarmId(farmId).stream()
                .map(AlertDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AlertDto> listByFarmWithReadStatus(Long farmId, Long userId) {
        List<Alert> alerts = alertRepository.findByFarmId(farmId);
        return enrichWithReadStatus(alerts, userId);
    }

    @Transactional(readOnly = true)
    public List<AlertDto> listByFarmAndStatus(Long farmId, AlertStatus status) {
        return alertRepository.findByFarmIdAndStatus(farmId, status).stream()
                .map(AlertDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public long countByFarmAndType(Long farmId, AlertType type) {
        return alertRepository.findByFarmId(farmId).stream()
                .filter(a -> a.getType() == type && a.getStatus() == AlertStatus.ACTIVE)
                .count();
    }

    // ── Mark read (per-user) ──

    @Transactional
    public AlertDto markRead(Long alertId, Long userId) {
        getAlertDomain(alertId); // ensure exists
        readStatusRepository.insertOnConflictDoNothing(alertId, userId);
        return getAlertWithReadStatus(alertId, userId);
    }

    @Transactional
    public int batchRead(List<Long> alertIds, Long userId) {
        int count = 0;
        for (Long alertId : alertIds) {
            if (alertRepository.findById(alertId).isPresent()) {
                readStatusRepository.insertOnConflictDoNothing(alertId, userId);
                count++;
            }
        }
        return count;
    }

    // ── Dismiss / Auto-resolve ──

    @Transactional
    public AlertDto dismiss(Long alertId, Long userId) {
        Alert alert = getAlertDomain(alertId);
        alert.dismiss(userId);
        Alert saved = alertRepository.save(alert);
        return getAlertWithReadStatus(saved.getId(), userId);
    }

    @Transactional
    public AlertDto autoResolve(Long alertId) {
        Alert alert = getAlertDomain(alertId);
        alert.autoResolve();
        Alert saved = alertRepository.save(alert);
        return AlertDto.from(saved);
    }

    @Transactional
    public void autoResolveByLivestockAndType(Long livestockId, AlertType type) {
        List<Alert> activeAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, type, AlertStatus.ACTIVE);
        for (Alert alert : activeAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
        }
    }

    // ── Legacy compatibility ──

    @Transactional
    @Deprecated
    public AlertDto acknowledge(com.smartlivestock.ranch.application.command.AcknowledgeAlertCommand command) {
        // Legacy redirect: mark as read instead
        return markRead(command.alertId(), command.userId());
    }

    @Transactional
    @Deprecated
    public AlertDto handle(com.smartlivestock.ranch.application.command.HandleAlertCommand command) {
        return dismiss(command.alertId(), command.userId());
    }

    @Transactional
    @Deprecated
    public AlertDto archive(com.smartlivestock.ranch.application.command.ArchiveAlertCommand command) {
        return autoResolve(command.alertId());
    }

    // ── Private helpers ──

    private List<AlertDto> enrichWithReadStatus(List<Alert> alerts, Long userId) {
        if (alerts.isEmpty()) return List.of();
        List<Long> alertIds = alerts.stream().map(Alert::getId).toList();
        Set<Long> readAlertIds = readStatusRepository.findReadAlertIdsByUserId(userId, alertIds);
        return alerts.stream()
                .map(alert -> AlertDto.from(alert).withRead(readAlertIds.contains(alert.getId())))
                .toList();
    }
}
