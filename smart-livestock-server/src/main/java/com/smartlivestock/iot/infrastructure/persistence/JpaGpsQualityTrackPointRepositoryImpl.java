package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualityTrackPoint;
import com.smartlivestock.iot.domain.model.TrackMatchSource;
import com.smartlivestock.iot.domain.repository.GpsQualityTrackPointRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityTrackPointJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityTrackPointRepositoryImpl implements GpsQualityTrackPointRepository {

    private final SpringDataGpsQualityTrackPointRepository springDataRepo;

    @Override
    public GpsQualityTrackPoint save(GpsQualityTrackPoint point) {
        return toDomain(springDataRepo.save(toJpa(point)));
    }

    @Override
    public List<GpsQualityTrackPoint> saveAll(List<GpsQualityTrackPoint> points) {
        return springDataRepo.saveAll(points.stream().map(this::toJpa).toList())
                .stream().map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityTrackPoint> findByTestIdOrderByCollectedAt(Long testId) {
        return springDataRepo.findByTestIdOrderByCollectedAt(testId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteByTestId(Long testId) {
        springDataRepo.deleteByTestId(testId);
    }

    private GpsQualityTrackPointJpaEntity toJpa(GpsQualityTrackPoint p) {
        GpsQualityTrackPointJpaEntity jpa = new GpsQualityTrackPointJpaEntity();
        jpa.setId(p.getId());
        jpa.setTestId(p.getTestId());
        jpa.setSequenceNo(p.getSequenceNo());
        jpa.setCollectedAt(p.getCollectedAt());
        jpa.setRtkLatitude(p.getRtkLatitude());
        jpa.setRtkLongitude(p.getRtkLongitude());
        jpa.setDeviceLatitude(p.getDeviceLatitude());
        jpa.setDeviceLongitude(p.getDeviceLongitude());
        jpa.setMatchSource(p.getMatchSource() != null ? p.getMatchSource().name() : null);
        jpa.setMatchedGpsLogId(p.getMatchedGpsLogId());
        jpa.setTimeDiffSeconds(p.getTimeDiffSeconds());
        jpa.setToleranceSeconds(p.getToleranceSeconds() != null ? p.getToleranceSeconds() : 60);
        return jpa;
    }

    private GpsQualityTrackPoint toDomain(GpsQualityTrackPointJpaEntity jpa) {
        GpsQualityTrackPoint p = new GpsQualityTrackPoint();
        p.setId(jpa.getId());
        p.setTestId(jpa.getTestId());
        p.setSequenceNo(jpa.getSequenceNo());
        p.setCollectedAt(jpa.getCollectedAt());
        p.setRtkLatitude(jpa.getRtkLatitude());
        p.setRtkLongitude(jpa.getRtkLongitude());
        p.setDeviceLatitude(jpa.getDeviceLatitude());
        p.setDeviceLongitude(jpa.getDeviceLongitude());
        p.setMatchSource(jpa.getMatchSource() != null ? TrackMatchSource.valueOf(jpa.getMatchSource()) : null);
        p.setMatchedGpsLogId(jpa.getMatchedGpsLogId());
        p.setTimeDiffSeconds(jpa.getTimeDiffSeconds());
        p.setToleranceSeconds(jpa.getToleranceSeconds());
        p.setCreatedAt(jpa.getCreatedAt());
        return p;
    }
}
