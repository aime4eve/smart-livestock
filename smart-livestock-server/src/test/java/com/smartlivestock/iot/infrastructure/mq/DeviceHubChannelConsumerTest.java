package com.smartlivestock.iot.infrastructure.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.application.TelemetryIngestionService;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeviceHubChannelConsumerTest {

    private static final String EUI = "00956906000285cf";
    private static final String TB_ID = "tb-uuid";
    private static final String CAPSULE_HEX = "686B7405010332" + "4900002710";

    @Mock
    private TbDeviceBindingRepository bindingRepository;
    @Mock
    private DeviceRepository deviceRepository;
    @Mock
    private DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    @Mock
    private TelemetryIngestionService ingestionService;

    private final ObjectMapper mapper = new ObjectMapper();
    private DeviceHubChannelConsumer consumer;

    @BeforeEach
    void setUp() {
        consumer = new DeviceHubChannelConsumer(mapper, bindingRepository,
                deviceRepository, deviceTelemetryLogRepository, ingestionService);
    }

    private Device activeCapsule() {
        Device device = new Device(1L, "DEV-DH-1", DeviceType.CAPSULE, EUI);
        device.setStatus(DeviceStatus.ACTIVE);
        device.setId(122L);
        return device;
    }

    private TbDeviceBinding resolvedBinding() {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setId(1L);
        binding.setTenantId(1L);
        binding.setDeviceId(122L);
        binding.setDeviceEui(EUI);
        binding.setExternalDeviceId(TB_ID);
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        return binding;
    }

    private void stubResolvedDevice() {
        when(bindingRepository.findByProviderAndExternalDeviceId(
                TbDeviceBinding.PROVIDER_THINGSBOARD, TB_ID))
                .thenReturn(Optional.of(resolvedBinding()));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeCapsule()));
    }

    private String frameJson(Map<String, Object> properties, Map<String, Object> extra)
            throws Exception {
        Map<String, Object> frame = new HashMap<>();
        frame.put("version", 1);
        frame.put("frameId", "f-1");
        frame.put("devEui", EUI);
        frame.put("tbDeviceId", TB_ID);
        frame.put("ts", 1000L);
        frame.put("properties", properties);
        frame.putAll(extra);
        return mapper.writeValueAsString(frame);
    }

    @Test
    void shouldMapResultFrameAndIngestWithTransportMetadata() throws Exception {
        stubResolvedDevice();
        String message = frameJson(Map.of(
                        "temperatureGroup", List.of(38.5, 38.6),
                        "gastricMotility", 987654,
                        "batteryVoltage", 2950,
                        "xAxisAccelerationValue", 100,
                        "software", "1.2.3"),
                Map.of("rssi", -67, "snr", 9, "gatewayId", "gw-01"));

        consumer.onMessage(message);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, Object>> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(ingestionService).ingest(eq(122L), readingsCaptor.capture(),
                eq(Instant.ofEpochMilli(1000L)), eq(TelemetrySource.THINGSBOARD));
        Map<String, Object> readings = readingsCaptor.getValue();
        assertThat(readings.get("temperatures")).asList().hasSize(2);
        assertThat(readings.get("gastricMotility")).isEqualTo(987654);
        assertThat(readings.get("battery")).isEqualTo(75);
        assertThat(readings.get("accelXRaw")).isEqualTo(100);
        assertThat(readings.get("softwareVersion")).isEqualTo("1.2.3");
        assertThat(readings.get("rssi")).isEqualTo(-67);
        assertThat(readings.get("snr")).isEqualTo(9);
        assertThat(readings.get("gatewayId")).isEqualTo("gw-01");
        assertThat(consumer.getIngestedCount()).isEqualTo(1);
    }

    @Test
    void shouldFallbackToDataHexDecodeForCapsule() throws Exception {
        stubResolvedDevice();
        String message = frameJson(Map.of(), Map.of("dataHex", CAPSULE_HEX));

        consumer.onMessage(message);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, Object>> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(ingestionService).ingest(eq(122L), readingsCaptor.capture(),
                eq(Instant.ofEpochMilli(1000L)), eq(TelemetrySource.THINGSBOARD));
        assertThat(readingsCaptor.getValue().get("battery")).isEqualTo(50);
    }

    @Test
    void shouldDropUndecodableFrameWithoutBlocking() throws Exception {
        stubResolvedDevice();
        String message = frameJson(Map.of(), Map.of());

        assertThatCode(() -> consumer.onMessage(message)).doesNotThrowAnyException();

        verify(ingestionService, never()).ingest(any(), any(), any(), any());
        assertThat(consumer.getUndecodableCount()).isEqualTo(1);
    }

    @Test
    void shouldDropUnknownDeviceWithoutBlocking() throws Exception {
        when(bindingRepository.findByProviderAndExternalDeviceId(
                TbDeviceBinding.PROVIDER_THINGSBOARD, TB_ID)).thenReturn(Optional.empty());
        when(bindingRepository.findByProviderAndDeviceEui(
                TbDeviceBinding.PROVIDER_THINGSBOARD, EUI)).thenReturn(Optional.empty());
        String message = frameJson(Map.of("battery", 80), Map.of());

        assertThatCode(() -> consumer.onMessage(message)).doesNotThrowAnyException();

        verify(ingestionService, never()).ingest(any(), any(), any(), any());
        assertThat(consumer.getUnknownDeviceCount()).isEqualTo(1);
    }

    @Test
    void shouldResolveBindingByDevEuiWhenTbDeviceIdUnknown() throws Exception {
        when(bindingRepository.findByProviderAndExternalDeviceId(
                TbDeviceBinding.PROVIDER_THINGSBOARD, TB_ID)).thenReturn(Optional.empty());
        when(bindingRepository.findByProviderAndDeviceEui(
                TbDeviceBinding.PROVIDER_THINGSBOARD, EUI))
                .thenReturn(Optional.of(resolvedBinding()));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(activeCapsule()));
        String message = frameJson(Map.of("battery", 80), Map.of());

        consumer.onMessage(message);

        verify(ingestionService).ingest(eq(122L), any(),
                eq(Instant.ofEpochMilli(1000L)), eq(TelemetrySource.THINGSBOARD));
    }

    @Test
    void shouldSkipFrameAlreadyIngested() throws Exception {
        stubResolvedDevice();
        when(deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(
                122L, Instant.ofEpochMilli(1000L))).thenReturn(true);
        String message = frameJson(Map.of("battery", 80), Map.of());

        consumer.onMessage(message);

        verify(ingestionService, never()).ingest(any(), any(), any(), any());
        assertThat(consumer.getDuplicateCount()).isEqualTo(1);
    }

    @Test
    void shouldSwallowUniqueConflictAsConcurrentIngest() throws Exception {
        stubResolvedDevice();
        when(deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(
                122L, Instant.ofEpochMilli(1000L))).thenReturn(false, true);
        doThrow(new DataIntegrityViolationException("duplicate key"))
                .when(ingestionService).ingest(eq(122L), any(), any(), any());
        String message = frameJson(Map.of("battery", 80), Map.of());

        assertThatCode(() -> consumer.onMessage(message)).doesNotThrowAnyException();

        assertThat(consumer.getDuplicateCount()).isEqualTo(1);
    }

    @Test
    void shouldRethrowUniqueConflictWhenRowAbsent() throws Exception {
        stubResolvedDevice();
        when(deviceTelemetryLogRepository.existsByDeviceIdAndReportTime(
                122L, Instant.ofEpochMilli(1000L))).thenReturn(false);
        doThrow(new DataIntegrityViolationException("other constraint"))
                .when(ingestionService).ingest(eq(122L), any(), any(), any());
        String message = frameJson(Map.of("battery", 80), Map.of());

        assertThatThrownBy(() -> consumer.onMessage(message))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void shouldPropagateTransientIngestFailureForRetry() throws Exception {
        stubResolvedDevice();
        doThrow(new RuntimeException("db down"))
                .when(ingestionService).ingest(eq(122L), any(), any(), any());
        String message = frameJson(Map.of("battery", 80), Map.of());

        assertThatThrownBy(() -> consumer.onMessage(message))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("db down");
    }

    @Test
    void shouldDropMalformedJson() {
        assertThatCode(() -> consumer.onMessage("not-json")).doesNotThrowAnyException();

        verify(ingestionService, never()).ingest(any(), any(), any(), any());
        assertThat(consumer.getMalformedCount()).isEqualTo(1);
    }

    @Test
    void shouldDropFrameWithMissingContractFields() throws Exception {
        Map<String, Object> frame = new HashMap<>();
        frame.put("version", 1);
        frame.put("frameId", "f-1");
        frame.put("devEui", EUI);
        frame.put("ts", 1000L);
        frame.put("properties", Map.of("battery", 80));

        assertThatCode(() -> consumer.onMessage(mapper.writeValueAsString(frame)))
                .doesNotThrowAnyException();

        verify(ingestionService, never()).ingest(any(), any(), any(), any());
        assertThat(consumer.getMalformedCount()).isEqualTo(1);
    }

    @Test
    void shouldClampOutOfRangeGpsBeforeIngest() throws Exception {
        stubResolvedDevice();
        String message = frameJson(
                Map.of("latitude", 2000, "longitude", 112.85, "battery", 66), Map.of());

        consumer.onMessage(message);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, Object>> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(ingestionService).ingest(eq(122L), readingsCaptor.capture(), any(), any());
        assertThat(readingsCaptor.getValue()).containsEntry("latitude", null);
        assertThat(readingsCaptor.getValue())
                .containsEntry("longitude", new BigDecimal("112.85"));
    }
}
