package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.LivestockLocationSnapshotJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockLocationSnapshotJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class SignalLocationProjectionService {

    private static final Set<String> VALID_SOURCES = Set.of(
            "AGENTIC_PLATFORM", "THINGSBOARD", "DATAGEN", "HTTP", "MANUAL_IMPORT"
    );

    private final LivestockLocationSnapshotJpaRepository snapshotRepository;
    private final SignalRevisionService revisionService;
    private final LivestockRepository livestockRepository;

    @Transactional
    public boolean projectCurrentFix(Long livestockId, Long farmId, Long deviceId,
                                     BigDecimal latitude, BigDecimal longitude,
                                     BigDecimal accuracy, Instant recordedAt, String source) {
        if (livestockId == null || farmId == null || deviceId == null
                || latitude == null || longitude == null || recordedAt == null
                || source == null || !VALID_SOURCES.contains(source)
                || latitude.compareTo(BigDecimal.valueOf(-90)) < 0
                || latitude.compareTo(BigDecimal.valueOf(90)) > 0
                || longitude.compareTo(BigDecimal.valueOf(-180)) < 0
                || longitude.compareTo(BigDecimal.valueOf(180)) > 0
                || (latitude.compareTo(BigDecimal.ZERO) == 0 && longitude.compareTo(BigDecimal.ZERO) == 0)) {
            return false;
        }

        LivestockLocationSnapshotJpaEntity existing = snapshotRepository.findByLivestockId(livestockId).orElse(null);
        if (existing != null && existing.getRecordedAt() != null
                && !recordedAt.isAfter(existing.getRecordedAt())) {
            return false;
        }

        long positionRevision = revisionService.bumpPosition(farmId);
        LivestockLocationSnapshotJpaEntity entity = existing == null
                ? new LivestockLocationSnapshotJpaEntity() : existing;
        entity.setLivestockId(livestockId);
        entity.setFarmId(farmId);
        entity.setDeviceId(deviceId);
        entity.setLatitude(latitude);
        entity.setLongitude(longitude);
        entity.setAccuracy(accuracy);
        entity.setRecordedAt(recordedAt);
        entity.setSource(source);
        entity.setPositionRevision(positionRevision);
        entity.setUpdatedAt(Instant.now());
        snapshotRepository.save(entity);

        livestockRepository.findById(livestockId).ifPresent(livestock -> {
            livestock.updatePosition(latitude, longitude, recordedAt);
            livestockRepository.save(livestock);
        });
        return true;
    }
}
