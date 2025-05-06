package com.smartlivestock.service.impl;

import com.smartlivestock.dto.CattleDto;
import com.smartlivestock.dto.CattleMetadataDto;
import com.smartlivestock.dto.SensorDataDto;
import com.smartlivestock.entity.Cattle;
import com.smartlivestock.entity.CattleMetadata;
import com.smartlivestock.entity.Device;
import com.smartlivestock.entity.SensorData;
import com.smartlivestock.exception.ResourceNotFoundException;
import com.smartlivestock.repository.CattleMetadataRepository;
import com.smartlivestock.repository.CattleRepository;
import com.smartlivestock.repository.DeviceRepository;
import com.smartlivestock.repository.SensorDataRepository;
import com.smartlivestock.service.CattleService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 牛只服务实现类
 */
@Service
@RequiredArgsConstructor
public class CattleServiceImpl implements CattleService {
    
    private final CattleRepository cattleRepository;
    private final CattleMetadataRepository metadataRepository;
    private final SensorDataRepository sensorDataRepository;
    private final DeviceRepository deviceRepository;
    
    /**
     * 创建牛只
     */
    @Override
    @Transactional
    public CattleDto createCattle(CattleDto cattleDto) {
        // 检查牛只ID是否已存在
        if (cattleRepository.existsByCattleId(cattleDto.getCattleId())) {
            throw new IllegalArgumentException("牛只ID已存在: " + cattleDto.getCattleId());
        }
        
        // 创建牛只实体
        Cattle cattle = Cattle.builder()
                .cattleId(cattleDto.getCattleId())
                .latitude(cattleDto.getLatitude())
                .longitude(cattleDto.getLongitude())
                .healthStatus(cattleDto.getHealthStatus() != null ? cattleDto.getHealthStatus() : "healthy")
                .lastUpdate(LocalDateTime.now())
                .build();
        
        // 如果指定了设备ID，关联设备
        if (cattleDto.getDeviceId() != null) {
            Device device = deviceRepository.findById(cattleDto.getDeviceId())
                    .orElseThrow(() -> new ResourceNotFoundException("Device", "id", cattleDto.getDeviceId()));
            cattle.setDevice(device);
        }
        
        // 保存牛只
        Cattle savedCattle = cattleRepository.save(cattle);
        
        // 如果有元数据，创建元数据
        if (cattleDto.getMetadata() != null) {
            CattleMetadata metadata = CattleMetadata.builder()
                    .cattle(savedCattle)
                    .age(cattleDto.getMetadata().getAge())
                    .weight(cattleDto.getMetadata().getWeight())
                    .breed(cattleDto.getMetadata().getBreed())
                    .notes(cattleDto.getMetadata().getNotes())
                    .build();
            
            metadataRepository.save(metadata);
            savedCattle.setMetadata(metadata);
        }
        
        // 如果有传感器数据，添加传感器数据
        if (cattleDto.getSensorDataList() != null && !cattleDto.getSensorDataList().isEmpty()) {
            for (SensorDataDto sensorDataDto : cattleDto.getSensorDataList()) {
                SensorData sensorData = SensorData.builder()
                        .cattle(savedCattle)
                        .timestamp(sensorDataDto.getTimestamp())
                        .stomachTemperature(sensorDataDto.getStomachTemperature())
                        .peristalticCount(sensorDataDto.getPeristalticCount())
                        .build();
                
                SensorData savedSensorData = sensorDataRepository.save(sensorData);
                savedCattle.addSensorData(savedSensorData);
            }
        }
        
        return mapToDto(savedCattle);
    }
    
    /**
     * 根据ID获取牛只
     */
    @Override
    @Transactional(readOnly = true)
    public CattleDto getCattleById(Long id) {
        Cattle cattle = cattleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", id));
        return mapToDto(cattle);
    }
    
    /**
     * 根据ID获取牛只，包含传感器数据
     */
    @Override
    @Transactional(readOnly = true)
    public CattleDto getCattleByIdWithSensorData(Long id) {
        Cattle cattle = cattleRepository.findByIdWithSensorData(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", id));
        return mapToDtoWithSensorData(cattle);
    }
    
    /**
     * 根据牛只ID获取牛只
     */
    @Override
    @Transactional(readOnly = true)
    public CattleDto getCattleByCattleId(String cattleId) {
        Cattle cattle = cattleRepository.findByCattleId(cattleId)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "cattleId", cattleId));
        return mapToDto(cattle);
    }
    
    /**
     * 获取所有牛只（分页）
     */
    @Override
    @Transactional(readOnly = true)
    public Page<CattleDto> getAllCattle(Pageable pageable) {
        Page<Cattle> cattlePage = cattleRepository.findAll(pageable);
        List<CattleDto> cattleDtos = cattlePage.getContent().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
        
        return new PageImpl<>(cattleDtos, pageable, cattlePage.getTotalElements());
    }
    
    /**
     * 根据健康状态获取牛只
     */
    @Override
    @Transactional(readOnly = true)
    public List<CattleDto> getCattleByHealthStatus(String healthStatus) {
        List<Cattle> cattleList = cattleRepository.findByHealthStatus(healthStatus);
        return cattleList.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 根据坐标范围获取牛只
     */
    @Override
    @Transactional(readOnly = true)
    public List<CattleDto> getCattleByCoordinatesRange(
            BigDecimal latMin, BigDecimal latMax, 
            BigDecimal lonMin, BigDecimal lonMax) {
        List<Cattle> cattleList = cattleRepository.findByCoordinatesWithinRange(
                latMin, latMax, lonMin, lonMax);
        return cattleList.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 更新牛只信息
     */
    @Override
    @Transactional
    public CattleDto updateCattle(Long id, CattleDto cattleDto) {
        Cattle cattle = cattleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", id));
        
        // 如果更新牛只ID，检查是否与其他牛只冲突
        if (!cattle.getCattleId().equals(cattleDto.getCattleId()) && 
                cattleRepository.existsByCattleId(cattleDto.getCattleId())) {
            throw new IllegalArgumentException("牛只ID已存在: " + cattleDto.getCattleId());
        }
        
        // 更新牛只信息
        cattle.setCattleId(cattleDto.getCattleId());
        cattle.setLatitude(cattleDto.getLatitude());
        cattle.setLongitude(cattleDto.getLongitude());
        cattle.setHealthStatus(cattleDto.getHealthStatus());
        cattle.setLastUpdate(LocalDateTime.now());
        
        // 如果更新了设备ID
        if (cattleDto.getDeviceId() != null) {
            Device device = deviceRepository.findById(cattleDto.getDeviceId())
                    .orElseThrow(() -> new ResourceNotFoundException("Device", "id", cattleDto.getDeviceId()));
            cattle.setDevice(device);
        } else {
            cattle.setDevice(null);
        }
        
        // 保存更新后的牛只
        Cattle updatedCattle = cattleRepository.save(cattle);
        
        return mapToDto(updatedCattle);
    }
    
    /**
     * 更新牛只位置
     */
    @Override
    @Transactional
    public CattleDto updateCattleLocation(Long id, BigDecimal latitude, BigDecimal longitude) {
        Cattle cattle = cattleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", id));
        
        cattle.setLatitude(latitude);
        cattle.setLongitude(longitude);
        cattle.setLastUpdate(LocalDateTime.now());
        
        Cattle updatedCattle = cattleRepository.save(cattle);
        
        return mapToDto(updatedCattle);
    }
    
    /**
     * 更新牛只健康状态
     */
    @Override
    @Transactional
    public CattleDto updateCattleHealthStatus(Long id, String healthStatus) {
        Cattle cattle = cattleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", id));
        
        cattle.setHealthStatus(healthStatus);
        cattle.setLastUpdate(LocalDateTime.now());
        
        Cattle updatedCattle = cattleRepository.save(cattle);
        
        return mapToDto(updatedCattle);
    }
    
    /**
     * 删除牛只
     */
    @Override
    @Transactional
    public void deleteCattle(Long id) {
        Cattle cattle = cattleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", id));
        cattleRepository.delete(cattle);
    }
    
    /**
     * 更新牛只元数据
     */
    @Override
    @Transactional
    public CattleMetadataDto updateCattleMetadata(Long cattleId, CattleMetadataDto metadataDto) {
        Cattle cattle = cattleRepository.findById(cattleId)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", cattleId));
        
        CattleMetadata metadata;
        if (cattle.getMetadata() == null) {
            // 创建新的元数据
            metadata = new CattleMetadata();
            metadata.setCattle(cattle);
        } else {
            // 更新现有元数据
            metadata = cattle.getMetadata();
        }
        
        metadata.setAge(metadataDto.getAge());
        metadata.setWeight(metadataDto.getWeight());
        metadata.setBreed(metadataDto.getBreed());
        metadata.setNotes(metadataDto.getNotes());
        
        CattleMetadata savedMetadata = metadataRepository.save(metadata);
        cattle.setMetadata(savedMetadata);
        
        return mapMetadataToDto(savedMetadata);
    }
    
    /**
     * 添加传感器数据
     */
    @Override
    @Transactional
    public SensorDataDto addSensorData(Long cattleId, SensorDataDto sensorDataDto) {
        Cattle cattle = cattleRepository.findById(cattleId)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", cattleId));
        
        SensorData sensorData = SensorData.builder()
                .cattle(cattle)
                .timestamp(sensorDataDto.getTimestamp() != null ? sensorDataDto.getTimestamp() : LocalDateTime.now())
                .stomachTemperature(sensorDataDto.getStomachTemperature())
                .peristalticCount(sensorDataDto.getPeristalticCount())
                .build();
        
        SensorData savedSensorData = sensorDataRepository.save(sensorData);
        cattle.addSensorData(savedSensorData);
        
        // 更新牛只最后更新时间
        cattle.setLastUpdate(LocalDateTime.now());
        cattleRepository.save(cattle);
        
        return mapSensorDataToDto(savedSensorData);
    }
    
    /**
     * 获取牛只的传感器数据
     */
    @Override
    @Transactional(readOnly = true)
    public List<SensorDataDto> getSensorDataByCattleId(Long cattleId) {
        // 确认牛只存在
        if (!cattleRepository.existsById(cattleId)) {
            throw new ResourceNotFoundException("Cattle", "id", cattleId);
        }
        
        List<SensorData> sensorDataList = sensorDataRepository.findByCattleId(cattleId);
        return sensorDataList.stream()
                .map(this::mapSensorDataToDto)
                .collect(Collectors.toList());
    }
    
    /**
     * 给牛只分配设备
     */
    @Override
    @Transactional
    public void assignDeviceToCattle(Long cattleId, Long deviceId) {
        Cattle cattle = cattleRepository.findById(cattleId)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", cattleId));
        
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ResourceNotFoundException("Device", "id", deviceId));
        
        cattle.setDevice(device);
        cattle.setLastUpdate(LocalDateTime.now());
        
        cattleRepository.save(cattle);
    }
    
    /**
     * 移除牛只的设备
     */
    @Override
    @Transactional
    public void removeDeviceFromCattle(Long cattleId) {
        Cattle cattle = cattleRepository.findById(cattleId)
                .orElseThrow(() -> new ResourceNotFoundException("Cattle", "id", cattleId));
        
        cattle.setDevice(null);
        cattle.setLastUpdate(LocalDateTime.now());
        
        cattleRepository.save(cattle);
    }
    
    /**
     * 将实体转换为DTO
     */
    private CattleDto mapToDto(Cattle cattle) {
        CattleDto.CattleDtoBuilder builder = CattleDto.builder()
                .id(cattle.getId())
                .cattleId(cattle.getCattleId())
                .latitude(cattle.getLatitude())
                .longitude(cattle.getLongitude())
                .healthStatus(cattle.getHealthStatus())
                .lastUpdate(cattle.getLastUpdate())
                .createdAt(cattle.getCreatedAt())
                .updatedAt(cattle.getUpdatedAt());
        
        // 添加设备信息
        if (cattle.getDevice() != null) {
            builder.deviceId(cattle.getDevice().getId());
            builder.deviceInfo(cattle.getDevice().getDeviceId() + " (" + cattle.getDevice().getDeviceType() + ")");
        }
        
        // 添加元数据
        if (cattle.getMetadata() != null) {
            builder.metadata(mapMetadataToDto(cattle.getMetadata()));
        }
        
        return builder.build();
    }
    
    /**
     * 将实体转换为DTO（包含传感器数据）
     */
    private CattleDto mapToDtoWithSensorData(Cattle cattle) {
        CattleDto cattleDto = mapToDto(cattle);
        
        // 添加传感器数据
        if (cattle.getSensorDataList() != null) {
            List<SensorDataDto> sensorDataDtos = cattle.getSensorDataList().stream()
                    .map(this::mapSensorDataToDto)
                    .collect(Collectors.toList());
            cattleDto.setSensorDataList(sensorDataDtos);
        }
        
        return cattleDto;
    }
    
    /**
     * 将元数据实体转换为DTO
     */
    private CattleMetadataDto mapMetadataToDto(CattleMetadata metadata) {
        return CattleMetadataDto.builder()
                .id(metadata.getId())
                .cattleId(metadata.getCattle().getId())
                .age(metadata.getAge())
                .weight(metadata.getWeight())
                .breed(metadata.getBreed())
                .notes(metadata.getNotes())
                .createdAt(metadata.getCreatedAt())
                .updatedAt(metadata.getUpdatedAt())
                .build();
    }
    
    /**
     * 将传感器数据实体转换为DTO
     */
    private SensorDataDto mapSensorDataToDto(SensorData sensorData) {
        return SensorDataDto.builder()
                .id(sensorData.getId())
                .cattleId(sensorData.getCattle().getId())
                .timestamp(sensorData.getTimestamp())
                .stomachTemperature(sensorData.getStomachTemperature())
                .peristalticCount(sensorData.getPeristalticCount())
                .createdAt(sensorData.getCreatedAt())
                .build();
    }
} 