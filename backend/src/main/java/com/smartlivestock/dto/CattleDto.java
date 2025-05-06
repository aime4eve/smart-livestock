package com.smartlivestock.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 牛只数据传输对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CattleDto {
    
    private Long id;
    
    @NotBlank(message = "牛只ID不能为空")
    @Pattern(regexp = "^[A-Z0-9]{3,20}$", message = "牛只ID格式不正确，应为3-20位大写字母和数字")
    private String cattleId;
    
    private BigDecimal latitude;
    
    private BigDecimal longitude;
    
    private String healthStatus;
    
    private Long deviceId;
    
    private String deviceInfo;
    
    private LocalDateTime lastUpdate;
    
    private CattleMetadataDto metadata;
    
    private List<SensorDataDto> sensorDataList = new ArrayList<>();
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
} 