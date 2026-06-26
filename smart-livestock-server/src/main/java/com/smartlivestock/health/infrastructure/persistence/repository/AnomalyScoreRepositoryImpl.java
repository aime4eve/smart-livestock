package com.smartlivestock.health.infrastructure.persistence.repository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.health.infrastructure.persistence.entity.AnomalyScoreJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.AnomalyScoreJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Repository
@RequiredArgsConstructor
public class AnomalyScoreRepositoryImpl implements AnomalyScoreRepository {

    private final AnomalyScoreJpaRepository jpaRepository;
    private final ObjectMapper objectMapper;

    @Override
    public AnomalyScore save(AnomalyScore score) {
        AnomalyScoreJpaEntity entity = toEntity(score);
        entity = jpaRepository.save(entity);
        return toDomain(entity);
    }

    @Override
    public Optional<AnomalyScore> findLatestByFarmIdAndLivestockId(Long farmId, Long livestockId) {
        return jpaRepository.findFirstByFarmIdAndLivestockIdOrderByCreatedAtDesc(farmId, livestockId)
                .map(this::toDomain);
    }

    @Override
    public List<AnomalyScore> findByFarmIdAndLivestockId(Long farmId, Long livestockId, int limit) {
        return jpaRepository.findByFarmIdAndLivestockIdOrderByCreatedAtDesc(farmId, livestockId,
                        PageRequest.of(0, limit))
                .stream()
                .map(this::toDomain)
                .collect(Collectors.toList());
    }

    // --- mappers ---

    private AnomalyScoreJpaEntity toEntity(AnomalyScore score) {
        AnomalyScoreJpaEntity entity = new AnomalyScoreJpaEntity();
        entity.setId(score.getId());
        entity.setTenantId(score.getTenantId());
        entity.setFarmId(score.getFarmId());
        entity.setLivestockId(score.getLivestockId());
        entity.setWindowStart(score.getWindowStart());
        entity.setWindowEnd(score.getWindowEnd());
        entity.setAnomalyScore(score.getAnomalyScore() != null ? score.getAnomalyScore().doubleValue() : null);
        entity.setAnomalyType(score.getAnomalyType());
        entity.setContributions(toJson(score.getContributions()));
        entity.setCapabilityUsed(score.getCapabilityUsed());
        entity.setNEff(score.getNEff());
        entity.setModelMeta(toJson(score.getModelMeta()));
        return entity;
    }

    private AnomalyScore toDomain(AnomalyScoreJpaEntity entity) {
        AnomalyScore score = new AnomalyScore();
        score.setId(entity.getId());
        score.setTenantId(entity.getTenantId());
        score.setFarmId(entity.getFarmId());
        score.setLivestockId(entity.getLivestockId());
        score.setWindowStart(entity.getWindowStart());
        score.setWindowEnd(entity.getWindowEnd());
        score.setAnomalyScore(entity.getAnomalyScore() != null ? BigDecimal.valueOf(entity.getAnomalyScore()) : null);
        score.setAnomalyType(entity.getAnomalyType());
        score.setContributions(fromJson(entity.getContributions()));
        score.setCapabilityUsed(entity.getCapabilityUsed());
        score.setNEff(entity.getNEff());
        score.setModelMeta(fromJson(entity.getModelMeta()));
        score.setCreatedAt(entity.getCreatedAt());
        return score;
    }

    private String toJson(Map<String, Object> map) {
        if (map == null || map.isEmpty()) return null;
        try {
            return objectMapper.writeValueAsString(map);
        } catch (Exception e) {
            log.warn("Failed to serialize map to JSON: {}", e.getMessage());
            return null;
        }
    }

    private Map<String, Object> fromJson(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            log.warn("Failed to deserialize JSON to map: {}", e.getMessage());
            return null;
        }
    }
}
