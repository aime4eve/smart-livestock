package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.DynamicTestRoutePoint;
import com.smartlivestock.iot.domain.repository.DynamicTestRoutePointRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.DynamicTestRoutePointJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaDynamicTestRoutePointRepositoryImpl implements DynamicTestRoutePointRepository {

    private final SpringDataDynamicTestRoutePointRepository springDataRepo;

    @Override
    public DynamicTestRoutePoint save(DynamicTestRoutePoint point) {
        return toDomain(springDataRepo.save(toJpa(point)));
    }

    @Override
    public List<DynamicTestRoutePoint> findByRouteIdOrderBySequenceNoAsc(Long routeId) {
        return springDataRepo.findByRouteIdOrderBySequenceNoAsc(routeId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public List<DynamicTestRoutePoint> saveAll(List<DynamicTestRoutePoint> points) {
        List<DynamicTestRoutePointJpaEntity> jpaList = points.stream().map(this::toJpa).toList();
        return springDataRepo.saveAll(jpaList).stream().map(this::toDomain).toList();
    }

    @Override
    public void deleteByRouteId(Long routeId) {
        springDataRepo.deleteByRouteId(routeId);
    }

    private DynamicTestRoutePointJpaEntity toJpa(DynamicTestRoutePoint p) {
        DynamicTestRoutePointJpaEntity jpa = new DynamicTestRoutePointJpaEntity();
        jpa.setId(p.getId());
        jpa.setRouteId(p.getRouteId());
        jpa.setRtkPointId(p.getRtkPointId());
        jpa.setSequenceNo(p.getSequenceNo());
        return jpa;
    }

    private DynamicTestRoutePoint toDomain(DynamicTestRoutePointJpaEntity jpa) {
        DynamicTestRoutePoint p = new DynamicTestRoutePoint();
        p.setId(jpa.getId());
        p.setRouteId(jpa.getRouteId());
        p.setRtkPointId(jpa.getRtkPointId());
        p.setSequenceNo(jpa.getSequenceNo());
        p.setCreatedAt(jpa.getCreatedAt());
        return p;
    }
}
