package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualityLineDeviation;
import com.smartlivestock.iot.domain.repository.GpsQualityLineDeviationRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLineDeviationJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityLineDeviationRepositoryImpl implements GpsQualityLineDeviationRepository {

    private final SpringDataGpsQualityLineDeviationRepository springDataRepo;

    @Override
    public List<GpsQualityLineDeviation> saveAll(List<GpsQualityLineDeviation> deviations) {
        return springDataRepo.saveAll(deviations.stream().map(this::toJpa).toList())
                .stream().map(this::toDomain).toList();
    }

    @Override
    public List<GpsQualityLineDeviation> findByTestIdOrderBySequenceNo(Long testId) {
        return springDataRepo.findByTestIdOrderBySequenceNo(testId).stream()
                .map(this::toDomain).toList();
    }

    @Override
    public void deleteByTestId(Long testId) {
        springDataRepo.deleteByTestId(testId);
    }

    private GpsQualityLineDeviationJpaEntity toJpa(GpsQualityLineDeviation d) {
        GpsQualityLineDeviationJpaEntity jpa = new GpsQualityLineDeviationJpaEntity();
        jpa.setId(d.getId());
        jpa.setTestId(d.getTestId());
        jpa.setSequenceNo(d.getSequenceNo());
        jpa.setRecordedAt(d.getRecordedAt());
        jpa.setLongitude(d.getLongitude());
        jpa.setLatitude(d.getLatitude());
        jpa.setDeviationM(d.getDeviationM());
        jpa.setSegmentNo(d.getSegmentNo());
        return jpa;
    }

    private GpsQualityLineDeviation toDomain(GpsQualityLineDeviationJpaEntity jpa) {
        GpsQualityLineDeviation d = new GpsQualityLineDeviation();
        d.setId(jpa.getId());
        d.setTestId(jpa.getTestId());
        d.setSequenceNo(jpa.getSequenceNo());
        d.setRecordedAt(jpa.getRecordedAt());
        d.setLongitude(jpa.getLongitude());
        d.setLatitude(jpa.getLatitude());
        d.setDeviationM(jpa.getDeviationM());
        d.setSegmentNo(jpa.getSegmentNo());
        return d;
    }
}
