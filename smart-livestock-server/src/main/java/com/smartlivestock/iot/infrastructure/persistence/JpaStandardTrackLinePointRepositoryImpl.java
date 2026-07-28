package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.StandardTrackLinePoint;
import com.smartlivestock.iot.domain.repository.StandardTrackLinePointRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.StandardTrackLinePointJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaStandardTrackLinePointRepositoryImpl implements StandardTrackLinePointRepository {

    private final SpringDataStandardTrackLinePointRepository springDataRepo;

    @Override
    public List<StandardTrackLinePoint> saveAll(List<StandardTrackLinePoint> points) {
        return springDataRepo.saveAll(points.stream().map(this::toJpa).toList())
                .stream().map(this::toDomain).toList();
    }

    @Override
    public List<StandardTrackLinePoint> findByLineIdOrderBySequenceNo(Long lineId) {
        return springDataRepo.findByLineIdOrderBySequenceNo(lineId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteByLineId(Long lineId) {
        springDataRepo.deleteByLineId(lineId);
    }

    private StandardTrackLinePointJpaEntity toJpa(StandardTrackLinePoint p) {
        StandardTrackLinePointJpaEntity jpa = new StandardTrackLinePointJpaEntity();
        jpa.setId(p.getId());
        jpa.setLineId(p.getLineId());
        jpa.setSequenceNo(p.getSequenceNo());
        jpa.setLongitude(p.getLongitude());
        jpa.setLatitude(p.getLatitude());
        return jpa;
    }

    private StandardTrackLinePoint toDomain(StandardTrackLinePointJpaEntity jpa) {
        StandardTrackLinePoint p = new StandardTrackLinePoint();
        p.setId(jpa.getId());
        p.setLineId(jpa.getLineId());
        p.setSequenceNo(jpa.getSequenceNo());
        p.setLongitude(jpa.getLongitude());
        p.setLatitude(jpa.getLatitude());
        return p;
    }
}
