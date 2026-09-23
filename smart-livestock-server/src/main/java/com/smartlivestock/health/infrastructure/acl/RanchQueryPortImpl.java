package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Component("healthRanchQueryPort")
public class RanchQueryPortImpl implements RanchQueryPort {

    private final LivestockRepository livestockRepository;
    private final AlertRepository alertRepository;
    private final SpringDataAlertRepository springDataAlertRepo;
    private final SpringDataAlertReadStatusRepository readStatusRepo;

    public RanchQueryPortImpl(LivestockRepository livestockRepository, AlertRepository alertRepository,
                              SpringDataAlertRepository springDataAlertRepo,
                              SpringDataAlertReadStatusRepository readStatusRepo) {
        this.livestockRepository = livestockRepository;
        this.alertRepository = alertRepository;
        this.springDataAlertRepo = springDataAlertRepo;
        this.readStatusRepo = readStatusRepo;
    }

    @Override
    public Optional<LivestockInfo> findLivestockById(Long livestockId) {
        return livestockRepository.findById(livestockId)
                .map(this::toInfo);
    }

    @Override
    public List<LivestockInfo> findAllByFarmId(Long farmId) {
        return livestockRepository.findByFarmId(farmId).stream()
                .map(this::toInfo)
                .toList();
    }

    @Override
    public int countActiveAlertsByFarmId(Long farmId) {
        return (int) alertRepository.findByFarmId(farmId).stream()
                .filter(a -> a.getStatus() == AlertStatus.ACTIVE)
                .count();
    }

    @Override
    public boolean hasActiveAlert(Long livestockId, String alertType) {
        return !alertRepository.findByLivestockIdAndTypeAndStatus(
                livestockId, AlertType.valueOf(alertType), AlertStatus.ACTIVE).isEmpty();
    }

    @Override
    public List<AlertBrief> findActiveAlertsByFarmIdAndTypes(Long farmId, Collection<String> types) {
        return springDataAlertRepo.findByFarmIdAndTypeInAndStatus(farmId, types, AlertStatus.ACTIVE.name())
                .stream().map(e -> new AlertBrief(
                        e.getId(), e.getLivestockId(), e.getType(), e.getSeverity(),
                        e.getCreatedAt(), e.getResolvedAt()))
                .toList();
    }

    @Override
    public List<AlertBrief> findResolvedAlertsByFarmIdAndTypesSince(Long farmId, Collection<String> types, Instant since) {
        return springDataAlertRepo
                .findByFarmIdAndTypeInAndStatusInAndResolvedAtGreaterThanEqual(
                        farmId, types,
                        List.of(AlertStatus.AUTO_RESOLVED.name(), AlertStatus.DISMISSED.name()),
                        since)
                .stream().map(e -> new AlertBrief(
                        e.getId(), e.getLivestockId(), e.getType(), e.getSeverity(),
                        e.getCreatedAt(), e.getResolvedAt()))
                .toList();
    }

    @Override
    public Set<Long> findReadAlertIds(Long userId, Collection<Long> alertIds) {
        if (alertIds == null || alertIds.isEmpty()) return Set.of();
        return readStatusRepo.findReadAlertIdsByUserId(userId, alertIds);
    }

    private LivestockInfo toInfo(Livestock l) {
        return new LivestockInfo(l.getId(), l.getFarmId(), l.getLivestockCode(), l.getGender(), l.getBreed());
    }
}
