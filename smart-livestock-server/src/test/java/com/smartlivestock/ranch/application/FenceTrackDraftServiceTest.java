package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.TrackDraftCandidatesDto;
import com.smartlivestock.ranch.application.dto.TrackDraftSourceDto;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.FenceQuotaPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;
import com.smartlivestock.ranch.domain.port.dto.TrackDraftPoint;
import com.smartlivestock.ranch.domain.port.dto.TrackerCandidate;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FenceTrackDraftServiceTest {

    private static final long FARM_ID = 42L;
    private static final Instant FROM = Instant.parse("2026-10-12T00:00:00Z");
    private static final Instant TO = Instant.parse("2026-11-11T00:00:00Z"); // exactly 30 days

    @Mock private IoTQueryPort ioTQueryPort;
    @Mock private LivestockRepository livestockRepository;
    @Mock private FenceRepository fenceRepository;
    @Mock private FenceQuotaPort fenceQuotaPort;

    private FenceTrackDraftService service;

    @BeforeEach
    void setUp() {
        service = new FenceTrackDraftService(
                ioTQueryPort, livestockRepository, fenceRepository, fenceQuotaPort);
    }

    // ---------- helpers ----------

    /** One farm livestock with the given id; ownership checks run on it. */
    private void stubFarmLivestock() {
        Livestock l = new Livestock(FARM_ID, "N0342", "Holstein", "F", null, null);
        l.setId(1001L);
        lenient().when(livestockRepository.findByFarmId(FARM_ID)).thenReturn(List.of(l));
    }

    /** Active installation map: deviceId -> brief of the given type. */
    private void stubActiveDevices(Map<Long, String> deviceTypes) {
        List<DeviceBrief> briefs = deviceTypes.entrySet().stream()
                .map(e -> new DeviceBrief(e.getKey(), "DEV-" + e.getKey(), null, e.getValue()))
                .toList();
        when(ioTQueryPort.findActiveDevicesByLivestockIds(List.of(1001L)))
                .thenReturn(Map.of(1001L, briefs));
    }

    private void stubTwoTrackerDevices() {
        stubFarmLivestock();
        stubActiveDevices(Map.of(101L, "TRACKER", 102L, "TRACKER"));
    }

    private static TrackDraftPoint point(String recordedAt) {
        return new TrackDraftPoint(new BigDecimal("28.1"), new BigDecimal("112.9"),
                null, Instant.parse(recordedAt));
    }

    private static void assertMessageKey(ApiException ex, String key) {
        assertEquals(key, ex.getMessage());
    }

    // ---------- validation ----------

    @Test
    void source_rejectsEmptyAndTooManyDevices() {
        ApiException empty = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, List.of(), FROM, TO));
        assertMessageKey(empty, "error.trackDraftTooManyDevices");

        List<Long> eleven = java.util.stream.LongStream.rangeClosed(1, 11).boxed().toList();
        ApiException tooMany = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, eleven, FROM, TO));
        assertMessageKey(tooMany, "error.trackDraftTooManyDevices");
    }

    @Test
    void source_rejectsNullDeviceIds() {
        ApiException ex = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, null, FROM, TO));
        assertMessageKey(ex, "error.trackDraftTooManyDevices");
    }

    @Test
    void source_rejectsDeviceNotOwnedByFarm() {
        stubFarmLivestock();
        stubActiveDevices(Map.of(101L, "TRACKER")); // 201 belongs elsewhere
        ApiException ex = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, List.of(101L, 201L), FROM, TO));
        assertMessageKey(ex, "error.trackDraftDeviceNotFound");
    }

    @Test
    void source_rejectsNonTrackerDevice() {
        stubFarmLivestock();
        stubActiveDevices(Map.of(101L, "EAR_TAG"));
        ApiException ex = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, List.of(101L), FROM, TO));
        assertMessageKey(ex, "error.trackDraftDeviceNotFound");
    }

    @Test
    void source_rejectsInvertedAndOverlongRange() {
        stubTwoTrackerDevices();
        ApiException inverted = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, List.of(101L), TO, FROM));
        assertMessageKey(inverted, "error.trackDraftRangeTooLong");

        Instant tooFar = FROM.plus(java.time.Duration.ofDays(31));
        ApiException overlong = assertThrows(ApiException.class,
                () -> service.source(FARM_ID, List.of(101L), FROM, tooFar));
        assertMessageKey(overlong, "error.trackDraftRangeTooLong");
    }

    @Test
    void source_acceptsExactlyThirtyDays() {
        stubFarmLivestock();
        stubActiveDevices(Map.of(101L, "TRACKER"));
        when(ioTQueryPort.countTrackPoints(101L, FROM, TO)).thenReturn(10L);
        when(ioTQueryPort.sampleTrackPoints(eq(101L), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of());
        TrackDraftSourceDto dto = service.source(FARM_ID, List.of(101L), FROM, TO);
        assertEquals(10L, dto.totalRaw());
    }

    // ---------- stride estimate ----------

    @Test
    void source_strideCeilsAtFiveThousand() {
        stubTwoTrackerDevices();
        // 3000 + 2499 = 5499 raw -> stride 2 (floor would wrongly give 1)
        when(ioTQueryPort.countTrackPoints(101L, FROM, TO)).thenReturn(3000L);
        when(ioTQueryPort.countTrackPoints(102L, FROM, TO)).thenReturn(2499L);
        when(ioTQueryPort.sampleTrackPoints(anyLong(), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of());

        TrackDraftSourceDto dto = service.source(FARM_ID, List.of(101L, 102L), FROM, TO);

        assertEquals(5499L, dto.totalRaw());
        assertEquals(2L, dto.sampledStride());
        assertTrue(dto.truncated());
        verify(ioTQueryPort).sampleTrackPoints(101L, FROM, TO, 2L);
        verify(ioTQueryPort).sampleTrackPoints(102L, FROM, TO, 2L);
    }

    @Test
    void source_exactlyFiveThousandKeepsStrideOne() {
        stubTwoTrackerDevices();
        when(ioTQueryPort.countTrackPoints(101L, FROM, TO)).thenReturn(2500L);
        when(ioTQueryPort.countTrackPoints(102L, FROM, TO)).thenReturn(2500L);
        when(ioTQueryPort.sampleTrackPoints(anyLong(), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of());

        TrackDraftSourceDto dto = service.source(FARM_ID, List.of(101L, 102L), FROM, TO);

        assertEquals(5000L, dto.totalRaw());
        assertEquals(1L, dto.sampledStride());
        assertFalse(dto.truncated());
    }

    @Test
    void source_zeroRawPointsSkipsSampling() {
        stubTwoTrackerDevices();
        when(ioTQueryPort.countTrackPoints(anyLong(), eq(FROM), eq(TO))).thenReturn(0L);

        TrackDraftSourceDto dto = service.source(FARM_ID, List.of(101L, 102L), FROM, TO);

        assertEquals(0L, dto.totalRaw());
        assertTrue(dto.points().isEmpty());
        assertEquals(1L, dto.sampledStride());
        assertFalse(dto.truncated());
        verify(ioTQueryPort, never()).sampleTrackPoints(anyLong(), eq(FROM), eq(TO), anyLong());
    }

    // ---------- serial fetch, merge ordering ----------

    @Test
    void source_countsAllDevicesBeforeSamplingSerially() {
        stubTwoTrackerDevices();
        when(ioTQueryPort.countTrackPoints(101L, FROM, TO)).thenReturn(3000L);
        when(ioTQueryPort.countTrackPoints(102L, FROM, TO)).thenReturn(2499L);
        when(ioTQueryPort.sampleTrackPoints(anyLong(), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of());

        service.source(FARM_ID, List.of(101L, 102L), FROM, TO);

        // Serial count-then-sample flow pinned by plan ruling ①: the merged
        // stride needs totalRaw, so every count precedes every sample.
        InOrder order = inOrder(ioTQueryPort);
        order.verify(ioTQueryPort).countTrackPoints(101L, FROM, TO);
        order.verify(ioTQueryPort).countTrackPoints(102L, FROM, TO);
        order.verify(ioTQueryPort).sampleTrackPoints(101L, FROM, TO, 2L);
        order.verify(ioTQueryPort).sampleTrackPoints(102L, FROM, TO, 2L);
    }

    @Test
    void source_mergesDevicePointsAscendingByRecordedAt() {
        stubTwoTrackerDevices();
        when(ioTQueryPort.countTrackPoints(101L, FROM, TO)).thenReturn(2L);
        when(ioTQueryPort.countTrackPoints(102L, FROM, TO)).thenReturn(2L);
        // Per-device lists are ascending internally but interleave globally.
        when(ioTQueryPort.sampleTrackPoints(eq(101L), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of(
                        point("2026-10-20T01:00:00Z"),
                        point("2026-10-20T04:00:00Z")));
        when(ioTQueryPort.sampleTrackPoints(eq(102L), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of(
                        point("2026-10-20T02:00:00Z"),
                        point("2026-10-20T03:00:00Z")));

        TrackDraftSourceDto dto = service.source(FARM_ID, List.of(101L, 102L), FROM, TO);

        assertEquals(List.of(
                Instant.parse("2026-10-20T01:00:00Z"),
                Instant.parse("2026-10-20T02:00:00Z"),
                Instant.parse("2026-10-20T03:00:00Z"),
                Instant.parse("2026-10-20T04:00:00Z")),
                dto.points().stream().map(TrackDraftSourceDto.Point::recordedAt).toList());
        assertEquals(4L, dto.totalRaw());
        assertEquals(List.of(
                new TrackDraftSourceDto.DeviceRaw(101L, 2L),
                new TrackDraftSourceDto.DeviceRaw(102L, 2L)),
                dto.perDevice());
    }

    @Test
    void source_keepsNullAccuracyAsNull() {
        stubFarmLivestock();
        stubActiveDevices(Map.of(101L, "TRACKER"));
        when(ioTQueryPort.countTrackPoints(101L, FROM, TO)).thenReturn(1L);
        when(ioTQueryPort.sampleTrackPoints(eq(101L), eq(FROM), eq(TO), anyLong()))
                .thenReturn(List.of(new TrackDraftPoint(
                        new BigDecimal("28.1"), new BigDecimal("112.9"),
                        null, Instant.parse("2026-10-20T01:00:00Z"))));

        TrackDraftSourceDto dto = service.source(FARM_ID, List.of(101L), FROM, TO);

        assertNull(dto.points().get(0).accuracyM());
    }

    // ---------- candidates + fenceQuota ----------

    private void stubCandidates() {
        when(ioTQueryPort.findTrackerCandidates(eq(FARM_ID), anyInt()))
                .thenReturn(List.of(new TrackerCandidate(
                        101L, "DEV-101", "N0342",
                        Instant.parse("2026-11-10T08:00:00Z"), 7986L)));
    }

    @Test
    void candidates_assemblesDevicesAndQuotaFromPorts() {
        stubCandidates();
        when(fenceRepository.countByFarmId(FARM_ID)).thenReturn(3L);
        when(fenceQuotaPort.resolveFenceManagementLimitForCurrentTenant()).thenReturn(20);

        TrackDraftCandidatesDto dto = service.candidates(FARM_ID, 30);

        assertEquals(1, dto.devices().size());
        assertEquals(101L, dto.devices().get(0).deviceId());
        assertEquals(3L, dto.fenceQuota().current());
        assertEquals(20, dto.fenceQuota().limit());
    }

    @Test
    void candidates_unlimitedTierPassesNullLimitThrough() {
        stubCandidates();
        when(fenceRepository.countByFarmId(FARM_ID)).thenReturn(3L);
        when(fenceQuotaPort.resolveFenceManagementLimitForCurrentTenant()).thenReturn(null);

        TrackDraftCandidatesDto dto = service.candidates(FARM_ID, 30);

        assertEquals(3L, dto.fenceQuota().current());
        assertNull(dto.fenceQuota().limit());
    }

    @Test
    void candidates_fullQuotaStillReportsBothNumbers() {
        stubCandidates();
        // Full: current == limit. The service reports facts; the client
        // disables the wizard entry (spec §5.5).
        when(fenceRepository.countByFarmId(FARM_ID)).thenReturn(20L);
        when(fenceQuotaPort.resolveFenceManagementLimitForCurrentTenant()).thenReturn(20);

        TrackDraftCandidatesDto dto = service.candidates(FARM_ID, 30);

        assertEquals(20L, dto.fenceQuota().current());
        assertEquals(20, dto.fenceQuota().limit());
    }
}
