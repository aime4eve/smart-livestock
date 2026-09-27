package com.smartlivestock.ranch.infrastructure.signal;

import com.smartlivestock.ranch.application.signal.SignalCursorTooOldException;
import com.smartlivestock.ranch.application.signal.SignalRevisionService;
import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.application.signal.SignalRevisionService.MapCursor;
import com.smartlivestock.ranch.application.signal.SignalStreamNotification;
import com.smartlivestock.ranch.application.signal.SignalStreamNotificationService;
import com.smartlivestock.ranch.application.signal.SignalStreamTicketService.TicketGrant;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Slf4j
@Component
public class SignalStreamHub implements SignalStreamNotificationService.Broadcaster {

    private static final int MAX_CONNECTIONS_PER_USER_FARM = 5;

    private final SignalRevisionService revisionService;
    private final Map<Long, List<Connection>> sessionsByFarm = new ConcurrentHashMap<>();
    private final Map<String, String> connectionIdsByStreamToken = new ConcurrentHashMap<>();
    private final int maxConnectionsPerUserFarm;

    public SignalStreamHub(
            SignalRevisionService revisionService,
            @Value("${signal.stream.max-connections-per-user-farm:5}")
            int maxConnectionsPerUserFarm
    ) {
        this.revisionService = revisionService;
        this.maxConnectionsPerUserFarm = maxConnectionsPerUserFarm;
    }

    public SseEmitter connect(
            TicketGrant grant,
            String cursor,
            String lastEventId,
            int activeConnections
    ) {
        if (activeConnections >= maxConnectionsPerUserFarm) {
            throw new IllegalStateException("Signal stream connection limit reached");
        }

        SseEmitter emitter = new SseEmitter(0L);
        FarmSignalRevision revision = revisionService.ensureFarm(grant.farmId());
        String initialCursor = lastEventId != null && !lastEventId.isBlank()
                ? lastEventId : cursor;

        MapCursor cursorState;
        try {
            cursorState = revisionService.validateMapCursor(revision, initialCursor);
        } catch (SignalCursorTooOldException e) {
            sendReconnect(emitter, grant.farmId(), revision);
            return emitter;
        }

        Connection connection = new Connection(grant, emitter);
        replaceStreamConnection(grant.streamToken(), connection);
        register(grant.farmId(), connection);

        try {
            emitter.send(SseEmitter.event().comment("connected"));
            if (hasChange(revision, cursorState)) {
                sendSignal(
                        connection,
                        revision,
                        List.of(),
                        List.of()
                );
            }
        } catch (Exception e) {
            remove(grant.farmId(), connection);
            emitter.completeWithError(e);
        }
        return emitter;
    }

    @Override
    public boolean hasSubscribers(Long farmId) {
        List<Connection> connections = sessionsByFarm.get(farmId);
        return connections != null && !connections.isEmpty();
    }

    public int countUserFarmConnections(Long userId, Long farmId) {
        List<Connection> connections = sessionsByFarm.get(farmId);
        if (connections == null) return 0;
        return (int) connections.stream()
                .filter(connection -> connection.grant.userId().equals(userId))
                .count();
    }

    @Override
    public void broadcast(SignalStreamNotification notification) {
        List<Connection> connections = sessionsByFarm.get(notification.farmId());
        if (connections == null || connections.isEmpty()) return;

        List<Connection> failed = new ArrayList<>();
        for (Connection connection : List.copyOf(connections)) {
            try {
                sendSignal(
                        connection,
                        revision(notification),
                        notification.livestockIds(),
                        notification.fenceIds()
                );
            } catch (Exception e) {
                failed.add(connection);
            }
        }
        failed.forEach(connection -> {
            remove(notification.farmId(), connection);
            connection.emitter().completeWithError(new IOException("stream send failed"));
        });
    }

    @Scheduled(fixedDelayString = "${signal.stream.heartbeat-ms:20000}")
    public void sendHeartbeats() {
        sessionsByFarm.forEach((farmId, connections) -> {
            List<Connection> failed = new ArrayList<>();
            for (Connection connection : List.copyOf(connections)) {
                try {
                    connection.emitter().send(SseEmitter.event().comment("heartbeat"));
                } catch (Exception e) {
                    failed.add(connection);
                }
            }
            failed.forEach(connection -> {
                remove(farmId, connection);
                connection.emitter().completeWithError(new IOException("heartbeat failed"));
            });
        });
    }

    private void replaceStreamConnection(String streamToken, Connection next) {
        String previousId = connectionIdsByStreamToken.put(streamToken, next.id());
        if (previousId == null) return;

        sessionsByFarm.values().forEach(connections -> connections.removeIf(connection -> {
            if (!connection.id().equals(previousId)) return false;
            connection.emitter().complete();
            return true;
        }));
    }

    private void register(Long farmId, Connection connection) {
        List<Connection> connections = new CopyOnWriteArrayList<>();
        List<Connection> existing = sessionsByFarm.putIfAbsent(farmId, connections);
        List<Connection> target = existing == null ? connections : existing;
        target.add(connection);

        connection.emitter().onCompletion(() -> remove(farmId, connection));
        connection.emitter().onTimeout(() -> remove(farmId, connection));
        connection.emitter().onError(error -> remove(farmId, connection));
    }

    private void remove(Long farmId, Connection connection) {
        List<Connection> connections = sessionsByFarm.get(farmId);
        if (connections != null) connections.remove(connection);
        connectionIdsByStreamToken.remove(connection.grant().streamToken(), connection.id());
    }

    private boolean hasChange(FarmSignalRevision revision, MapCursor cursor) {
        return revision.statusRevision() > cursor.statusRevision()
                || revision.positionRevision() > cursor.positionRevision()
                || revision.fenceGeometryRevision() > cursor.fenceGeometryRevision();
    }

    private void sendSignal(
            Connection connection,
            FarmSignalRevision revision,
            List<Long> livestockIds,
            List<Long> fenceIds
    ) throws IOException {
        String cursor = cursor(revision);
        connection.emitter().send(
                SseEmitter.event()
                        .id(cursor)
                        .name("signal-changed")
                        .data(
                                new SignalStreamNotification(
                                        revision.farmId(),
                                        livestockIds,
                                        fenceIds,
                                        revision.statusRevision(),
                                        revision.positionRevision(),
                                        revision.fenceGeometryRevision()
                                ),
                                MediaType.APPLICATION_JSON
                        )
        );
    }

    private void sendReconnect(
            SseEmitter emitter,
            Long farmId,
            FarmSignalRevision revision
    ) {
        try {
            emitter.send(
                    SseEmitter.event()
                            .id(cursor(revision))
                            .name("signal-reconnect")
                            .data(Map.of("farmId", farmId, "reason", "CURSOR_TOO_OLD"),
                                    MediaType.APPLICATION_JSON)
            );
            emitter.complete();
        } catch (Exception e) {
            emitter.completeWithError(e);
        }
    }

    private FarmSignalRevision revision(SignalStreamNotification notification) {
        return new FarmSignalRevision(
                notification.farmId(),
                notification.statusRevision(),
                notification.positionRevision(),
                notification.fenceGeometryRevision(),
                null
        );
    }

    private String cursor(FarmSignalRevision revision) {
        return revision.statusRevision() + ":" + revision.positionRevision() + ":"
                + revision.fenceGeometryRevision();
    }

    private record Connection(String id, TicketGrant grant, SseEmitter emitter) {
        private Connection(TicketGrant grant, SseEmitter emitter) {
            this(UUID.randomUUID().toString(), grant, emitter);
        }
    }
}
