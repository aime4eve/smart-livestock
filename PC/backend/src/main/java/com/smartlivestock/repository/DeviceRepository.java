package com.smartlivestock.repository;

import com.smartlivestock.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 设备数据访问层接口
 */
@Repository
public interface DeviceRepository extends JpaRepository<Device, Long> {
    
    Optional<Device> findByDeviceId(String deviceId);
    
    boolean existsByDeviceId(String deviceId);
    
    List<Device> findByDeviceType(String deviceType);
    
    List<Device> findByStatus(String status);
    
    List<Device> findByBatteryLevelLessThan(Integer batteryLevel);
} 