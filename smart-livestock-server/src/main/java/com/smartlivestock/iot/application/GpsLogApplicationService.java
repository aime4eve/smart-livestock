package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.dto.GpsLogDto;
import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GpsLogApplicationService {

    private final GpsLogRepository gpsLogRepository;

    @Transactional
    public GpsLogDto logGps(Long deviceId, BigDecimal latitude, BigDecimal longitude,
                            BigDecimal accuracy, Instant recordedAt) {
        GpsLog gpsLog = new GpsLog(deviceId, latitude, longitude, accuracy, recordedAt);
        GpsLog saved = gpsLogRepository.save(gpsLog);
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
}
