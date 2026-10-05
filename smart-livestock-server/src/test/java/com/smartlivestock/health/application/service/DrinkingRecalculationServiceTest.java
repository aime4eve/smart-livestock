package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingRecalcResponse;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.RecalcStats;
import com.smartlivestock.health.application.service.DrinkingRecalculationService.FarmSweep;
import com.smartlivestock.health.application.service.DrinkingRecalculationService.RecalcWindow;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Collection;
import java.util.List;
import java.util.Set;

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
 * Pure unit tests for the NIX-256 Task 4 recalculation orchestration
 * (mocked detection service + ports): farm-universe resolution, per-farm
 * failure isolation with correct aggregation, the admin device mode, and
 * the closed-date-range window parsing/validation (static, package-visible).
 */
class DrinkingRecalculationServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    private DrinkingEventDetectionService detectionService;
    private DeviceQueryPort deviceQueryPort;
    private RanchQueryPort ranchQueryPort;
    private DrinkingRecalculationService service;

    @BeforeEach
    void setUp() {
        detectionService = mock(DrinkingEventDetectionService.class);
        deviceQueryPort = mock(DeviceQueryPort.class);
        ranchQueryPort = mock(RanchQueryPort.class);
        service = new DrinkingRecalculationService(detectionService, deviceQueryPort, ranchQueryPort);
    }

    // ── Farm universe resolution ─────────────────────────────────

    @Test
    void farmUniverseDeduplicatesBindingsIntoSortedFarmSet() {
        when(deviceQueryPort.findAllActiveCapsuleBindings()).thenReturn(List.of(
                new CapsuleBinding(11L, 101L),
                new CapsuleBinding(12L, 102L),
                new CapsuleBinding(13L, 103L)));
        when(ranchQueryPort.findAllById(anyCollection())).thenReturn(List.of(
                livestock(11L, 2L),
                livestock(12L, 2L),
                livestock(13L, 1L)));

        Set<Long> farms = service.farmsWithActiveCapsuleBindings();

        assertThat(farms).containsExactly(1L, 2L); // TreeSet: stable batch order
    }

    @Test
    void softDeletedLivestockResolveToNoFarm() {
        // findAllById excludes soft-deleted livestock — a binding whose
        // owner is gone simply drops out of the universe, consistent with
        // recalculateFarm's own livestock listing.
        when(deviceQueryPort.findAllActiveCapsuleBindings())
                .thenReturn(List.of(new CapsuleBinding(11L, 101L)));
        when(ranchQueryPort.findAllById(anyCollection())).thenReturn(List.of());

        assertThat(service.farmsWithActiveCapsuleBindings()).isEmpty();
    }

    @Test
    void emptyBindingUniverseSkipsTheRanchLookup() {
        when(deviceQueryPort.findAllActiveCapsuleBindings()).thenReturn(List.of());

        assertThat(service.farmsWithActiveCapsuleBindings()).isEmpty();
        verify(ranchQueryPort, never()).findAllById(anyCollection());
    }

    // ── Farm sweep: isolation + aggregation ──────────────────────

    @Test
    void oneFarmFailureDoesNotStopTheSweepAndIsCounted() {
        when(deviceQueryPort.findAllActiveCapsuleBindings()).thenReturn(List.of(
                new CapsuleBinding(11L, 101L), new CapsuleBinding(12L, 102L)));
        when(ranchQueryPort.findAllById(anyCollection()))
                .thenReturn(List.of(livestock(11L, 1L), livestock(12L, 2L)));
        Instant from = Instant.parse("2026-10-03T16:00:00Z");
        Instant to = Instant.parse("2026-10-04T16:00:00Z");
        when(detectionService.recalculateFarm(1L, from, to))
                .thenThrow(new IllegalStateException("farm 1 exploded"));
        when(detectionService.recalculateFarm(2L, from, to))
                .thenReturn(new RecalcStats(5, 9));

        FarmSweep sweep = service.recalculateAllFarms(from, to);

        // Farm 1 threw but farm 2 still ran; failed count surfaced.
        verify(detectionService).recalculateFarm(eq(1L), eq(from), eq(to));
        verify(detectionService).recalculateFarm(eq(2L), eq(from), eq(to));
        assertThat(sweep).isEqualTo(new FarmSweep(2, 5, 9, 1));
    }

    @Test
    void sweepAggregatesDevicesAndEventsAcrossFarms() {
        when(deviceQueryPort.findAllActiveCapsuleBindings()).thenReturn(List.of(
                new CapsuleBinding(11L, 101L), new CapsuleBinding(12L, 102L)));
        when(ranchQueryPort.findAllById(anyCollection()))
                .thenReturn(List.of(livestock(11L, 1L), livestock(12L, 2L)));
        Instant from = Instant.parse("2026-10-03T16:00:00Z");
        Instant to = Instant.parse("2026-10-04T16:00:00Z");
        when(detectionService.recalculateFarm(1L, from, to)).thenReturn(new RecalcStats(10, 40));
        when(detectionService.recalculateFarm(2L, from, to)).thenReturn(new RecalcStats(5, 25));

        FarmSweep sweep = service.recalculateAllFarms(from, to);

        assertThat(sweep).isEqualTo(new FarmSweep(2, 15, 65, 0));
    }

    // ── Admin entry: device mode vs farm mode ────────────────────

    @Test
    void deviceModeRecalculatesOneDeviceAfterExistenceCheck() {
        when(deviceQueryPort.deviceExists(101L)).thenReturn(true);
        RecalcStats stats = new RecalcStats(1, 3);
        when(detectionService.recalculateDevice(eq(101L), any(), any())).thenReturn(stats);

        DrinkingRecalcResponse response = service.recalculate(
                101L, "2026-10-03", "2026-10-03");

        assertThat(response.scope()).isEqualTo("DEVICE");
        assertThat(response.farms()).isNull();
        assertThat(response.devices()).isEqualTo(1);
        assertThat(response.events()).isEqualTo(3);
        assertThat(response.failedFarms()).isZero();
        // Farm sweep must not run in device mode.
        verify(deviceQueryPort, never()).findAllActiveCapsuleBindings();
    }

    @Test
    void deviceModeRejectsUnknownDeviceWith404() {
        when(deviceQueryPort.deviceExists(999L)).thenReturn(false);

        assertThatThrownBy(() -> service.recalculate(999L, "2026-10-03", "2026-10-03"))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.deviceNotFound")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
    }

    @Test
    void farmModeSweepsEveryFarmAndReportsScope() {
        when(deviceQueryPort.findAllActiveCapsuleBindings())
                .thenReturn(List.of(new CapsuleBinding(11L, 101L)));
        when(ranchQueryPort.findAllById(anyCollection()))
                .thenReturn(List.of(livestock(11L, 1L)));
        when(detectionService.recalculateFarm(any(), any(), any()))
                .thenReturn(new RecalcStats(4, 12));

        DrinkingRecalcResponse response = service.recalculate(null, "2026-10-03", "2026-10-03");

        assertThat(response.scope()).isEqualTo("ALL_FARMS");
        assertThat(response.farms()).isEqualTo(1);
        assertThat(response.devices()).isEqualTo(4);
        assertThat(response.events()).isEqualTo(12);
        assertThat(response.failedFarms()).isZero();
    }

    // ── Window parsing: closed date range in Asia/Shanghai ───────

    @Test
    void windowIsClosedDateRangeAtShanghaiMidnights() {
        RecalcWindow window = DrinkingRecalculationService.parseWindow("2026-10-01", "2026-10-03");

        // from-day 00:00 → to+1-day 00:00 (+08) — "to" is recalculated
        // through its day end.
        assertThat(window.from()).isEqualTo(Instant.parse("2026-09-30T16:00:00Z"));
        assertThat(window.to()).isEqualTo(Instant.parse("2026-10-03T16:00:00Z"));
    }

    @Test
    void singleDayRangeSpansExactlyOneCowDay() {
        RecalcWindow window = DrinkingRecalculationService.parseWindow("2026-10-01", "2026-10-01");
        assertThat(window.from()).isEqualTo(Instant.parse("2026-09-30T16:00:00Z"));
        assertThat(window.to()).isEqualTo(Instant.parse("2026-10-01T16:00:00Z"));
    }

    @Test
    void todayAsToIsAllowedButTomorrowIsRejected() {
        String today = LocalDate.now(ZONE).toString();
        String tomorrow = LocalDate.now(ZONE).plusDays(1).toString();

        assertThat(DrinkingRecalculationService.parseWindow(today, today)).isNotNull();

        assertThatThrownBy(() -> DrinkingRecalculationService.parseWindow(tomorrow, tomorrow))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.futureDate")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.VALIDATION_ERROR);
    }

    @Test
    void missingMalformedOrInvertedRangesAreRejected() {
        assertRangeInvalid(null, "2026-10-03");
        assertRangeInvalid("2026-10-03", null);
        assertRangeInvalid("2026-10-03", "");
        assertRangeInvalid("2026/10/03", "2026-10-03");   // wrong format
        assertRangeInvalid("not-a-date", "2026-10-03");
        assertRangeInvalid("2026-10-05", "2026-10-03");   // from > to
    }

    private void assertRangeInvalid(String from, String to) {
        assertThatThrownBy(() -> DrinkingRecalculationService.parseWindow(from, to))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.rangeInvalid")
                .extracting(e -> ((ApiException) e).getCode())
                .isEqualTo(ErrorCode.VALIDATION_ERROR);
    }

    private static LivestockInfo livestock(Long id, Long farmId) {
        return new LivestockInfo(id, farmId, "L-" + id, null, null);
    }
}
