package com.smartlivestock.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import javax.persistence.*;
import java.time.LocalDateTime;

/**
 * 设备实体类，对应数据库中的devices表
 */
@Entity
@Table(name = "devices")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Device {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "device_id", nullable = false, unique = true, length = 50)
    private String deviceId;
    
    @Column(name = "device_type", nullable = false, length = 50)
    private String deviceType;
    
    @Column(nullable = false, length = 20)
    private String status;
    
    @Column(name = "last_online")
    private LocalDateTime lastOnline;
    
    @Column(name = "battery_level")
    private Integer batteryLevel;
    
    @Column(name = "firmware_version", length = 50)
    private String firmwareVersion;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        if (status == null) {
            status = "active";
        }
    }
} 