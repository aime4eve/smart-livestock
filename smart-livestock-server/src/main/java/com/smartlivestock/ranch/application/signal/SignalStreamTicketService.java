package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class SignalStreamTicketService {

    private final Map<String, TicketGrant> grantsByTicket = new ConcurrentHashMap<>();
    private final Map<String, TicketGrant> grantsByStreamToken = new ConcurrentHashMap<>();
    private final Clock clock;
    private final Duration ticketTtl;
    private final Duration reconnectTokenTtl;

    public SignalStreamTicketService(
            Clock clock,
            @Value("${signal.stream.ticket-ttl:PT30S}") Duration ticketTtl,
            @Value("${signal.stream.reconnect-token-ttl:PT10M}") Duration reconnectTokenTtl
    ) {
        this.clock = clock;
        this.ticketTtl = ticketTtl;
        this.reconnectTokenTtl = reconnectTokenTtl;
    }

    public TicketGrant issue(Long userId, Long tenantId, Long farmId) {
        cleanup();
        TicketGrant grant = new TicketGrant(
                UUID.randomUUID().toString(),
                UUID.randomUUID() + "." + UUID.randomUUID(),
                userId,
                tenantId,
                farmId,
                clock.instant(),
                clock.instant().plus(ticketTtl)
        );
        grantsByTicket.put(grant.ticket(), grant);
        grantsByStreamToken.put(grant.streamToken(), grant);
        return grant;
    }

    public TicketGrant consume(
            String ticket, Long userId, Long tenantId, Long farmId, String streamToken
    ) {
        cleanup();
        TicketGrant grant = grantsByTicket.get(ticket);
        if (grant == null) throw invalidTicket();

        synchronized (grant) {
            if (!grant.consumed) {
                if (!grant.matches(userId, tenantId, farmId)
                        || grant.expiresAt().isBefore(clock.instant())
                        || !grant.streamToken().equals(streamToken)) {
                    throw invalidTicket();
                }
                grant.consumed = true;
                return grant;
            }
        }

        return reconnect(streamToken, userId, tenantId, farmId);
    }

    public TicketGrant consume(
            String ticket, Long farmId, String streamToken, boolean browserReconnect
    ) {
        cleanup();
        TicketGrant grant = grantsByTicket.get(ticket);
        if (grant == null) throw invalidTicket();

        synchronized (grant) {
            if (!grant.consumed) {
                if (!grant.farmId().equals(farmId)
                        || grant.expiresAt().isBefore(clock.instant())
                        || !grant.streamToken().equals(streamToken)) {
                    throw invalidTicket();
                }
                grant.consumed = true;
                return grant;
            }
        }
        if (!browserReconnect
                || !grant.streamToken().equals(streamToken)
                || !grant.farmId().equals(farmId)
                || grant.issuedAt().plus(reconnectTokenTtl).isBefore(clock.instant())) {
            throw invalidTicket();
        }
        return grant;
    }

    public TicketGrant reconnect(
            String streamToken, Long userId, Long tenantId, Long farmId
    ) {
        cleanup();
        TicketGrant grant = streamToken == null ? null : grantsByStreamToken.get(streamToken);
        if (grant == null
                || !grant.consumed
                || !grant.matches(userId, tenantId, farmId)
                || grant.issuedAt().plus(reconnectTokenTtl).isBefore(clock.instant())) {
            throw invalidTicket();
        }
        return grant;
    }

    @Scheduled(fixedDelay = 60_000)
    public void cleanup() {
        Instant now = clock.instant();
        grantsByTicket.values().removeIf(grant -> {
            boolean expired = grant.expiresAt().isBefore(now)
                    || grant.issuedAt().plus(reconnectTokenTtl).isBefore(now);
            if (expired) grantsByStreamToken.remove(grant.streamToken(), grant);
            return expired;
        });
    }

    private ApiException invalidTicket() {
        return new ApiException(
                ErrorCode.SIGNAL_STREAM_TICKET_INVALID,
                "error.signalStreamTicketInvalid"
        );
    }

    public static final class TicketGrant {
        private final String ticket;
        private final String streamToken;
        private final Long userId;
        private final Long tenantId;
        private final Long farmId;
        private final Instant issuedAt;
        private final Instant expiresAt;
        private boolean consumed;

        private TicketGrant(
                String ticket,
                String streamToken,
                Long userId,
                Long tenantId,
                Long farmId,
                Instant issuedAt,
                Instant expiresAt
        ) {
            this.ticket = ticket;
            this.streamToken = streamToken;
            this.userId = userId;
            this.tenantId = tenantId;
            this.farmId = farmId;
            this.issuedAt = issuedAt;
            this.expiresAt = expiresAt;
        }

        public String ticket() { return ticket; }
        public String streamToken() { return streamToken; }
        public Long userId() { return userId; }
        public Long tenantId() { return tenantId; }
        public Long farmId() { return farmId; }
        public Instant issuedAt() { return issuedAt; }
        public Instant expiresAt() { return expiresAt; }
        public boolean consumed() { return consumed; }

        private boolean matches(Long userId, Long tenantId, Long farmId) {
            return this.userId.equals(userId)
                    && this.tenantId.equals(tenantId)
                    && this.farmId.equals(farmId);
        }
    }
}
