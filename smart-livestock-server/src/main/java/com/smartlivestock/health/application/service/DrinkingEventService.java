package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingEventResponse;
import com.smartlivestock.health.domain.model.DrinkingAlgorithmVersion;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;

/**
 * Marking-loop application service (NIX-256 Task 3, spec §15.2): ranch-owner
 * label flips and manual back-fill of missed drinking events. Read/query
 * endpoints for the UI land in Task 5; this service stays the write path.
 */
@Service
@RequiredArgsConstructor
public class DrinkingEventService {

    /** Manual entries are interpreted in the ranch operating timezone (B3). */
    private static final ZoneId ENTRY_ZONE = ZoneId.of("Asia/Shanghai");
    private static final int NOTE_MAX_LENGTH = 500;

    private final DrinkingEventJpaRepository eventRepository;
    private final RanchQueryPort ranchQueryPort;
    private final DeviceQueryPort deviceQueryPort;

    /**
     * Statistics filter shared by every counting view (revised spec §15.3,
     * reused by the Task 5 summary endpoints):
     * {@code label != REJECTED && (source != ALGORITHM_CANDIDATE || label == CONFIRMED)}
     * — detected rows count by default, rejected rows never count, manual
     * back-fills count, and a borderline candidate counts only once the
     * ranch owner confirms it (ruling ③, §15.2 "转正参与统计").
     */
    static boolean isCounted(DrinkingEventJpaEntity row) {
        return row.getLabel() != DrinkingEventLabel.REJECTED
                && (!DrinkingEventSources.ALGORITHM_CANDIDATE.equals(row.getSource())
                        || row.getLabel() == DrinkingEventLabel.CONFIRMED);
    }

    /**
     * PATCH label: confirm / reject / reset a drinking event. An
     * ALGORITHM_CANDIDATE row keeps its source when confirmed — the
     * statistics contract reads the label/source pair (isCounted), so no
     * source rewrite is needed to "promote" it.
     */
    @Transactional
    public DrinkingEventResponse updateLabel(Long farmId, Long livestockId, Long eventId, String label) {
        requireLivestockInFarm(farmId, livestockId);
        DrinkingEventJpaEntity entity = requireEvent(livestockId, eventId);
        entity.setLabel(parseLabel(label));
        DrinkingEventJpaEntity saved = eventRepository.save(entity);
        return toResponse(saved);
    }

    /**
     * POST manual: back-fill a missed drinking event. source=MANUAL,
     * label=CONFIRMED, confidence=1.0, algorithm_version=manual (so it never
     * collides with algorithm rows on the UNIQUE key and is never deleted by
     * a recalculation), event_end_at=start, no temperature observation.
     */
    @Transactional
    public DrinkingEventResponse createManual(Long farmId, Long livestockId, String eventStartAt, String note) {
        requireLivestockInFarm(farmId, livestockId);
        Instant startAt = parseEventStartAt(eventStartAt);
        requireNoteLength(note);
        CapsuleBinding binding = deviceQueryPort.findActiveCapsuleBinding(livestockId)
                .orElseThrow(() -> new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.noDevice"));

        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setDeviceId(binding.deviceId());
        entity.setLivestockId(livestockId);
        entity.setEventStartAt(startAt);
        entity.setEventEndAt(startAt);
        entity.setTempDrop(null);
        entity.setMinTemp(null);
        entity.setSource(DrinkingEventSources.MANUAL);
        entity.setLabel(DrinkingEventLabel.CONFIRMED);
        entity.setConfidence(BigDecimal.ONE);
        entity.setAlgorithmVersion(DrinkingAlgorithmVersion.MANUAL);
        entity.setNote(note);
        DrinkingEventJpaEntity saved = eventRepository.save(entity);
        return toResponse(saved);
    }

    // ── Validation helpers ──────────────────────────────────────

    private void requireLivestockInFarm(Long farmId, Long livestockId) {
        ranchQueryPort.findLivestockById(livestockId)
                .filter(info -> info.farmId().equals(farmId))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.drinking.livestockNotFound"));
    }

    private DrinkingEventJpaEntity requireEvent(Long livestockId, Long eventId) {
        return eventRepository.findById(eventId)
                .filter(entity -> livestockId != null && livestockId.equals(entity.getLivestockId()))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.drinking.eventNotFound"));
    }

    private static DrinkingEventLabel parseLabel(String value) {
        if (value == null || value.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.labelInvalid");
        }
        try {
            return DrinkingEventLabel.valueOf(value.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.labelInvalid");
        }
    }

    /** Manual entry format: wall-clock "yyyy-MM-dd HH:mm" (ISO 'T' also accepted). */
    private static final DateTimeFormatter MANUAL_TIME_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    /**
     * "yyyy-MM-dd HH:mm" wall clock in Asia/Shanghai → UTC instant; future
     * instants are rejected (back-filling only).
     */
    private static Instant parseEventStartAt(String value) {
        LocalDateTime dateTime;
        try {
            dateTime = LocalDateTime.parse(
                    value == null ? "" : value.trim().replace('T', ' '), MANUAL_TIME_FORMAT);
        } catch (DateTimeParseException exception) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.requestInvalid");
        }
        Instant instant = dateTime.atZone(ENTRY_ZONE).toInstant();
        if (instant.isAfter(Instant.now())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.futureDate");
        }
        return instant;
    }

    private static void requireNoteLength(String note) {
        if (note != null && note.length() > NOTE_MAX_LENGTH) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.noteTooLong");
        }
    }

    private static DrinkingEventResponse toResponse(DrinkingEventJpaEntity entity) {
        return new DrinkingEventResponse(
                entity.getId(),
                entity.getLivestockId(),
                entity.getDeviceId(),
                entity.getEventStartAt(),
                entity.getEventEndAt(),
                entity.getTempDrop(),
                entity.getMinTemp(),
                entity.getSource(),
                entity.getLabel().name(),
                entity.getConfidence(),
                entity.getAlgorithmVersion(),
                entity.getNote(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
