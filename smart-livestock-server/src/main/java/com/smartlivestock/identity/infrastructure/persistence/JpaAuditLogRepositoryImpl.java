package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.smartlivestock.identity.infrastructure.persistence.mapper.AuditLogMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class JpaAuditLogRepositoryImpl implements AuditLogRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public AuditLog save(AuditLog auditLog) {
        AuditLogJpaEntity saved = entityManager.merge(AuditLogMapper.toJpaEntity(auditLog));
        return AuditLogMapper.toDomain(saved);
    }

    @Override
    public List<AuditLog> findAll(int page, int pageSize, Long tenantId, Long userId,
                                  String action, String startTime, String endTime) {
        StringBuilder jpql = new StringBuilder("SELECT a FROM AuditLogJpaEntity a WHERE 1=1");
        if (tenantId != null) jpql.append(" AND a.tenantId = :tenantId");
        if (userId != null) jpql.append(" AND a.userId = :userId");
        if (action != null && !action.isEmpty()) jpql.append(" AND a.action = :action");
        if (startTime != null) jpql.append(" AND a.occurredAt >= :startTime");
        if (endTime != null) jpql.append(" AND a.occurredAt <= :endTime");
        jpql.append(" ORDER BY a.occurredAt DESC");

        TypedQuery<AuditLogJpaEntity> query = entityManager.createQuery(jpql.toString(), AuditLogJpaEntity.class);
        if (tenantId != null) query.setParameter("tenantId", tenantId);
        if (userId != null) query.setParameter("userId", userId);
        if (action != null && !action.isEmpty()) query.setParameter("action", action);
        if (startTime != null) query.setParameter("startTime", Instant.parse(startTime));
        if (endTime != null) query.setParameter("endTime", Instant.parse(endTime));

        query.setFirstResult((page - 1) * pageSize);
        query.setMaxResults(pageSize);

        return query.getResultList().stream().map(AuditLogMapper::toDomain).collect(Collectors.toList());
    }

    @Override
    public long count(Long tenantId, Long userId, String action, String startTime, String endTime) {
        StringBuilder jpql = new StringBuilder("SELECT COUNT(a) FROM AuditLogJpaEntity a WHERE 1=1");
        if (tenantId != null) jpql.append(" AND a.tenantId = :tenantId");
        if (userId != null) jpql.append(" AND a.userId = :userId");
        if (action != null && !action.isEmpty()) jpql.append(" AND a.action = :action");
        if (startTime != null) jpql.append(" AND a.occurredAt >= :startTime");
        if (endTime != null) jpql.append(" AND a.occurredAt <= :endTime");

        var query = entityManager.createQuery(jpql.toString(), Long.class);
        if (tenantId != null) query.setParameter("tenantId", tenantId);
        if (userId != null) query.setParameter("userId", userId);
        if (action != null && !action.isEmpty()) query.setParameter("action", action);
        if (startTime != null) query.setParameter("startTime", Instant.parse(startTime));
        if (endTime != null) query.setParameter("endTime", Instant.parse(endTime));

        return query.getSingleResult();
    }
}
