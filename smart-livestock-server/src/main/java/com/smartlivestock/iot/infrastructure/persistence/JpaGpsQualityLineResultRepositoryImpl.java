package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsQualityLineResult;
import com.smartlivestock.iot.domain.repository.GpsQualityLineResultRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsQualityLineResultJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaGpsQualityLineResultRepositoryImpl implements GpsQualityLineResultRepository {

    private final SpringDataGpsQualityLineResultRepository springDataRepo;

    @Override
    public GpsQualityLineResult save(GpsQualityLineResult result) {
        GpsQualityLineResultJpaEntity jpa = toJpa(result);
        if (result.getTestId() != null) {
            springDataRepo.findById(result.getTestId())
                    .ifPresent(existing -> jpa.setComputedAt(existing.getComputedAt()));
        }
        return toDomain(springDataRepo.save(jpa));
    }

    @Override
    public Optional<GpsQualityLineResult> findByTestId(Long testId) {
        return springDataRepo.findById(testId).map(this::toDomain);
    }

    @Override
    public void deleteByTestId(Long testId) {
        springDataRepo.deleteById(testId);
    }

    private GpsQualityLineResultJpaEntity toJpa(GpsQualityLineResult r) {
        GpsQualityLineResultJpaEntity jpa = new GpsQualityLineResultJpaEntity();
        jpa.setTestId(r.getTestId());
        jpa.setSampleCount(r.getSampleCount());
        jpa.setTripCount(r.getTripCount());
        jpa.setMeanDeviationM(r.getMeanDeviationM());
        jpa.setP50M(r.getP50M());
        jpa.setP95M(r.getP95M());
        jpa.setMaxDeviationM(r.getMaxDeviationM());
        jpa.setWithin15mPct(r.getWithin15mPct());
        jpa.setWithin25mPct(r.getWithin25mPct());
        jpa.setWithin40mPct(r.getWithin40mPct());
        jpa.setGrade(r.getGrade());
        jpa.setFirstRecordedAt(r.getFirstRecordedAt());
        jpa.setLastRecordedAt(r.getLastRecordedAt());
        jpa.setComputedAt(r.getComputedAt());
        return jpa;
    }

    private GpsQualityLineResult toDomain(GpsQualityLineResultJpaEntity jpa) {
        GpsQualityLineResult r = new GpsQualityLineResult();
        r.setTestId(jpa.getTestId());
        r.setSampleCount(jpa.getSampleCount());
        r.setTripCount(jpa.getTripCount());
        r.setMeanDeviationM(jpa.getMeanDeviationM());
        r.setP50M(jpa.getP50M());
        r.setP95M(jpa.getP95M());
        r.setMaxDeviationM(jpa.getMaxDeviationM());
        r.setWithin15mPct(jpa.getWithin15mPct());
        r.setWithin25mPct(jpa.getWithin25mPct());
        r.setWithin40mPct(jpa.getWithin40mPct());
        r.setGrade(jpa.getGrade());
        r.setFirstRecordedAt(jpa.getFirstRecordedAt());
        r.setLastRecordedAt(jpa.getLastRecordedAt());
        r.setComputedAt(jpa.getComputedAt());
        return r;
    }
}
