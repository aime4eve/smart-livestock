package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.StandardTrackLinePointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataStandardTrackLinePointRepository
        extends JpaRepository<StandardTrackLinePointJpaEntity, Long> {

    List<StandardTrackLinePointJpaEntity> findByLineIdOrderBySequenceNo(Long lineId);

    void deleteByLineId(Long lineId);
}
