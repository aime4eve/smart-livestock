package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.DeviceHealthSeries;
import com.smartlivestock.health.application.dto.HealthDtos.MotilityReading;
import com.smartlivestock.health.application.dto.HealthDtos.TemperatureReading;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;

@Service
@RequiredArgsConstructor
public class DeviceHealthSeriesApplicationService {

    private final TemperatureLogRepository temperatureLogRepository;
    private final RumenMotilityLogRepository motilityLogRepository;

    @Transactional(readOnly = true)
    public DeviceHealthSeries getSeries(Long deviceId) {
        Instant now = Instant.now();
        var temperatures = temperatureLogRepository
                .findByDeviceIdAndTimeRange(deviceId, now.minus(Duration.ofHours(72)), now)
                .stream()
                .map(log -> new TemperatureReading(log.getTemperature(), log.getRecordedAt()))
                .toList();
        var motilities = motilityLogRepository
                .findByDeviceIdAndTimeRange(deviceId, now.minus(Duration.ofHours(24)), now)
                .stream()
                .map(this::toMotilityReading)
                .toList();

        return new DeviceHealthSeries(deviceId.toString(), temperatures, motilities);
    }

    private MotilityReading toMotilityReading(
            com.smartlivestock.health.domain.model.RumenMotilityLog log) {
        return new MotilityReading(
                log.getFrequency(), log.getIntensity(), log.getRawCounter(),
                log.getCounterDelta(), log.getSource(), log.getRecordedAt());
    }
}
