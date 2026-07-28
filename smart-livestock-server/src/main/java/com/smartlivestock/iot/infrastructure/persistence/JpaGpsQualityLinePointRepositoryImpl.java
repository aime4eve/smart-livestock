package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualityLinePoint;
import com.smartlivestock.iot.domain.repository.GpsQualityLinePointRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLinePointJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityLinePointRepositoryImpl implements GpsQualityLinePointRepository {

    private final SpringDataGpsQualityLinePointRepository springDataRepo;

    @Override
    public List<GpsQualityLinePoint> saveAll(List<GpsQualityLinePoint> points) {
        return springDataRepo.saveAll(points.stream().map(this::toJpa).toList())
                .stream().map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityLinePoint> findByTestIdOrderBySequenceNo(Long testId) {
        return springDataRepo.findByTestIdOrderBySequenceNo(testId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteByTestId(Long testId) {
        springDataRepo.deleteByTestId(testId);
    }

    private GpsQualityLinePointJpaEntity toJpa(GpsQualityLinePoint p) {
        GpsQualityLinePointJpaEntity jpa = new GpsQualityLinePointJpaEntity();
        jpa.setId(p.getId());
        jpa.setTestId(p.getTestId());
        jpa.setSequenceNo(p.getSequenceNo());
        jpa.setLongitude(p.getLongitude());
        jpa.setLatitude(p.getLatitude());
        return jpa;
    }

    private GpsQualityLinePoint toDomain(GpsQualityLinePointJpaEntity jpa) {
        GpsQualityLinePoint p = new GpsQualityLinePoint();
        p.setId(jpa.getId());
        p.setTestId(jpa.getTestId());
        p.setSequenceNo(jpa.getSequenceNo());
        p.setLongitude(jpa.getLongitude());
        p.setLatitude(jpa.getLatitude());
        return p;
    }
}
