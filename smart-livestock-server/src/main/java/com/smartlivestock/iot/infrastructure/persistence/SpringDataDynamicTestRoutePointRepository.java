package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DynamicTestRoutePointJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SpringDataDynamicTestRoutePointRepository extends JpaRepository<DynamicTestRoutePointJpaEntity, Long> {

    List<DynamicTestRoutePointJpaEntity> findByRouteIdOrderBySequenceNoAsc(Long routeId);

    /**
     * Bulk delete executed immediately against the DB. A derived deleteByRouteId
     * would queue entity removals in the persistence context, and Hibernate
     * flushes inserts before deletes — re-inserted (route_id, sequence_no)
     * keys then collide with rows not yet deleted (unique constraint).
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM DynamicTestRoutePointJpaEntity p WHERE p.routeId = :routeId")
    void deleteByRouteId(@Param("routeId") Long routeId);
}
