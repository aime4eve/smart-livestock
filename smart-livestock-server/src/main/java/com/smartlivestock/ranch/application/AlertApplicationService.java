package com.smartlivestock.ranch.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.application.dto.AlertSummaryDto.AlertSummaryResponse;
import com.smartlivestock.ranch.application.dto.AlertSummaryDto.ActiveSummary;
import com.smartlivestock.ranch.application.dto.AlertSummaryDto.TypeGroupCounts;
import com.smartlivestock.ranch.application.service.AlertMessageLocalizer;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertReadStatusJpaEntity;
import com.smartlivestock.ranch.application.signal.SignalRevisionService;
import com.smartlivestock.shared.cache.RedisCacheService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AlertApplicationService {

    private static final String SUMMARY_CACHE_PREFIX = "alerts:summary:";
    private static final Set<String> GROUP_FENCE = Set.of("FENCE_BREACH", "FENCE_APPROACH", "ZONE_APPROACH");
    private static final Set<String> GROUP_HEALTH = Set.of(
            "TEMPERATURE_ABNORMAL", "DIGESTIVE_ABNORMAL", "ESTRUS", "EPIDEMIC", "AI_ANOMALY");
    private static final Set<String> GROUP_DEVICE = Set.of("DEVICE_TAMPER", "DEVICE_LOW_BATTERY", "DEVICE_OFFLINE");

    private final AlertRepository alertRepository;
    private final SpringDataAlertReadStatusRepository readStatusRepository;
    private final AlertMessageLocalizer alertMessageLocalizer;
    private final IoTQueryPort ioTQueryPort;
    private final RedisCacheService redisCacheService;
    private final ObjectMapper objectMapper;
    private final SignalRevisionService signalRevisionService;

    // ── Create ──

    @Transactional
    public AlertDto createAlert(Long farmId, AlertType type, Severity severity, String message) {
        Alert alert = new Alert(farmId, null, null, type, severity, message);
        Alert saved = alertRepository.save(alert);
        signalRevisionService.bumpStatus(farmId);
        return fromLocalized(saved);
    }

    @Transactional
    public AlertDto createAlert(Long farmId, Long livestockId, Long fenceId,
                                AlertType type, Severity severity, String message) {
        Alert alert = new Alert(farmId, livestockId, fenceId, type, severity, message);
        Alert saved = alertRepository.save(alert);
        signalRevisionService.bumpStatus(farmId);
        return fromLocalized(saved);
    }

    // ── Read (single) ──

    @Transactional(readOnly = true)
    public AlertDto getAlert(Long id) {
        Alert alert = getAlertDomain(id);
        return fromLocalized(alert, deviceCodes(List.of(alert)));
    }

    @Transactional(readOnly = true)
    public AlertDto getAlertWithReadStatus(Long id, Long userId) {
        Alert alert = getAlertDomain(id);
        boolean read = readStatusRepository.existsByAlertIdAndUserId(id, userId);
        return fromLocalized(alert, deviceCodes(List.of(alert))).withRead(read);
    }

    @Transactional(readOnly = true)
    public Alert getAlertDomain(Long id) {
        return alertRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "告警不存在: " + id));
    }

    // ── List ──

    @Transactional(readOnly = true)
    public List<AlertDto> listByFarm(Long farmId) {
        List<Alert> alerts = alertRepository.findByFarmId(farmId);
        Map<Long, String> codes = deviceCodes(alerts);
        return alerts.stream()
                .map(alert -> fromLocalized(alert, codes))
                .toList();
    }

    /**
     * True pagination with real total (replaces the former recent-200 window).
     *
     * @param status     null = all; ACTIVE / RESOLVED (DISMISSED+AUTO_RESOLVED) / single status
     * @param severity   null = all
     * @param types      null/empty = all alert types
     * @param fenceId    null = no fence filter
     * @param unreadOnly keep only alerts the user has not read (needs userId)
     * @param userId     nullable (Open API): read flags stay false when null
     */
    @Transactional(readOnly = true)
    public AlertRepository.AlertPage<AlertDto> listByFarmPaged(Long farmId, Long userId, String status,
                                                               String severity, Collection<String> types,
                                                               Long fenceId, boolean unreadOnly,
                                                               int page, int pageSize) {
        List<AlertStatus> statuses = resolveStatuses(status);
        Severity severityEnum = resolveSeverity(severity);
        boolean filterUnread = unreadOnly && userId != null;
        AlertRepository.AlertPage<Alert> result = alertRepository.findPageByFilters(
                farmId, statuses, severityEnum, types, fenceId, filterUnread, userId, page, pageSize);

        Map<Long, String> codes = deviceCodes(result.items());
        Set<Long> readIds = userId == null || result.items().isEmpty()
                ? Set.of()
                : readStatusRepository.findReadAlertIdsByUserId(userId,
                        result.items().stream().map(Alert::getId).toList());
        List<AlertDto> items = result.items().stream()
                .map(alert -> fromLocalized(alert, codes)
                        .withRead(readIds.contains(alert.getId())))
                .toList();
        return new AlertRepository.AlertPage<>(items, result.total());
    }

    /**
     * Farm-global alert counters (summary strip / ranch badges), short-TTL
     * cached per user because unread differs per user. Cross-user staleness
     * after rule-driven changes is bounded by the 10s TTL. When {@code types}
     * is non-empty the counters are scoped to those alert types (category
     * views) and the cache key varies with the type set.
     */
    @Transactional(readOnly = true)
    public AlertSummaryResponse getAlertSummary(Long farmId, Long userId, Collection<String> types) {
        String cacheKey = summaryCacheKey(farmId, userId, types);
        try {
            String cached = redisCacheService.get(cacheKey);
            if (cached != null) {
                return objectMapper.readValue(cached, AlertSummaryResponse.class);
            }
        } catch (Exception ignored) {
            // Cache miss or deserialization error — fall through to DB query
        }

        int activeTotal = 0, critical = 0, warning = 0, info = 0, resolved = 0;
        Map<String, Long> activeByType = new HashMap<>();
        for (AlertRepository.StatusSeverityTypeCount row : alertRepository.countByFarmGrouped(farmId, types)) {
            if ("ACTIVE".equals(row.status())) {
                int c = (int) row.count();
                activeTotal += c;
                switch (row.severity() == null ? "" : row.severity()) {
                    case "CRITICAL" -> critical += c;
                    case "WARNING" -> warning += c;
                    // default bins INFO (and anything unexpected) so the three
                    // cells always reconcile with total
                    default -> info += c;
                }
                activeByType.merge(row.type(), row.count(), Long::sum);
            } else {
                resolved += (int) row.count();
            }
        }

        int unreadTotal = 0;
        Map<String, Long> unreadByType = new HashMap<>();
        for (AlertRepository.TypeCount row : alertRepository.countActiveUnreadGroupedByType(farmId, userId, types)) {
            unreadTotal += (int) row.count();
            unreadByType.put(row.type(), row.count());
        }

        AlertSummaryResponse response = new AlertSummaryResponse(
                new ActiveSummary(activeTotal, unreadTotal, critical, warning, info,
                        groupCounts(activeByType), groupCounts(unreadByType)),
                resolved);

        try {
            redisCacheService.set(cacheKey, objectMapper.writeValueAsString(response), Duration.ofSeconds(10));
        } catch (Exception ignored) {
            // Cache write failure is non-critical
        }
        return response;
    }

    private TypeGroupCounts groupCounts(Map<String, Long> byType) {
        return new TypeGroupCounts(
                sumGroup(byType, GROUP_FENCE),
                sumGroup(byType, GROUP_HEALTH),
                sumGroup(byType, GROUP_DEVICE));
    }

    private int sumGroup(Map<String, Long> byType, Set<String> group) {
        return (int) byType.entrySet().stream()
                .filter(e -> group.contains(e.getKey()))
                .mapToLong(Map.Entry::getValue)
                .sum();
    }

    private List<AlertStatus> resolveStatuses(String status) {
        if (status == null || status.isBlank()) {
            return List.of(AlertStatus.values());
        }
        return switch (status.toUpperCase()) {
            case "ACTIVE" -> List.of(AlertStatus.ACTIVE);
            case "RESOLVED" -> List.of(AlertStatus.DISMISSED, AlertStatus.AUTO_RESOLVED);
            case "DISMISSED" -> List.of(AlertStatus.DISMISSED);
            case "AUTO_RESOLVED" -> List.of(AlertStatus.AUTO_RESOLVED);
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR, "非法 status: " + status);
        };
    }

    private Severity resolveSeverity(String severity) {
        if (severity == null || severity.isBlank()) return null;
        try {
            return Severity.valueOf(severity.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "非法 severity: " + severity);
        }
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
        Alert alert = getAlertDomain(alertId); // ensure exists
        readStatusRepository.insertOnConflictDoNothing(alertId, userId);
        evictSummaryCache(alert.getFarmId(), userId);
        signalRevisionService.bumpStatus(alert.getFarmId());
        return getAlertWithReadStatus(alertId, userId);
    }

    @Transactional
    public int batchRead(List<Long> alertIds, Long userId) {
        int count = 0;
        Set<Long> affectedFarms = new LinkedHashSet<>();
        for (Long alertId : alertIds) {
            Alert alert = alertRepository.findById(alertId).orElse(null);
            if (alert != null) {
                readStatusRepository.insertOnConflictDoNothing(alertId, userId);
                affectedFarms.add(alert.getFarmId());
                count++;
            }
        }
        affectedFarms.forEach(farmId -> evictSummaryCache(farmId, userId));
        affectedFarms.forEach(signalRevisionService::bumpStatus);
        return count;
    }

    // ── Dismiss / Auto-resolve ──

    @Transactional
    public AlertDto dismiss(Long alertId, Long userId) {
        Alert alert = getAlertDomain(alertId);
        alert.dismiss(userId);
        Alert saved = alertRepository.save(alert);
        evictSummaryCache(saved.getFarmId(), userId);
        signalRevisionService.bumpStatus(saved.getFarmId());
        return getAlertWithReadStatus(saved.getId(), userId);
    }

    @Transactional
    public AlertDto autoResolve(Long alertId) {
        Alert alert = getAlertDomain(alertId);
        alert.autoResolve();
        Alert saved = alertRepository.save(alert);
        signalRevisionService.bumpStatus(alert.getFarmId());
        return fromLocalized(saved);
    }

    @Transactional
    public void autoResolveByLivestockAndType(Long livestockId, AlertType type) {
        List<Alert> activeAlerts = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, type, AlertStatus.ACTIVE);
        for (Alert alert : activeAlerts) {
            alert.autoResolve();
            alertRepository.save(alert);
            signalRevisionService.bumpStatus(alert.getFarmId());
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

    private String summaryCacheKey(Long farmId, Long userId, Collection<String> types) {
        String typeSuffix = (types == null || types.isEmpty())
                ? "all"
                : types.stream().sorted().collect(Collectors.joining(","));
        return SUMMARY_CACHE_PREFIX + farmId + ":" + userId + ":" + typeSuffix;
    }

    /**
     * Per-user summary cache eviction (farm-wide variant). Rule-driven status
     * changes (create/autoResolve from telemetry consumers) don't pass through
     * here, and category-scoped variants rely on the 10s TTL.
     */
    private void evictSummaryCache(Long farmId, Long userId) {
        try {
            redisCacheService.delete(summaryCacheKey(farmId, userId, null));
        } catch (Exception ignored) {
            // Eviction failure is non-critical: TTL bounds staleness
        }
    }

    private AlertDto fromLocalized(Alert alert) {
        return fromLocalized(alert, Map.of());
    }

    private AlertDto fromLocalized(Alert alert, Map<Long, String> deviceCodes) {
        String code = alert.getDeviceId() == null ? null : deviceCodes.get(alert.getDeviceId());
        return AlertDto.from(alert, alertMessageLocalizer.localize(alert), code);
    }

    /** Batch-resolve device serials for device-originated alerts (one port call). */
    private Map<Long, String> deviceCodes(List<Alert> alerts) {
        List<Long> deviceIds = alerts.stream()
                .map(Alert::getDeviceId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        if (deviceIds.isEmpty()) return Map.of();
        Map<Long, String> codes = ioTQueryPort.findDeviceCodesByIds(deviceIds);
        return codes == null ? Map.of() : codes;
    }
}
