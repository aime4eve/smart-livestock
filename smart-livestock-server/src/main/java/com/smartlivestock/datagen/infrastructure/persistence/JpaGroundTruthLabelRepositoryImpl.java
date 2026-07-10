package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import com.smartlivestock.datagen.infrastructure.persistence.mapper.GroundTruthLabelMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGroundTruthLabelRepositoryImpl implements GroundTruthLabelRepository {
    private final GroundTruthLabelJpaRepository jpaRepository;

    @Override
    public GroundTruthLabel save(GroundTruthLabel label) {
        var entity = GroundTruthLabelMapper.toEntity(label);
        entity = jpaRepository.save(entity);
        return GroundTruthLabelMapper.toDomain(entity);
    }

    @Override
    public List<GroundTruthLabel> findByLivestockIdAndPeriodOverlap(Long livestockId, Instant from, Instant to) {
        return jpaRepository.findByLivestockIdAndPeriodOverlap(livestockId, from, to).stream()
            .map(GroundTruthLabelMapper::toDomain).toList();
    }
}
