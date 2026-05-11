package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.AlertMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaAlertRepositoryImpl implements AlertRepository {

    private final SpringDataAlertRepository springDataRepo;

    @Override
    public Alert save(Alert alert) {
        return AlertMapper.toDomain(springDataRepo.save(AlertMapper.toJpaEntity(alert)));
    }

    @Override
    public Optional<Alert> findById(Long id) {
        return springDataRepo.findById(id).map(AlertMapper::toDomain);
    }

    @Override
    public List<Alert> findByFarmId(Long farmId) {
        return springDataRepo.findByFarmId(farmId).stream()
                .map(AlertMapper::toDomain)
                .toList();
    }

    @Override
    public List<Alert> findByFarmIdAndStatus(Long farmId, AlertStatus status) {
        return springDataRepo.findByFarmIdAndStatus(farmId, status.name()).stream()
                .map(AlertMapper::toDomain)
                .toList();
    }
}
