package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.LivestockRoamDailyJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface SpringDataLivestockRoamDailyRepository
        extends JpaRepository<LivestockRoamDailyJpaEntity, Long> {

    Optional<LivestockRoamDailyJpaEntity> findByDeviceIdAndRoamDay(Long deviceId, LocalDate roamDay);

    List<LivestockRoamDailyJpaEntity> findByDeviceIdAndRoamDayBetweenOrderByRoamDay(
            Long deviceId, LocalDate from, LocalDate to);
}
