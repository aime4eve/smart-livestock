package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.AlertMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaAlertRepositoryImpl implements AlertRepository {

    private final SpringDataAlertRepository springDataRepo;
    private final SpringDataAlertReadStatusRepository springDataReadStatusRepo;

    @Override
    public Alert save(Alert alert) {
        if (alert.getId() != null) {
            return springDataRepo.findById(alert.getId())
                    .map(existing -> {
                        AlertMapper.updateEntity(existing, alert);
                        return AlertMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> AlertMapper.toDomain(springDataRepo.save(AlertMapper.toJpaEntity(alert))));
        }
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
    public List<StatusSeverityTypeCount> countByFarmGrouped(Long farmId, Collection<String> types) {
        List<String> typeNames = resolveTypeNames(types);
        return springDataRepo.countByFarmGrouped(farmId, typeNames).stream()
                .map(p -> new StatusSeverityTypeCount(p.getStatus(), p.getSeverity(), p.getType(), p.getCnt()))
                .toList();
    }

    @Override
    public List<TypeCount> countActiveUnreadGroupedByType(Long farmId, Long userId, Collection<String> types) {
        List<String> typeNames = resolveTypeNames(types);
        return springDataRepo.countActiveUnreadGroupedByType(farmId, userId, typeNames).stream()
                .map(p -> new TypeCount(p.getType(), p.getCnt()))
                .toList();
    }

    private List<String> resolveTypeNames(Collection<String> types) {
        return types == null || types.isEmpty()
                ? Arrays.stream(AlertType.values()).map(AlertType::name).toList()
                : List.copyOf(types);
    }

    @Override
    public AlertPage<Alert> findPageByFilters(Long farmId, Collection<AlertStatus> statuses,
                                              Severity severity, Collection<String> types,
                                              Long fenceId, boolean unreadOnly, Long readerId,
                                              int page, int size) {
        // Always pass full value lists instead of null so the JPQL needs no
        // nullable-parameter handling (Postgres type-inference safe); only the
        // scalar fenceId uses the IS NULL pattern.
        List<String> statusNames = statuses.stream().map(AlertStatus::name).toList();
        List<String> severityNames = severity == null
                ? Arrays.stream(Severity.values()).map(Severity::name).toList()
                : List.of(severity.name());
        List<String> typeNames = types == null || types.isEmpty()
                ? Arrays.stream(AlertType.values()).map(AlertType::name).toList()
                : List.copyOf(types);
        Pageable pageable = PageRequest.of(Math.max(page - 1, 0), Math.max(size, 1));
        List<Alert> items = springDataRepo
                .pageByFilters(farmId, statusNames, severityNames, typeNames, fenceId, unreadOnly, readerId, pageable)
                .stream()
                .map(AlertMapper::toDomain)
                .toList();
        long total = springDataRepo.countByFilters(farmId, statusNames, severityNames, typeNames, fenceId, unreadOnly, readerId);
        return new AlertPage(items, total);
    }

    @Override
    public List<Alert> findByLivestockIdAndTypeAndStatus(Long livestockId, AlertType type, AlertStatus status) {
        return springDataRepo.findByLivestockIdAndTypeAndStatus(livestockId, type.name(), status.name()).stream()
                .map(AlertMapper::toDomain)
                .toList();
    }

    @Override
    public List<Alert> findByDeviceIdAndTypeAndStatus(Long deviceId, AlertType type, AlertStatus status) {
        return springDataRepo.findByDeviceIdAndTypeAndStatus(deviceId, type.name(), status.name()).stream()
                .map(AlertMapper::toDomain)
                .toList();
    }

    @Override
    public int deleteByFenceId(Long fenceId) {
        return springDataRepo.deleteByFenceId(fenceId);
    }

    @Override
    public int deleteReadStatusByFenceId(Long fenceId) {
        return springDataReadStatusRepo.deleteByFenceId(fenceId);
    }

    @Override
    public int clearFenceReference(Long fenceId) {
        return springDataRepo.clearFenceReference(fenceId);
    }
}
