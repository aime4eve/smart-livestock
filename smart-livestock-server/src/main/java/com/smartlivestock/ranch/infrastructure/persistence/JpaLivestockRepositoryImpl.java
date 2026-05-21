package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.LivestockMapper;
import lombok.RequiredArgsConstructor;
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
        // Soft delete: set deletedAt timestamp
        springDataRepo.findById(id).ifPresent(jpa -> {
            jpa.setDeletedAt(Instant.now());
            springDataRepo.save(jpa);
        });
    }

    @Override
    public long countByFarmId(Long farmId) {
        return springDataRepo.countByFarmId(farmId);
    }
}
