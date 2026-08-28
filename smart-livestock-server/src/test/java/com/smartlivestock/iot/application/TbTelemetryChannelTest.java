package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
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
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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

    private TbProperties properties;
    private TbTelemetryChannel channel;

    @BeforeEach
    void setUp() {
        properties = new TbProperties();
        properties.setEnabled(true);
        properties.setBatchSize(10);
        channel = new TbTelemetryChannel(properties, tbClient, bindingRepository,
                deviceRepository, ingestionService);
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

        when(bindingRepository.findByStatus(TbDeviceBinding.Status.RESOLVED)).thenReturn(List.of(binding));
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
    void shouldSkipNonActiveDeviceWithoutFetch() {
        TbDeviceBinding binding = new TbDeviceBinding();
        binding.setDeviceId(122L);
        binding.setStatus(TbDeviceBinding.Status.RESOLVED);
        Device device = activeTracker();
        device.setStatus(DeviceStatus.INVENTORY);

        when(bindingRepository.findByStatus(TbDeviceBinding.Status.RESOLVED)).thenReturn(List.of(binding));
        when(deviceRepository.findById(122L)).thenReturn(Optional.of(device));

        channel.poll();

        verify(tbClient, never()).fetchTimeseries(any(), anyLong(), anyLong(), anyInt());
        verify(ingestionService, never()).ingest(any(), any(), any(), any());
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
}
