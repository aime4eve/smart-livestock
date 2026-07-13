package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.dto.GpsLogDto;
import com.smartlivestock.iot.domain.event.GpsLogUpdatedEvent;
import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GpsLogApplicationService {

    private final GpsLogRepository gpsLogRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public GpsLogDto logGps(Long deviceId, BigDecimal latitude, BigDecimal longitude,
                            BigDecimal accuracy, Instant recordedAt) {
        GpsLog gpsLog = new GpsLog(deviceId, latitude, longitude, accuracy, recordedAt);
        GpsLog saved = gpsLogRepository.save(gpsLog);

        // Publish domain event for cross-context consumers (e.g., fence breach detection)
        eventPublisher.publishEvent(new GpsLogUpdatedEvent(
                deviceId, latitude, longitude, recordedAt));

        return GpsLogDto.from(saved);
    }

    @Transactional(readOnly = true)
    public List<GpsLogDto> getByDevice(Long deviceId) {
        return gpsLogRepository.findByDeviceId(deviceId).stream()
                .map(GpsLogDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<GpsLogDto> getByDeviceAndTimeRange(Long deviceId, Instant from, Instant to) {
        return gpsLogRepository.findByDeviceIdAndRecordedAtBetween(deviceId, from, to).stream()
                .map(GpsLogDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<GpsLogDto> sampleByDeviceAndTimeRange(Long deviceId, Instant from, Instant to, int sampleSize) {
        long total = gpsLogRepository.countByDeviceIdAndRecordedAtBetween(deviceId, from, to);
        if (total <= sampleSize) {
            return gpsLogRepository.findByDeviceIdAndRecordedAtBetween(deviceId, from, to).stream()
                    .map(GpsLogDto::from)
                    .toList();
        }
        long stride = total / sampleSize;
        return gpsLogRepository.sampleByDeviceIdAndTimeRange(deviceId, from, to, stride).stream()
                .map(GpsLogDto::from)
                .toList();
    }
}
