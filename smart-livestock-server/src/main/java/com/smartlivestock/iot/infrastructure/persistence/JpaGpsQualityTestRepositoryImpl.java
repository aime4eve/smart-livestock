package com.smartlivestock.iot.infrastructure.persistence;

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
    public List<GpsQualityTest> findBySessionId(Long sessionId) {
        return springDataRepo.findBySessionId(sessionId).stream().map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTest> findByRtkPointId(Long rtkPointId) {
        return springDataRepo.findByRtkPointId(rtkPointId).stream().map(this::toDomain).toList();
    }

    @Override
    public Page<GpsQualityTest> findFiltered(Long rtkPointId, Long routeId, String testType, Pageable pageable) {
        Specification<GpsQualityTestJpaEntity> spec = (root, query, cb) -> {
            var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            if (rtkPointId != null) predicates.add(cb.equal(root.get("rtkPointId"), rtkPointId));
            if (routeId != null) predicates.add(cb.equal(root.get("routeId"), routeId));
            if (testType != null && !testType.isEmpty()) predicates.add(cb.equal(root.get("testType"), testType));
            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        };
        return springDataRepo.findAll(spec, pageable).map(this::toDomain);
    }

    @Override
    public void deleteById(Long id) { springDataRepo.deleteById(id); }

    private GpsQualityTestJpaEntity toJpa(GpsQualityTest t) {
        GpsQualityTestJpaEntity jpa = new GpsQualityTestJpaEntity();
        jpa.setId(t.getId());
        jpa.setSessionId(t.getSessionId());
        jpa.setTestType(t.getTestType() != null ? t.getTestType().name() : TestType.STATIC.name());
        jpa.setRtkPointId(t.getRtkPointId());
        jpa.setRouteId(t.getRouteId());
        jpa.setTestStartedAt(t.getTestStartedAt());
        jpa.setTestEndedAt(t.getTestEndedAt());
        return jpa;
    }

    private GpsQualityTest toDomain(GpsQualityTestJpaEntity jpa) {
        GpsQualityTest t = new GpsQualityTest();
        t.setId(jpa.getId());
        t.setSessionId(jpa.getSessionId());
        t.setTestType(jpa.getTestType() != null ? TestType.valueOf(jpa.getTestType()) : TestType.STATIC);
        t.setRtkPointId(jpa.getRtkPointId());
        t.setRouteId(jpa.getRouteId());
        t.setTestStartedAt(jpa.getTestStartedAt());
        t.setTestEndedAt(jpa.getTestEndedAt());
        t.setCreatedAt(jpa.getCreatedAt());
        t.setUpdatedAt(jpa.getUpdatedAt());
        return t;
    }
}
