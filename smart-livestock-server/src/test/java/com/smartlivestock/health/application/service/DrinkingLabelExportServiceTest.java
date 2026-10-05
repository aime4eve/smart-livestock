package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.nio.charset.StandardCharsets;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Pure unit tests for the NIX-256 Task 6 label export (spec §15.4) with a
 * mocked repository: CSV header/escaping/time rendering, the livestock →
 * farm_id join (bound, unbound and soft-deleted), and the closed Shanghai
 * window semantics shared with the recalc endpoint.
 */
class DrinkingLabelExportServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    private DrinkingEventJpaRepository eventRepository;
    private RanchQueryPort ranchQueryPort;
    private DrinkingLabelExportService service;

    @BeforeEach
    void setUp() {
        eventRepository = mock(DrinkingEventJpaRepository.class);
        ranchQueryPort = mock(RanchQueryPort.class);
        service = new DrinkingLabelExportService(eventRepository, ranchQueryPort);
    }

    // ── CSV rendering ────────────────────────────────────────────

    @Test
    void exportBuildsCsvWithBomHeaderEscapingTimesAndFarmJoin() {
        // Row 1: detected row, livestock 5 → farm 1, plain Chinese note.
        DrinkingEventJpaEntity detected = row(1L, 5L, 100L, "2026-10-01T14:30", "2026-10-01T14:50");
        detected.setTempDrop(new BigDecimal("1.20"));
        detected.setMinTemp(new BigDecimal("37.90"));
        detected.setSource("THINGSBOARD");
        detected.setLabel(DrinkingEventLabel.CONFIRMED);
        detected.setConfidence(new BigDecimal("0.850"));
        detected.setAlgorithmVersion("v1");
        detected.setNote("正常饮水，温度回落良好");
        detected.setUpdatedAt(at("2026-10-04T08:00:05"));

        // Row 2: note containing comma, quote and a newline — must be
        // RFC 4180-escaped (quoted, inner quotes doubled).
        DrinkingEventJpaEntity messy = row(2L, 5L, 100L, "2026-10-02T09:00", "2026-10-02T09:10");
        messy.setSource("DATAGEN");
        messy.setLabel(DrinkingEventLabel.UNLABELED);
        messy.setConfidence(new BigDecimal("0.400"));
        messy.setAlgorithmVersion("v1");
        messy.setNote("含,逗号\"引号\n换行");

        // Row 3: manual back-fill of an unbound row (livestock_id null) —
        // no temperature columns, farm_id empty.
        DrinkingEventJpaEntity manual = row(3L, null, 101L, "2026-10-03T10:00", "2026-10-03T10:00");
        manual.setSource("MANUAL");
        manual.setLabel(DrinkingEventLabel.CONFIRMED);
        manual.setConfidence(BigDecimal.ONE);
        manual.setAlgorithmVersion("manual");

        // Row 4: livestock 6 is soft-deleted (absent from the port) —
        // farm_id stays empty too.
        DrinkingEventJpaEntity orphan = row(4L, 6L, 102L, "2026-10-03T11:00", "2026-10-03T11:20");
        orphan.setSource("THINGSBOARD");
        orphan.setLabel(DrinkingEventLabel.UNLABELED);
        orphan.setConfidence(new BigDecimal("0.600"));
        orphan.setAlgorithmVersion("v1");

        when(eventRepository.findByEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtAscIdAsc(
                any(), any())).thenReturn(List.of(detected, messy, manual, orphan));
        when(ranchQueryPort.findAllById(anyCollection()))
                .thenReturn(List.of(new LivestockInfo(5L, 1L, "SL-5", "F", "西门塔尔")));

        DrinkingLabelExportService.LabelExport export = service.exportCsv("2026-10-01", "2026-10-03");

        String csv = new String(export.body(), StandardCharsets.UTF_8);
        // Records are CRLF-separated; the embedded newline in row 2's note
        // stays inside its record, so the record count is header + 4 rows.
        String[] records = csv.split("\r\n", -1);
        assertThat(records).hasSize(5);
        assertThat(csv).startsWith("\uFEFF"); // Excel-friendly UTF-8 BOM
        // The BOM sits in front of the header, inside its first record.
        assertThat(records[0]).isEqualTo("\uFEFF" + DrinkingLabelExportService.CSV_HEADER);
        assertThat(export.filename()).isEqualTo("drinking-labels_2026-10-01_2026-10-03.csv");

        // Row 1: full column layout, Shanghai offset times; minute precision
        // collapses to HH:mm, seconds render when non-zero.
        assertThat(records[1]).isEqualTo(
                "1,1,100,5,2026-10-01T14:30+08:00,2026-10-01T14:50+08:00,"
                        + "1.20,37.90,THINGSBOARD,CONFIRMED,0.850,v1,正常饮水，温度回落良好,"
                        + "2026-10-04T08:00+08:00,2026-10-04T08:00:05+08:00");

        // Row 2: quoting/escaping of comma, double-quote, newline.
        assertThat(records[2]).isEqualTo(
                "2,1,100,5,2026-10-02T09:00+08:00,2026-10-02T09:10+08:00,"
                        + ",,DATAGEN,UNLABELED,0.400,v1,"
                        + "\"含,逗号\"\"引号\n换行\","
                        + "2026-10-04T08:00+08:00,2026-10-04T08:00+08:00");

        // Row 3: null livestock → empty farm_id; null temp/note columns empty.
        assertThat(records[3]).isEqualTo(
                "3,,101,,2026-10-03T10:00+08:00,2026-10-03T10:00+08:00,"
                        + ",,MANUAL,CONFIRMED,1,manual,,"
                        + "2026-10-04T08:00+08:00,2026-10-04T08:00+08:00");

        // Row 4: soft-deleted livestock resolves to no farm → empty farm_id.
        assertThat(records[4]).startsWith(
                "4,,102,6,2026-10-03T11:00+08:00,2026-10-03T11:20+08:00,");
    }

    // ── Window semantics: closed Shanghai date range ──────────────

    @Test
    void exportUsesClosedShanghaiWindowPassedToRepository() {
        when(eventRepository.findByEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtAscIdAsc(
                any(), any())).thenReturn(List.of());

        service.exportCsv("2026-10-01", "2026-10-03");

        // from-day 00:00 inclusive, to+1-day 00:00 exclusive (+08) — the
        // same half-open window the recalc endpoint builds.
        verify(eventRepository).findByEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtAscIdAsc(
                eq(Instant.parse("2026-09-30T16:00:00Z")),
                eq(Instant.parse("2026-10-03T16:00:00Z")));
        // No rows → no livestock batch lookup.
        verify(ranchQueryPort, never()).findAllById(anyCollection());
    }

    @Test
    void exportSkipsTheLivestockLookupWhenNoRowIsBound() {
        DrinkingEventJpaEntity unbound = row(1L, null, 101L, "2026-10-01T14:30", "2026-10-01T14:50");
        when(eventRepository.findByEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtAscIdAsc(
                any(), any())).thenReturn(List.of(unbound));

        service.exportCsv("2026-10-01", "2026-10-01");

        verify(ranchQueryPort, never()).findAllById(anyCollection());
        String csv = new String(service.exportCsv("2026-10-01", "2026-10-01").body(), StandardCharsets.UTF_8);
        assertThat(csv.split("\r\n", -1)[1]).startsWith("1,,101,,");
    }

    // ── Validation: same rules as the recalc endpoint ─────────────

    @Test
    void exportRejectsMissingMalformedInvertedAndFutureRanges() {
        assertRangeInvalid(null, "2026-10-03");
        assertRangeInvalid("2026-10-03", null);
        assertRangeInvalid("", "2026-10-03");
        assertRangeInvalid("not-a-date", "2026-10-03");
        assertRangeInvalid("2026-10-05", "2026-10-03");   // from > to
        // to-day in the future: rejected exactly like the recalc endpoint.
        String tomorrow = LocalDate.now(ZONE).plusDays(1).toString();
        assertThatThrownBy(() -> service.exportCsv(tomorrow, tomorrow))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.futureDate")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.VALIDATION_ERROR);
        // None of the rejected requests reached the repository.
        verify(eventRepository, never())
                .findByEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtAscIdAsc(any(), any());
    }

    private void assertRangeInvalid(String from, String to) {
        assertThatThrownBy(() -> service.exportCsv(from, to))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.rangeInvalid")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.VALIDATION_ERROR);
    }

    // ── Fixtures ─────────────────────────────────────────────────

    private static DrinkingEventJpaEntity row(Long id, Long livestockId, Long deviceId,
                                              String startWall, String endWall) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setId(id);
        entity.setLivestockId(livestockId);
        entity.setDeviceId(deviceId);
        entity.setEventStartAt(at(startWall));
        entity.setEventEndAt(at(endWall));
        entity.setCreatedAt(at("2026-10-04T08:00"));
        entity.setUpdatedAt(at("2026-10-04T08:00"));
        return entity;
    }

    /** Wall-clock "yyyy-MM-dd'T'HH:mm[:ss]" in Asia/Shanghai → instant. */
    private static Instant at(String wallClock) {
        return LocalDateTime.parse(wallClock).atZone(ZONE).toInstant();
    }
}
