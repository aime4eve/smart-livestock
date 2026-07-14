package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.LivestockMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaLivestockRepositoryImpl implements LivestockRepository {

    private final SpringDataLivestockRepository springDataRepo;

    @Override
    public Livestock save(Livestock livestock) {
        Long id = livestock.getId();
        if (id != null) {
            return springDataRepo.findById(id)
                    .map(existing -> {
                        LivestockMapper.copyToJpaEntity(livestock, existing);
                        return LivestockMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> LivestockMapper.toDomain(springDataRepo.save(LivestockMapper.toJpaEntity(livestock))));
        }
        return LivestockMapper.toDomain(springDataRepo.save(LivestockMapper.toJpaEntity(livestock)));
    }

    @Override
    public Optional<Livestock> findById(Long id) {
        return springDataRepo.findById(id).map(LivestockMapper::toDomain);
    }

    @Override
    public List<Livestock> findByFarmId(Long farmId) {
        return springDataRepo.findByFarmId(farmId).stream()
                .map(LivestockMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<Livestock> findByLivestockCode(String livestockCode) {
        return springDataRepo.findByLivestockCode(livestockCode).map(LivestockMapper::toDomain);
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.findById(id).ifPresent(jpa -> {
            jpa.setDeletedAt(Instant.now());
            springDataRepo.save(jpa);
        });
    }

    @Override
    public long countByFarmId(Long farmId) {
        return springDataRepo.countByFarmId(farmId);
    }

    @Override
    public long countByFarmIdAndTenantId(Long farmId, Long tenantId) {
        return springDataRepo.countByFarmIdAndTenantId(farmId, tenantId);
    }

    @Override
    public long countByTenantId(Long tenantId) {
        return springDataRepo.countByTenantId(tenantId);
    }

    @Override
    public List<Livestock> findByFarmIdPaged(Long farmId, int offset, int limit) {
        Pageable pageable = PageRequest.of(offset / limit, limit);
        return springDataRepo.findByFarmIdPaged(farmId, pageable)
                .stream().map(LivestockMapper::toDomain).toList();
    }

    @Override
    public List<Livestock> findByFarmIdAndKeyword(Long farmId, String keyword, int offset, int limit) {
        Pageable pageable = PageRequest.of(offset / limit, limit);
        return springDataRepo.findByFarmIdAndKeyword(farmId, keyword, pageable)
                .stream().map(LivestockMapper::toDomain).toList();
    }

    @Override
    public long countByFarmIdPaged(Long farmId) {
        return springDataRepo.countByFarmIdActive(farmId);
    }

    @Override
    public long countByFarmIdAndKeyword(Long farmId, String keyword) {
        return springDataRepo.countByFarmIdAndKeyword(farmId, keyword);
    }
}
