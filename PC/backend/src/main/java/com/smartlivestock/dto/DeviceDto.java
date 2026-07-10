package com.smartlivestock.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotBlank;
import java.time.LocalDateTime;

/**
 * 设备数据传输对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceDto {
    
    private Long id;
    
    @NotBlank(message = "设备ID不能为空")
    private String deviceId;
    
    @NotBlank(message = "设备类型不能为空")
    private String deviceType;
    
    private String status;
    
    private LocalDateTime lastOnline;
    
    private Integer batteryLevel;
    
    private String firmwareVersion;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
} 