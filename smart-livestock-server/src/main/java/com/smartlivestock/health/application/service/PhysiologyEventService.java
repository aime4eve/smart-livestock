package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventListResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventRequest;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventUpdateRequest;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyStageProjection;
import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.domain.model.PhysiologyEvent;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.infrastructure.persistence.entity.EpidemicDispositionJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * CRUD application service for the manual physiology event stream
 * (NIX-256 Task 1a). Only MANUAL rows may be created here — and only they
 * can be edited or deleted; ALERT_CONFIRM rows are read-only.
 * <p>
 * The list endpoint additionally merges the read-time view required by the
 * physiology card (spec §10): active epidemic dispositions are projected as
 * ILLNESS rows (never stored) and the stage chip comes from
 * {@link PhysiologyQueryPort#currentStage}.
 */
@Service
@RequiredArgsConstructor
public class PhysiologyEventService {

    /** Entry dates are interpreted in the ranch's operating timezone. */
    private static final ZoneId ENTRY_ZONE = ZoneId.of("Asia/Shanghai");
    private static final int NOTE_MAX_LENGTH = 500;

    private final PhysiologyEventJpaRepository eventRepository;
    private final EpidemicDispositionJpaRepository dispositionRepository;
    private final RanchQueryPort ranchQueryPort;
    private final PhysiologyQueryPort physiologyQueryPort;

    /**
     * Physiology card list: table rows (with ongoing-illness flag) merged
     * with active disposition projections, sorted occurred_at DESC, plus the
     * lactation/dry stage projection (null when no stage-defining event).
     */
    @Transactional(readOnly = true)
    public PhysiologyEventListResponse listEvents(Long farmId, Long livestockId) {
        requireLivestockInFarm(farmId, livestockId);
        Set<Instant> closedOnsets = closedManualIllnessOnsets(livestockId);
        List<PhysiologyEventResponse> items = new ArrayList<>();
        eventRepository.findByLivestockIdOrderByOccurredAtDesc(livestockId)
                .forEach(entity -> items.add(toResponse(entity, isOngoing(entity, closedOnsets))));
        dispositionRepository.findByLivestockId(livestockId).stream()
                .filter(disposition -> disposition.getStatus() == EpidemicDispositionStatus.PENDING
                        || disposition.getStatus() == EpidemicDispositionStatus.IN_PROGRESS)
                .forEach(disposition -> items.add(dispositionRow(disposition)));
        items.sort(Comparator.comparing(PhysiologyEventResponse::occurredAt,
                Comparator.reverseOrder()));
        PhysiologyStageProjection stage = physiologyQueryPort.currentStage(livestockId)
                .map(value -> new PhysiologyStageProjection(value.type().name(), value.since()))
                .orElse(null);
        return new PhysiologyEventListResponse(items, stage);
    }

    /**
     * Create a manual event. Idempotent on (livestock, eventType, occurredAt,
     * MANUAL): an existing row is returned as-is; a concurrent duplicate that
     * slips past the pre-check is caught on the unique index and resolved by
     * re-reading the winning row. Deliberately NOT wrapped in a service
     * transaction — save() must own its transaction so the integrity
     * violation rolls back only the insert, leaving the fallback lookup a
     * clean read (a participating save would poison the shared transaction
     * with rollback-only).
     */
    public PhysiologyEventResponse createEvent(Long farmId, Long livestockId,
                                               PhysiologyEventRequest request, Long userId) {
        requireLivestockInFarm(farmId, livestockId);
        PhysiologyEventType eventType = parseEventType(request == null ? null : request.eventType());
        Instant occurredAt = parseOccurredAt(request == null ? null : request.occurredAt());
        String note = request == null ? null : request.note();
        requireNoteLength(note);

        var existing = eventRepository.findByLivestockIdAndEventTypeAndOccurredAtAndSource(
                livestockId, eventType, occurredAt, PhysiologySource.MANUAL);
        if (existing.isPresent()) {
            return toResponse(existing.get(), isOngoing(existing.get(),
                    closedManualIllnessOnsets(livestockId)));
        }
        PhysiologyEvent event = new PhysiologyEvent();
        event.setLivestockId(livestockId);
        event.setEventType(eventType);
        event.setOccurredAt(occurredAt);
        event.setSource(PhysiologySource.MANUAL);
        event.setRefId(null);
        event.setNote(note);
        event.setCreatedBy(userId);
        event.setUpdatedBy(userId);
        try {
            PhysiologyEventJpaEntity saved = eventRepository.save(toJpa(event));
            return toResponse(saved, isOngoing(saved, closedManualIllnessOnsets(livestockId)));
        } catch (DataIntegrityViolationException race) {
            // Lost a concurrent insert on uq_physiology_manual_dup: the winner
            // is committed (Postgres unique waits for the other tx), so the
            // re-read always finds it — keep the idempotent contract.
            return eventRepository.findByLivestockIdAndEventTypeAndOccurredAtAndSource(
                            livestockId, eventType, occurredAt, PhysiologySource.MANUAL)
                    .map(winner -> toResponse(winner, isOngoing(winner,
                            closedManualIllnessOnsets(livestockId))))
                    .orElseThrow(() -> race);
        }
    }

    /**
     * Update occurredAt/note; MANUAL rows only. Note clearing is explicit
     * (N17): Jackson binds an absent key and an explicit JSON null to the
     * same {@code null} — both keep the stored note; a present-but-blank
     * note ("", whitespace) clears the column to NULL; a non-blank note
     * replaces it (length still capped at 500). No JsonNullable / Optional
     * wrapper is needed: the two "keep" cases are intentionally
     * indistinguishable, so the plain record binding carries the contract.
     */
    @Transactional
    public PhysiologyEventResponse updateEvent(Long farmId, Long livestockId, Long eventId,
                                               PhysiologyEventUpdateRequest request, Long userId) {
        requireLivestockInFarm(farmId, livestockId);
        PhysiologyEventJpaEntity entity = requireEvent(livestockId, eventId);
        requireManual(entity);
        if (request == null || request.occurredAt() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.requestInvalid");
        }
        Instant occurredAt = parseOccurredAt(request.occurredAt());
        String note = request.note();
        requireNoteLength(note);

        // Moving onto another MANUAL row's (livestock, type, date) triple
        // would collide with the partial unique index.
        eventRepository.findByLivestockIdAndEventTypeAndOccurredAtAndSource(
                        livestockId, entity.getEventType(), occurredAt, PhysiologySource.MANUAL)
                .filter(other -> !entity.getId().equals(other.getId()))
                .ifPresent(other -> {
                    throw new ApiException(ErrorCode.STATE_CONFLICT, "error.physiology.duplicateEvent");
                });

        entity.setOccurredAt(occurredAt);
        if (note != null) {
            // Explicit note key: blank (trim-empty) clears the column,
            // non-blank replaces it; absent/null keeps the stored value.
            entity.setNote(note.isBlank() ? null : note);
        }
        entity.setUpdatedBy(userId);
        PhysiologyEventJpaEntity saved = eventRepository.save(entity);
        return toResponse(saved, isOngoing(saved, closedManualIllnessOnsets(livestockId)));
    }

    /** Delete; MANUAL rows only. */
    @Transactional
    public void deleteEvent(Long farmId, Long livestockId, Long eventId) {
        requireLivestockInFarm(farmId, livestockId);
        PhysiologyEventJpaEntity entity = requireEvent(livestockId, eventId);
        requireManual(entity);
        eventRepository.delete(entity);
    }

    // ── Validation helpers ──────────────────────────────────────

    private void requireLivestockInFarm(Long farmId, Long livestockId) {
        if (livestockId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.livestockRequired");
        }
        ranchQueryPort.findLivestockById(livestockId)
                .filter(info -> info.farmId().equals(farmId))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.physiology.livestockNotFound"));
    }

    private PhysiologyEventJpaEntity requireEvent(Long livestockId, Long eventId) {
        return eventRepository.findById(eventId)
                .filter(entity -> entity.getLivestockId().equals(livestockId))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.physiology.eventNotFound"));
    }

    private void requireManual(PhysiologyEventJpaEntity entity) {
        if (entity.getSource() != PhysiologySource.MANUAL) {
            throw new ApiException(ErrorCode.STATE_CONFLICT, "error.physiology.readOnlySource");
        }
    }

    private static PhysiologyEventType parseEventType(String value) {
        if (value == null || value.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.requestInvalid");
        }
        try {
            return PhysiologyEventType.valueOf(value.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.requestInvalid");
        }
    }

    /**
     * "yyyy-MM-dd" at Asia/Shanghai midnight → UTC instant; future dates
     * (later than today in Asia/Shanghai) are rejected.
     */
    private static Instant parseOccurredAt(String value) {
        LocalDate date;
        try {
            date = LocalDate.parse(value == null ? "" : value.trim());
        } catch (DateTimeParseException exception) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.requestInvalid");
        }
        if (date.isAfter(LocalDate.now(ENTRY_ZONE))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.futureDate");
        }
        return date.atStartOfDay(ENTRY_ZONE).toInstant();
    }

    private static void requireNoteLength(String note) {
        if (note != null && note.length() > NOTE_MAX_LENGTH) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.physiology.noteTooLong");
        }
    }

    // ── Read-time merge helpers ─────────────────────────────────

    /** Onsets of manually paired (closed) illness windows for this livestock. */
    private Set<Instant> closedManualIllnessOnsets(Long livestockId) {
        List<PhysiologyQueryService.TimedEvent> history = eventRepository
                .findByLivestockIdAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
                        livestockId,
                        List.of(PhysiologyEventType.ILLNESS, PhysiologyEventType.RECOVERY),
                        PhysiologySource.MANUAL, Instant.now())
                .stream()
                .map(entity -> new PhysiologyQueryService.TimedEvent(
                        entity.getEventType(), entity.getOccurredAt()))
                .toList();
        return PhysiologyQueryService.pairIllnessRecovery(history).stream()
                .filter(window -> window.endedAt() != null)
                .map(PhysiologyQueryService.PairedWindow::occurredAt)
                .collect(Collectors.toSet());
    }

    /** A manual ILLNESS row is active while its window has not been closed. */
    private static boolean isOngoing(PhysiologyEventJpaEntity entity, Set<Instant> closedOnsets) {
        return entity.getSource() == PhysiologySource.MANUAL
                && entity.getEventType() == PhysiologyEventType.ILLNESS
                && !closedOnsets.contains(entity.getOccurredAt());
    }

    /**
     * Active disposition projected as an ILLNESS row (spec §10 card header
     * row). id is null — it is not a physiology_events row; refId carries
     * the disposition id.
     */
    private static PhysiologyEventResponse dispositionRow(EpidemicDispositionJpaEntity disposition) {
        return new PhysiologyEventResponse(
                null,
                disposition.getLivestockId(),
                PhysiologyEventType.ILLNESS.name(),
                "DISPOSITION",
                disposition.getId(),
                null,
                disposition.getCreatedAt(),
                null,
                disposition.getCreatedAt(),
                null,
                disposition.getUpdatedAt(),
                true
        );
    }

    // ── Mapping ─────────────────────────────────────────────────

    private static PhysiologyEventJpaEntity toJpa(PhysiologyEvent event) {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setId(event.getId());
        entity.setLivestockId(event.getLivestockId());
        entity.setEventType(event.getEventType());
        entity.setOccurredAt(event.getOccurredAt());
        entity.setSource(event.getSource());
        entity.setRefId(event.getRefId());
        entity.setNote(event.getNote());
        entity.setCreatedBy(event.getCreatedBy());
        entity.setUpdatedBy(event.getUpdatedBy());
        return entity;
    }

    private static PhysiologyEventResponse toResponse(PhysiologyEventJpaEntity entity, boolean active) {
        return new PhysiologyEventResponse(
                entity.getId(),
                entity.getLivestockId(),
                entity.getEventType().name(),
                entity.getSource().name(),
                entity.getRefId(),
                entity.getNote(),
                entity.getOccurredAt(),
                entity.getCreatedBy(),
                entity.getCreatedAt(),
                entity.getUpdatedBy(),
                entity.getUpdatedAt(),
                active
        );
    }
}
