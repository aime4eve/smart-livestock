package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.ContactTrace;
import com.smartlivestock.health.domain.repository.ContactTraceRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.ContactTraceJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class ContactTraceRepositoryImpl implements ContactTraceRepository {

    private final ContactTraceJpaRepository jpaRepo;

    @Override
    public List<ContactTrace> findByFarmIdOrderByLastContactAtDesc(Long farmId) {
        return jpaRepo.findByFarmIdOrderByLastContactAtDesc(farmId).stream()
                .map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<ContactTrace> findByFromLivestockIdOrderByLastContactAtDesc(Long fromLivestockId) {
        return jpaRepo.findByFromLivestockIdOrderByLastContactAtDesc(fromLivestockId).stream()
                .map(HealthMapper::toDomain).toList();
    }

    @Override
    public ContactTrace save(ContactTrace trace) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(trace)));
    }
}
