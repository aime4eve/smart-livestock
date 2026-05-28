package com.smartlivestock.repository;

import com.smartlivestock.entity.CattleMetadata;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

/**
 * 牛只元数据访问层接口
 */
@Repository
public interface CattleMetadataRepository extends JpaRepository<CattleMetadata, Long> {
    
    List<CattleMetadata> findByCattleId(Long cattleId);
    
    List<CattleMetadata> findByBreed(String breed);
    
    List<CattleMetadata> findByAgeBetween(Integer minAge, Integer maxAge);
    
    List<CattleMetadata> findByWeightGreaterThan(BigDecimal weight);
} 