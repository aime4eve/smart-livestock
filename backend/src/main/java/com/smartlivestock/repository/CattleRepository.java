package com.smartlivestock.repository;

import com.smartlivestock.entity.Cattle;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * 牛只数据访问层接口
 */
@Repository
public interface CattleRepository extends JpaRepository<Cattle, Long> {
    
    Optional<Cattle> findByCattleId(String cattleId);
    
    boolean existsByCattleId(String cattleId);
    
    List<Cattle> findByHealthStatus(String healthStatus);
    
    @Query("SELECT c FROM Cattle c WHERE c.latitude BETWEEN :latMin AND :latMax AND c.longitude BETWEEN :lonMin AND :lonMax")
    List<Cattle> findByCoordinatesWithinRange(
            @Param("latMin") BigDecimal latMin,
            @Param("latMax") BigDecimal latMax,
            @Param("lonMin") BigDecimal lonMin,
            @Param("lonMax") BigDecimal lonMax);
    
    @Query("SELECT c FROM Cattle c LEFT JOIN FETCH c.sensorDataList WHERE c.id = :id")
    Optional<Cattle> findByIdWithSensorData(@Param("id") Long id);
    
    @Query("SELECT c FROM Cattle c LEFT JOIN FETCH c.metadata WHERE c.id = :id")
    Optional<Cattle> findByIdWithMetadata(@Param("id") Long id);
    
    @Query("SELECT c FROM Cattle c WHERE c.device.id = :deviceId")
    List<Cattle> findByDeviceId(@Param("deviceId") Long deviceId);
    
    Page<Cattle> findAll(Pageable pageable);
} 