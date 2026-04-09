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

/**
 * 牛只元数据实体类，对应数据库中的cattle_metadata表
 * 与Cattle是一对一关系
 */
@Entity
@Table(name = "cattle_metadata")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CattleMetadata {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cattle_id", nullable = false, unique = true)
    private Cattle cattle;
    
    private Integer age;
    
    @Column(precision = 7, scale = 2)
    private BigDecimal weight;
    
    @Column(length = 100)
    private String breed;
    
    @Column(columnDefinition = "TEXT")
    private String notes;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
} 