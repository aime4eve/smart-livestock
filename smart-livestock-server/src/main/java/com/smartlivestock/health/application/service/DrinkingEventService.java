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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Locale;

/**
 * Marking-loop application service (NIX-256 Task 3, spec §15.2) plus the
 * event-list read (Task 5a): ranch-owner label flips, manual back-fill of
 * missed drinking events, and the UI detail query. Aggregations live in
 * {@link DrinkingSummaryService}; this service stays the row-level path.
 */
@Service
@RequiredArgsConstructor
public class DrinkingEventService {

    /** Manual entries and UI day windows are interpreted in the ranch operating timezone (B3/F5). */
    private static final ZoneId ENTRY_ZONE = ZoneId.of("Asia/Shanghai");
    private static final int NOTE_MAX_LENGTH = 500;
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ISO_LOCAL_DATE;

    private final DrinkingEventJpaRepository eventRepository;
    private final RanchQueryPort ranchQueryPort;
    private final DeviceQueryPort deviceQueryPort;

    /**
     * Confidence below which a row is served with {@code lowConfidence=true}
     * (spec §15.2 "pending verification" marker); MANUAL rows are
     * human-asserted and never flag.
     */
    @Value("${health.drinking.low-confidence:0.5}")
    double lowConfidence;

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
     * Idempotent on (device, event_start_at, manual): an existing row is
     * returned as-is; a concurrent double click that slips past the
     * pre-check is caught on the unique index and resolved by re-reading
     * the winning row — same convention as physiology events. Deliberately
     * NOT wrapped in a service transaction: save() must own its transaction
     * so the integrity violation rolls back only the insert, leaving the
     * fallback lookup a clean read.
     */
    public DrinkingEventResponse createManual(Long farmId, Long livestockId, String eventStartAt, String note) {
        requireLivestockInFarm(farmId, livestockId);
        Instant startAt = parseEventStartAt(eventStartAt);
        requireNoteLength(note);
        CapsuleBinding binding = deviceQueryPort.findActiveCapsuleBinding(livestockId)
                .orElseThrow(() -> new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.noDevice"));

        var existing = eventRepository.findByDeviceIdAndEventStartAtAndAlgorithmVersion(
                binding.deviceId(), startAt, DrinkingAlgorithmVersion.MANUAL);
        if (existing.isPresent()) {
            return toResponse(existing.get());
        }
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
        try {
            DrinkingEventJpaEntity saved = eventRepository.save(entity);
            return toResponse(saved);
        } catch (DataIntegrityViolationException race) {
            // Lost a concurrent insert on UNIQUE (device_id, event_start_at,
            // algorithm_version): the winner is committed (Postgres unique
            // waits for the other tx), so the re-read always finds it — the
            // double click answers the first row instead of a 500.
            return eventRepository.findByDeviceIdAndEventStartAtAndAlgorithmVersion(
                            binding.deviceId(), startAt, DrinkingAlgorithmVersion.MANUAL)
                    .map(this::toResponse)
                    .orElseThrow(() -> race);
        }
    }

    // ── Read path (Task 5a, endpoint 1) ────────────────────────

    /**
     * All rows of the livestock inside {@code [from, to)} (Task 5a): every
     * row is returned — detected, borderline candidates, REJECTED and MANUAL
     * — because the client renders the source/label groups itself.
     * {@code from}/{@code to} are optional calendar days in Asia/Shanghai
     * forming a <b>closed date range</b> (from 00:00 → to+1 day 00:00), the
     * same window semantics as the admin recalculation; both default to the
     * recent 7 days ending today.
     */
    @Transactional(readOnly = true)
    public List<DrinkingEventResponse> listEvents(Long farmId, Long livestockId, String from, String to) {
        requireLivestockInFarm(farmId, livestockId);
        LocalDate toDay = parseDay(to, LocalDate.now(ENTRY_ZONE), "error.drinking.rangeInvalid");
        LocalDate fromDay = parseDay(from, toDay.minusDays(6), "error.drinking.rangeInvalid");
        if (fromDay.isAfter(toDay)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.rangeInvalid");
        }
        if (toDay.isAfter(LocalDate.now(ENTRY_ZONE))) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.drinking.futureDate");
        }
        Instant windowFrom = fromDay.atStartOfDay(ENTRY_ZONE).toInstant();
        Instant windowTo = toDay.plusDays(1).atStartOfDay(ENTRY_ZONE).toInstant();
        return eventRepository
                .findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                        livestockId, windowFrom, windowTo)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /** Parse an optional ISO calendar day; blank/absent falls back to the default. */
    private static LocalDate parseDay(String value, LocalDate fallback, String errorKey) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        try {
            return LocalDate.parse(value.trim(), DATE_FORMAT);
        } catch (DateTimeParseException exception) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, errorKey);
        }
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

    /** Spec §15.2 marker: a detected row below the threshold flags low. */
    private boolean isLowConfidence(DrinkingEventJpaEntity entity) {
        if (DrinkingEventSources.MANUAL.equals(entity.getSource())) {
            return false; // human-asserted back-fills are never "pending verification"
        }
        return entity.getConfidence() != null && entity.getConfidence().doubleValue() < lowConfidence;
    }

    private DrinkingEventResponse toResponse(DrinkingEventJpaEntity entity) {
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
                entity.getUpdatedAt(),
                isLowConfidence(entity)
        );
    }
}
