package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.LivestockRoamDaily;
import com.smartlivestock.iot.domain.repository.LivestockRoamRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.LivestockRoamDailyJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaLivestockRoamRepositoryImpl implements LivestockRoamRepository {

    private final SpringDataLivestockRoamDailyRepository springData;

    @Override
    @Transactional
    public LivestockRoamDaily save(LivestockRoamDaily aggregate) {
        LivestockRoamDailyJpaEntity entity = springData
                .findByDeviceIdAndRoamDay(aggregate.deviceId(), aggregate.roamDay())
                .orElseGet(LivestockRoamDailyJpaEntity::new);
        entity.setDeviceId(aggregate.deviceId());
        entity.setRoamDay(aggregate.roamDay());
        entity.setMaxDistanceM(aggregate.maxDistanceM());
        entity.setMeanDistanceM(aggregate.meanDistanceM());
        entity.setFrameCount(aggregate.frameCount());
        entity.setUpdatedAt(Instant.now());
        return toDomain(springData.save(entity));
    }

    @Override
    public List<LivestockRoamDaily> findByDeviceBetween(Long deviceId, LocalDate from, LocalDate to) {
        return springData.findByDeviceIdAndRoamDayBetweenOrderByRoamDay(deviceId, from, to).stream()
                .map(this::toDomain)
                .toList();
    }

    private LivestockRoamDaily toDomain(LivestockRoamDailyJpaEntity e) {
        return new LivestockRoamDaily(e.getDeviceId(), e.getRoamDay(),
                e.getMaxDistanceM(), e.getMeanDistanceM(), e.getFrameCount());
    }
}
