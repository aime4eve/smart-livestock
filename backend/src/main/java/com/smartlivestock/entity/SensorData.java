package com.smartlivestock.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 传感器数据实体类，对应数据库中的sensor_data表
 * 与Cattle是多对一关系
 */
@Entity
@Table(name = "sensor_data")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SensorData {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cattle_id", nullable = false)
    private Cattle cattle;
    
    @Column(nullable = false)
    private LocalDateTime timestamp;
    
    @Column(name = "stomach_temperature", nullable = false, precision = 5, scale = 2)
    private BigDecimal stomachTemperature;
    
    @Column(name = "peristaltic_count", nullable = false)
    private Integer peristalticCount;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        if (timestamp == null) {
            timestamp = LocalDateTime.now();
        }
    }
} 