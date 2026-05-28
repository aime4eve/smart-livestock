package com.smartlivestock.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 牛只元数据数据传输对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CattleMetadataDto {
    
    private Long id;
    
    private Long cattleId;
    
    private Integer age;
    
    private BigDecimal weight;
    
    private String breed;
    
    private String notes;
    
    private LocalDateTime createdAt;
    
    private LocalDateTime updatedAt;
} 