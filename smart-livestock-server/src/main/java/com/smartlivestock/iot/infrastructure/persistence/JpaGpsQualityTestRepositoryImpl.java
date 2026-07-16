package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.CalibrationStatus;
import com.smartlivestock.iot.domain.model.GpsQualityTest;
import com.smartlivestock.iot.domain.model.TestType;
import com.smartlivestock.iot.domain.repository.GpsQualityTestRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTestJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityTestRepositoryImpl implements GpsQualityTestRepository {

    private final SpringDataGpsQualityTestRepository springDataRepo;

    @Override
    public GpsQualityTest save(GpsQualityTest test) {
        GpsQualityTestJpaEntity jpa = toJpa(test);
        if (test.getId() != null) {
            springDataRepo.findById(test.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<GpsQualityTest> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<GpsQualityTest> findActiveByDeviceId(Long deviceId) {
        return springDataRepo.findActiveByDeviceId(deviceId).map(this::toDomain);
    }

    @Override
    public List<GpsQualityTest> findByRtkPointIdOrderByStartedAtDesc(Long rtkPointId) {
        return springDataRepo.findByRtkPointIdOrderByStartedAtDesc(rtkPointId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTest> findByDeviceIdOrderByStartedAtDesc(Long deviceId) {
        return springDataRepo.findByDeviceIdOrderByStartedAtDesc(deviceId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public Page<GpsQualityTest> findFiltered(Long rtkPointId, Long deviceId, String status, String testType, Pageable pageable) {
        Specification<GpsQualityTestJpaEntity> spec = (root, query, cb) -> {
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
            if (testType != null && !testType.isEmpty()) {
                predicates.add(cb.equal(root.get("testType"), testType));
            }
            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
        return springDataRepo.findAll(spec, pageable).map(this::toDomain);
    }

    @Override
    public List<GpsQualityTest> findAll() {
        return springDataRepo.findAll().stream().map(this::toDomain).toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }

    private GpsQualityTestJpaEntity toJpa(GpsQualityTest s) {
        GpsQualityTestJpaEntity jpa = new GpsQualityTestJpaEntity();
        jpa.setId(s.getId());
        jpa.setDeviceId(s.getDeviceId());
        jpa.setTestType(s.getTestType() != null ? s.getTestType().name() : TestType.STATIC.name());
        jpa.setRtkPointId(s.getRtkPointId());
        jpa.setRouteId(s.getRouteId());
        jpa.setStartedAt(s.getStartedAt());
        jpa.setEndedAt(s.getEndedAt());
        jpa.setStatus(s.getStatus() != null ? s.getStatus().name() : CalibrationStatus.IN_PROGRESS.name());
        return jpa;
    }

    private GpsQualityTest toDomain(GpsQualityTestJpaEntity jpa) {
        GpsQualityTest s = new GpsQualityTest();
        s.setId(jpa.getId());
        s.setDeviceId(jpa.getDeviceId());
        s.setTestType(jpa.getTestType() != null ? TestType.valueOf(jpa.getTestType()) : TestType.STATIC);
        s.setRtkPointId(jpa.getRtkPointId());
        s.setRouteId(jpa.getRouteId());
        s.setStartedAt(jpa.getStartedAt());
        s.setEndedAt(jpa.getEndedAt());
        s.setStatus(CalibrationStatus.valueOf(jpa.getStatus()));
        s.setCreatedAt(jpa.getCreatedAt());
        s.setUpdatedAt(jpa.getUpdatedAt());
        return s;
    }
}
