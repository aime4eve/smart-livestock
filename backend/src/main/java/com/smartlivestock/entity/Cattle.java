package com.smartlivestock.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 牛只实体类，对应数据库中的cattle表
 */
@Entity
@Table(name = "cattle")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Cattle {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "cattle_id", nullable = false, unique = true, length = 50)
    private String cattleId;
    
    @Column(precision = 10, scale = 7)
    private BigDecimal latitude;
    
    @Column(precision = 10, scale = 7)
    private BigDecimal longitude;
    
    @Column(name = "health_status", nullable = false, length = 20)
    private String healthStatus;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "device_id")
    private Device device;
    
    @Column(name = "last_update")
    private LocalDateTime lastUpdate;
    
    @OneToOne(mappedBy = "cattle", cascade = CascadeType.ALL, orphanRemoval = true)
    private CattleMetadata metadata;
    
    @OneToMany(mappedBy = "cattle", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<SensorData> sensorDataList = new ArrayList<>();
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        if (healthStatus == null) {
            healthStatus = "healthy";
        }
    }
    
    // 添加传感器数据的便捷方法
    public void addSensorData(SensorData sensorData) {
        sensorDataList.add(sensorData);
        sensorData.setCattle(this);
    }
    
    // 移除传感器数据的便捷方法
    public void removeSensorData(SensorData sensorData) {
        sensorDataList.remove(sensorData);
        sensorData.setCattle(null);
    }
    
    // 设置元数据的便捷方法
    public void setMetadata(CattleMetadata metadata) {
        if (metadata == null) {
            if (this.metadata != null) {
                this.metadata.setCattle(null);
            }
        } else {
            metadata.setCattle(this);
        }
        this.metadata = metadata;
    }
} 