package com.smartlivestock.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 传感器数据传输对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SensorDataDto {
    
    private Long id;
    
    private Long cattleId;
    
    @NotNull(message = "时间戳不能为空")
    private LocalDateTime timestamp;
    
    @NotNull(message = "胃温数据不能为空")
    private BigDecimal stomachTemperature;
    
    @NotNull(message = "蠕动次数不能为空")
    private Integer peristalticCount;
    
    private LocalDateTime createdAt;
} 