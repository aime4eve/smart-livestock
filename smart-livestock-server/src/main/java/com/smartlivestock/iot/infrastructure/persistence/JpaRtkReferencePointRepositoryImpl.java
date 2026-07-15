package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.RtkReferencePoint;
import com.smartlivestock.iot.domain.repository.RtkReferencePointRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.RtkReferencePointJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaRtkReferencePointRepositoryImpl implements RtkReferencePointRepository {

    private final SpringDataRtkReferencePointRepository springDataRepo;

    @Override
    public RtkReferencePoint save(RtkReferencePoint point) {
        RtkReferencePointJpaEntity jpa = toJpa(point);
        if (point.getId() != null) {
            springDataRepo.findById(point.getId())
                    .ifPresent(existing -> jpa.setCreatedAt(existing.getCreatedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<RtkReferencePoint> findById(Long id) {
        return springDataRepo.findById(id).map(this::toDomain);
    }

    @Override
    public List<RtkReferencePoint> findAll() {
        return springDataRepo.findAll().stream().map(this::toDomain).toList();
    }

    @Override
    public List<RtkReferencePoint> findByLocationName(String locationName) {
        return springDataRepo.findByLocationNameOrderById(locationName).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return springDataRepo.existsById(id);
    }

    private RtkReferencePointJpaEntity toJpa(RtkReferencePoint p) {
        RtkReferencePointJpaEntity jpa = new RtkReferencePointJpaEntity();
        jpa.setId(p.getId());
        jpa.setLocationName(p.getLocationName());
        jpa.setPointLabel(p.getPointLabel());
        jpa.setLatitude(p.getLatitude());
        jpa.setLongitude(p.getLongitude());
        return jpa;
    }

    private RtkReferencePoint toDomain(RtkReferencePointJpaEntity jpa) {
        RtkReferencePoint p = new RtkReferencePoint();
        p.setId(jpa.getId());
        p.setLocationName(jpa.getLocationName());
        p.setPointLabel(jpa.getPointLabel());
        p.setLatitude(jpa.getLatitude());
        p.setLongitude(jpa.getLongitude());
        p.setCreatedAt(jpa.getCreatedAt());
        p.setUpdatedAt(jpa.getUpdatedAt());
        return p;
    }
}
