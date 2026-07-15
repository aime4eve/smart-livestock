package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.RtkReferencePointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataRtkReferencePointRepository extends JpaRepository<RtkReferencePointJpaEntity, Long> {
    List<RtkReferencePointJpaEntity> findByLocationNameOrderById(@Param("locationName") String locationName);
}
