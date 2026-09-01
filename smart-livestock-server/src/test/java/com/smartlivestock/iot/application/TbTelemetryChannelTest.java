package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.doNothing;

@ExtendWith(MockitoExtension.class)
class TbTelemetryChannelTest {

    @Mock
    private TbClient tbClient;
    @Mock
    private TbDeviceBindingRepository bindingRepository;
    @Mock
    private DeviceRepository deviceRepository;
    @Mock
    private TelemetryIngestionService ingestionService;
    @Mock
    private DeviceTelemetryLogRepository deviceTelemetryLogRepository;

    private TbProperties properties;
    private TbTelemetryChannel channel;

    @BeforeEach
    void setUp() {
        properties = new TbProperties();
        properties.setEnabled(true);
        properties.setBatchSize(10);
        channel = new TbTelemetryChannel(properties, tbClient, bindingRepository,
                deviceRepository, deviceTelemetryLogRepository, ingestionService);
    }

    private Device activeTracker() {
        Device device = new Device(1L, "DEV-TB-1", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.ACTIVE);
        device.setId(122L);
        return device;
    }

    private String timeseries(String ts, String battery) {
        return "{\"result\":[" + frameJson(ts, battery) + "]}";
    }

    @Test
    void shouldIngestFramesAndAdvanceCursor() {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setId(1L);
        binding.setDeviceId(122L);
        binding.setDeviceEui("00956906000285cf");
        binding.setExternalDeviceId("tb-uuid");
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        binding.setTelemetryCursorMs(null);

        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{\"result\":[" + frameJson("1000", "65") + "," + frameJson("2000", "66") + "]}"));

        channel.poll();

        ArgumentCaptor<Instant> tsCaptor = ArgumentCaptor.forClass(Instant.class);
        verify(ingestionService, org.mockito.Mockito.times(2)).ingest(
                eq(122L), any(), tsCaptor.capture(), eq(com.smartlivestock.iot.domain.model.TelemetrySource.THINGSBOARD));
        assertThat(tsCaptor.getAllValues()).isSorted();
        assertThat(tsCaptor.getAllValues()).hasSize(2);

        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isEqualTo(2000L);
    }

    @Test
    void shouldTreatExistingDtlFrameAsIdempotentSuccess() {
        TbDeviceBinding binding = resolvedBinding(500L);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{\"result\":[" + frameJson("1000", "65") + "]}"));
        when(deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(eq(122L),
                eq(Instant.ofEpochMilli(1000L)))).thenReturn(true);

        channel.poll();

        verify(ingestionService, never()).ingest(any(), any(), any(), any());
        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isEqualTo(1000L);
    }

    @Test
    void shouldStopAtFailedFrameAndKeepSuccessfulPrefixCursor() {
        TbDeviceBinding binding = resolvedBinding(500L);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{\"result\":[" + frameJson("1000", "65")
                        + "," + frameJson("2000", "66")
                        + "," + frameJson("3000", "67") + "]}"));
        doNothing()
                .doThrow(new RuntimeException("ingest failed"))
                .doNothing()
                .when(ingestionService).ingest(eq(122L), any(), any(), any());

        channel.poll();

        verify(ingestionService).ingest(eq(122L), any(),
                eq(Instant.ofEpochMilli(1000L)), any());
        verify(ingestionService).ingest(eq(122L), any(),
                eq(Instant.ofEpochMilli(2000L)), any());
        verify(ingestionService, never()).ingest(eq(122L), any(),
                eq(Instant.ofEpochMilli(3000L)), any());
        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isEqualTo(1000L);
    }

    @Test
    void shouldContinueWhenBatchReachesLimit() {
        properties.setBatchSize(2);
        TbDeviceBinding binding = resolvedBinding(null);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{\"result\":[" + frameJson("1000", "65")
                        + "," + frameJson("2000", "66") + "]}"))
                .thenReturn(parse("{\"result\":[" + frameJson("3000", "67") + "]}"));

        channel.poll();

        var startCaptor = ArgumentCaptor.forClass(Long.class);
        verify(tbClient, org.mockito.Mockito.times(2)).fetchTimeseries(
                eq("tb-uuid"), startCaptor.capture(), anyLong(), eq(2));
        assertThat(startCaptor.getAllValues().get(1)).isEqualTo(2000L);
        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isEqualTo(3000L);
    }

    @Test
    void shouldClampOutOfRangeGpsBeforeIngest() {
        TbDeviceBinding binding = resolvedBinding(null);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{\"result\":[{\"ts\":1000,\"value\":\"{\\\"decodeStatus\\\":true,"
                        + "\\\"decodeData\\\":{\\\"properties\\\":{\\\"latitude\\\":2000,"
                        + "\\\"longitude\\\":112.85,\\\"battery\\\":66}}}\"}]}"));

        channel.poll();

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, Object>> readingsCaptor =
                ArgumentCaptor.forClass(Map.class);
        verify(ingestionService).ingest(eq(122L), readingsCaptor.capture(),
                eq(Instant.ofEpochMilli(1000L)), any());
        assertThat(readingsCaptor.getValue()).containsEntry("latitude", null);
        assertThat(readingsCaptor.getValue()).containsEntry("longitude", new java.math.BigDecimal("112.85"));
    }

    @Test
    void shouldSkipNonActiveDeviceWithoutFetch() {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setDeviceId(122L);
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        Device device = activeTracker();
        device.setStatus(DeviceStatus.INVENTORY);

        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(device));

        channel.poll();

        verify(tbClient, never()).fetchTimeseries(any(), anyLong(), anyLong(), anyInt());
        verify(ingestionService, never()).ingest(any(), any(), any(), any());
    }

    @Test
    void shouldSkipUndecodableFramesAndAdvanceCursorPastThem() {
        TbDeviceBinding binding = resolvedBinding(500L);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        // Incident NIX-179: a modified TB rule chain saves decodeStatus:false
        // frames between good ones; they must be skipped and the cursor must
        // advance past them instead of stalling on the same page forever.
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{\"result\":[" + frameJson("1000", "65")
                        + ",{\"ts\":1500,\"value\":\"{\\\"decodeStatus\\\":false,\\\"error\\\":\\\"Invalid sync header\\\"}\"}"
                        + "]}"));

        channel.poll();

        verify(ingestionService).ingest(eq(122L), any(),
                eq(Instant.ofEpochMilli(1000L)), any());
        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isEqualTo(1500L);
        assertThat(bindingCaptor.getValue().getConsecutiveFailures()).isZero();
    }

    @Test
    void shouldCountConsecutiveFailuresOnPageError() {
        TbDeviceBinding binding = resolvedBinding(500L);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenThrow(new RuntimeException("TB unreachable"));

        channel.poll();

        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getConsecutiveFailures()).isEqualTo(1);
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isEqualTo(500L);
        assertThat(bindingCaptor.getValue().getLastPollAt()).isNotNull();
    }

    @Test
    void shouldResetFailuresOnCleanCycleWithoutFrames() {
        TbDeviceBinding binding = resolvedBinding(null);
        binding.setConsecutiveFailures(2);
        when(bindingRepository.findByTenantIdAndStatus(1L, TbDeviceBinding.Status.RESOLVED))
                .thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeTracker()));
        when(tbClient.fetchTimeseries(eq("tb-uuid"), anyLong(), anyLong(), anyInt()))
                .thenReturn(parse("{}"));

        channel.poll();

        ArgumentCaptor<TbDeviceBinding> bindingCaptor = ArgumentCaptor.forClass(TbDeviceBinding.class);
        verify(bindingRepository).save(bindingCaptor.capture());
        assertThat(bindingCaptor.getValue().getConsecutiveFailures()).isZero();
        assertThat(bindingCaptor.getValue().getTelemetryCursorMs()).isNull();
        assertThat(bindingCaptor.getValue().getLastPollAt()).isNotNull();
    }

    private com.fasterxml.jackson.databind.JsonNode parse(String raw) {
        try {
            return new ObjectMapper().readTree(raw);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private String frameJson(String ts, String battery) {
        return "{\"ts\":" + ts + ",\"value\":\"{\\\"decodeStatus\\\":true,\\\"decodeData\\\":{\\\"properties\\\":{\\\"battery\\\":" + battery + "}}}\"}";
    }

    private TbDeviceBinding resolvedBinding(Long cursor) {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setId(1L);
        binding.setTenantId(1L);
        binding.setDeviceId(122L);
        binding.setDeviceEui("00956906000285cf");
        binding.setExternalDeviceId("tb-uuid");
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        binding.setTelemetryCursorMs(cursor);
        return binding;
    }
}
