package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.CalibrationStatus;
import com.smartlivestock.iot.domain.model.RtkCalibrationSession;
import com.smartlivestock.iot.domain.repository.RtkCalibrationSessionRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.RtkCalibrationSessionJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaRtkCalibrationSessionRepositoryImpl implements RtkCalibrationSessionRepository {

    private final SpringDataRtkCalibrationSessionRepository springDataRepo;

    @Override
    public RtkCalibrationSession save(RtkCalibrationSession session) {
        RtkCalibrationSessionJpaEntity jpa = toJpa(session);
        if (session.getId() != null) {
            springDataRepo.findById(session.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<RtkCalibrationSession> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<RtkCalibrationSession> findActiveByDeviceId(Long deviceId) {
        return springDataRepo.findActiveByDeviceId(deviceId).map(this::toDomain);
    }

    @Override
    public List<RtkCalibrationSession> findByRtkPointIdOrderByStartedAtDesc(Long rtkPointId) {
        return springDataRepo.findByRtkPointIdOrderByStartedAtDesc(rtkPointId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<RtkCalibrationSession> findByDeviceIdOrderByStartedAtDesc(Long deviceId) {
        return springDataRepo.findByDeviceIdOrderByStartedAtDesc(deviceId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public Page<RtkCalibrationSession> findFiltered(Long rtkPointId, Long deviceId, String status, Pageable pageable) {
        Specification<RtkCalibrationSessionJpaEntity> spec = (root, query, cb) -> {
            var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            if (rtkPointId != null) {
                predicates.add(cb.equal(root.get("rtkPointId"), rtkPointId));
            }
            if (deviceId != null) {
                predicates.add(cb.equal(root.get("deviceId"), deviceId));
            }
            if (status != null && !status.isEmpty()) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
        return springDataRepo.findAll(spec, pageable).map(this::toDomain);
    }

    @Override
    public List<RtkCalibrationSession> findAll() {
        return springDataRepo.findAll().stream().map(this::toDomain).toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }

    private RtkCalibrationSessionJpaEntity toJpa(RtkCalibrationSession s) {
        RtkCalibrationSessionJpaEntity jpa = new RtkCalibrationSessionJpaEntity();
        jpa.setId(s.getId());
        jpa.setRtkPointId(s.getRtkPointId());
        jpa.setDeviceId(s.getDeviceId());
        jpa.setStartedAt(s.getStartedAt());
        jpa.setEndedAt(s.getEndedAt());
        jpa.setStatus(s.getStatus() != null ? s.getStatus().name() : CalibrationStatus.IN_PROGRESS.name());
        return jpa;
    }

    private RtkCalibrationSession toDomain(RtkCalibrationSessionJpaEntity jpa) {
        RtkCalibrationSession s = new RtkCalibrationSession();
        s.setId(jpa.getId());
        s.setRtkPointId(jpa.getRtkPointId());
        s.setDeviceId(jpa.getDeviceId());
        s.setStartedAt(jpa.getStartedAt());
        s.setEndedAt(jpa.getEndedAt());
        s.setStatus(CalibrationStatus.valueOf(jpa.getStatus()));
        s.setCreatedAt(jpa.getCreatedAt());
        s.setUpdatedAt(jpa.getUpdatedAt());
        return s;
    }
}
