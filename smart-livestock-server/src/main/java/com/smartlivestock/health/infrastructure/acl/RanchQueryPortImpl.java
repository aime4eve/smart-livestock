package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component("healthRanchQueryPort")
public class RanchQueryPortImpl implements RanchQueryPort {

    private final LivestockRepository livestockRepository;
    private final AlertRepository alertRepository;

    public RanchQueryPortImpl(LivestockRepository livestockRepository, AlertRepository alertRepository) {
        this.livestockRepository = livestockRepository;
        this.alertRepository = alertRepository;
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
                .filter(a -> "ACTIVE".equals(a.getStatus()))
                .count();
    }

    private LivestockInfo toInfo(Livestock l) {
        return new LivestockInfo(l.getId(), l.getFarmId(), l.getLivestockCode(), l.getGender(), l.getBreed());
    }
}
