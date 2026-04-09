package com.smartlivestock.repository;

import com.smartlivestock.entity.SensorData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 传感器数据访问层接口
 */
@Repository
public interface SensorDataRepository extends JpaRepository<SensorData, Long> {
    
    List<SensorData> findByCattleId(Long cattleId);
    
    List<SensorData> findByCattleIdAndTimestampBetween(
            Long cattleId, LocalDateTime startTime, LocalDateTime endTime);
} 