package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.smartlivestock.identity.infrastructure.persistence.mapper.AuditLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class JpaAuditLogRepositoryImpl implements AuditLogRepository {

    private final SpringDataAuditLogRepository springDataRepo;

    @Override
    public AuditLog save(AuditLog auditLog) {
        return AuditLogMapper.toDomain(springDataRepo.save(AuditLogMapper.toJpaEntity(auditLog)));
    }

    @Override
    public List<AuditLog> findAll(int page, int pageSize, Long tenantId, Long userId,
                                  String action, String startTime, String endTime) {
        Page<AuditLogJpaEntity> result = springDataRepo.findFiltered(
                tenantId, userId, action, startTime, endTime,
                PageRequest.of(page - 1, pageSize));
        return result.getContent().stream().map(AuditLogMapper::toDomain).collect(Collectors.toList());
    }

    @Override
    public long count(Long tenantId, Long userId, String action, String startTime, String endTime) {
        return springDataRepo.findFiltered(
                tenantId, userId, action, startTime, endTime,
                PageRequest.of(0, 1)).getTotalElements();
    }
}
