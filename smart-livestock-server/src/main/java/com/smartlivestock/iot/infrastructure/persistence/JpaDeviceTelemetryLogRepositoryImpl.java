package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.infrastructure.persistence.mapper.DeviceTelemetryLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeviceTelemetryLogRepositoryImpl implements DeviceTelemetryLogRepository {

    private final SpringDataDeviceTelemetryLogRepository springDataRepo;

    @Override
    public DeviceTelemetryLog save(DeviceTelemetryLog log) {
        return DeviceTelemetryLogMapper.toDomain(springDataRepo.save(DeviceTelemetryLogMapper.toJpaEntity(log)));
    }

    @Override
    public Optional<DeviceTelemetryLog> findLatestByDeviceId(Long deviceId) {
        return springDataRepo.findLatestByDeviceId(deviceId, PageRequest.of(0, 1))
                .stream().findFirst()
                .map(DeviceTelemetryLogMapper::toDomain);
    }
}
