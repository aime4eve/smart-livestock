package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.RumenMotilityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeviceHealthSeriesApplicationServiceTest {

    @Mock
    private TemperatureLogRepository temperatureLogRepository;

    @Mock
    private RumenMotilityLogRepository motilityLogRepository;

    @InjectMocks
    private DeviceHealthSeriesApplicationService service;

    @Test
    void getSeries_queriesDeviceWindowsAndMapsReadings() {
        TemperatureLog temperature = new TemperatureLog();
        temperature.setTemperature(new BigDecimal("38.6"));
        temperature.setRecordedAt(Instant.now().minusSeconds(600));
        RumenMotilityLog motility = new RumenMotilityLog();
        motility.setFrequency(new BigDecimal("3.20"));
        motility.setIntensity(BigDecimal.ZERO);
        motility.setRecordedAt(Instant.now().minusSeconds(300));
        when(temperatureLogRepository.findByDeviceIdAndTimeRange(
                eq(51L), any(Instant.class), any(Instant.class)))
                .thenReturn(List.of(temperature));
        when(motilityLogRepository.findByDeviceIdAndTimeRange(
                eq(51L), any(Instant.class), any(Instant.class)))
                .thenReturn(List.of(motility));

        var result = service.getSeries(51L);

        assertEquals("51", result.deviceId());
        assertEquals(1, result.temperature72h().size());
        assertEquals(new BigDecimal("38.6"), result.temperature72h().get(0).temperature());
        assertEquals(1, result.motility24h().size());
        assertEquals(new BigDecimal("3.20"), result.motility24h().get(0).frequency());

        var temperatureStart = org.mockito.ArgumentCaptor.forClass(Instant.class);
        var temperatureEnd = org.mockito.ArgumentCaptor.forClass(Instant.class);
        var motilityStart = org.mockito.ArgumentCaptor.forClass(Instant.class);
        var motilityEnd = org.mockito.ArgumentCaptor.forClass(Instant.class);
        verify(temperatureLogRepository).findByDeviceIdAndTimeRange(
                eq(51L), temperatureStart.capture(), temperatureEnd.capture());
        verify(motilityLogRepository).findByDeviceIdAndTimeRange(
                eq(51L), motilityStart.capture(), motilityEnd.capture());
        assertEquals(Duration.ofHours(72),
                Duration.between(temperatureStart.getValue(), temperatureEnd.getValue()));
        assertEquals(Duration.ofHours(24),
                Duration.between(motilityStart.getValue(), motilityEnd.getValue()));
    }
}
