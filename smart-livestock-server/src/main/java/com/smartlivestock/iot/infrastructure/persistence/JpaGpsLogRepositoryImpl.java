package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.infrastructure.persistence.mapper.GpsLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGpsLogRepositoryImpl implements GpsLogRepository {

    private final SpringDataGpsLogRepository springDataRepo;

    @Override
    public GpsLog save(GpsLog gpsLog) {
        return GpsLogMapper.toDomain(springDataRepo.save(GpsLogMapper.toJpaEntity(gpsLog)));
    }

    @Override
    public List<GpsLog> findByDeviceId(Long deviceId) {
        return springDataRepo.findByDeviceId(deviceId).stream()
                .map(GpsLogMapper::toDomain)
                .toList();
    }

    @Override
    public List<GpsLog> findByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to) {
        return springDataRepo.findByDeviceIdAndRecordedAtBetween(deviceId, from, to).stream()
                .map(GpsLogMapper::toDomain)
                .toList();
    }
}
