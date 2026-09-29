package com.smartlivestock.health.infrastructure.persistence.jpa;

import com.smartlivestock.health.infrastructure.persistence.entity.ContactTraceJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ContactTraceJpaRepository extends JpaRepository<ContactTraceJpaEntity, Long> {
    List<ContactTraceJpaEntity> findByFarmIdOrderByLastContactAtDesc(Long farmId);
    List<ContactTraceJpaEntity> findByFromLivestockIdOrderByLastContactAtDesc(Long fromLivestockId);

    @Query("select t from ContactTraceJpaEntity t where t.farmId = :farmId"
            + " and (t.fromLivestockId = :livestockId or t.toLivestockId = :livestockId)"
            + " order by t.lastContactAt desc")
    List<ContactTraceJpaEntity> findByFarmIdAndLivestockParticipation(@Param("farmId") Long farmId,
                                                                      @Param("livestockId") Long livestockId);
}
