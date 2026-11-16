package com.smartlivestock.platform.messaging.push;

import com.eatthepath.pushy.apns.ApnsClient;
import com.eatthepath.pushy.apns.ApnsClientBuilder;
import com.eatthepath.pushy.apns.util.SimpleApnsPushNotification;
import com.eatthepath.pushy.apns.auth.ApnsSigningKey;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

/**
 * NIX-430: thin Pushy wrapper for the APNs provider API (token-based auth
 * with the .p8 key — the same key family as the App Store Connect API key).
 * One client per environment (sandbox hosts dev-signed builds, production
 * hosts TestFlight/App Store); clients are built lazily and reused.
 */
@Service
public class ApnsPushService {

    private static final Logger log = LoggerFactory.getLogger(ApnsPushService.class);

    private final PushProperties properties;
    private final Map<String, ApnsClient> clientsByEnv = new HashMap<>();

    public ApnsPushService(PushProperties properties) {
        this.properties = properties;
    }

    /**
     * Fire-and-forget send: Pushy handles the IO on its own event loop; the
     * callback reports per-token outcomes. {@code invalidTokenSink} receives
     * tokens APNs no longer accepts (BadDeviceToken / Unregistered) so the
     * caller can reap them.
     */
    public void sendAll(Collection<UserPushTokenJpaEntity> tokens, String payloadJson,
                        Consumer<String> invalidTokenSink) {
        ApnsClient client = clientFor(properties.getEnvironment());
        if (client == null) {
            log.warn("[push] APNs client unavailable (enabled={}, key configured: {}) — skipping {} sends",
                    properties.isEnabled(), properties.getKeyPath() != null, tokens.size());
            return;
        }
        for (UserPushTokenJpaEntity tokenRow : tokens) {
            SimpleApnsPushNotification notification = new SimpleApnsPushNotification(
                    tokenRow.getToken(), properties.getTopic(), payloadJson);
            try {
                client.sendNotification(notification).whenComplete((response, throwable) -> {
                    if (throwable != null) {
                        log.warn("[push] send failed token=…{}: {}",
                                tail(tokenRow.getToken()), throwable.toString());
                        return;
                    }
                    if (!response.isAccepted()) {
                        String reason = response.getRejectionReason()
                                .map(Object::toString).orElse("unknown");
                        log.info("[push] rejected token=…{} reason={}", tail(tokenRow.getToken()), reason);
                        if ("BadDeviceToken".equals(reason) || "Unregistered".equals(reason)) {
                            invalidTokenSink.accept(tokenRow.getToken());
                        }
                    }
                });
            } catch (IllegalStateException e) {
                // Pushy throws ISE if the client was shut down mid-flight.
                log.warn("[push] client closed before send: {}", e.toString());
                return;
            }
        }
    }

    private ApnsClient clientFor(String environment) {
        synchronized (clientsByEnv) {
            ApnsClient existing = clientsByEnv.get(environment);
            if (existing != null) {
                // Closed clients are evicted from this map in close(); a cached
                // one is always live (Pushy 0.15 has no isOpen probe).
                return existing;
            }
        }
        if (properties.getKeyId() == null || properties.getTeamId() == null
                || (properties.getKeyBase64() == null && properties.getKeyPath() == null)) {
            log.error("[push] APNs enabled but key-id/team-id/key material incomplete — push disabled");
            return null;
        }
        try {
            boolean production = "production".equalsIgnoreCase(environment);
            ApnsSigningKey signingKey = loadSigningKey();
            ApnsClient client = new ApnsClientBuilder()
                    .setApnsServer(production
                            ? ApnsClientBuilder.PRODUCTION_APNS_HOST
                            : ApnsClientBuilder.DEVELOPMENT_APNS_HOST)
                    .setSigningKey(signingKey)
                    .build();
            synchronized (clientsByEnv) {
                clientsByEnv.put(environment, client);
            }
            log.info("[push] APNs client ready (environment={}, topic={})",
                    environment, properties.getTopic());
            return client;
        } catch (IOException | GeneralSecurityException e) {
            log.error("[push] failed to build APNs client for {}: {}", environment, e.toString());
            return null;
        }
    }

    /** Base64 env var wins over the file path — see PushProperties.keyBase64. */
    private ApnsSigningKey loadSigningKey()
            throws IOException, GeneralSecurityException {
        if (properties.getKeyBase64() != null && !properties.getKeyBase64().isBlank()) {
            byte[] pem = java.util.Base64.getDecoder()
                    .decode(properties.getKeyBase64().replaceAll("\\s", ""));
            return ApnsSigningKey.loadFromInputStream(
                    new java.io.ByteArrayInputStream(pem),
                    properties.getTeamId(), properties.getKeyId());
        }
        return ApnsSigningKey.loadFromPkcs8File(
                new File(properties.getKeyPath()),
                properties.getTeamId(), properties.getKeyId());
    }

    private static String tail(String token) {
        return token.length() <= 8 ? token : token.substring(token.length() - 8);
    }

    @PreDestroy
    void close() {
        synchronized (clientsByEnv) {
            clientsByEnv.values().forEach(client -> {
                try {
                    client.close().get(5, java.util.concurrent.TimeUnit.SECONDS);
                } catch (Exception e) {
                    log.warn("[push] client close interrupted: {}", e.toString());
                }
            });
            clientsByEnv.clear();
        }
    }
}
