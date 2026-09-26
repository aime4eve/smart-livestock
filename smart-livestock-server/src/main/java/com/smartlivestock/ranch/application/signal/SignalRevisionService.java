package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.infrastructure.persistence.FarmSignalRevisionJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.FarmSignalRevisionJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class SignalRevisionService {

    private static final long REPLAY_LIMIT = 1_000;
    private static final long MAX_CURSOR_AGE_HOURS = 24;

    private final FarmSignalRevisionJpaRepository revisionRepository;
    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Transactional
    public FarmSignalRevision ensureFarm(Long farmId) {
        FarmSignalRevision existing = findByFarmId(farmId).orElse(null);
        if (existing != null) return existing;

        FarmSignalRevisionJpaEntity entity = new FarmSignalRevisionJpaEntity();
        entity.setFarmId(farmId);
        entity.setStatusRevision(0L);
        entity.setPositionRevision(0L);
        entity.setFenceGeometryRevision(0L);
        entity.setUpdatedAt(Instant.now());
        return toRevision(revisionRepository.save(entity));
    }

    @Transactional(readOnly = true)
    public Optional<FarmSignalRevision> findByFarmId(Long farmId) {
        return revisionRepository.findById(farmId).map(this::toRevision);
    }

    @Transactional
    public long bumpStatus(Long farmId) {
        return bump(farmId, "status_revision");
    }

    @Transactional
    public long bumpPosition(Long farmId) {
        return bump(farmId, "position_revision");
    }

    @Transactional
    public long bumpFenceGeometry(Long farmId) {
        return bump(farmId, "fence_geometry_revision");
    }

    public void validateListCursor(FarmSignalRevision revision, long cursor) {
        validateRevision("status", cursor, revision.statusRevision(), revision.updatedAt());
    }

    public MapCursor validateMapCursor(FarmSignalRevision revision, String cursor) {
        String[] parts = cursor == null || cursor.isBlank() ? new String[0] : cursor.split(":");
        if (parts.length != 3) {
            throw new SignalCursorInvalidException(
                    "cursor must be statusRevision:positionRevision:fenceGeometryRevision");
        }
        try {
            long status = Long.parseLong(parts[0]);
            long position = Long.parseLong(parts[1]);
            long geometry = Long.parseLong(parts[2]);
            validateRevision("status", status, revision.statusRevision(), revision.updatedAt());
            validateRevision("position", position, revision.positionRevision(), revision.updatedAt());
            validateRevision("fence geometry", geometry, revision.fenceGeometryRevision(), revision.updatedAt());
            return new MapCursor(status, position, geometry);
        } catch (NumberFormatException e) {
            throw new SignalCursorInvalidException("cursor components must be non-negative integers", e);
        }
    }

    private void validateRevision(String name, long cursor, long current, Instant updatedAt) {
        if (cursor < 0 || cursor > current) {
            throw new SignalCursorInvalidException(
                    name + " cursor is invalid or ahead of the current signal state");
        }
        if (current - cursor > REPLAY_LIMIT
                || updatedAt.isBefore(Instant.now().minus(MAX_CURSOR_AGE_HOURS, ChronoUnit.HOURS))) {
            throw new SignalCursorTooOldException(name + " cursor is too old and requires a full resync");
        }
    }

    private long bump(Long farmId, String column) {
        ensureFarm(farmId);
        MapSqlParameterSource params = new MapSqlParameterSource("farmId", farmId);
        Long next = jdbcTemplate.queryForObject(
                "UPDATE farm_signal_revisions "
                        + "SET " + column + " = " + column + " + 1, updated_at = NOW() "
                        + "WHERE farm_id = :farmId RETURNING " + column,
                params,
                Long.class
        );
        if (next == null) {
            throw new IllegalStateException("Signal revision update returned no value for farm " + farmId);
        }
        return next;
    }

    private FarmSignalRevision toRevision(FarmSignalRevisionJpaEntity entity) {
        return new FarmSignalRevision(
                entity.getFarmId(),
                entity.getStatusRevision(),
                entity.getPositionRevision(),
                entity.getFenceGeometryRevision(),
                entity.getUpdatedAt()
        );
    }

    public record FarmSignalRevision(
            Long farmId,
            Long statusRevision,
            Long positionRevision,
            Long fenceGeometryRevision,
            Instant updatedAt
    ) {}

    public record MapCursor(long statusRevision, long positionRevision, long fenceGeometryRevision) {}
}
