package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.service.DrinkingRecalculationService.RecalcWindow;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Drinking label-dataset export (NIX-256 Task 6, spec §15.4): dumps every
 * drinking-event row of a closed Asia/Shanghai date range as CSV — the
 * training/evaluation dataset the offline calibration loop
 * ({@code calibrate.py --labels}) reads. Kept out of
 * {@link DrinkingEventService} on purpose: that service is the
 * ranch-scoped marking-loop row path, while this is a cross-farm admin
 * batch read plus CSV rendering.
 */
@Service
@RequiredArgsConstructor
public class DrinkingLabelExportService {

    /** Times render with the ranch operating-zone offset (B3/F5). */
    private static final ZoneId EXPORT_ZONE = DrinkingEventDetectionService.COW_DAY_ZONE;
    /**
     * ISO-8601 with the Asia/Shanghai offset; whole-minute instants drop
     * the seconds ("2026-10-01T14:30+08:00", the spec §15.4 example) —
     * drinking windows live on the minute grid, so most rows print short.
     */
    private static final DateTimeFormatter MINUTE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mmXXX");
    private static final DateTimeFormatter FULL_TIME = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    static final String CSV_HEADER =
            "id,farm_id,device_id,livestock_id,event_start_at,event_end_at,temp_drop,min_temp,"
                    + "source,label,confidence,algorithm_version,note,created_at,updated_at";

    /** UTF-8 BOM so Excel opens the Chinese note column without an import wizard. */
    private static final char UTF8_BOM = '\uFEFF';

    private final DrinkingEventJpaRepository eventRepository;
    private final RanchQueryPort ranchQueryPort;

    /** CSV download artifact: UTF-8 body (BOM included) + attachment filename. */
    public record LabelExport(byte[] body, String filename) {}

    /**
     * Dump every row whose {@code event_start_at} falls in the closed date
     * range from-day 00:00 → to+1-day 00:00 (Asia/Shanghai) — the identical
     * window semantics and validation as the admin recalc endpoint, shared
     * via {@link DrinkingRecalculationService#parseWindow(String, String)}.
     * farm_id is joined through livestock ({@code drinking_events} carries
     * no farm column); rows whose livestock is null or no longer resolvable
     * (soft-deleted) export an empty farm_id.
     */
    @Transactional(readOnly = true)
    public LabelExport exportCsv(String from, String to) {
        RecalcWindow window = DrinkingRecalculationService.parseWindow(from, to);
        List<DrinkingEventJpaEntity> rows = eventRepository
                .findByEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtAscIdAsc(
                        window.from(), window.to());
        Map<Long, Long> farmByLivestock = resolveFarms(rows);
        String csv = renderCsv(rows, farmByLivestock);
        return new LabelExport(csv.getBytes(StandardCharsets.UTF_8),
                "drinking-labels_" + dayOf(window.from()) + "_" + dayOf(window.to()).minusDays(1) + ".csv");
    }

    /**
     * livestock_id → farm_id mapping for the exported rows. One batch
     * lookup (soft-deleted livestock excluded by the port) — no N+1 for
     * the few-thousand-row export volume.
     */
    private Map<Long, Long> resolveFarms(List<DrinkingEventJpaEntity> rows) {
        Set<Long> livestockIds = rows.stream()
                .map(DrinkingEventJpaEntity::getLivestockId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());
        if (livestockIds.isEmpty()) {
            // Collections.emptyMap (not Map.of): its get(null) is a safe miss,
            // and rows with a null livestock_id perform exactly that lookup.
            return Collections.emptyMap();
        }
        return ranchQueryPort.findAllById(livestockIds).stream()
                .collect(Collectors.toMap(LivestockInfo::id, LivestockInfo::farmId, (a, b) -> a));
    }

    // ── CSV rendering ───────────────────────────────────────────

    private static String renderCsv(List<DrinkingEventJpaEntity> rows, Map<Long, Long> farmByLivestock) {
        StringBuilder csv = new StringBuilder(rows.size() * 160 + 128)
                .append(UTF8_BOM)
                .append(CSV_HEADER);
        for (DrinkingEventJpaEntity row : rows) {
            appendRow(csv,
                    row.getId(),
                    farmByLivestock.get(row.getLivestockId()),
                    row.getDeviceId(),
                    row.getLivestockId(),
                    row.getEventStartAt(),
                    row.getEventEndAt(),
                    row.getTempDrop(),
                    row.getMinTemp(),
                    row.getSource(),
                    row.getLabel() == null ? null : row.getLabel().name(),
                    row.getConfidence(),
                    row.getAlgorithmVersion(),
                    row.getNote(),
                    row.getCreatedAt(),
                    row.getUpdatedAt());
        }
        return csv.toString();
    }

    /** RFC 4180 row: CRLF separators, every field passed through the escaper. */
    private static void appendRow(StringBuilder csv, Object... values) {
        csv.append("\r\n");
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                csv.append(',');
            }
            csv.append(escape(field(values[i])));
        }
    }

    /** null → empty, Instant → Asia/Shanghai offset ISO-8601, numbers plain. */
    private static String field(Object value) {
        if (value == null) {
            return "";
        }
        if (value instanceof Instant instant) {
            return renderTime(instant);
        }
        if (value instanceof BigDecimal decimal) {
            return decimal.toPlainString();
        }
        return value.toString();
    }

    /** Whole minutes drop the seconds; sub-minute precision keeps them. */
    private static String renderTime(Instant instant) {
        ZonedDateTime wall = instant.atZone(EXPORT_ZONE);
        return wall.getSecond() == 0 && wall.getNano() == 0
                ? wall.format(MINUTE_TIME)
                : wall.format(FULL_TIME);
    }

    /** Quote a field containing comma/quote/CR/LF, doubling inner quotes. */
    private static String escape(String value) {
        if (value.indexOf(',') < 0 && value.indexOf('"') < 0
                && value.indexOf('\r') < 0 && value.indexOf('\n') < 0) {
            return value;
        }
        return '"' + value.replace("\"", "\"\"") + '"';
    }

    private static LocalDate dayOf(Instant instant) {
        return instant.atZone(EXPORT_ZONE).toLocalDate();
    }
}
