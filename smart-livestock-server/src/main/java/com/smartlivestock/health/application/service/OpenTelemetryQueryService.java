package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.OpenTelemetryDtos.ActivityReading;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.DeviceHealthTelemetry;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.LivestockTelemetry;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.MotilityReading;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.SeriesPage;
import com.smartlivestock.health.application.dto.OpenTelemetryDtos.TemperatureReading;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.RumenMotilityLog;
import com.smartlivestock.shared.domain.TelemetryPage;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Set;

/**
 * Livestock/device health telemetry for the Open API endpoints (NIX-323).
 * Types filter: temperature / motility / activity; empty or null selects all.
 */
@Service
@RequiredArgsConstructor
public class OpenTelemetryQueryService {

    public static final String TYPE_TEMPERATURE = "temperature";
    public static final String TYPE_MOTILITY = "motility";
    public static final String TYPE_ACTIVITY = "activity";

    private final TemperatureLogRepository temperatureLogRepository;
    private final RumenMotilityLogRepository motilityLogRepository;
    private final ActivityLogRepository activityLogRepository;

    @Transactional(readOnly = true)
    public LivestockTelemetry queryByLivestock(Long livestockId, Long deviceId, Set<String> types,
                                                Instant from, Instant to, int page, int pageSize) {
        boolean wantTemp = wants(types, TYPE_TEMPERATURE);
        boolean wantMotility = wants(types, TYPE_MOTILITY);
        boolean wantActivity = wants(types, TYPE_ACTIVITY);

        SeriesPage<TemperatureReading> temperature = wantTemp
                ? toSeries(temperatureLogRepository.findPageByLivestock(livestockId, from, to, page, pageSize),
                        this::toTemperatureReading, page, pageSize)
                : emptySeries(page, pageSize);
        SeriesPage<MotilityReading> motility = wantMotility
                ? toSeries(motilityLogRepository.findPageByLivestock(livestockId, from, to, page, pageSize),
                        this::toMotilityReading, page, pageSize)
                : emptySeries(page, pageSize);
        SeriesPage<ActivityReading> activity = wantActivity
                ? toSeries(activityLogRepository.findPageByLivestock(livestockId, from, to, page, pageSize),
                        this::toActivityReading, page, pageSize)
                : emptySeries(page, pageSize);

        return new LivestockTelemetry(livestockId, deviceId, from, to, temperature, motility, activity);
    }

    @Transactional(readOnly = true)
    public DeviceHealthTelemetry queryByDevice(Long deviceId, Set<String> types,
                                               Instant from, Instant to, int page, int pageSize) {
        boolean wantTemp = wants(types, TYPE_TEMPERATURE);
        boolean wantMotility = wants(types, TYPE_MOTILITY);

        SeriesPage<TemperatureReading> temperature = wantTemp
                ? toSeries(temperatureLogRepository.findPageByDevice(deviceId, from, to, page, pageSize),
                        this::toTemperatureReading, page, pageSize)
                : emptySeries(page, pageSize);
        SeriesPage<MotilityReading> motility = wantMotility
                ? toSeries(motilityLogRepository.findPageByDevice(deviceId, from, to, page, pageSize),
                        this::toMotilityReading, page, pageSize)
                : emptySeries(page, pageSize);

        return new DeviceHealthTelemetry(deviceId, from, to, temperature, motility);
    }

    public static boolean wants(Set<String> types, String type) {
        return types == null || types.isEmpty() || types.contains(type);
    }

    private TemperatureReading toTemperatureReading(TemperatureLog log) {
        return new TemperatureReading(log.getTemperature(), log.getBaselineTemp(), log.getDelta(),
                log.getSource(), log.getRecordedAt());
    }

    private MotilityReading toMotilityReading(RumenMotilityLog log) {
        return new MotilityReading(log.getFrequency(), log.getIntensity(), log.getRawCounter(),
                log.getCounterDelta(), log.getSource(), log.getRecordedAt());
    }

    private ActivityReading toActivityReading(ActivityLog log) {
        return new ActivityReading(log.getStepCount(), log.getActivityIndex(), log.getDistanceMeters(),
                log.getSource(), log.getRecordedAt());
    }

    private <D, T> SeriesPage<T> toSeries(TelemetryPage<D> page,
            java.util.function.Function<D, T> mapper, int pageNo, int pageSize) {
        return new SeriesPage<>(page.items().stream().map(mapper).toList(), pageNo, pageSize, page.total());
    }

    private static <T> SeriesPage<T> emptySeries(int page, int pageSize) {
        return new SeriesPage<>(java.util.List.of(), page, pageSize, 0L);
    }
}
