package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualitySession;
import com.smartlivestock.iot.domain.model.SessionStatus;
import com.smartlivestock.iot.domain.repository.GpsQualitySessionRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualitySessionJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualitySessionRepositoryImpl implements GpsQualitySessionRepository {

    private final SpringDataGpsQualitySessionRepository springDataRepo;

    @Override
    public GpsQualitySession save(GpsQualitySession session) {
        GpsQualitySessionJpaEntity jpa = toJpa(session);
        if (session.getId() != null) {
            springDataRepo.findById(session.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<GpsQualitySession> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<GpsQualitySession> findActiveByDeviceId(Long deviceId) {
        return springDataRepo.findActiveByDeviceId(deviceId).map(this::toDomain);
    }

    @Override
    public Page<GpsQualitySession> findFiltered(Long deviceId, String status, Pageable pageable) {
        Specification<GpsQualitySessionJpaEntity> spec = (root, query, cb) -> {
            var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            if (deviceId != null) predicates.add(cb.equal(root.get("deviceId"), deviceId));
            if (status != null && !status.isEmpty()) predicates.add(cb.equal(root.get("status"), status));
            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
        return springDataRepo.findAll(spec, pageable).map(this::toDomain);
    }

    @Override
    public void deleteById(Long id) { springDataRepo.deleteById(id); }

    private GpsQualitySessionJpaEntity toJpa(GpsQualitySession s) {
        GpsQualitySessionJpaEntity jpa = new GpsQualitySessionJpaEntity();
        jpa.setId(s.getId());
        jpa.setDeviceId(s.getDeviceId());
        jpa.setStartedAt(s.getStartedAt());
        jpa.setEndedAt(s.getEndedAt());
        jpa.setStatus(s.getStatus() != null ? s.getStatus().name() : SessionStatus.IN_PROGRESS.name());
        jpa.setNote(s.getNote());
        return jpa;
    }

    private GpsQualitySession toDomain(GpsQualitySessionJpaEntity jpa) {
        GpsQualitySession s = new GpsQualitySession();
        s.setId(jpa.getId());
        s.setDeviceId(jpa.getDeviceId());
        s.setStartedAt(jpa.getStartedAt());
        s.setEndedAt(jpa.getEndedAt());
        s.setStatus(SessionStatus.valueOf(jpa.getStatus()));
        s.setNote(jpa.getNote());
        s.setCreatedAt(jpa.getCreatedAt());
        s.setUpdatedAt(jpa.getUpdatedAt());
        return s;
    }
}
