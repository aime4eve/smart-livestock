package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.DataExportJobJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface SpringDataDataExportJobRepository extends JpaRepository<DataExportJobJpaEntity, Long> {

    List<DataExportJobJpaEntity> findByStatus(String status);

    List<DataExportJobJpaEntity> findByTenantIdOrderByIdDesc(Long tenantId);

    List<DataExportJobJpaEntity> findTop200ByOrderByIdDesc();

    @Query("SELECT j FROM DataExportJobJpaEntity j WHERE j.status = :status AND j.windowEndsAt < :now")
    List<DataExportJobJpaEntity> findByStatusAndWindowEndsAtBefore(@Param("status") String status,
                                                                   @Param("now") Instant now);
}
