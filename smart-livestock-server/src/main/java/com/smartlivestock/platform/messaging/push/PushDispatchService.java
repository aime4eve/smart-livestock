package com.smartlivestock.platform.messaging.push;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.UserJpaEntity;
import com.smartlivestock.ranch.application.service.AlertMessageLocalizer;
import com.smartlivestock.ranch.application.signal.AlertCreatedEvent;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Consumer;
import java.util.stream.Collectors;

/**
 * NIX-430: pushes alerts to the devices of the farm's active members.
 * Listens for {@link AlertCreatedEvent} after the alert commit, then fans
 * out off-thread: recipients = farm ACTIVE assignments whose
 * {@code users.push_alerts_enabled} is on, tokens filtered to the server's
 * APNs environment. Invalid tokens reported by APNs are reaped.
 */
@Service
public class PushDispatchService {

    private static final Logger log = LoggerFactory.getLogger(PushDispatchService.class);

    private final PushProperties properties;
    private final ApnsPushService apnsPushService;
    private final AlertRepository alertRepository;
    private final AlertMessageLocalizer alertMessageLocalizer;
    private final UserFarmAssignmentRepository userFarmAssignmentRepository;
    private final SpringDataUserRepository userRepository;
    private final SpringDataUserPushTokenRepository pushTokenRepository;
    private final ObjectMapper objectMapper;

    /** Serializes the (small) fan-out work; the network IO itself is Pushy-async. */
    private final ExecutorService dispatchExecutor =
            Executors.newSingleThreadExecutor(r -> {
                Thread t = new Thread(r, "push-dispatch");
                t.setDaemon(true);
                return t;
            });

    public PushDispatchService(PushProperties properties, ApnsPushService apnsPushService,
                               AlertRepository alertRepository,
                               AlertMessageLocalizer alertMessageLocalizer,
                               UserFarmAssignmentRepository userFarmAssignmentRepository,
                               SpringDataUserRepository userRepository,
                               SpringDataUserPushTokenRepository pushTokenRepository,
                               ObjectMapper objectMapper) {
        this.properties = properties;
        this.apnsPushService = apnsPushService;
        this.alertRepository = alertRepository;
        this.alertMessageLocalizer = alertMessageLocalizer;
        this.userFarmAssignmentRepository = userFarmAssignmentRepository;
        this.userRepository = userRepository;
        this.pushTokenRepository = pushTokenRepository;
        this.objectMapper = objectMapper;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onAlertCreated(AlertCreatedEvent event) {
        if (!properties.isEnabled()) {
            return;
        }
        dispatchExecutor.execute(() -> {
            try {
                doDispatch(event);
            } catch (Exception e) {
                // The dispatch must never take the caller down — log and move on.
                log.error("[push] dispatch failed for alert {}: {}",
                        event.alertId(), e.toString(), e);
            }
        });
    }

    void doDispatch(AlertCreatedEvent event) {
        // Belt-and-braces guard (the listener checks too): keeps the gate
        // testable at doDispatch level and safe for direct callers.
        if (!properties.isEnabled()) {
            return;
        }
        Alert alert = alertRepository.findById(event.alertId()).orElse(null);
        if (alert == null) {
            log.warn("[push] alert {} vanished before dispatch", event.alertId());
            return;
        }
        Set<Long> userIds = userFarmAssignmentRepository
                .findByFarmIdAndStatus(event.farmId(), "ACTIVE").stream()
                .map(a -> a.getUserId())
                .collect(Collectors.toSet());
        if (userIds.isEmpty()) {
            return;
        }
        List<Long> pushableUserIds = userRepository.findAllById(userIds).stream()
                .filter(u -> Boolean.TRUE.equals(u.getPushAlertsEnabled()))
                .map(UserJpaEntity::getId)
                .toList();
        if (pushableUserIds.isEmpty()) {
            return;
        }
        List<UserPushTokenJpaEntity> tokens = pushTokenRepository
                .findByUserIdInAndPlatform(pushableUserIds, "ios").stream()
                .filter(t -> properties.getEnvironment().equalsIgnoreCase(t.getApnsEnv()))
                .toList();
        if (tokens.isEmpty()) {
            return;
        }

        String body = alertMessageLocalizer.localize(alert,
                java.util.Locale.forLanguageTag(properties.getLocale()));
        String payload = buildPayload(event.farmId(), alert, body);
        log.info("[push] dispatching alert {} to {} device(s) (env={})",
                event.alertId(), tokens.size(), properties.getEnvironment());

        // Reaping must not run on Pushy's Netty event loop (blocking JPA IO) —
        // hand it back to the dispatch executor.
        Consumer<String> invalidTokenSink = invalidToken ->
                dispatchExecutor.execute(() ->
                        pushTokenRepository.findByToken(invalidToken)
                                .ifPresent(pushTokenRepository::delete));
        apnsPushService.sendAll(tokens, payload, invalidTokenSink);
    }

    private String buildPayload(Long farmId, Alert alert, String body) {
        try {
            Map<String, Object> aps = Map.of(
                    "alert", Map.of(
                            "title", "BoviScout",
                            "body", body == null ? "" : body),
                    "sound", "default");
            Map<String, Object> custom = Map.of(
                    "alertId", alert.getId(),
                    "farmId", farmId,
                    "type", alert.getType().name(),
                    "severity", alert.getSeverity().name());
            Map<String, Object> root = new java.util.HashMap<>(aps);
            root.putAll(custom);
            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            // Payload build must never break dispatch — degrade to minimal alert.
            log.warn("[push] payload build failed, falling back to minimal: {}", e.toString());
            return "{\"aps\":{\"alert\":{\"title\":\"BoviScout\",\"body\":\"\"},\"sound\":\"default\"}}";
        }
    }
}
