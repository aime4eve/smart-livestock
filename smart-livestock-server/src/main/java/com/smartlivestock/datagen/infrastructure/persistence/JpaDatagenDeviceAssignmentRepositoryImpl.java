package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;
import com.smartlivestock.datagen.domain.repository.DatagenDeviceAssignmentRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenDeviceAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.mapper.DatagenControlMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDatagenDeviceAssignmentRepositoryImpl
        implements DatagenDeviceAssignmentRepository {
    private final DatagenDeviceAssignmentJpaRepository jpaRepository;

    @Override
    public DatagenDeviceAssignment save(DatagenDeviceAssignment assignment) {
        DatagenDeviceAssignmentJpaEntity existing = assignment.getId() == null
                ? null : jpaRepository.findById(assignment.getId()).orElse(null);
        return DatagenControlMapper.toDomain(
                jpaRepository.save(DatagenControlMapper.toEntity(assignment, existing)));
    }

    @Override
    public List<DatagenDeviceAssignment> saveAll(
            Iterable<DatagenDeviceAssignment> assignments) {
        List<DatagenDeviceAssignment> result = new ArrayList<>();
        for (DatagenDeviceAssignment assignment : assignments) {
            result.add(save(assignment));
        }
        return result;
    }

    @Override
    public List<DatagenDeviceAssignment> findByControlId(Long controlId) {
        return jpaRepository.findByControlId(controlId).stream()
                .map(DatagenControlMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<DatagenDeviceAssignment> findByControlIdAndDeviceId(
            Long controlId, Long deviceId) {
        return jpaRepository.findByControlIdAndDeviceId(controlId, deviceId)
                .map(DatagenControlMapper::toDomain);
    }

    @Override
    public List<DatagenDeviceAssignment> findActiveByControlId(Long controlId) {
        return jpaRepository.findByControlIdAndRemovedAtIsNull(controlId).stream()
                .map(DatagenControlMapper::toDomain)
                .toList();
    }

    @Override
    public List<DatagenDeviceAssignment> findActiveByScenarioId(Long scenarioId) {
        return jpaRepository.findActiveByScenarioId(scenarioId).stream()
                .map(DatagenControlMapper::toDomain)
                .toList();
    }
}
