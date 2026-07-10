package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.infrastructure.persistence.entity.AuditLogJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SpringDataAuditLogRepository extends JpaRepository<AuditLogJpaEntity, Long> {

    @Query("SELECT a FROM AuditLogJpaEntity a WHERE " +
            "(:tenantId IS NULL OR a.tenantId = :tenantId) AND " +
            "(:userId IS NULL OR a.userId = :userId) AND " +
            "(:action IS NULL OR a.action = :action) AND " +
            "(:startTime IS NULL OR a.occurredAt >= CAST(:startTime AS instant)) AND " +
            "(:endTime IS NULL OR a.occurredAt <= CAST(:endTime AS instant)) " +
            "ORDER BY a.occurredAt DESC")
    Page<AuditLogJpaEntity> findFiltered(
            @Param("tenantId") Long tenantId,
            @Param("userId") Long userId,
            @Param("action") String action,
            @Param("startTime") String startTime,
            @Param("endTime") String endTime,
            Pageable pageable);
}
